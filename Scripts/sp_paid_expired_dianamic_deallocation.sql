DELIMITER $$

USE `db_activity`$$

DROP PROCEDURE IF EXISTS `sp_paid_expired_dianamic_deallocation`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_paid_expired_dianamic_deallocation`(IN T_id INT(11))
BEGIN
	#Routine body goes here...
	
		
DECLARE m_qry MEDIUMTEXT;
    
	
	SET @m_qry=CONCAT("alter table test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd add key(empcode);");

PREPARE stmt FROM @m_qry;
        EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
			
/*	
				 SET @m_qry=CONCAT("INSERT INTO online_regis.tbl_marketingIntCampaign_allocation_backup
SELECT  a.* FROM online_regis.marketingIntCampaign a
JOIN (SELECT DISTINCT  empcode FROM test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd) b
ON a.empcode=b.empcode
WHERE  a.allocated_campaign_flag IN(SELECT DISTINCT allocated_flags FROM test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd);");

PREPARE stmt FROM @m_qry;
         EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
*/
				 SET @m_qry=CONCAT("INSERT INTO online_regis.tbl_marketingIntCampaign_allocation_backup
SELECT  a.* FROM online_regis.marketingIntCampaign a
JOIN (SELECT DISTINCT  empcode FROM test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd) b
ON b.empcode=a.empcode;");

PREPARE stmt FROM @m_qry;
         EXECUTE stmt;
			DEALLOCATE PREPARE stmt;			
			
/*			
				SET @m_qry=CONCAT("DELETE a.* FROM online_regis.marketingIntCampaign a
 JOIN (SELECT DISTINCT  empcode FROM test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd) b
ON a.empcode=b.empcode
WHERE  a.allocated_campaign_flag IN(SELECT DISTINCT allocated_flags FROM test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd);");

 PREPARE stmt FROM @m_qry;
        EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
*/	
		
				SET @m_qry=CONCAT("DELETE a.* FROM online_regis.marketingIntCampaign a
 JOIN (SELECT DISTINCT  empcode FROM test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd) b
ON b.empcode=a.empcode;");

 PREPARE stmt FROM @m_qry;
        EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
			
			
		
			SET @m_qry=CONCAT("DROP TABLE IF EXISTS  test.tbl_marketingIntCampaign_allocation_",T_id,"_tbd;");
		
					
PREPARE stmt FROM @m_qry;
        EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
			
		
	

END$$

DELIMITER ;