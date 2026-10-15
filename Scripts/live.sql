/*
SQLyog Community
MySQL - 8.0.25-commercial : Database - db_leave_management_v1
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
USE `db_leave_management_v1`;

/* Procedure structure for procedure `sp_create_audit_report` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_create_audit_report` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_audit_report`()
BEGIN

  DECLARE var_current_year INT DEFAULT YEAR(CURDATE());
  DECLARE var_current_month INT DEFAULT MONTH(CURDATE());
  DECLARE var_start_year_num INT DEFAULT YEAR(CURDATE());
  DECLARE var_end_year_num INT DEFAULT YEAR(CURDATE());

  if var_current_month >= 1 AND  var_current_month <= 3 THEN
      SET var_start_year_num = var_start_year_num-1;
      SET var_end_year_num = var_start_year_num+1;
  END IF;
  if var_current_month >= 4 AND  var_current_month <= 12 THEN
      SET var_start_year_num = var_start_year_num;
      SET var_end_year_num = var_start_year_num+1;
  END IF;

  

  
  SET @leave_type_id = 1;
  WHILE @leave_type_id <= 2 DO
      DROP TABLE IF EXISTS tbl_leave_ledger_for_audit;
      CREATE TABLE tbl_leave_ledger_for_audit like tbl_leave_ledger;
      IF @leave_type_id = 1 THEN 
        INSERT into tbl_leave_ledger_for_audit
        SELECT * FROM tbl_leave_ledger WHERE leave_type_id = @leave_type_id AND year_no >= var_current_year  AND remark NOT LIKE '%correction%' AND remark NOT LIKE '%wrong%' ORDER BY id_ ASC;
      ELSE
        INSERT into tbl_leave_ledger_for_audit
        SELECT * FROM tbl_leave_ledger WHERE leave_type_id = @leave_type_id AND year_no >= var_current_year  AND remark NOT LIKE '%correction%' AND remark NOT LIKE '%wrong%' ORDER BY id_ ASC;
      END IF;

      IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-04-01'))) THEN
        DROP TABLE IF EXISTS db_leave_management_v1.tbl_apr;
        CREATE TABLE db_leave_management_v1.tbl_apr
        SELECT * FROM (
        SELECT employee_id,leave_type_id,
        IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_apr,
        SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_apr,
        SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_apr,
        SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_apr,
        SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_apr
        FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
        join db_hr.tbl_employee_info b
        on a.employee_id = b.empcode
        WHERE month_no = 4  AND year_no = var_start_year_num
        AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-04-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
        GROUP BY employee_id,leave_type_id) a;

        drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_apr a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-04-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_apr
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-04-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
      END IF;


    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-05-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_may;
      CREATE TABLE db_leave_management_v1.tbl_may
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_may,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_may,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_may,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_may,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_may
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 5  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-05-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_may a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-05-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_may
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-05-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-06-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_jun;
      CREATE TABLE db_leave_management_v1.tbl_jun
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_jun,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_jun,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_jun,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_jun,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_jun
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 6  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-06-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_jun a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-06-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_jun
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-06-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;


    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-07-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_jul;
      CREATE TABLE db_leave_management_v1.tbl_jul
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_jul,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_jul,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_jul,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_jul,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_jul
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 7  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-07-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_jul a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-07-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_jul
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-07-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;


    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-08-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_aug;
      CREATE TABLE db_leave_management_v1.tbl_aug
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_aug,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_aug,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_aug,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_aug,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_aug
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 8  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-08-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_aug a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-08-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_aug
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-08-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;


    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-09-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_sep;
      CREATE TABLE db_leave_management_v1.tbl_sep
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_sep,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_sep,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_sep,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_sep,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_sep
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 9  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-09-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_sep a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-09-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_sep
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-09-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;


    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-10-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_oct;
      CREATE TABLE db_leave_management_v1.tbl_oct
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_oct,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_oct,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_oct,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_oct,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_oct
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 10  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-10-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_oct a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-10-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_oct
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-10-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;


    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-11-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_nov;
      CREATE TABLE db_leave_management_v1.tbl_nov
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_nov,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_nov,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_nov,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_nov,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_nov
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 11  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-11-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_nov a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-11-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_nov
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-11-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;

    END IF;


    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-12-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_dec;
      CREATE TABLE db_leave_management_v1.tbl_dec
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_dec,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_dec,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_dec,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_dec,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_dec
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 12  AND year_no = var_start_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-12-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_dec a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_start_year_num, '-12-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_dec
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_start_year_num, '-12-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;

    IF(CURDATE() >= DATE(CONCAT(var_end_year_num,'-01-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_jan;
      CREATE TABLE db_leave_management_v1.tbl_jan
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_jan,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_jan,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_jan,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_jan,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_jan
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 1  AND year_no = var_end_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_end_year_num, '-01-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_jan a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_end_year_num, '-01-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_jan
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_end_year_num, '-01-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;

    END IF;

    IF(CURDATE() >= DATE(CONCAT(var_end_year_num,'-02-01'))) THEN
      DROP TABLE IF EXISTS db_leave_management_v1.tbl_feb;
      CREATE TABLE db_leave_management_v1.tbl_feb
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      SUM(IF(remark like '%EXTRA CARRY FORWARDED LEAVES REVERTED%',debit,0)) laps_jan,
      ((IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)))-(SUM(IF(remark like '%EXTRA CARRY FORWARDED LEAVES REVERTED%',debit,0)))) opening_balance_feb,
      SUM(IF(remark = 'debit on account of leave application' AND remark <> 'EXTRA CARRY FORWARDED LEAVES REVERTED',debit,0)) availments_feb,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_feb,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_feb,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_feb
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 2  AND year_no = var_end_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_end_year_num, '-02-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_feb a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_end_year_num, '-02-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_feb
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_end_year_num, '-02-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;

    IF(CURDATE() >= DATE(CONCAT(var_end_year_num,'-03-01'))) THEN

      DROP TABLE IF EXISTS db_leave_management_v1.tbl_mar;
      CREATE TABLE db_leave_management_v1.tbl_mar
      SELECT * FROM (
      SELECT employee_id,leave_type_id,
      IF(SUBSTRING_INDEX(GROUP_CONCAT(remark ORDER BY id_ ASC),',',1) like '%trans%',SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ ASC),',',1),SUBSTRING_INDEX(GROUP_CONCAT(previous_balance ORDER BY id_ ASC),',',1)) opening_balance_mar,
      SUM(IF(remark = 'debit on account of leave application',debit,0)) availments_mar,
      SUM(IF(remark like '%hours%' OR remark LIKE '%Leave Quota Adjusted%' OR remark like '%HR%',debit,0)) auto_adjustments_mar,
      SUM(IF((remark like '%credit%' OR remark LIKE '%Leave Quota Adjusted%'),credit,0)) entitlements_mar,
      SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) closing_balance_mar
      FROM db_leave_management_v1.tbl_leave_ledger_for_audit a
      join db_hr.tbl_employee_info b
      on a.employee_id = b.empcode 
      WHERE  month_no = 3  AND year_no = var_end_year_num
      AND (b.date_of_leaving > DATE(CONCAT(var_end_year_num, '-03-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00')
      GROUP BY employee_id,leave_type_id) a;

      drop table if exists db_leave_management_v1.tbl_left_over_employees_for_audit_report;
        create table db_leave_management_v1.tbl_left_over_employees_for_audit_report
        select empcode from db_hr.tbl_employee_info b
        left JOIN db_leave_management_v1.tbl_mar a
        on b.empcode = a.employee_id
        where ((b.date_of_leaving > DATE(CONCAT(var_end_year_num, '-03-01')) OR b.date_of_leaving IS NULL OR b.date_of_leaving = '0000-00-00 00:00:00') and a.employee_id is null) AND ((empcode like '1%' OR empcode like '0%') AND length(empcode) <= 8);

        INSERT IGNORE INTO db_leave_management_v1.tbl_mar
        SELECT employee_id,@leave_type_id leave_type_id,balance opening_balance_apr,0 availments_apr,0 auto_adjustments_apr,0 entitlements_apr,balance closing_balance_apr
        FROM tbl_left_over_employees_for_audit_report a
        JOIN (
            SELECT employee_id,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1) balance
            FROM tbl_leave_ledger_for_audit
            WHERE update_at < DATE(CONCAT(var_end_year_num, '-03-01 04:00:00'))
            GROUP BY employee_id
            ORDER BY update_at DESC
        ) last_balance 
        ON a.empcode = last_balance.employee_id
        GROUP BY a.empcode;
    END IF;

    DROP TABLE IF EXISTS db_leave_management_v1.tbl_report;
    CREATE TABLE db_leave_management_v1.tbl_report (
    `Empcode` VARCHAR(50) CHARACTER SET latin1 NOT NULL,
    `Empname` VARCHAR(255)  DEFAULT NULL,
    `Grade` VARCHAR(12)  DEFAULT NULL,
    `City` VARCHAR(65)  DEFAULT NULL,
    `Att Rule` VARCHAR(255)  DEFAULT NULL,
    `Section` VARCHAR(255)  DEFAULT NULL,
    `Department` VARCHAR(255)  DEFAULT NULL,
    `Designation` VARCHAR(255)  DEFAULT NULL,
    `Workable Days Per Week` INT DEFAULT NULL,
    `STATUS` VARCHAR(255)  DEFAULT NULL,
    `advance_leave` TEXT,
    `added_on` DATETIME DEFAULT NULL,
    `left_on` DATETIME DEFAULT NULL,
    `attendanceid` INT DEFAULT NULL,
    PRIMARY KEY(empcode)
    ) ENGINE = MYISAM;

    TRUNCATE db_leave_management_v1.tbl_report;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-04-01'))) THEN

      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_apr` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_apr` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_apr` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_apr` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_apr` DECIMAL(4, 2) DEFAULT '0.00';
      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_apr; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_apr b ON a.empcode = b.employee_id
      SET
        a.opening_balance_apr = b.opening_balance_apr,
        a.availments_apr = IFNULL(b.availments_apr,0),
        a.entitlements_apr = IFNULL(b.entitlements_apr,0),
        a.closing_balance_apr = IFNULL(b.closing_balance_apr,0),
        a.auto_adjustments_apr = IFNULL(b.auto_adjustments_apr,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-05-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_may` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_may` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_may` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_may` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_may` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_may; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_may b ON a.empcode = b.employee_id
      SET
        a.opening_balance_may = b.opening_balance_may,
        a.availments_may = IFNULL(b.availments_may,0),
        a.entitlements_may = IFNULL(b.entitlements_may,0),
        a.closing_balance_may = IFNULL(b.closing_balance_may,0),
        a.auto_adjustments_may = IFNULL(b.auto_adjustments_may,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-06-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_jun` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_jun` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_jun` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_jun` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_jun` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_jun; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_jun b ON a.empcode = b.employee_id
      SET
        a.opening_balance_jun = b.opening_balance_jun,
        a.availments_jun = IFNULL(b.availments_jun,0),
        a.entitlements_jun = IFNULL(b.entitlements_jun,0),
        a.closing_balance_jun = IFNULL(b.closing_balance_jun,0),
        a.auto_adjustments_jun = IFNULL(b.auto_adjustments_jun,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-07-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_jul` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_jul` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_jul` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_jul` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_jul` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_jul; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_jul b ON a.empcode = b.employee_id
      SET
        a.opening_balance_jul = b.opening_balance_jul,
        a.availments_jul = IFNULL(b.availments_jul,0),
        a.entitlements_jul = IFNULL(b.entitlements_jul,0),
        a.closing_balance_jul = IFNULL(b.closing_balance_jul,0),
        a.auto_adjustments_jul = IFNULL(b.auto_adjustments_jul,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-08-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_aug` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_aug` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_aug` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_aug` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_aug` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_aug; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_aug b ON a.empcode = b.employee_id
      SET
        a.opening_balance_aug = b.opening_balance_aug,
        a.availments_aug = IFNULL(b.availments_aug,0),
        a.entitlements_aug = IFNULL(b.entitlements_aug,0),
        a.closing_balance_aug = IFNULL(b.closing_balance_aug,0),
        a.auto_adjustments_aug = IFNULL(b.auto_adjustments_aug,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-09-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_sep` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_sep` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_sep` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_sep` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_sep` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_sep; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_sep b ON a.empcode = b.employee_id
      SET
        a.opening_balance_sep = b.opening_balance_sep,
        a.availments_sep = IFNULL(b.availments_sep,0),
        a.entitlements_sep = IFNULL(b.entitlements_sep,0),
        a.closing_balance_sep = IFNULL(b.closing_balance_sep,0),
        a.auto_adjustments_sep = IFNULL(b.auto_adjustments_sep,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-10-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_oct` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_oct` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_oct` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_oct` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_oct` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_oct; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_oct b ON a.empcode = b.employee_id
      SET
        a.opening_balance_oct = b.opening_balance_oct,
        a.availments_oct = IFNULL(b.availments_oct,0),
        a.entitlements_oct = IFNULL(b.entitlements_oct,0),
        a.closing_balance_oct = IFNULL(b.closing_balance_oct,0),
        a.auto_adjustments_oct = IFNULL(b.auto_adjustments_oct,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-11-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_nov` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_nov` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_nov` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_nov` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_nov` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_nov; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_nov b ON a.empcode = b.employee_id
      SET
        a.opening_balance_nov = b.opening_balance_nov,
        a.availments_nov = IFNULL(b.availments_nov,0),
        a.entitlements_nov = IFNULL(b.entitlements_nov,0),
        a.closing_balance_nov = IFNULL(b.closing_balance_nov,0),
        a.auto_adjustments_nov = IFNULL(b.auto_adjustments_nov,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_start_year_num,'-12-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_dec` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_dec` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_dec` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_dec` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_dec` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_dec; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_dec b ON a.empcode = b.employee_id
      SET
        a.opening_balance_dec = b.opening_balance_dec,
        a.availments_dec = IFNULL(b.availments_dec,0),
        a.entitlements_dec = IFNULL(b.entitlements_dec,0),
        a.closing_balance_dec = IFNULL(b.closing_balance_dec,0),
        a.auto_adjustments_dec = IFNULL(b.auto_adjustments_dec,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_end_year_num,'-01-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_jan` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_jan` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_jan` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_jan` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_jan` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_jan; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_jan b ON a.empcode = b.employee_id
      SET
        a.opening_balance_jan = b.opening_balance_jan,
        a.availments_jan = IFNULL(b.availments_jan,0),
        a.entitlements_jan = IFNULL(b.entitlements_jan,0),
        a.closing_balance_jan = IFNULL(b.closing_balance_jan,0),
        a.auto_adjustments_jan = IFNULL(b.auto_adjustments_jan,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_end_year_num,'-02-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `laps_jan` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `opening_balance_feb` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_feb` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_feb` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_feb` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_feb` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_feb; 
      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_feb b ON a.empcode = b.employee_id
      SET
        a.laps_jan = b.laps_jan,
        a.opening_balance_feb = b.opening_balance_feb,
        a.availments_feb = IFNULL(b.availments_feb,0),
        a.entitlements_feb = IFNULL(b.entitlements_feb,0),
        a.closing_balance_feb = IFNULL(b.closing_balance_feb,0),
        a.auto_adjustments_feb = IFNULL(b.auto_adjustments_feb,0);
    end if;

    IF(CURDATE() >= DATE(CONCAT(var_end_year_num,'-03-01'))) THEN
      ALTER TABLE db_leave_management_v1.tbl_report
      ADD `opening_balance_mar` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `availments_mar` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `auto_adjustments_mar` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `entitlements_mar` DECIMAL(4, 2) DEFAULT '0.00',
      ADD `closing_balance_mar` DECIMAL(4, 2) DEFAULT '0.00';

      INSERT IGNORE INTO db_leave_management_v1.tbl_report(empcode)
      SELECT employee_id FROM db_leave_management_v1.tbl_mar; 

      UPDATE
        db_leave_management_v1.tbl_report a
        JOIN db_leave_management_v1.tbl_mar b ON a.empcode = b.employee_id
      SET
        a.opening_balance_mar = b.opening_balance_mar,
        a.availments_mar = IFNULL(b.availments_mar,0),
        a.entitlements_mar = IFNULL(b.entitlements_mar,0),
        a.closing_balance_mar = IFNULL(b.closing_balance_mar,0),
        a.auto_adjustments_mar = IFNULL(b.auto_adjustments_mar,0);
    end if;

    UPDATE db_leave_management_v1.tbl_report a
    JOIN db_hr.tbl_employee_info b
    ON a.empcode = b.empcode
    SET a.Empname = b.Empname, a.grade = b.grade, a.Section=b.Section, a.Department=b.Department,a.`Workable Days Per Week`  = no_of_workable_days_per_week,a.city = b.city,a.Designation=b.Designation,a.added_on=b.added_on,a.left_on = b.date_of_leaving,STATUS = IF(resign_flag = 1 AND delete_flag = 0,'Active','Inactive');


    UPDATE db_leave_management_v1.tbl_report a
    JOIN db_attendance.tbl_empdeptattendance_mapping  b
    ON a.empcode = b.empid
    SET a.attendanceid = b.attendanceid;

    UPDATE db_leave_management_v1.tbl_report a
    JOIN db_attendance.tbl_attendance_rule  b
    ON a.attendanceid = b.attendanceid
    SET a.`Att Rule` = b.title;

    UPDATE db_leave_management_v1.tbl_report a
    JOIN db_attendance.tbl_attendance_rule  b
    ON a.attendanceid = b.attendanceid
    SET a.`Att Rule` = b.title;

    UPDATE db_leave_management_v1.tbl_report a
    LEFT JOIN `temp_tbl_employees_for_leave_accounting_new` b
    ON a.empcode = b.empid
    SET advance_leave = IF(b.frequency_id = 1,'Advance',IF(b.frequency_id = 2,'Accrul',NULL));

    UPDATE db_leave_management_v1.tbl_report a
    JOIN leave_rule_configuration b
    ON a.attendanceid = b.rule_id AND IF(a.grade = 'staff', a.grade, TRIM(REPLACE(a.grade, 'G', ''))) = b.grade AND a.`Workable Days Per Week` = b.working_days
    SET advance_leave = IF(b.frequency_id = 1,'Advance',IF(b.frequency_id = 2,'Accrul',NULL))
    WHERE advance_leave IS NULL;


    DELETE FROM  db_leave_management_v1.tbl_report
    WHERE empname IS NULL;

    DELETE FROM db_leave_management_v1.tbl_report
    WHERE (empcode not like '1%' AND empcode not like '0%' )OR length(empcode) > 8;

    ALTER TABLE db_leave_management_v1.tbl_report
    DROP COLUMN  attendanceid;

    DELETE from db_leave_management_v1.tbl_report 
    where empcode in (select employee_id from (select *,count(1) cnt_ from db_leave_management_v1.tbl_leave_ledger WHERE leave_type_id = 1 group by employee_id having cnt_ = 1 and balance = 0) b);

    SET @report_name = IF(@leave_type_id = 1,'_sl_','_pl_');
    SET @sql_query = CONCAT("DROP TABLE IF EXISTS db_leave_management_v1.tbl",@report_name,"report_",var_start_year_num);

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    SET @sql_query = CONCAT("RENAME table db_leave_management_v1.tbl_report to db_leave_management_v1.tbl",@report_name,"report_",var_start_year_num);

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;

  SET @leave_type_id = @leave_type_id+1;
  END WHILE;


END */$$
DELIMITER ;

/* Procedure structure for procedure `sp_credit_fresh_leaves` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_credit_fresh_leaves` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_credit_fresh_leaves`(var_employee_id VARCHAR(60),var_month_num INT,var_year_num INT,var_rank INT)
BEGIN

DECLARE var_employee_leave_quota_PL DECIMAL(4,2) DEFAULT 0;
DECLARE var_employee_leave_quota_SL DECIMAL(4,2) DEFAULT 0;
DECLARE max_entry_ids INT DEFAULT 0;
DECLARE var_counter INT DEFAULT 0;
DECLARE var_loop_employee_id VARCHAR(60) CHARSET utf8mb4;
DECLARE var_frequency TINYINT DEFAULT 1;
DECLARE max_num_leave_per_year_PL DECIMAL(4,2) DEFAULT 0;
DECLARE max_num_leave_per_year_SL DECIMAL(4,2) DEFAULT 0;
DECLARE var_emp_fresh_entries_for_this_month INT DEFAULT 0;
DECLARE var_emp_fresh_pl_entries_for_this_month INT DEFAULT 0;
DECLARE var_emp_fresh_sl_entries_for_this_month INT DEFAULT 0;
DECLARE month_year VARCHAR(20) DEFAULT NULL;
DECLARE var_input_params JSON DEFAULT NULL;
DECLARE var_confirmation_flag INT DEFAULT 1;
DECLARE var_added_on DATETIME DEFAULT NULL;
DECLARE var_confirmation_date DATETIME DEFAULT NULL;
DECLARE var_months_remaining INT DEFAULT 1;
DECLARE var_left_on DATETIME DEFAULT NULL;
DECLARE var_active_flag INT DEFAULT 0;
DECLARE const_cycle_start_month INT DEFAULT 1;
DECLARE const_current_cycle_year INT DEFAULT 2024;
DECLARE var_PL_credited DECIMAL(8,2) DEFAULT 0;
DECLARE var_SL_credited DECIMAL(8, 2) DEFAULT 0;
DECLARE var_PL_credited_curr_month DECIMAL(8,2) DEFAULT 0;
DECLARE var_SL_debited_for_adjustment DECIMAL(8, 2) DEFAULT 0;
DECLARE var_SL_credited_for_adjustment DECIMAL(8, 2) DEFAULT 0;
DECLARE var_PL_debited_for_adjustment DECIMAL(8, 2) DEFAULT 0;
DECLARE var_PL_credited_for_adjustment DECIMAL(8, 2) DEFAULT 0;
DECLARE var_latest_object_index INT DEFAULT 0;
DECLARE const_cycle_start_date INT DEFAULT 1;
DECLARE const_current_date DATETIME DEFAULT CURRENT_TIMESTAMP;

DECLARE error_code CHAR(5) DEFAULT NULL;
DECLARE error_message TEXT DEFAULT 'success';

DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1
						error_code = RETURNED_SQLSTATE, 
						error_message = MESSAGE_TEXT;
				CALL sp_create_leave_accounting_log('NA','NA','NA','sp_credit_fresh_leaves',error_message,const_current_date,'NA',NULL,NULL,CURRENT_TIMESTAMP,0,var_input_params);
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
		END;

SET var_input_params = JSON_OBJECT(
		'employee_id',var_employee_id,
		'month_num',var_month_num,
		'year_num',var_year_num,
		'action_date',const_current_date,
		'rank',var_rank
);



CALL sp_get_month_name_with_year(var_month_num, var_year_num, @result);
SET month_year = @result;

SELECT cycle_start_month,cycle_start_date,current_cycle_year INTO const_cycle_start_month,const_cycle_start_date,const_current_cycle_year FROM `tbl_leave_cycle_config`;

SELECT
		CASE
				WHEN var_month_num >= const_cycle_start_month THEN 12 - var_month_num + const_cycle_start_month
				ELSE const_cycle_start_month - var_month_num
		END INTO var_months_remaining;

IF var_employee_id IS NULL THEN
		START TRANSACTION;
		SELECT COUNT(1) INTO max_entry_ids FROM  temp_tbl_employees_for_leave_accounting_new WHERE empid IN (SELECT DISTINCT employee_id FROM tbl_leave_balances) AND  rank_ = var_rank FOR SHARE;
		COMMIT;
		WHILE var_counter < max_entry_ids DO
				START TRANSACTION;
					SELECT empid INTO var_loop_employee_id FROM  temp_tbl_employees_for_leave_accounting_new WHERE empid IN (SELECT DISTINCT employee_id FROM tbl_leave_balances) AND  rank_ = var_rank LIMIT var_counter,1 FOR SHARE;
				COMMIT;
				IF var_loop_employee_id IS NOT NULL THEN
						SELECT frequency_id,max_num_leave_per_year,sl_max_num_leave_per_year,confirmation_flag,entry_on,confirmation_date,left_on INTO var_frequency,max_num_leave_per_year_PL,max_num_leave_per_year_SL,var_confirmation_flag,var_added_on,var_confirmation_date,var_left_on FROM  temp_tbl_employees_for_leave_accounting_new WHERE empid = var_loop_employee_id;
						IF var_left_on = '0000-00-00 00:00:00' OR var_left_on IS NULL THEN 
								SET var_active_flag = 1;
						ELSE
								SET var_active_flag = 0;
						END IF;
						SET var_PL_credited = 0;
						SET var_SL_credited = 0;
						SET var_PL_debited_for_adjustment = 0;
						SET var_PL_credited_for_adjustment = 0;
						SET var_SL_debited_for_adjustment = 0;
						SET var_SL_credited_for_adjustment = 0;
						IF var_frequency = 1 THEN
								SELECT COUNT(1) INTO var_emp_fresh_pl_entries_for_this_month FROM tbl_leave_ledger WHERE 
								update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND leave_type_id = 2;
								SELECT COUNT(1) INTO var_emp_fresh_sl_entries_for_this_month FROM tbl_leave_ledger WHERE 
								update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND leave_type_id = 1;
						ELSEIF var_frequency = 2 THEN
								SELECT COUNT(1) INTO var_emp_fresh_pl_entries_for_this_month FROM tbl_leave_ledger WHERE year_no = const_current_cycle_year AND month_no = var_month_num AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND employee_id = var_loop_employee_id AND leave_type_id = 2;
								SELECT COUNT(1) INTO var_emp_fresh_sl_entries_for_this_month FROM tbl_leave_ledger  WHERE year_no = const_current_cycle_year AND month_no = var_month_num AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND employee_id = var_loop_employee_id AND leave_type_id = 1;

								SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0), ifnull(SUM(CASE WHEN leave_type_id = 1 THEN credit ELSE 0 END),0) INTO var_PL_credited,var_SL_credited
									FROM tbl_leave_ledger
									WHERE update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND remark LIKE '%Fresh%leave%';

								SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0) INTO var_PL_credited_curr_month
									FROM tbl_leave_ledger
									WHERE month_no = MONTH(NOW()) AND year_no = YEAR(NOW()) AND employee_id = var_loop_employee_id AND remark LIKE '%Fresh%leave%'; 	

								SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN debit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 1 THEN debit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 1 THEN credit ELSE 0 END),0) INTO var_PL_debited_for_adjustment,
								var_PL_credited_for_adjustment,
								var_SL_debited_for_adjustment,
								var_SL_credited_for_adjustment 
								FROM tbl_leave_ledger WHERE update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND (remark LIKE 'leave quota%' OR remark like '%HR%module%');

						END IF;
						SET var_employee_leave_quota_PL = 0;
						SET var_employee_leave_quota_SL = 0;
						IF var_frequency IS NOT NULL AND max_num_leave_per_year_PL IS NOT NULL AND var_active_flag = 1 THEN
								IF var_frequency = 1 THEN
										IF var_emp_fresh_pl_entries_for_this_month = 0 THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL/12 * var_months_remaining;
										END IF;
										IF var_emp_fresh_sl_entries_for_this_month = 0 THEN
												SET var_employee_leave_quota_SL = max_num_leave_per_year_SL/12 * var_months_remaining;
										END IF;
								ELSEIF var_frequency = 2 AND (DATEDIFF(const_current_date, var_added_on)+1 = 180 AND var_emp_fresh_pl_entries_for_this_month = 0)THEN 
										IF var_PL_credited_curr_month = 0 THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL / 12 * 6;
										ELSEIF DAY(var_added_on) > 15 AND var_PL_credited_curr_month >= 1  THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL / 12 * 5;
										END IF;
								ELSEIF var_frequency = 2 AND DATEDIFF(const_current_date, var_added_on)+1 > 180 AND var_emp_fresh_pl_entries_for_this_month = 0 THEN
										SET var_employee_leave_quota_PL = max_num_leave_per_year_PL/12;
								END IF; 
								IF var_emp_fresh_sl_entries_for_this_month = 0 AND var_frequency = 2 AND (
								(YEAR(CURDATE()) = YEAR(var_added_on) AND MONTH(CURDATE()) = MONTH(var_added_on) AND DAY(var_added_on) < 15) OR (YEAR(CURDATE()) > YEAR(var_added_on) OR (YEAR(CURDATE()) = YEAR(var_added_on) AND MONTH(CURDATE()) > MONTH(var_added_on)))
									)  THEN
										SET var_employee_leave_quota_SL = max_num_leave_per_year_SL/12;
								END IF;

								IF var_PL_credited IS NULL THEN SET var_PL_credited = 0; END IF;
								IF var_SL_credited IS NULL THEN SET var_SL_credited = 0; END IF;
								IF var_PL_debited_for_adjustment IS NULL THEN SET var_PL_debited_for_adjustment = 0; END IF;
								IF var_PL_credited_for_adjustment IS NULL THEN SET var_PL_credited_for_adjustment = 0; END IF;
								IF var_SL_debited_for_adjustment IS NULL THEN SET var_SL_debited_for_adjustment = 0; END IF;
								IF var_SL_credited_for_adjustment IS NULL THEN SET var_SL_credited_for_adjustment = 0; END IF;
								IF var_employee_leave_quota_SL > 0 THEN
									IF var_frequency = 2 THEN 
										IF var_SL_credited+var_SL_credited_for_adjustment-var_SL_debited_for_adjustment+var_employee_leave_quota_SL <= max_num_leave_per_year_SL/12*var_month_num THEN
											START TRANSACTION;
												CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_SL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),1,'fresh');
											COMMIT;
										END IF;
									ELSE
										IF var_SL_credited+var_SL_credited_for_adjustment-var_SL_debited_for_adjustment+var_employee_leave_quota_SL <= max_num_leave_per_year_SL THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_SL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),1,'fresh');
										COMMIT;
										END IF;
									END IF;
								END IF;
								IF var_employee_leave_quota_PL > 0 THEN
									IF var_frequency = 2 THEN
										IF var_PL_credited+var_PL_credited_for_adjustment-var_PL_debited_for_adjustment+var_employee_leave_quota_PL <= max_num_leave_per_year_PL/12*var_month_num THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_PL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),2,'fresh');
										COMMIT;
										END IF;
									ELSE
										IF var_PL_credited+var_PL_credited_for_adjustment-var_PL_debited_for_adjustment+var_employee_leave_quota_PL <= max_num_leave_per_year_PL THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_PL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),2,'fresh');
										COMMIT;
										END IF;
									END IF;
								END IF;
						END IF;
				END IF; 
				SET var_counter = var_counter + 1;
		END WHILE;		
		SET var_counter = 0;
		SELECT COUNT(1) INTO max_entry_ids FROM  temp_tbl_employees_for_leave_accounting_new a 
		LEFT JOIN tbl_leave_balances b
		ON b.employee_id = a.empid 
		WHERE b.balance_id IS NULL AND a.rank_ = var_rank;
		WHILE var_counter < max_entry_ids DO
				SELECT empid INTO var_loop_employee_id FROM  temp_tbl_employees_for_leave_accounting_new a 
				LEFT JOIN tbl_leave_balances b
				ON b.employee_id = a.empid 
				WHERE b.balance_id IS NULL AND a.rank_ = var_rank LIMIT var_counter,1;
				IF var_loop_employee_id IS NOT NULL THEN
						SELECT frequency_id,max_num_leave_per_year,sl_max_num_leave_per_year,confirmation_flag,entry_on,confirmation_date,left_on INTO var_frequency,max_num_leave_per_year_PL,max_num_leave_per_year_SL,var_confirmation_flag,var_added_on,var_confirmation_date,var_left_on FROM  temp_tbl_employees_for_leave_accounting_new WHERE empid = var_loop_employee_id;
						IF var_left_on = '0000-00-00 00:00:00' OR var_left_on IS NULL THEN 
								SET var_active_flag = 1;
						ELSE
								SET var_active_flag = 0;
						END IF;
						SET var_PL_credited = 0;
						SET var_SL_credited = 0;
						SET var_PL_debited_for_adjustment = 0;
						SET var_PL_credited_for_adjustment = 0;
						SET var_SL_debited_for_adjustment = 0;
						SET var_SL_credited_for_adjustment = 0;
						IF var_frequency = 1 THEN
								SELECT COUNT(1) INTO var_emp_fresh_pl_entries_for_this_month FROM tbl_leave_ledger WHERE 
								update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND leave_type_id = 2;
								SELECT COUNT(1) INTO var_emp_fresh_sl_entries_for_this_month FROM tbl_leave_ledger WHERE 
								update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND leave_type_id = 1;
						ELSEIF var_frequency = 2 THEN
								SELECT COUNT(1) INTO var_emp_fresh_pl_entries_for_this_month FROM tbl_leave_ledger WHERE year_no = const_current_cycle_year AND month_no = var_month_num AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND employee_id = var_loop_employee_id AND leave_type_id = 2;
								SELECT COUNT(1) INTO var_emp_fresh_sl_entries_for_this_month FROM tbl_leave_ledger  WHERE year_no = const_current_cycle_year AND month_no = var_month_num AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND employee_id = var_loop_employee_id AND leave_type_id = 1;

								SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0), ifnull(SUM(CASE WHEN leave_type_id = 1 THEN credit ELSE 0 END),0) INTO var_PL_credited,var_SL_credited
									FROM tbl_leave_ledger
									WHERE update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND remark LIKE '%Fresh%leave%';

									SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0) INTO var_PL_credited_curr_month
									FROM tbl_leave_ledger
									WHERE month_no = MONTH(NOW()) AND year_no = YEAR(NOW()) AND employee_id = var_loop_employee_id AND remark LIKE '%Fresh%leave%';

								SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN debit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 1 THEN debit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 1 THEN credit ELSE 0 END),0) 
								INTO 
								var_PL_debited_for_adjustment,
								var_PL_credited_for_adjustment,
								var_SL_debited_for_adjustment,
								var_SL_credited_for_adjustment 
								FROM tbl_leave_ledger WHERE update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_loop_employee_id AND (remark LIKE 'leave quota%' OR remark like '%HR%module%');

						END IF;
						SET var_employee_leave_quota_PL = 0;
						SET var_employee_leave_quota_SL = 0;
						IF var_frequency IS NOT NULL AND max_num_leave_per_year_PL IS NOT NULL AND var_active_flag = 1 THEN
								IF var_frequency = 1 THEN
										IF var_emp_fresh_pl_entries_for_this_month = 0 THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL/12 * var_months_remaining;
										END IF;
										IF var_emp_fresh_sl_entries_for_this_month = 0 THEN
												SET var_employee_leave_quota_SL = max_num_leave_per_year_SL/12 * var_months_remaining;
										END IF;
								ELSEIF var_frequency = 2 AND (DATEDIFF(const_current_date, var_added_on)+1 = 180 AND var_emp_fresh_pl_entries_for_this_month = 0) THEN 
										IF var_PL_credited_curr_month = 0 THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL / 12 * 6;
										ELSEIF DAY(var_added_on) > 15 AND var_PL_credited_curr_month >= 1  THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL / 12 * 5;
										END IF;
								ELSEIF var_frequency = 2 AND DATEDIFF(const_current_date, var_added_on)+1 > 180 AND var_emp_fresh_pl_entries_for_this_month = 0 THEN
										SET var_employee_leave_quota_PL = max_num_leave_per_year_PL/12;
								END IF; 
								IF var_emp_fresh_sl_entries_for_this_month = 0 AND var_frequency = 2 AND (
								(YEAR(CURDATE()) = YEAR(var_added_on) AND MONTH(CURDATE()) = MONTH(var_added_on) AND DAY(var_added_on) < 15) OR (YEAR(CURDATE()) > YEAR(var_added_on) OR (YEAR(CURDATE()) = YEAR(var_added_on) AND MONTH(CURDATE()) > MONTH(var_added_on)))
									) THEN
										SET var_employee_leave_quota_SL = max_num_leave_per_year_SL/12;
								END IF;

								IF var_PL_credited IS NULL THEN SET var_PL_credited = 0; END IF;
								IF var_SL_credited IS NULL THEN SET var_SL_credited = 0; END IF;
								IF var_PL_debited_for_adjustment IS NULL THEN SET var_PL_debited_for_adjustment = 0; END IF;
								IF var_PL_credited_for_adjustment IS NULL THEN SET var_PL_credited_for_adjustment = 0; END IF;
								IF var_SL_debited_for_adjustment IS NULL THEN SET var_SL_debited_for_adjustment = 0; END IF;
								IF var_SL_credited_for_adjustment IS NULL THEN SET var_SL_credited_for_adjustment = 0; END IF;
								
								IF var_employee_leave_quota_SL > 0 THEN
									IF var_frequency = 2 THEN
										IF var_SL_credited+var_SL_credited_for_adjustment-var_SL_debited_for_adjustment+var_employee_leave_quota_SL <= max_num_leave_per_year_SL/ var_month_num THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_SL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),1,'fresh');
										COMMIT;
										END IF;
									ELSE
										IF var_SL_credited+var_SL_credited_for_adjustment-var_SL_debited_for_adjustment+var_employee_leave_quota_SL <= max_num_leave_per_year_SL THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_SL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),1,'fresh');
										COMMIT;
										END IF;
									END IF;
								END IF;
								IF var_employee_leave_quota_PL > 0 THEN
									IF var_frequency = 2 THEN	
										IF var_PL_credited+var_PL_credited_for_adjustment-var_PL_debited_for_adjustment+var_employee_leave_quota_PL <= max_num_leave_per_year_PL/12*var_month_num THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_PL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),2,'fresh');
										COMMIT;
										END IF;
									ELSE
										IF var_PL_credited+var_PL_credited_for_adjustment-var_PL_debited_for_adjustment+var_employee_leave_quota_PL <= max_num_leave_per_year_PL THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_loop_employee_id,var_employee_leave_quota_PL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),2,'fresh');
										COMMIT;
										END IF;
									END IF;
								END IF;
						END IF;
				END IF; 
				SET var_counter = var_counter + 1;
				
		END WHILE;
ELSE
		IF var_employee_id IS NOT NULL THEN
						SELECT frequency_id,max_num_leave_per_year,sl_max_num_leave_per_year,confirmation_flag,entry_on,confirmation_date,left_on INTO var_frequency,max_num_leave_per_year_PL,max_num_leave_per_year_SL,var_confirmation_flag,var_added_on,var_confirmation_date,var_left_on FROM  temp_tbl_employees_for_leave_accounting_new WHERE empid = var_employee_id;
						IF var_left_on = '0000-00-00 00:00:00' OR var_left_on IS NULL THEN 
								SET var_active_flag = 1;
						ELSE
								SET var_active_flag = 0;
						END IF;
						SET var_PL_credited = 0;
						SET var_SL_credited = 0;
						SET var_PL_debited_for_adjustment = 0;
						SET var_PL_credited_for_adjustment = 0;
						SET var_SL_debited_for_adjustment = 0;
						SET var_SL_credited_for_adjustment = 0;
						IF var_frequency = 1 THEN
								SELECT COUNT(1) INTO var_emp_fresh_pl_entries_for_this_month FROM tbl_leave_ledger WHERE 
								update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_employee_id AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND leave_type_id = 2;
								SELECT COUNT(1) INTO var_emp_fresh_sl_entries_for_this_month FROM tbl_leave_ledger WHERE 
								update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_employee_id AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND leave_type_id = 1;
						ELSEIF var_frequency = 2 THEN
								SELECT COUNT(1) INTO var_emp_fresh_pl_entries_for_this_month FROM tbl_leave_ledger WHERE year_no = const_current_cycle_year AND month_no = var_month_num AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND employee_id = var_employee_id AND leave_type_id = 2;
								SELECT COUNT(1) INTO var_emp_fresh_sl_entries_for_this_month FROM tbl_leave_ledger  WHERE year_no = const_current_cycle_year AND month_no = var_month_num AND (remark LIKE '%Fresh%leave%' OR remark = 'Transfering from old system to new system') AND employee_id = var_employee_id AND leave_type_id = 1;

								SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0), ifnull(SUM(CASE WHEN leave_type_id = 1 THEN credit ELSE 0 END),0) INTO var_PL_credited,var_SL_credited
									FROM tbl_leave_ledger
									WHERE update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_employee_id AND remark LIKE '%Fresh%leave%';

									SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0) INTO var_PL_credited_curr_month
									FROM tbl_leave_ledger
									WHERE month_no = MONTH(NOW()) AND year_no = YEAR(NOW()) AND employee_id = var_employee_id AND remark LIKE '%Fresh%leave%';

								SELECT 
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN debit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 2 THEN credit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 1 THEN debit ELSE 0 END),0),
								ifnull(SUM(CASE WHEN leave_type_id = 1 THEN credit ELSE 0 END),0) 
								INTO 
								var_PL_debited_for_adjustment,
								var_PL_credited_for_adjustment,
								var_SL_debited_for_adjustment,
								var_SL_credited_for_adjustment 
								FROM tbl_leave_ledger WHERE update_at >= DATE(CONCAT(const_current_cycle_year,'-',LPAD(const_cycle_start_month,2,'0'),'-',const_cycle_start_date)) AND employee_id = var_employee_id AND (remark LIKE 'leave quota%' OR remark like '%HR%module%');

						END IF;
						SET var_employee_leave_quota_PL = 0;
						SET var_employee_leave_quota_SL = 0;
						IF var_frequency IS NOT NULL AND max_num_leave_per_year_PL IS NOT NULL AND var_active_flag = 1 THEN
								IF var_frequency = 1 THEN
										IF var_emp_fresh_pl_entries_for_this_month = 0 THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL/12 * var_months_remaining;
										END IF;
										IF var_emp_fresh_sl_entries_for_this_month = 0 THEN
												SET var_employee_leave_quota_SL = max_num_leave_per_year_SL/12 * var_months_remaining;
										END IF;
								ELSEIF var_frequency = 2 AND (DATEDIFF(const_current_date, var_added_on)+1 = 180 AND var_emp_fresh_pl_entries_for_this_month = 0) THEN 
										IF var_PL_credited_curr_month = 0 THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL / 12 * 6;
										ELSEIF DAY(var_added_on) > 15 AND var_PL_credited_curr_month >= 1  THEN
												SET var_employee_leave_quota_PL = max_num_leave_per_year_PL / 12 * 5;
										END IF;
								ELSEIF var_frequency = 2 AND DATEDIFF(const_current_date, var_added_on)+1 > 180 AND var_emp_fresh_pl_entries_for_this_month = 0 THEN
										SET var_employee_leave_quota_PL = max_num_leave_per_year_PL/12;
								END IF; 
								IF var_emp_fresh_sl_entries_for_this_month = 0 AND var_frequency = 2 AND (
								(YEAR(CURDATE()) = YEAR(var_added_on) AND MONTH(CURDATE()) = MONTH(var_added_on) AND DAY(var_added_on) < 15) OR (YEAR(CURDATE()) > YEAR(var_added_on) OR (YEAR(CURDATE()) = YEAR(var_added_on) AND MONTH(CURDATE()) > MONTH(var_added_on)))
									) THEN
										SET var_employee_leave_quota_SL = max_num_leave_per_year_SL/12;
								END IF;

								IF var_PL_credited IS NULL THEN SET var_PL_credited = 0; END IF;
								IF var_SL_credited IS NULL THEN SET var_SL_credited = 0; END IF;
								IF var_PL_debited_for_adjustment IS NULL THEN SET var_PL_debited_for_adjustment = 0; END IF;
								IF var_PL_credited_for_adjustment IS NULL THEN SET var_PL_credited_for_adjustment = 0; END IF;
								IF var_SL_debited_for_adjustment IS NULL THEN SET var_SL_debited_for_adjustment = 0; END IF;
								IF var_SL_credited_for_adjustment IS NULL THEN SET var_SL_credited_for_adjustment = 0; END IF;
								IF var_employee_leave_quota_SL > 0 THEN
									IF var_frequency = 2 THEN
										IF var_SL_credited+var_SL_credited_for_adjustment-var_SL_debited_for_adjustment+var_employee_leave_quota_SL <= max_num_leave_per_year_SL/12*var_month_num THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_employee_id,var_employee_leave_quota_SL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),1,'fresh');
										COMMIT;
										END IF;
									ELSE
										IF var_SL_credited+var_SL_credited_for_adjustment-var_SL_debited_for_adjustment+var_employee_leave_quota_SL <= max_num_leave_per_year_SL/12*var_month_num THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_employee_id,var_employee_leave_quota_SL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),1,'fresh');
										COMMIT;
										END IF;
									END IF;
								END IF;
								IF var_employee_leave_quota_PL > 0 THEN
									IF var_frequency = 2 THEN
										IF var_PL_credited+var_PL_credited_for_adjustment-var_PL_debited_for_adjustment+var_employee_leave_quota_PL <= max_num_leave_per_year_PL/12*var_month_num THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_employee_id,var_employee_leave_quota_PL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),2,'fresh');
										COMMIT;
										END IF;
									ELSE
										IF var_PL_credited+var_PL_credited_for_adjustment-var_PL_debited_for_adjustment+var_employee_leave_quota_PL <= max_num_leave_per_year_PL THEN
										START TRANSACTION;
											CALL  sp_add_fresh_leaves(var_employee_id,var_employee_leave_quota_PL,'internal',CONCAT('Credit -  Fresh Leave of ',month_year),2,'fresh');
										COMMIT;
										END IF;
									END IF;
								END IF;
						END IF;
				END IF; 
END IF;
CALL sp_create_leave_accounting_log('NA','NA','NA','sp_credit_fresh_leaves',error_message,const_current_date,'NA',NULL,NULL,CURRENT_TIMESTAMP,1,var_input_params);
END */$$
DELIMITER ;

/* Procedure structure for procedure `sp_data_sanity` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_data_sanity` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_data_sanity`()
BEGIN

	UPDATE tbl_leave_ledger SET remark = 'wrong entries' WHERE employee_id = '10104431'
	AND remark = 'Credit -  Fresh LEAVE OF Apr 2025';

	CALL sp_add_new_leaves('10104431',-1,'internal','debit on account of correction',1);

	CALL sp_add_new_leaves('10104431',-1,'internal','debit on account of correction',2);
	 
END */$$
DELIMITER ;

/* Procedure structure for procedure `sp_get_employee_leave_related_data` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_get_employee_leave_related_data` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_employee_leave_related_data`(IN input_json JSON,
OUT output_json JSON)
BEGIN

    DECLARE var_employee_id VARCHAR(60);
    DECLARE var_leave_type_id INT;
    DECLARE var_leave_balance_PL DECIMAL(10,2);
    DECLARE var_leave_primary_balance_PL DECIMAL(10, 2);
    DECLARE var_leave_secondary_balance_PL DECIMAL(10, 2);
    DECLARE var_leave_balance_SL DECIMAL(10,2);
    DECLARE var_leave_primary_balance_SL DECIMAL(10, 2);
    DECLARE var_leave_secondary_balance_SL DECIMAL(10, 2);
    DECLARE var_PL_JSON JSON DEFAULT NULL;
    DECLARE var_SL_JSON JSON DEFAULT NULL;
    DECLARE var_considerate_leave_JSON JSON DEFAULT NULL;
    DECLARE var_action_type VARCHAR(20);
    DECLARE var_leave_credit_PL DECIMAL(10,2);
    DECLARE var_leave_debit_PL DECIMAL(10,2);
    DECLARE var_leave_credit_SL DECIMAL(10,2);
    DECLARE var_leave_debit_SL DECIMAL(10,2);
    DECLARE var_from_date DATETIME DEFAULT CURDATE();
    DECLARE var_to_date DATETIME DEFAULT CURRENT_TIMESTAMP;
    DECLARE var_leave_request JSON DEFAULT NULL;
    DECLARE var_late_mark_PL JSON DEFAULT NULL;
    DECLARE var_late_mark_SL JSON DEFAULT NULL;
    DECLARE var_special_leaves JSON DEFAULT NULL;
    DECLARE var_special_leave_days DECIMAL (10,2);
    DECLARE var_leave_pending_SL DECIMAL (10,2);
    DECLARE var_leave_pending_PL DECIMAL (10, 2);
    DECLARE var_balances_table VARCHAR(255) DEFAULT 'tbl_leave_balances';
    DECLARE var_requests_table VARCHAR(255) DEFAULT 'tbl_leave_requests';
    DECLARE var_ledger_table VARCHAR(255) DEFAULT 'tbl_leave_ledger';
    DECLARE var_ledger_considerate_table VARCHAR(255) DEFAULT 'tbl_leave_ledger_considerate';
    DECLARE var_leave_key VARCHAR(10) DEFAULT "leaves";
    DECLARE var_balances_table_employee VARCHAR(100) DEFAULT 'tbl_leave_balances';
    DECLARE var_ledger_table_employee VARCHAR(100) DEFAULT 'tbl_leave_ledger';
    DECLARE var_ledger_considerate_table_employee VARCHAR(100) DEFAULT 'tbl_leave_ledger_considerate';
    DECLARE var_requests_table_employee VARCHAR(100) DEFAULT 'tbl_leave_requests';
    DECLARE var_leave_fresh_credit_PL DECIMAL (10, 2);
    DECLARE var_leave_fresh_credit_SL DECIMAL (10, 2);

    
    SET var_employee_id = JSON_UNQUOTE(JSON_EXTRACT(input_json, '$.employee_id'));
    SET var_leave_type_id = JSON_UNQUOTE(JSON_EXTRACT(input_json, '$.leave_type_id'));
    SET var_from_date = IFNULL(JSON_UNQUOTE(JSON_EXTRACT(input_json, '$.from_date')),CONCAT(YEAR(NOW()),'-04-01 00:00:00'));
    SET var_to_date = IFNULL(JSON_UNQUOTE(JSON_EXTRACT(input_json, '$.to_date')),CURRENT_TIMESTAMP);

    SELECT cycle_start_month,cycle_start_date INTO @const_first_month_of_leave_cycle,@const_first_date_of_leave_cycle FROM tbl_leave_cycle_config;

    SET @var_first_date_of_leave_cycle = CONCAT(YEAR(var_from_date),'-',LPAD(@const_first_month_of_leave_cycle,2,'0'),'-',LPAD(@const_first_date_of_leave_cycle,2,'0'));

    SET @var_last_date_of_leave_cycle = CONCAT(YEAR(var_from_date)+1,'-',LPAD(@const_first_month_of_leave_cycle,2,'0'),'-',LPAD(@const_first_date_of_leave_cycle,2,'0'));
    
    IF YEAR(var_from_date) <> YEAR(NOW()) THEN
        SET var_balances_table = CONCAT(var_balances_table,'_',YEAR(var_from_date));
        SET var_ledger_table = CONCAT(var_ledger_table,'_',YEAR(var_from_date));
        SET var_ledger_considerate_table = CONCAT(var_ledger_considerate_table,'_',YEAR(var_from_date));
    END IF;
    SET var_balances_table_employee = CONCAT(var_balances_table,'_',var_employee_id);
    SET var_ledger_table_employee = CONCAT(var_ledger_table,'_',var_employee_id);
    SET var_ledger_considerate_table_employee = CONCAT(var_ledger_considerate_table,'_',var_employee_id);
    SET var_requests_table_employee = CONCAT('tbl_leave_requests_',var_employee_id);

    SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_balances_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    



    SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_ledger_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    
    
    SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_ledger_considerate_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    

    SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_requests_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql_query = CONCAT(
      "CREATE TABLE IF NOT EXISTS ",var_requests_table_employee," SELECT * from ",var_requests_table," where employee_id = '",var_employee_id,"' AND ((start_date >='",@var_first_date_of_leave_cycle,"' AND  start_date <= '",@var_last_date_of_leave_cycle,"') OR (comp_off_date >='",@var_first_date_of_leave_cycle,"' AND  comp_off_date <= '",@var_last_date_of_leave_cycle,"'))");
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql_query = CONCAT(
      "CREATE TABLE IF NOT EXISTS ",var_balances_table_employee," SELECT * from ",var_balances_table," where employee_id = '",var_employee_id,"'");
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql_query = CONCAT(
      "CREATE TABLE IF NOT EXISTS ",var_ledger_table_employee," SELECT * from ",var_ledger_table," where employee_id = '",var_employee_id,"'");
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql_query = CONCAT(
      "CREATE TABLE IF NOT EXISTS ",var_ledger_considerate_table_employee," SELECT * from ",var_ledger_considerate_table," where employee_id = '",var_employee_id,"'");
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;


      
      SET @sql_query = CONCAT(
        "SELECT balance INTO @var_leave_primary_balance_PL FROM ",var_balances_table_employee," a JOIN 
        temp_tbl_employees_for_leave_accounting_new b
        ON a.employee_id = b.empid
        WHERE employee_id = '", var_employee_id,"' AND leave_type_id = 2"
      );

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_balance_PL = @var_leave_primary_balance_PL;
      SET var_leave_primary_balance_PL = @var_leave_primary_balance_PL;
      DEALLOCATE PREPARE stmt;

      SET @sql_query = CONCAT(
        "SELECT IF(SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1)>3*max_num_leave_per_year,3 * max_num_leave_per_year,SUBSTRING_INDEX(GROUP_CONCAT(balance ORDER BY id_ DESC),',',1)) INTO @var_leave_secondary_balance_PL FROM ",var_ledger_table_employee," a JOIN 
        temp_tbl_employees_for_leave_accounting_new b
        ON a.employee_id = b.empid
        WHERE employee_id = '", var_employee_id,"' AND leave_type_id = 2 AND month_no = 12 AND year_no = 2024"
      );

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_secondary_balance_PL = @var_leave_secondary_balance_PL;
      DEALLOCATE PREPARE stmt;


      SET @sql_query = CONCAT(
        "SELECT p_balance,0 INTO @var_leave_primary_balance_SL,@var_leave_secondary_balance_SL FROM ",var_balances_table_employee," a JOIN 
        temp_tbl_employees_for_leave_accounting_new b
        ON a.employee_id = b.empid WHERE employee_id = '", var_employee_id,"' AND leave_type_id = 1"
      );

      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_balance_SL = @var_leave_primary_balance_SL+@var_leave_secondary_balance_SL;
      SET var_leave_primary_balance_SL = @var_leave_primary_balance_SL;
      SET var_leave_secondary_balance_SL = @var_leave_secondary_balance_SL;
      DEALLOCATE PREPARE stmt;

      


      

      SET @sql_query = CONCAT(
        "SELECT sum(credit) INTO @var_leave_credit_PL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 2 and (remark not like '%trans%' AND remark not like '%correction%' AND remark not like '%wrong%') AND year_no = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_credit_PL = @var_leave_credit_PL;
      DEALLOCATE PREPARE stmt;

      

      SET @sql_query = CONCAT(
        "SELECT sum(leave_days) INTO @var_leave_debit_PL FROM tbl_leave_requests WHERE status IN( 'APPROVED','CANCEL REQUEST APPLIED') AND employee_id = '",var_employee_id,"' AND leave_type_id = 2 AND YEAR(approved_on) = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_debit_PL = @var_leave_debit_PL;
      DEALLOCATE PREPARE stmt;


      

      SET @sql_query = CONCAT(
        "SELECT sum(credit) INTO @var_leave_credit_SL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 1 and (remark not like '%trans%' AND remark not like '%correction%' AND remark not like '%wrong%') AND year_no = '",YEAR(var_from_date),"'"
      );
      
      
      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_credit_SL = @var_leave_credit_SL;
      DEALLOCATE PREPARE stmt;


      
      SET @sql_query = CONCAT(
        "SELECT sum(leave_days) INTO @var_leave_debit_SL FROM tbl_leave_requests WHERE status IN( 'APPROVED','CANCEL REQUEST APPLIED') AND employee_id = '",var_employee_id,"' AND leave_type_id = 1 AND YEAR(approved_on) = '",YEAR(var_from_date),"'"
      );
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_debit_SL = @var_leave_debit_SL;
      DEALLOCATE PREPARE stmt;


      

      SET @sql_query = CONCAT(
        "SELECT sum(leave_days) INTO @var_leave_pending_SL FROM ",var_requests_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 1 and status = 'pending' AND YEAR(applied_on) = '",YEAR(var_from_date),"'"
      );
      
      
      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_pending_SL = @var_leave_pending_SL;
      DEALLOCATE PREPARE stmt;


      

      SET @sql_query = CONCAT(
        "SELECT sum(leave_days) INTO @var_leave_pending_PL FROM ",var_requests_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 2 and status = 'pending' AND YEAR(applied_on) = '",YEAR(var_from_date),"'"
      );
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_pending_PL = @var_leave_pending_PL;
      DEALLOCATE PREPARE stmt;


      

      SET @sql_query = CONCAT(
        "SELECT sum(ifnull(credit,0))-sum(ifnull(debit,0)) INTO @var_leave_fresh_credit_PL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 2 and (remark like '%fresh%' or remark like '%leave quota adjusted%') AND year_no = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_fresh_credit_PL = @var_leave_fresh_credit_PL;
      DEALLOCATE PREPARE stmt;



      

      
      SET var_PL_JSON = JSON_OBJECT('primary_balance',IFNULL(var_leave_primary_balance_PL,0),'carry_forwarded_balance',IFNULL(var_leave_secondary_balance_PL,0),'total_balance',IFNULL(var_leave_balance_PL,0),'credit',IFNULL(var_leave_credit_PL,0),'auto_credit',IFNULL(var_leave_fresh_credit_PL,0),'debit',IFNULL(var_leave_debit_PL,0),'pending',IFNULL(var_leave_pending_PL, 0));


      

      SET @sql_query = CONCAT(
        "SELECT sum(ifnull(credit, 0)) - sum(ifnull(debit, 0)) INTO @var_leave_fresh_credit_SL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 1 and (remark like '%fresh%' or remark like '%leave quota adjusted%') AND year_no = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_fresh_credit_SL = @var_leave_fresh_credit_SL;
      DEALLOCATE PREPARE stmt;

      

      SET var_SL_JSON = JSON_OBJECT('primary_balance',IFNULL(var_leave_primary_balance_SL,0),'carry_forwarded_balance',IFNULL(var_leave_secondary_balance_SL,0),'total_balance',IFNULL(var_leave_balance_SL,0),'credit',IFNULL(var_leave_credit_SL,0),'auto_credit',IFNULL(var_leave_fresh_credit_SL,0),'debit',IFNULL(var_leave_debit_SL,0),'pending',IFNULL(var_leave_pending_SL, 0));

       
      
        SET @sql_query = CONCAT(
        "SELECT CONCAT('[',GROUP_CONCAT(LEAVES ORDER BY 
        CASE when status = 'pending' then 0 else 1 end,
    COALESCE(approved_on, declined_on, applied_on, withdrawn_on) DESC,
    declined_on DESC,
    applied_on DESC,
    withdrawn_on DESC),']') INTO @var_leave_request FROM (
          SELECT JSON_OBJECT(
              'employee_id',employee_id,
              'request_id', request_id,
              'requester_id', requester_id,
              'leave_type_id', leave_type_id,
              'start_date', start_date,
              'end_date', end_date,
              'leave_days', leave_days,
              'status', STATUS,
              'applied_on', applied_on,
              'withdrawn_on', withdrawn_on,
              'declined_on', declined_on,
              'approved_on', approved_on,
              'cancel_request_on', cancel_request_on,
              'cancel_request_approved_on', cancel_request_approved_on,
              'cancel_request_declined_on', cancel_request_declined_on,
              'transition_state', transition_state,
              'work_date', work_date,
              'comp_off_date', comp_off_date,
              'hr_declined_on', hr_declined_on,
              'hr_approved_on', hr_approved_on,
              'hr_cancel_request_approved_on', hr_cancel_request_approved_on,
              'hr_cancel_request_declined_on', hr_cancel_request_declined_on,
              'hr_cancel_request_applied_on', hr_cancel_request_applied_on,
              'hr_requester_id', hr_requester_id,
              'reason',reason
          ) AS LEAVES,
          applied_on,
          start_date,
          approved_on,
          declined_on,
          withdrawn_on,
          status
          FROM ",var_requests_table_employee,"
          WHERE employee_id = '",var_employee_id,"'
          AND leave_type_id IN (2)
           ORDER BY applied_on DESC)t"
            );

      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_request = @var_leave_request;
      DEALLOCATE PREPARE stmt;

      SET var_leave_request = JSON_OBJECT('leaves', var_leave_request);

      SET var_PL_JSON = JSON_MERGE_PATCH(var_PL_JSON, var_leave_request);

        

        SET @sql_query = CONCAT(
        "SELECT CONCAT('[',GROUP_CONCAT(LEAVES ORDER BY 
        CASE when status = 'pending' then 0 else 1 end,
    COALESCE(approved_on, declined_on, applied_on, withdrawn_on) DESC,
    declined_on DESC,
    applied_on DESC,
    withdrawn_on DESC),']') INTO @var_leave_request FROM (
          SELECT JSON_OBJECT(
              'employee_id',employee_id,
              'request_id', request_id,
              'requester_id', requester_id,
              'leave_type_id', leave_type_id,
              'start_date', start_date,
              'end_date', end_date,
              'leave_days', leave_days,
              'status', STATUS,
              'applied_on', applied_on,
              'withdrawn_on', withdrawn_on,
              'declined_on', declined_on,
              'approved_on', approved_on,
              'cancel_request_on', cancel_request_on,
              'cancel_request_approved_on', cancel_request_approved_on,
              'cancel_request_declined_on', cancel_request_declined_on,
              'transition_state', transition_state,
              'work_date', work_date,
              'comp_off_date', comp_off_date,
              'hr_declined_on', hr_declined_on,
              'hr_approved_on', hr_approved_on,
              'hr_cancel_request_approved_on', hr_cancel_request_approved_on,
              'hr_cancel_request_declined_on', hr_cancel_request_declined_on,
              'hr_cancel_request_applied_on', hr_cancel_request_applied_on,
              'hr_requester_id', hr_requester_id,
              'reason',reason
          ) AS LEAVES,
          applied_on,
          start_date,
          approved_on,
          declined_on,
          withdrawn_on,
          status
          FROM ",var_requests_table_employee,"
          WHERE employee_id = '",var_employee_id,"'
          AND leave_type_id IN (1)
           ORDER BY applied_on DESC)t"
            );
      
      
      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_request = @var_leave_request;
      DEALLOCATE PREPARE stmt;

      SET var_leave_request = JSON_OBJECT('leaves', var_leave_request);

        SET var_SL_JSON = JSON_MERGE_PATCH(var_SL_JSON, var_leave_request);

        

        SET @sql_query = CONCAT(
        "SELECT JSON_OBJECT(
          'late_mark', JSON_ARRAYAGG(
              JSON_OBJECT(
                'update_at', update_at,
                'debit',debit
              )
            )
          ) INTO @var_leave_debit_PL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 2 and remark like '%hours%' AND year_no = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_late_mark_PL = @var_leave_debit_PL;
      DEALLOCATE PREPARE stmt;

        SET var_PL_JSON = JSON_MERGE_PATCH(var_PL_JSON, var_late_mark_PL);

        

        SET @sql_query = CONCAT(
        "SELECT JSON_OBJECT(
          'hr_credit', JSON_ARRAYAGG(
              JSON_OBJECT(
                'update_at', update_at,
                'credit',credit,
                'remark',remark
              )
            )
          ) INTO @var_leave_credit_PL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 2 and remark like '%HR%' and credit > 0 AND YEAR(update_at) = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_late_mark_PL = @var_leave_credit_PL;
      DEALLOCATE PREPARE stmt;

        SET var_PL_JSON = JSON_MERGE_PATCH(var_PL_JSON, var_late_mark_PL);

        

        SET @sql_query = CONCAT(
        "SELECT JSON_OBJECT(
          'hr_debit', JSON_ARRAYAGG(
              JSON_OBJECT(
                'update_at', update_at,
                'debit',debit,
                'remark',remark
              )
            )
          ) INTO @var_leave_debit_PL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 2 and remark like '%HR%' and debit > 0 AND YEAR(update_at) = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_late_mark_PL = @var_leave_debit_PL;
      DEALLOCATE PREPARE stmt;

        SET var_PL_JSON = JSON_MERGE_PATCH(var_PL_JSON, var_late_mark_PL);

        

        SET @sql_query = CONCAT(
        "SELECT JSON_OBJECT(
          'hr_credit', JSON_ARRAYAGG(
              JSON_OBJECT(
                'update_at', update_at,
                'credit',credit,
                'remark',remark
              )
            )
          ) INTO @var_leave_credit_SL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 1 and remark like '%HR%' and credit > 0 AND YEAR(update_at) = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query; 
      
      EXECUTE stmt;
      SET var_late_mark_SL = @var_leave_credit_SL;
      DEALLOCATE PREPARE stmt;

        SET var_SL_JSON = JSON_MERGE_PATCH(var_SL_JSON, var_late_mark_SL);

        

        SET @sql_query = CONCAT(
        "SELECT JSON_OBJECT(
          'hr_debit', JSON_ARRAYAGG(
              JSON_OBJECT(
                'update_at', update_at,
                'debit',debit,
                'remark',remark
              )
            )
          ) INTO @var_leave_debit_SL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 1 and remark like '%HR%' and debit > 0 AND YEAR(update_at) = '",YEAR(var_from_date),"'"
      );
      
      

      PREPARE stmt FROM @sql_query;
       
      EXECUTE stmt;
      SET var_late_mark_SL = @var_leave_debit_SL;
      DEALLOCATE PREPARE stmt;

        SET var_SL_JSON = JSON_MERGE_PATCH(var_SL_JSON, var_late_mark_SL);
        
        

        SET @sql_query = CONCAT(
        "SELECT JSON_OBJECT(
          'late_mark', JSON_ARRAYAGG(
              JSON_OBJECT(
                'update_at', update_at,
                'debit',debit
              )
            )
          ) INTO @var_leave_debit_SL FROM ",var_ledger_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id = 1 and remark like '%hours%' AND year_no = '",YEAR(var_from_date),"'"
      );

      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_late_mark_SL = @var_leave_debit_SL;
      DEALLOCATE PREPARE stmt;

        SET var_SL_JSON = JSON_MERGE_PATCH(var_SL_JSON, var_late_mark_SL);

      
      SET @sql_query = CONCAT(
      "SELECT CONCAT('[',GROUP_CONCAT(LEAVES ORDER BY 
      CASE when status = 'pending' then 0 else 1 end,
    COALESCE(approved_on, declined_on, applied_on, withdrawn_on) DESC,
    declined_on DESC,
    applied_on DESC,
    withdrawn_on DESC),']') INTO @var_leave_request FROM (
          SELECT JSON_OBJECT(
              'employee_id',employee_id,
              'request_id', request_id,
              'requester_id', requester_id,
              'leave_type_id', leave_type_id,
              'start_date', start_date,
              'end_date', end_date,
              'leave_days', leave_days,
              'status', STATUS,
              'applied_on', applied_on,
              'withdrawn_on', withdrawn_on,
              'declined_on', declined_on,
              'approved_on', approved_on,
              'cancel_request_on', cancel_request_on,
              'cancel_request_approved_on', cancel_request_approved_on,
              'cancel_request_declined_on', cancel_request_declined_on,
              'transition_state', transition_state,
              'work_date', work_date,
              'comp_off_date', comp_off_date,
              'hr_declined_on', hr_declined_on,
              'hr_approved_on', hr_approved_on,
              'hr_cancel_request_approved_on', hr_cancel_request_approved_on,
              'hr_cancel_request_declined_on', hr_cancel_request_declined_on,
              'hr_cancel_request_applied_on', hr_cancel_request_applied_on,
              'hr_requester_id', hr_requester_id,
              'reason',reason
          ) AS LEAVES,
          applied_on,
          start_date,
          approved_on,
          declined_on,
          withdrawn_on,
          status
          FROM ",var_requests_table_employee,"
          WHERE employee_id = '",var_employee_id,"'
          AND leave_type_id IN (3,4,7,8,9,10,11,12)
           ORDER BY applied_on DESC)t"
            );

          
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_leave_request = @var_leave_request;
      DEALLOCATE PREPARE stmt;

      SET var_considerate_leave_JSON = JSON_OBJECT('leaves', var_leave_request);


      
      SET @sql_query = CONCAT(
        "SELECT IFNULL(sum(leave_days),0) INTO @var_special_leave_days FROM ",var_requests_table_employee," WHERE employee_id = '",var_employee_id,"' AND leave_type_id IN(3, 4, 7, 8, 9, 10, 11, 12) and status = 'pending' AND year(applied_on) = '",YEAR(var_from_date),"'"
      );

      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_special_leave_days = @var_special_leave_days;
      DEALLOCATE PREPARE stmt;

      SET var_special_leaves = JSON_OBJECT('pending',var_special_leave_days);

      SET var_considerate_leave_JSON = JSON_MERGE_PATCH(var_considerate_leave_JSON, var_special_leaves);

      
      SET @sql_query = CONCAT(
        "SELECT IFNULL(sum(leave_days_debit),0) INTO @var_special_leave_days FROM ",var_ledger_considerate_table_employee," WHERE employee_id = '",var_employee_id,"' AND YEAR(update_at) = '",YEAR(var_from_date),"'"
      );

      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_special_leave_days = @var_special_leave_days;
      DEALLOCATE PREPARE stmt;

      

      

      
      SET @sql_query = CONCAT(
        "SELECT IFNULL(sum(leave_days_credit),0) INTO @var_special_leave_days FROM ",var_ledger_considerate_table_employee," WHERE employee_id = '",var_employee_id,"' AND YEAR(update_at) = '",YEAR(var_from_date),"'"
      );

      
      

      PREPARE stmt FROM @sql_query; 
      EXECUTE stmt;
      SET var_special_leave_days = var_special_leave_days-@var_special_leave_days;
      DEALLOCATE PREPARE stmt;

      SET var_special_leaves = JSON_OBJECT('debit',IF(var_special_leave_days < 0,0,var_special_leave_days ));

      SET var_considerate_leave_JSON = JSON_MERGE_PATCH(var_considerate_leave_JSON, var_special_leaves);


        IF var_leave_type_id IS NOT NULL THEN
          IF var_leave_type_id = 1 THEN
            SET output_json = JSON_OBJECT('employee_id', var_employee_id,'SL',var_SL_JSON,'SPECIAL',var_considerate_leave_JSON);
          ELSEIF var_leave_type_id = 2 THEN
            SET output_json = JSON_OBJECT('employee_id', var_employee_id,'PL',var_PL_JSON,'SPECIAL',var_considerate_leave_JSON);
          ELSE
            SET output_json = JSON_OBJECT('employee_id', var_employee_id,'SPECIAL',var_considerate_leave_JSON);
          END IF;
        ELSE
          SET output_json = JSON_OBJECT('employee_id', var_employee_id,'SL',var_SL_JSON,'PL',var_PL_JSON,'SPECIAL',var_considerate_leave_JSON);
        END IF;

        SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_balances_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    



    SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_ledger_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    
    
    SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_ledger_considerate_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    

    SET @sql_query = CONCAT(
      "DROP TABLE IF EXISTS ",var_requests_table_employee);
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END */$$
DELIMITER ;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
