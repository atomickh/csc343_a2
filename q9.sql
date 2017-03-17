

-- Inseparable

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q9;

-- You must not change this table definition.
CREATE TABLE q9 (
	student1 varchar(25),
	student2 varchar(25)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS exist_pairs CASCADE;
DROP VIEW IF EXISTS not_always CASCADE;
DROP VIEW IF EXISTS all_pairs CASCADE;
DROP VIEW IF EXISTS exist_group_pairs CASCADE;
-- Define views for your intermediate steps here.

-- Pairs of students and what groups they worked on together
CREATE VIEW exist_group_pairs AS (
	SELECT t1.group_id, t1.username AS student1, t2.username AS student2
	FROM Membership AS t1 JOIN Membership AS t2 
		ON (t1.group_id = t2.group_id AND t1.username != t2.username AND t1.username < t2.username) 
);

-- Pairs of students that worked together and what assignments they worked on
-- ALready checked to ensure that first student is ahead of second student alphabetically
CREATE VIEW exist_pairs AS (
	SELECT t4.assignment_id, t3.student1, t3.student2 
	FROM exist_group_pairs AS t3
		JOIN AssignmentGroup AS t4
		ON (t3.group_id = t4.group_id)
);

-- All possible combination of student pairs and assignments
CREATE VIEW all_pairs AS (
	SELECT t4.assignment_id, t3.student1, t3.student2 
	FROM (  SELECT t1.username AS student1, t2.username AS student2
			FROM MarkusUser AS t1 JOIN MarkusUser AS t2 
				ON (t1.username != t2.username 
				    AND t1.type = 'student' 
				    AND t2.type = 'student' 
				    AND t1.username < t2.username) 
		) AS t3
		JOIN Assignment AS t4
		ON (t4.group_max > 1)
);

-- Student pairs that did not always occur
CREATE VIEW not_always AS (
	SELECT student1, student2
	FROM (SELECT * FROM all_pairs EXCEPT SELECT * FROM exist_pairs) AS t1
);


-- Final answer.
INSERT INTO q9 (
	SELECT DISTINCT student1, student2
	FROM (SELECT student1, student2 FROM all_pairs EXCEPT SELECT * FROM not_always) AS t1
);
	-- put a final query here so that its results will go into the table.

