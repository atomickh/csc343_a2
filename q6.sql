

-- Steady work

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q6;

-- You must not change this table definition.
CREATE TABLE q6 (
	group_id integer,
	first_file varchar(25),
	first_time timestamp,
	first_submitter varchar(25),
	last_file varchar(25),
	last_time timestamp, 
	last_submitter varchar(25),
	elapsed_time interval
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS A1_group, first_sub, last_sub CASCADE;

-- Define views for your intermediate steps here.

-- Groups that are associated with A1
CREATE VIEW A1_group AS (
	SELECT group_id
	FROM AssignmentGroup NATURAL JOIN Assignment
	WHERE Assignment.description = 'A1'
);

-- First submissions for each A1 group	
CREATE VIEW first_sub AS (
	SELECT t1.file_name, t1.username, t1.group_id, t1.submission_date
	FROM Submissions AS t1
		JOIN (
			SELECT t3.group_id, MIN(submission_date) AS first_date
			FROM Submissions AS t3
			GROUP BY t3.group_id
			HAVING EXISTS(SELECT 1 FROM A1_group WHERE t3.group_id = A1_group.group_id)
		) AS t2 ON (t1.group_id = t2.group_id AND t1.submission_date = t2.first_date)
);	
		
-- Last submissions for each A1 Group	
CREATE VIEW last_sub AS (
	SELECT t1.file_name, t1.username, t1.group_id, t1.submission_date
	FROM Submissions AS t1
		JOIN(
			SELECT t3.group_id, MAX(submission_date) AS last_date
			FROM Submissions AS t3
			GROUP BY t3.group_id
			HAVING EXISTS(SELECT 1 FROM A1_group WHERE t3.group_id = A1_group.group_id)
		) AS t2 ON (t1.group_id = t2.group_id AND t1.submission_date = t2.last_date)
);

	
	
-- Final answer.
INSERT INTO q6 (
	SELECT t1.group_id AS group_id, 
		   t1.file_name AS first_file,
		   t1.submission_date AS first_time,
		   t1.username AS first_submitter,
		   t2.file_name AS last_file,
		   t2.submission_date AS last_time,
		   t2.username AS last_submitter, 
		   (t2.submission_date - t1.submission_date) AS elapsed_time 
		   FROM first_sub AS t1 JOIN last_sub AS t2 
				ON(t1.group_id = t2.group_id)
);
	-- put a final query here so that its results will go into the table.

