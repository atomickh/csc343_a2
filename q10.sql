

-- A1 report

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q10;

-- You must not change this table definition.
CREATE TABLE q10 (
	group_id integer,
	mark real,
	compared_to_average real,
	status varchar(5)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS assignment_total CASCADE;
DROP VIEW IF EXISTS group_marks CASCADE;
DROP VIEW IF EXISTS groups_one CASCADE;
DROP VIEW IF EXISTS a1_average CASCADE;
DROP VIEW IF EXISTS group_percent CASCADE;

-- Define views for your intermediate steps here.

-- Calculate the total weighted rubric mark 
CREATE VIEW assignment_total AS (
	SELECT DISTINCT assignment_id, SUM(out_of*weight) AS total
	FROM RubricItem NATURAL JOIN Assignment
	GROUP BY assignment_id, description
	HAVING Assignment.description = 'A1'
);

-- Group weighted marks (not percentage)
CREATE VIEW group_marks AS (
	--SELECT t1.group_id, SUM(t2.weight*t1.grade) AS mark
	--FROM Grade AS t1 NATURAL JOIN RubricItem AS t2
	--GROUP BY t1.group_id
	
	SELECT t1.group_id, t2.mark 
	FROM AssignmentGroup AS t1 NATURAL LEFT JOIN Result AS t2
);
);


-- Groups assigned to A1
CREATE VIEW groups_one AS (
	SELECT DISTINCT group_id, total
	FROM (AssignmentGroup NATURAL JOIN assignment_total)
);

-- Average mark for A1
CREATE VIEW a1_average AS (
	SELECT AVG(mark) AS average
	FROM  groups_one NATURAL JOIN group_marks
);

-- Group percentage of every group assigned to A1
CREATE VIEW group_percent AS (
	SELECT t3.group_id, 100*t3.mark/t3.total AS mark, 100*(t3.mark - t3.average)*t3.mark/(t3.mark*t3.total) AS compared_to_average 
	FROM ((groups_one NATURAL LEFT JOIN a1_average) AS t1
		NATURAL JOIN (groups_one NATURAL LEFT JOIN group_marks) AS t2) AS t3
);

-- Final answer with case in order to figure out status
INSERT INTO q10(
	SELECT group_id, mark, compared_to_average,
		CASE WHEN compared_to_average = null THEN null 
			 WHEN compared_to_average < 0 THEN 'below'
			 WHEN compared_to_average > 0 THEN 'above'
			 WHEN compared_to_average = 0 THEN 'at'
		END AS status
	FROM group_percent
);
	-- put a final query here so that its results will go into the table.
	

