USE `essentialmode`;

INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_mekaniker', 'Mekaniker', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_mekaniker', 'Mekaniker', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_mekaniker', 'Mekaniker', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('mekaniker','Mekaniker')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('police',0,'recruit','Provanställd',20,'{}','{}'),
	('police',1,'novice','Anställd',40,'{}','{}'),
	('police',2,'experimente','Mellanchef',60,'{}','{}'),
	('police',3,'chief','Chef',85,'{}','{}'),
	('police',4,'boss','VD',100,'{}','{}')
;

INSERT INTO `items` (name, label, weight) VALUES
	('gazbottle', 'bouteille de gaz', 2),
	('fixtool', 'outils réparation', 2),
	('carotool', 'outils carosserie', 2),
	('blowpipe', 'Chalumeaux', 2),
	('fixkit', 'Kit réparation', 3),
	('carokit', 'Kit carosserie', 3)
;