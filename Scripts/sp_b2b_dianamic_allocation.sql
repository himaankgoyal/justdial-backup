DELIMITER $$

USE `db_activity`$$

DROP PROCEDURE IF EXISTS `sp_b2b_dianamic_allocation`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_b2b_dianamic_allocation`(IN T_id INT(11))
BEGIN
	#Routine body goes here...
	
	
	
    
	
DECLARE m_qry MEDIUMTEXT;
    
	
SET @m_qry=CONCAT("alter table test.tbl_bp_popular_paid_data_",T_id,"_tbd add key(docid),add key(parentid),add key(source),add key(empcode);");
PREPARE stmt FROM @m_qry;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

			
CREATE TABLE IF NOT EXISTS db_activity.tbl_bp_popular_paid_data_backup_alloc (
docid VARCHAR(255),
parentid VARCHAR(255),
SOURCE VARCHAR(75),
given_empcode VARCHAR(75),
existing_empcode VARCHAR(75),
allocate_date DATETIME,
KEY(docid),
KEY(parentid),
KEY(given_empcode)
)ENGINE=INNODB CHARSET=latin1;
			
			
SET @m_qry=CONCAT("insert into db_activity.tbl_bp_popular_paid_data_backup_alloc(docid,parentid,source,given_empcode,existing_empcode,allocate_date)
select a.docid,a.parentid,a.source,a.empcode as given_empcode,b.empcode as existing_empcode,now() from test.tbl_bp_popular_paid_data_",T_id,"_tbd a join db_activity.tbl_bp_popular_paid_data b on a.parentid=b.parentid and a.source=b.source;");
PREPARE stmt FROM @m_qry;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;			
			
SET @m_qry=CONCAT("INSERT IGNORE INTO db_activity.tbl_bp_popular_paid_data(docid,source,parentid,companyname,data_city,empcode,parent_city,main_city_flag,mobile,landline,primary_cat,hotcategory,primary_catname,hot_category_name,allocate_date)
 SELECT docid,source,parentid,companyname,data_city,empcode,parent_city,main_city_flag,mobile,landline,primary_cat,hotcategory,primary_catname,hot_category_name,CURRENT_DATE() From test.tbl_bp_popular_paid_data_",T_id,"_tbd;");
 PREPARE stmt FROM @m_qry;
 EXECUTE stmt;
 DEALLOCATE PREPARE stmt;	

### Existing contracts

SET @m_qry=CONCAT("UPDATE db_activity.tbl_bp_popular_paid_data a JOIN test.tbl_bp_popular_paid_data_",T_id,"_tbd b ON b.parentid=a.parentid AND b.source=a.source SET a.empcode=b.empcode,a.allocate_date=NOW();");
 PREPARE stmt FROM @m_qry;
 EXECUTE stmt;
 DEALLOCATE PREPARE stmt;
	
SET @m_qry=CONCAT("REPLACE INTO db_activity.tbl_bp_popular_paid_data(docid,source,parentid,companyname,data_city,empcode,parent_city,main_city_flag,mobile,landline,primary_cat,hotcategory,primary_catname,hot_category_name,allocate_date)
SELECT docid,source,parentid,companyname,data_city,empcode,parent_city,main_city_flag,mobile,landline,primary_cat,hotcategory,primary_catname,hot_category_name,NOW() FROM test.tbl_bp_popular_paid_data_",T_id,"_tbd WHERE docid<>'';");	
 PREPARE stmt FROM @m_qry;
 EXECUTE stmt;
DEALLOCATE PREPARE stmt;
		
SET @m_qry=CONCAT("DROP TABLE IF EXISTS  test.tbl_bp_popular_paid_data_",T_id,"_tbd;");
PREPARE stmt FROM @m_qry;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
			
		
	

END$$

DELIMITER ;