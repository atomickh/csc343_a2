
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
DROP VIEW IF EXISTS grader_history CASCADE;
DROP VIEW IF EXISTS total_possible_mark_for_each_assignment CASCADE;
DROP VIEW IF EXISTS grading_done CASCADE;
DROP VIEW IF EXISTS group_strength CASCADE;
DROP VIEW IF EXISTS q2_percentage CASCADE;
DROP VIEW IF EXISTS q2_avg_percentage CASCADE;
DROP VIEW IF EXISTS constraint_one CASCADE;
DROP VIEW IF EXISTS constraint_two CASCADE;
DROP VIEW IF EXISTS constraint_third CASCADE;
DROP VIEW IF EXISTS non_constraint_third CASCADE;
DROP VIEW IF EXISTS q2_avg_percentage CASCADE;
DROP VIEW IF EXISTS q2_total_avg_grader CASCADE;
DROP VIEW IF EXISTS required_ta_names CASCADE;
DROP VIEW IF EXISTS taNames CASCADE;
DROP VIEW IF EXISTS increase CASCADE;
DROP VIEW IF EXISTS q2_required_table CASCADE;
DROP VIEW IF EXISTS q2_grade_details_for_every_assignment CASCADE;
DROP VIEW IF EXISTS q2_grade_for_every_assignment_graded CASCADE;
DROP VIEW IF EXISTS q2_grade_for_all_assignments CASCADE;
DROP VIEW IF EXISTS q2_group_percentages CASCADE;
DROP VIEW IF EXISTS total_assignments CASCADE;
DROP VIEW IF EXISTS assignments_list CASCADE;
-- Define views for your intermediate steps here.

CREATE VIEW assignments_list(assignment_id,description) AS
SELECT DISTINCT assignment_id, description
FROM Assignment;

-- create a view for every grade by every group for every assignment
CREATE VIEW q2_grade_details_for_every_assignment(assignment_id, group_id, weight, out_of, grade) AS
SELECT RubricItem.assignment_id, group_id, RubricItem.weight, RubricItem.out_of, Grade.grade
FROM RubricItem NATURAL JOIN Grade;

-- create a view to calculate total mark and grades got
CREATE VIEW q2_grade_for_every_assignment_graded(assignment_id, group_id, total_mark, grade_recieved) AS
SELECT assignment_id, group_id, SUM(weight*out_of) as total_mark, SUM(weight*grade) as grade_recieved
FROM q2_grade_details_for_every_assignment
GROUP BY assignment_id, group_id;

CREATE VIEW q2_grade_for_all_assignments(assignment_id, group_id, out_of, grade) AS
SELECT assignments_list.assignment_id, group_id, total_mark, grade_recieved
FROM q2_grade_for_every_assignment_graded NATURAL FULL JOIN assignments_list;

--view to store percentage of each assignment by each student
CREATE VIEW q2_group_percentages(assignment_id, group_id, percentage) AS
SELECT assignment_id, group_id,((grade)/(out_of)*100)
FROM q2_grade_for_all_assignments;

-- view for GraderHistory which shows every graded assignment by grader
CREATE VIEW grader_history(username, assignment_id, assignment_due_date, group_id, total_mark) AS
SELECT Grader.username, AssignmentGroup.assignment_id, Assignment.due_date, Grader.group_id, q2_group_percentages.percentage
FROM AssignmentGroup NATURAL JOIN Grader NATURAL JOIN Result NATURAL JOIN Assignment NATURAL JOIN q2_group_percentages
ORDER BY username, assignment_id, group_id;
--view to calculate total out-of mark

-- to find number of people in a group
CREATE VIEW group_strength(group_id, groupStrength) AS
SELECT group_id, count(username)
FROM Membership
GROUP BY group_id;

--join upper three views
CREATE VIEW grading_done(username, assignment_id, assignment_due_date, group_id, groupStrength, percentage) AS
SELECT username, assignment_id, assignment_due_date, group_id, groupStrength, total_mark
FROM grader_history NATURAL JOIN group_strength;


-- to check first constraint 'They have graded (that is, they have been assigned to at least one group) on every assignment'
CREATE VIEW constraint_one(username) AS
SELECT grading_done.username
FROM grading_done
GROUP BY grading_done.username
HAVING count(DISTINCT grading_done.assignment_id) =
(SELECT count(DISTINCT Assignment.assignment_id)
FROM Assignment);

--total no of assignments
create view total_assignments(total) AS
SELECT count(DISTINCT assignment_id)
FROM Assignment;


-- to check second constraint 'They have completed grading (that is, there is a grade recorded in the Result table) for at least 10 groups on each assignment.'
CREATE VIEW constraint_two(username) AS
SELECT DISTINCT username
FROM grading_done
GROUP BY username, assignment_id
HAVING count(*)>=10;

-- to calculate average for each assignment by grader
CREATE VIEW q2_avg_percentage(username, assignment_id, assignment_due_date, avg_percentage) AS
SELECT username, assignment_id, assignment_due_date, (SUM(groupStrength*percentage)/SUM(groupStrength))
FROM grading_done
GROUP BY username, assignment_id, assignment_due_date
ORDER BY username, assignment_id, assignment_due_date;

-- to check third constraint 'The average grade they have given has gone up consistently from assignment to assignment over time (based on the assignment due date).'
CREATE VIEW non_constraint_third(username) AS
SELECT DISTINCT a.username
FROM q2_avg_percentage a, q2_avg_percentage b
WHERE a.username = b.username AND a.assignment_id <> b.assignment_id AND a.assignment_due_date > b.assignment_due_date AND a.avg_percentage < b.avg_percentage
--GROUP BY a.username, a.assignment_id
--HAVING count(*) = (
--SELECT count(*)-1 as count
--FROM q2_avg_percentage c
--WHERE c.username = a.username AND c.assignment_id = a.assignment_id
--GROUP BY c.username, c.assignment_id

;

CREATE VIEW constraint_third(username) AS
(SELECT DISTINCT username FROM grading_done)
EXCEPT
(SELECT DISTINCT username FROM non_constraint_third);
-- to calculate overall average for each grader i.e. including all assignments

CREATE VIEW q2_total_avg_grader(username, total_average) AS
SELECT username, avg(avg_percentage)
FROM q2_avg_percentage
GROUP BY username;

-- to apply constraints to TA, i.e. apply our above three constraints
CREATE VIEW required_ta_names(username) AS
SELECT constraint_one.username
FROM constraint_one NATURAL JOIN constraint_two NATURAL JOIN constraint_third;

-- to get TA name
CREATE VIEW taNames(username, ta_name) AS
SELECT username, (firstname|| ' '|| surname) as ta_name
FROM MarkusUser
WHERE type = 'TA';


-- to calculate the increase of grades from first to last assignment for each grader
CREATE VIEW increase(username, grade_increase) AS
SELECT a.username, max(a.avg_percentage)-min(a.avg_percentage)
FROM q2_avg_percentage a, required_ta_names b
WHERE a.username = b.username
GROUP BY a.username;

--now the required table
CREATE VIEW q2_required_table(ta_name, average_mark_all_assignments, mark_change_first_last) AS
SELECT taNames.ta_name, q2_total_avg_grader.total_average, increase.grade_increase
FROM taNames, q2_total_avg_grader, increase
WHERE taNames.username = q2_total_avg_grader.username AND taNames.username = increase.username ;
-- Final answer.
INSERT INTO q2 (ta_name, average_mark_all_assignments, mark_change_first_last)
(SELECT ta_name, average_mark_all_assignments, mark_change_first_last
FROM q2_required_table);
-- put a final query here so that its results will go into the table.
