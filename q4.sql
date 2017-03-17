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


-- Define views for your intermediate steps here.

--to create a view for all graders assignment to assignment
CREATE VIEW graders_assigned(assignment_id, group_id, username) AS
SELECT AssignmentGroup.assignment_id, AssignmentGroup.group_id, Grader.username
FROM AssignmentGroup, Grader
WHERE AssignmentGroup.group_id = Grader.group_id;





-- create a view for every grade by every group for every assignment
CREATE VIEW q4_every_group_grade_for_every_assignment(assignment_id, username, group_id, rubric_id, weight, out_of, grade) AS
SELECT RubricItem.assignment_id, Grader.username, Grade.group_id, RubricItem.rubric_id, RubricItem.weight, RubricItem.out_of, Grade.grade
FROM RubricItem ,Grader, Grade
WHERE RubricItem.rubric_id = Grade.rubric_id AND Grade.group_id = Grader.group_id;


-- create a view to calculate total mark and grades got
CREATE VIEW q4_grades(assignment_id, username, group_id, total_mark, grade_recieved) AS
SELECT assignment_id,username, group_id, SUM(weight*out_of) as total_mark, SUM(weight*grade) as grade_recieved
FROM q4_every_group_grade_for_every_assignment
GROUP BY assignment_id, username, group_id;

-- creata a view for percentage
CREATE VIEW q4_percentages(assignment_id, username, group_id, percentage) AS
SELECT assignment_id, username, group_id, (grade_recieved/total_mark)*100 as percentage
FROM q4_grades;



--to create a view for assignment already graded
CREATE VIEW assignment_graded(assignment_id, group_id, username) AS
SELECT assignment_id, group_id, username
FROM q4_percentages;


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

--create a view for min and max grade
CREATE VIEW grade_min_max(assignment_id, username, min_mark, max_mark) AS
SELECT assignment_id, username, min(percentage), max(percentage)
FROM q4_percentages
GROUP BY assignment_id, username;

--required view
CREATE VIEW q4_required_table(assignment_id, username, num_marked, num_not_marked, min_mark, max_mark) AS
SELECT assignment_id, username, coalesce(num_marked,0), coalesce(num_not_marked,0), grade_min_max.min_mark, grade_min_max.max_mark
FROM count_assignment_not_graded NATURAL FULL JOIN grade_min_max NATURAL FULL JOIN count_assignment_graded;
--WHERE (count_assignment_graded.assignment_id = grade_min_max.assignment_id AND count_assignment_not_graded.assignment_id = grade_min_max.assignment_id
--AND count_assignment_graded.username = grade_min_max.username AND count_assignment_not_graded.username = grade_min_max.username)
--


-- Final answer.
INSERT INTO q4(assignment_id, username, num_marked, num_not_marked, min_mark, max_mark)
(SELECT assignment_id, username, num_marked, num_not_marked, min_mark, max_mark
FROM q4_required_table);

-- put a final query here so that its results will go into the table.
