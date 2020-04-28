CREATE TABLE `payroll` (
	`identifier` VARCHAR(255) NOT NULL
);

CREATE TABLE `payroll_code` (	
	`code` VARCHAR(255) NOT NULL
);

INSERT INTO `items`(`name`, `label`, `limit`, `rare`,  `can_remove`) VALUES 
('marijuana','Marijuana', 50, 0, 1);