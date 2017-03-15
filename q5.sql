-- Uneven workloads

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q5;

-- You must not change this table definition.
CREATE TABLE q5 (
	assignment_id integer,
	username varchar(25), 
	num_assigned integer
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS graders_assignmentgroup CASCADE;
DROP VIEW IF EXISTS count_groups CASCADE;
DROP VIEW IF EXISTS required_assignment_id CASCADE;
DROP VIEW IF EXISTS required_table CASCADE;
-- Define views for your intermediate steps here.

-- view to first join AssignmentGroup and Grader
CREATE VIEW graders_assignmentgroup(assignment_id,username,group_id) AS
SELECT AssignmentGroup.assignment_id, Grader.username, Grader.group_id
FROM Grader, AssignmentGroup
WHERE Grader.group_id=AssignmentGroup.group_id;

-- view to count groups for each grader by assignment_id
CREATE VIEW count_groups(assignment_id,username,groups_count) AS
SELECT assignment_id,username,count(group_id)
FROM graders_assignmentgroup
GROUP BY username,assignment_id;

-- view to have assignment_id with groups_count range greater than 10
CREATE VIEW required_assignment_id(assignment_id) AS
SELECT assignment_id
FROM count_groups
GROUP BY assignment_id
HAVING (max(groups_count)-min(groups_count) > 10);

-- view to create required table
CREATE VIEW required_table(assignment_id,username,num_assigned) AS
SELECT count_groups.assignment_id, count_groups.username, count_groups.groups_count
FROM count_groups, required_assignment_id
WHERE count_groups.assignment_id=required_assignment_id.assignment_id;

-- Final answer.
INSERT INTO q5(assignment_id,username,num_assigned)
(SELECT assignment_id,username,num_assigned
FROM required_table); 
	-- put a final query here so that its results will go into the table.
