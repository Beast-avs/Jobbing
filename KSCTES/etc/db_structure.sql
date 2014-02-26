DROP TABLE IF EXISTS domains;
CREATE TABLE `domains` ( 
	`ID` int(4) NOT NULL auto_increment, 
	`DomainName` varchar(255) NOT NULL, 
	`DateCreate` datetime NOT NULL, 
	`DateUpdate` datetime, 
	`DateExpire` datetime NOT NULL,
	`AdminContact` int(4),
	`TechContact` int(4),
	`RegistrantContact` int(4),
	`NameServers` int(4),  
	PRIMARY KEY (`ID`),
	CONSTRAINT `reg_cont_fk` FOREIGN KEY (`RegistrantContact`) REFERENCES `registrant_contacts` (`ID`) ON DELETE CASCADE,
	CONSTRAINT `adm_cont_fk` FOREIGN KEY (`AdminContact`) REFERENCES `administrative_contacts` (`ID`) ON DELETE CASCADE,
	CONSTRAINT `tech_cont_fk` FOREIGN KEY (`TechContact`) REFERENCES `technical_contacts` (`ID`) ON DELETE CASCADE,
	CONSTRAINT `ns_fk` FOREIGN KEY (`NameServers`) REFERENCES `name_servers` (`ID`) ON DELETE CASCADE
);

DROP TABLE IF EXISTS registrant_contacts;
CREATE TABLE `registrant_contacts` ( 
	`ID` int(4) NOT NULL auto_increment, 
	`RegistrantName` varchar(255), 
	`RegistrantCompany` varchar(255), 
	`RegistrantAddress` varchar(255), 
	`RegistrantPhone` varchar(255),
	`RegistrantMail` varchar(255), 
	PRIMARY KEY (`ID`)
);

DROP TABLE IF EXISTS administrative_contacts;
CREATE TABLE `administrative_contacts` ( 
	`ID` int(4) NOT NULL auto_increment, 
	`AdminName` varchar(255), 
	`AdminCompany` varchar(255), 
	`AdminAddress` varchar(255), 
	`AdminPhone` varchar(255),
	`AdminMail` varchar(255), 
	PRIMARY KEY (`ID`)
);

DROP TABLE IF EXISTS technical_contacts;
CREATE TABLE `technical_contacts` ( 
	`ID` int(4) NOT NULL auto_increment, 
	`TechName` varchar(255), 
	`TechCompany` varchar(255), 
	`TechAddress` varchar(255), 
	`TechPhone` varchar(255),
	`TechMail` varchar(255), 
	PRIMARY KEY (`ID`)
);

DROP TABLE IF EXISTS name_servers;
CREATE TABLE `name_servers` ( 
	`ID` int(4) NOT NULL auto_increment,
	`NameSeraver` varchar(255),
	PRIMARY KEY (`ID`)
);