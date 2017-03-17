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
DROP VIEW IF EXISTS all_students CASCADE;
DROP VIEW IF EXISTS assignments_list CASCADE;
DROP VIEW IF EXISTS solo_students CASCADE;
DROP VIEW IF EXISTS q3_grade_details_for_every_assignment CASCADE;
DROP VIEW IF EXISTS q3_grade_for_every_assignment_graded CASCADE;
DROP VIEW IF EXISTS each_assignment_mark CASCADE;
DROP VIEW IF EXISTS solo_students_percentage CASCADE;
DROP VIEW IF EXISTS solo_students_stat CASCADE;
DROP VIEW IF EXISTS collab_students CASCADE;
DROP VIEW IF EXISTS each_assignment_mark CASCADE;
DROP VIEW IF EXISTS q3_grade_for_all_assignments CASCADE;
DROP VIEW IF EXISTS solo_students_percentage_two CASCADE;
DROP VIEW IF EXISTS collab_groups_percentage CASCADE;
DROP VIEW IF EXISTS collab_groups_stat CASCADE;
DROP VIEW IF EXISTS q3_required_table CASCADE;
DROP VIEW IF EXISTS collab_groups_percentage_two CASCADE;

DROP VIEW IF EXISTS q3_group_percentages CASCADE;
--All students VIEW
CREATE VIEW all_students(group_id, team_size) AS
SELECT group_id, count(username)
FROM Membership
GROUP BY group_id
ORDER BY group_id asc;

--all_assignments
CREATE VIEW assignments_list(assignment_id,description) AS
SELECT DISTINCT assignment_id, description
FROM Assignment;

-- view for grade max possible for each assignment 
CREATE VIEW each_assignment_mark(assignment_id, group_id, total_out_of) AS
SELECT assignment_id, group_id, SUM(weight*out_of)
FROM RubricItem, Grade
WHERE RubricItem.rubric_id = Grade.rubric_id
GROUP BY group_id, assignment_id;

-- view for result of solo students
CREATE VIEW solo_students(assignment_id,group_id) AS
SELECT AssignmentGroup.assignment_id, AssignmentGroup.group_id
FROM AssignmentGroup NATURAL FULL JOIN all_students
WHERE all_students.team_size = 1 ;

-- create a view for every grade by every group for every assignment
CREATE VIEW q3_grade_details_for_every_assignment(assignment_id, group_id, weight, out_of, grade) AS
SELECT RubricItem.assignment_id, group_id, RubricItem.weight, RubricItem.out_of, Grade.grade
FROM RubricItem NATURAL JOIN Grade;

-- create a view to calculate total mark and grades got
CREATE VIEW q3_grade_for_every_assignment_graded(assignment_id, group_id, total_mark, grade_recieved) AS
SELECT assignment_id, group_id, SUM(weight*out_of) as total_mark, SUM(weight*grade) as grade_recieved
FROM q3_grade_details_for_every_assignment
GROUP BY assignment_id, group_id;

CREATE VIEW q3_grade_for_all_assignments(assignment_id, group_id, out_of, grade) AS
SELECT assignments_list.assignment_id, group_id, total_mark, grade_recieved
FROM q3_grade_for_every_assignment_graded NATURAL FULL JOIN assignments_list;

--view to store percentage of each assignment by each student
CREATE VIEW q3_group_percentages(assignment_id, group_id, solo_percentage) AS
SELECT assignment_id, group_id,((grade)/(out_of)*100)
FROM q3_grade_for_all_assignments;

--view to store percentage of each assignment by each SOLO student
CREATE VIEW solo_students_percentage_two(assignment_id, group_id, solo_percentage) AS
SELECT q3_group_percentages.assignment_id, solo_students.group_id, solo_percentage
FROM solo_students NATURAL FULL JOIN q3_group_percentages ;

CREATE VIEW solo_students_percentage(assignment_id, group_id, solo_percentage) AS
SELECT assignment_id,group_id, CASE WHEN group_id IS null THEN null ELSE solo_percentage END as temp
FROM solo_students_percentage_two;

--view for required solo students statistics
CREATE VIEW solo_students_stat(assignment_id, num_solo, average_solo ) AS
SELECT assignment_id, coalesce(count(group_id),0), avg(solo_percentage)
FROM solo_students_percentage
GROUP BY assignment_id;

--final stat

-- view for result of collab group students
CREATE VIEW collab_students(assignment_id,group_id,team_size) AS
SELECT AssignmentGroup.assignment_id, AssignmentGroup.group_id, team_size
FROM AssignmentGroup NATURAL FULL JOIN all_students
WHERE all_students.team_size > 1  ;

--view to store percentage of each assignment by each collab group student
CREATE VIEW collab_groups_percentage_two(assignment_id, group_id, group_percentage, team_size) AS
SELECT q3_group_percentages.assignment_id, collab_students.group_id,solo_percentage, team_size
FROM collab_students NATURAL FULL JOIN q3_group_percentages ;


CREATE VIEW collab_groups_percentage(assignment_id, group_id, group_percentage, team_size) AS
SELECT assignment_id,group_id, CASE WHEN group_id IS null THEN null ELSE group_percentage END as temp, team_size
FROM collab_groups_percentage_two;

--view for required collab group students statistics
CREATE VIEW collab_groups_stat(assignment_id, num_collaborators,average_collaborators, total_collab_groups) AS
SELECT assignment_id,coalesce(SUM(team_size),0),(SUM(group_percentage)/count(group_percentage)), count(collab_groups_percentage.group_id)
FROM collab_groups_percentage
GROUP BY assignment_id;

-- required table for q3
CREATE VIEW q3_required_table(assignment_id, description, num_solo, average_solo, num_collaborators, average_collaborators,average_students_per_group) AS
SELECT assignments_list.assignment_id, assignments_list.description, coalesce(solo_students_stat.num_solo,0), solo_students_stat.average_solo, coalesce(collab_groups_stat.num_collaborators,0), collab_groups_stat.average_collaborators,CASE WHEN total_collab_groups = 0 THEN null ELSE (solo_students_stat.num_solo+collab_groups_stat.num_collaborators)/(collab_groups_stat.total_collab_groups + num_solo) END as temp
FROM assignments_list NATURAL FULL JOIN solo_students_stat NATURAL JOIN collab_groups_stat;
-- Final answer
INSERT INTO q3 (assignment_id, description, num_solo, average_solo, num_collaborators, average_collaborators,average_students_per_submission)
(SELECT assignment_id, description, num_solo, average_solo, num_collaborators, average_collaborators,average_students_per_group
FROM q3_required_table);
-- put a final query here so that its results will go into the table.
