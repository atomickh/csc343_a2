-- Solo superior

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q3;

-- You must not change this table definition.
CREATE TABLE q3 (
	assignment_id integer,
	description varchar(100), 
	num_solo integer, 
	average_solo real,
	num_collaborators integer, 
	average_collaborators real, 
	average_students_per_submission real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.

-- Final answer.
INSERT INTO q3
	-- put a final query here so that its results will go into the table.
