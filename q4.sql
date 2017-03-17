-- Grader report

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q4;

-- You must not change this table definition.
CREATE TABLE q4 (
        assignment_id integer,
        username varchar(25),
        num_marked integer,
        num_not_marked integer,
        min_mark real,
        max_mark real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)

DROP VIEW IF EXISTS graders_assigned CASCADE;
DROP VIEW IF EXISTS assignment_graded CASCADE;
DROP VIEW IF EXISTS assignment_not_graded CASCADE;
DROP VIEW IF EXISTS count_assignment_graded CASCADE;
DROP VIEW IF EXISTS count_assignment_not_graded CASCADE;
DROP VIEW IF EXISTS q4_every_group_grade_for_every_assignment CASCADE;
DROP VIEW IF EXISTS q4_grades CASCADE;
DROP VIEW IF EXISTS q4_percentages CASCADE;
DROP VIEW IF EXISTS grade_min_max CASCADE;
DROP VIEW IF EXISTS q4_required_table CASCADE;
DROP VIEW IF EXISTS q4_each_assignment_mark CASCADE;


-- Define views for your intermediate steps here.

--to create a view for all graders assignment to assignment
CREATE VIEW graders_assigned(assignment_id, group_id, username) AS
SELECT AssignmentGroup.assignment_id, AssignmentGroup.group_id, Grader.username
FROM AssignmentGroup, Grader
WHERE AssignmentGroup.group_id = Grader.group_id;

--to create a view for assignment already graded
CREATE VIEW assignment_graded(assignment_id, group_id, username, mark_recieved) AS
SELECT graders_assigned.assignment_id, Result.group_id, graders_assigned.username, Result.mark
FROM graders_assigned NATURAL JOIN Result
WHERE Result.mark IS NOT NULL;

--to creata a view for assignment not graded but graders assigned
CREATE VIEW assignment_not_graded(assignment_id, group_id, username) AS
SELECT assignment_id, group_id, username
FROM graders_assigned
WHERE (assignment_id, group_id, username) NOT IN (
SELECT assignment_id, group_id, username
FROM assignment_graded);

--to count num of assignment graded
CREATE VIEW count_assignment_graded(assignment_id, username, num_marked) AS
SELECT assignment_id, username, count(*)
FROM assignment_graded
GROUP BY assignment_id, username;

--to count num of assignment not graded
CREATE VIEW count_assignment_not_graded(assignment_id, username, num_not_marked) AS
SELECT assignment_id, username, count(*)
FROM assignment_not_graded
GROUP BY assignment_id, username;

-- view for grade max possible for each assignment 
CREATE VIEW q4_each_assignment_mark(assignment_id, group_id, total_out_of) AS
SELECT assignment_id, group_id, SUM(weight*out_of)
FROM RubricItem, Grade
WHERE RubricItem.rubric_id = Grade.rubric_id
GROUP BY group_id, assignment_id;

-- creata a view for percentage
CREATE VIEW q4_percentages(assignment_id, username, group_id, percentage) AS
SELECT assignment_id, username, group_id, (mark_recieved/total_out_of)*100 as percentage
FROM assignment_graded NATURAL JOIN q4_each_assignment_mark;

--create a view for min and max grade
CREATE VIEW grade_min_max(assignment_id, username, min_mark, max_mark) AS
SELECT assignment_id, username, min(percentage), max(percentage)
FROM q4_percentages
GROUP BY assignment_id, username;

--required view
CREATE VIEW q4_required_table(assignment_id, username, num_marked, num_not_marked, min_mark, max_mark) AS
SELECT grade_min_max.assignment_id, grade_min_max.username, coalesce(num_marked,0), coalesce(num_not_marked,0), grade_min_max.min_mark, grade_min_max.max_mark
FROM count_assignment_not_graded NATURAL FULL JOIN grade_min_max NATURAL FULL JOIN count_assignment_graded;
--WHERE (count_assignment_graded.assignment_id = grade_min_max.assignment_id AND count_assignment_not_graded.assignment_id = grade_min_max.assignment_id
--AND count_assignment_graded.username = grade_min_max.username AND count_assignment_not_graded.username = grade_min_max.username)
--


-- Final answer.
INSERT INTO q4(assignment_id, username, num_marked, num_not_marked, min_mark, max_mark)
(SELECT assignment_id, username, num_marked, num_not_marked, min_mark, max_mark
FROM q4_required_table);

-- put a final query here so that its results will go into the table.
