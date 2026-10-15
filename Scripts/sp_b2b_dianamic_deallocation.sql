DELIMITER $$

USE `db_activity`$$

DROP PROCEDURE IF EXISTS `sp_b2b_dianamic_deallocation`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_b2b_dianamic_deallocation`(IN T_id INT(11))
BEGIN
	#Routine body goes here...
	
	
	
    
	
    	DECLARE m_qry MEDIUMTEXT;
    
	
	SET @m_qry=CONCAT("alter table test.tbl_bp_popular_paid_data_",T_id,"_tbd add key(empcode);");

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
			
			
SET @m_qry=CONCAT("insert into db_activity.tbl_bp_popular_paid_data_backup_alloc(docid,parentid,source,existing_empcode,given_empcode,allocate_date)
select b.docid,b.parentid,b.source,b.empcode as existing_empcode,a.empcode as given_empcode,now() from test.tbl_bp_popular_paid_data_",T_id,"_tbd a join db_activity.tbl_bp_popular_paid_data b on a.empcode=b.empcode;");
PREPARE stmt FROM @m_qry;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;			
			
			
				 SET @m_qry=CONCAT("delete a.* from db_activity.tbl_bp_popular_paid_data  a 
					join test.tbl_bp_popular_paid_data_",T_id,"_tbd b 
					on b.empcode=a.empcode;");

PREPARE stmt FROM @m_qry;
         EXECUTE stmt;
			DEALLOCATE PREPARE stmt;

/*
				 SET @m_qry=CONCAT("UPDATE db_activity.tbl_bp_popular_paid_data  a 
					join test.tbl_bp_popular_paid_data_",T_id,"_tbd b 
					on a.empcode=b.empcode set a.empcode='';");

PREPARE stmt FROM @m_qry;
         EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
*/			
			
			SET @m_qry=CONCAT("DROP TABLE IF EXISTS  test.tbl_bp_popular_paid_data_",T_id,"_tbd;");
		
					
PREPARE stmt FROM @m_qry;
        EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
			
		
	

END$$

DELIMITER ;