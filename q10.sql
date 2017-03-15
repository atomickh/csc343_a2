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
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.

CREATE VIEW assignment_total AS (
	SELECT DISTINCT assignment_id, SUM(out_of) AS total 
	FROM RubricItem
	GROUP BY assignment_id
	HAVING assignment_id = 1
);

CREATE VIEW groups_one AS (
	SELECT group_id, total
	FROM (AssignmentGroup NATURAL JOIN assignment_total)
	WHERE assignment_id = 1
);

CREATE VIEW a1_average AS (
	SELECT AVG(mark) AS average
	FROM  groups_one JOIN Result
		ON (groups_one.group_id = Result.group_id)
);

CREATE VIEW group_mark AS (
	SELECT t3.group_id, 100*t3.mark/t3.total AS mark, (t3.mark - t3.average) AS compared_to_average 
	FROM ((groups_one CROSS JOIN a1_average) AS t1
		NATURAL JOIN (groups_one NATURAL JOIN Result) AS t2
		) AS t3
		
);




-- Final answer.
INSERT INTO q10(
	SELECT group_id, mark, compared_to_average,
		CASE WHEN compared_to_average < 0 THEN 'below'
			 WHEN compared_to_average > 0 THEN 'above'
			 WHEN compared_to_average = 0 THEN 'at'
		END AS status
	FROM group_mark
);
	-- put a final query here so that its results will go into the table.
