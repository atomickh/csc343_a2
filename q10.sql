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
DROP VIEW IF EXISTS assignment_total, group_marks, groups_one, a1_average, group_percent CASCADE;

-- Define views for your intermediate steps here.

CREATE VIEW assignment_total AS (
	SELECT DISTINCT assignment_id, SUM(out_of) AS total
	FROM RubricItem NATURAL JOIN Assignment
	GROUP BY assignment_id, description
	HAVING Assignment.description = 'A1'
);

-- Group weighted marks (not percentage)
CREATE VIEW group_marks AS (
	SELECT t1.group_id, SUM(t2.weight*t1.grade) AS mark
	FROM Grade AS t1 JOIN RubricItem AS t2
	     ON (t1.rubric_id = t2.rubric_id)
	GROUP BY t1.group_id
);

-- Groups assigned to A1
CREATE VIEW groups_one AS (
	SELECT DISTINCT group_id, total
	FROM (AssignmentGroup NATURAL JOIN assignment_total)
);

CREATE VIEW a1_average AS (
	SELECT AVG(mark) AS average
	FROM  groups_one NATURAL JOIN group_marks
);

CREATE VIEW group_percent AS (
	SELECT t3.group_id, 100*t3.mark/t3.total AS mark, (t3.mark - t3.average)*t3.mark/t3.mark AS compared_to_average 
	FROM ((groups_one NATURAL LEFT JOIN a1_average) AS t1
		NATURAL JOIN (groups_one NATURAL LEFT JOIN group_marks) AS t2) AS t3
);

-- Final answer.
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
