-- Getting soft

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q2;

-- You must not change this table definition.
CREATE TABLE q2 (
	ta_name varchar(100),
	average_mark_all_assignments real,
	mark_change_first_last real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.

-- Final answer.
INSERT INTO q2 
	-- put a final query here so that its results will go into the table.
