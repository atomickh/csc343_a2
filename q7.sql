

-- High coverage

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q7;

-- You must not change this table definition.
CREATE TABLE q7 (
	ta varchar(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS all_ts_pairs CASCADE;
DROP VIEW IF EXISTS all_tas_pairs CASCADE;
DROP VIEW IF EXISTS all_pairs CASCADE;
DROP VIEW IF EXISTS exist_pairs CASCADE;
DROP VIEW IF EXISTS exist_tas_pairs CASCADE;
DROP VIEW IF EXISTS exist_ts_pairs CASCADE;
DROP VIEW IF EXISTS not_output_ta CASCADE;

-- Define views for your intermediate steps here.
-- Every ta, group, assignment combination and the ones that actually occured
CREATE VIEW all_pairs AS (
	SELECT t1.username, t2.group_id, t2.assignment_id
	FROM MarkusUser AS t1
		JOIN AssignmentGroup AS t2
		ON (t1.type = 'TA')
);	


CREATE VIEW exist_pairs AS (
	SELECT t1.username, t1.group_id, t2.assignment_id
	FROM Grader AS t1 NATURAL JOIN AssignmentGroup As t2
);

-- All student TA Pairs that can occur and actually occurred
CREATE VIEW all_ts_pairs AS(
	SELECT t1.username, t2.username AS student
	FROM MarkusUser AS t1 
		JOIN MarkusUser AS t2
		ON (t1.type = 'TA' AND t2.type = 'student')
);

CREATE VIEW exist_ts_pairs AS(
	SELECT t1.username, t2.username AS student
	FROM exist_pairs AS t1
		JOIN (	SELECT t3.username, t4.group_id 
				FROM Membership AS t3 
					JOIN AssignmentGroup AS t4
					ON (t3.group_id = t4.group_id )
			 ) AS t2
		ON (t1.group_id = t2.group_id)
);

-- All TA assignment pairs that can occur and actually occurred
CREATE VIEW all_tas_pairs AS(
	SELECT DISTINCT username, assignment_id
	FROM all_pairs
);

CREATE VIEW exist_tas_pairs AS(
	SELECT DISTINCT username, assignment_id
	FROM exist_pairs
);

CREATE VIEW not_output_ta AS (
	SELECT username AS ta
	FROM ((SELECT DISTINCT username 
	      FROM (SELECT * FROM all_ts_pairs EXCEPT SELECT * FROM exist_ts_pairs) AS t1) 
	UNION ( SELECT DISTINCT username
	      FROM (SELECT * FROM all_tas_pairs EXCEPT SELECT * FROM exist_tas_pairs) AS t2)) AS t3
);

-- Final answer.
INSERT INTO q7 (
	SELECT username AS ta 
	FROM MarkusUser WHERE type = 'TA' 
	EXCEPT
	SELECT * FROM not_output_ta
);
	-- put a final query here so that its results will go into the table.

	

