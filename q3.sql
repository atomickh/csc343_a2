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
DROP VIEW IF EXISTS all_students CASCADE;
DROP VIEW IF EXISTS solo_students_result CASCADE;
DROP VIEW IF EXISTS each_assignment_mark CASCADE;
DROP VIEW IF EXISTS solo_students_percentage CASCADE;
DROP VIEW IF EXISTS solo_students_stat CASCADE;
DROP VIEW IF EXISTS collab_students_result CASCADE;
DROP VIEW IF EXISTS each_assignment_mark CASCADE;
DROP VIEW IF EXISTS collab_groups_percentage CASCADE;
DROP VIEW IF EXISTS collab_groups_stat CASCADE;
DROP VIEW IF EXISTS q3_required_table CASCADE;

-- Define views for your intermediate steps here.

--all students VIEW
CREATE VIEW all_students(group_id, team_size) AS
SELECT group_id, count(username)
FROM Membership
GROUP BY group_id;

-- view for result of solo students
CREATE VIEW solo_students_result(assignment_id,group_id,total_mark) AS
SELECT AssignmentGroup.assignment_id, AssignmentGroup.group_id, Result.mark
FROM AssignmentGroup, Result, all_students
WHERE all_students.team_size = 1 AND AssignmentGroup.group_id = all_students.group_id AND all_students.group_id = Result.group_id;

-- view for grade max possible for each assignment 
CREATE VIEW each_assignment_mark(assignment_id, total_out_of) AS
SELECT assignment_id, SUM(weight*out_of)
FROM RubricItem
GROUP BY assignment_id;

--view to store percentage of each assignment by each solo student
CREATE VIEW solo_students_percentage(assignment_id, group_id, solo_percentage) AS
SELECT solo_students_result.assignment_id, solo_students_result.group_id, solo_students_result.total_mark/each_assignment_mark.total_out_of*100
FROM solo_students_result, each_assignment_mark
WHERE solo_students_result.assignment_id = each_assignment_mark.assignment_id;

--view for required solo students statistics
CREATE VIEW solo_students_stat(assignment_id, num_solo, average_solo)
SELECT assignment_id, count(group_id), (SUM(solo_percentage)/count(solo_percentage))
FROM solo_students_percentage
GROUP BY assignment_id;
 
-- view for result of students working in groups
CREATE VIEW collab_students_result(assignment_id,group_id,total_mark) AS
SELECT AssignmentGroup.assignment_id, AssignmentGroup.group_id, Result.mark
FROM AssignmentGroup, Result, all_students
WHERE all_students.team_size > 1 AND AssignmentGroup.group_id = all_students.group_id AND all_students.group_id = Result.group_id;

--view to store percentage of each assignment by each collab group 
CREATE VIEW collab_groups_percentage(assignment_id, group_id, group_percentage) AS
SELECT collab_students_result.assignment_id, collab_students_result.group_id, collab_students_result.total_mark/each_assignment_mark.total_out_of*100
FROM collab_students_result, each_assignment_mark
WHERE collab_students_result.assignment_id = each_assignment_mark.assignment_id;

--view for required collab group students statistics
CREATE VIEW collab_groups_stat(assignment_id, num_collaborators, average_collaborators, total_collab_groups)
SELECT assignment_id, SUM(group_id), (SUM(group_percentage)/count(group_percentage)), count(group_id)
FROM solo_students_percentage
GROUP BY assignment_id;


-- required table for q3
CREATE VIEW q3_required_table(assignment_id, description, num_solo, average_solo, num_collaborators, average_collaborators,average_students_per_group)
SELECT Assignment.assignment_id, Assignment.description, solo_students_stat.num_solo, solo_students_stat.average_solo, collab_groups_stat.num_collaborators, b_groups_stat.average_collaborators, (solo_students_stat.num_solo+collab_groups_stat.num_collaborators)/(solo_students_stat.num_solo+collab_groups_stat.total_collab_groups)
FROM Assignment, solo_students_stat, collab_groups_stat
WHERE Assignment.assignment_id = solo_students_stat.assignment_id AND solo_students_stat.assignment_id = collab_groups_stat.assignment_id;


-- Final answe
INSERT INTO q3 (assignment_id, description, num_solo, average_solo, num_collaborators, average_collaborators,average_students_per_submission)
(SELECT assignment_id, description, num_solo, average_solo, num_collaborators, average_collaborators,average_students_per_group
FROM q3_required_table);	
-- put a final query here so that its results will go into the table.
