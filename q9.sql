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
DROP VIEW IF EXISTS exist_pairs, multi_groups, all_pairs CASCADE;
-- Define views for your intermediate steps here.

CREATE VIEW exist_pairs AS (
	SELECT t4.assignment_id, t3.student1, t3.student2 
	FROM (
		SELECT t1.group_id, t1.username AS student1, t2.username AS student2
		FROM Membership AS t1 JOIN Membership AS t2 
			ON (t1.group_id = t2.group_id AND t1.username != t2.username AND t1.username < t2.username) 
		) AS t3
		JOIN AssignmentGroups as t4
		ON (t3.group_id = t2.group_id)
);

CREATE VIEW multi_groups AS (
	SELECT group_id 
	FROM AssignmentGroups AS t1 JOIN Assignment As t2
		ON (t2.group_max > 1 AND t1.assignment_id = t2.assignment_id)
);


CREATE VIEW all_pairs AS (
	SELECT t4.assignment_id, t3.student1, t3.student2 
	FROM (  SELECT t1.username AS student1, t2.username AS student2
			FROM MarkusUser AS t1 JOIN MarkusUser AS t2 
				ON (t1.username != t2.username AND t1.type = 'student' AND t2.type = 'student' AND t1.username < t2.username) 
		) AS t3
		JOIN Assignment AS t4
		ON (t2.group_max > 1)
);

-- Final answer.
INSERT INTO q9 (
	SELECT DISTINCT student1, student2 
	FROM (all_pairs EXCEPT exist_pairs)
);
	-- put a final query here so that its results will go into the table.
