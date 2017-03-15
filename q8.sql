-- Never solo by choice

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q8;

-- You must not change this table definition.
CREATE TABLE q8 (
	username varchar(25),
	group_average real,
	solo_average real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS multi_groups, solo_groups, contributed, always_grouped, assignment_total, group_marks, group_associated, group_average, solo_average CASCADE;

-- Define views for your intermediate steps here.

CREATE VIEW multi_groups AS (
	SELECT t2.group_id 
	FROM Assignment AS t1 JOIN AssignmentGroup AS t2
		ON (t1.assignment_id = t2.assignment_id AND t1.group_max > 1)
);

CREATE VIEW solo_groups AS (
	(SELECT Membership.group_id
	FROM Membership 
	GROUP BY group_id
	HAVING COUNT(*) = 1)
	INTERSECT 
	(SELECT * FROM multi_groups)
);

CREATE VIEW contributed AS (
	SELECT DISTINCT username
	FROM Submissions 
	WHERE NOT EXISTS(SELECT 1 FROM solo_groups WHERE Submissions.group_id = solo_groups.group_id)
);	

CREATE VIEW always_grouped AS (
	(SELECT DISTINCT username FROM MarkusUser WHERE type = 'student')
	EXCEPT 
	( SELECT username 
	  FROM Membership JOIN solo_groups 
	  ON (Membership.group_id = solo_groups.group_id))
);


CREATE VIEW assignment_total AS (
	SELECT DISTINCT assignment_id, SUM(out_of*weight) AS total 
	FROM RubricItem
	GROUP BY assignment_id
);

-- Group weighted marks (not percentage)
CREATE VIEW group_marks AS (
	SELECT t1.group_id, SUM(t2.weight*t1.grade) AS mark
	FROM Grade AS t1 JOIN RubricItem AS t2
	     ON (t1.rubric_id = t2.rubric_id)
	GROUP BY t1.group_id
);



-- Group with usernames that meet the criterions
CREATE VIEW group_associated AS (
	SELECT t1.group_id, t2.username, t3.assignment_id
	FROM Result AS t1 JOIN Membership AS t2 
		ON (t1.group_id = t2.group_id AND 
			EXISTS(SELECT 1 
				FROM (SELECT * FROM always_grouped INTERSECT SELECT * FROM contributed) AS t4
				WHERE t2.username = t4.username))
		JOIN AssignmentGroup AS t3
		ON (t3.group_id = t1.group_id AND t3.group_id = t2.group_id)
);


CREATE VIEW group_average AS (
	SELECT t1.username, 100*AVG(t2.mark/t3.total) AS group_average
	FROM group_associated AS t1 
	        JOIN group_marks AS t2 
	        ON (t1.group_id = t2.group_id 
		    AND EXISTS(SELECT 1 FROM multi_groups WHERE multi_groups.group_id = t1.group_id))
		NATURAL JOIN assignment_total AS t3
		
	GROUP BY t1.username
);


CREATE VIEW solo_average AS (
	SELECT t1.username, 100*AVG(t2.mark/t3.total) AS solo_average
	FROM group_associated AS t1 
		JOIN group_marks AS t2 
		ON (t1.group_id = t2.group_id
		     AND NOT EXISTS(SELECT 1 FROM multi_groups WHERE multi_groups.group_id = t1.group_id))
		NATURAL JOIN assignment_total AS t3
	GROUP BY t1.username
);


-- Final answer.
INSERT INTO q8(
	SELECT t1.username, t1.group_average, t2.solo_average
	FROM group_average AS t1 JOIN solo_average AS t2
	ON t1.username = t2.username
);
	-- put a final query here so that its results will go into the table.