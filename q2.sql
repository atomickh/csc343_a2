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
DROP VIEW IF EXISTS grader_history CASCADE;
DROP VIEW IF EXISTS total_possible_mark_for_each_assignment CASCADE;
DROP VIEW IF EXISTS grading_done CASCADE;
DROP VIEW IF EXISTS group_strength CASCADE;
DROP VIEW IF EXISTS q2_percentage CASCADE;
DROP VIEW IF EXISTS q2_avg_percentage CASCADE;
DROP VIEW IF EXISTS constraint_one CASCADE;
DROP VIEW IF EXISTS constraint_two CASCADE;
DROP VIEW IF EXISTS constraint_third CASCADE;
DROP VIEW IF EXISTS q2_avg_percentage CASCADE;
DROP VIEW IF EXISTS q2_total_avg_grader CASCADE;
DROP VIEW IF EXISTS required_ta_names CASCADE;
DROP VIEW IF EXISTS taNames CASCADE;
DROP VIEW IF EXISTS increase CASCADE;
DROP VIEW IF EXISTS q2_required_table CASCADE;

-- Define views for your intermediate steps here.

-- view for GraderHistory which shows every graded assignment by grader
CREATE VIEW grader_history(username, assignment_id, assignment_due_date, group_id, total_mark) AS
SELECT Grader.username, AssignmentGroup.assignment_id, Assignment.due_date, Grader.group_id, Result.mark
FROM AssignmentGroup, Grader, Result, Assignment
WHERE AssignmentGroup.group_id = Grader.group_id AND Grader.group_id = Result.group_id AND AssignmentGroup.assignment_id = Assignment.assignment_id AND Result.released = true;

--view to calculate total out-of mark
CREATE VIEW total_possible_mark_for_each_assignment(assignment_id, total_out_of) AS
SELECT assignment_id, (SUM(weight*out_of)) as total_out_of	  
FROM RubricItem
GROUP BY assignment_id;

-- to find number of people in a group
CREATE VIEW group_strength(group_id, groupStrength) AS
SELECT group_id, count(username)
FROM Membership
GROUP BY group_id;

--join upper three views
CREATE VIEW grading_done(username, assignment_id, assignment_due_date, group_id, groupStrength, total_mark, total_out_of) AS
SELECT grader_history.username, grader_history.assignment_id, grader_history.assignment_due_date, grader_history.group_id, group_strength.groupStrength, grader_history.total_mark,total_possible_mark_for_each_assignment.total_out_of 
FROM grader_history, total_possible_mark_for_each_assignment, group_strength
WHERE grader_history.assignment_id = total_possible_mark_for_each_assignment.assignment_id AND grader_history.group_id = group_strength.group_id ;

-- to check first constraint 'They have graded (that is, they have been assigned to at least one group) on every assignment'
CREATE VIEW constraint_one(username) AS
SELECT grading_done.username
FROM grading_done
GROUP BY grading_done.username
HAVING count(DISTINCT grading_done.assignment_id) = 
(SELECT count(DISTINCT Assignment.assignment_id)
FROM Assignment);


-- to calculate percentage for each assignment for each group 
CREATE VIEW q2_percentage(username, assignment_id, assignment_due_date, group_id, groupStrength, percentage) AS
SELECT username, assignment_id, assignment_due_date, group_id, groupStrength, (total_mark/total_out_of*100)
FROM grading_done;

-- to check second constraint 'They have completed grading (that is, there is a grade recorded in the Result table) for at least 10 groups on each assignment.'
CREATE VIEW constraint_two(username) AS
SELECT username
FROM q2_percentage
GROUP BY username, assignment_id
HAVING count(*)>=10;



-- to calculate average for each assignment by grader
CREATE VIEW q2_avg_percentage(username, assignment_id, assignment_due_date, avg_percentage) AS
SELECT username, assignment_id, assignment_due_date, (SUM(groupStrength*percentage)/SUM(groupStrength))
FROM q2_percentage
GROUP BY username, assignment_id, assignment_due_date;


-- to check third constraint 'The average grade they have given has gone up consistently from assignment to assignment over time (based on the assignment due date).'
CREATE VIEW constraint_third(username, assignment_id) AS
SELECT a.username, a.assignment_id 
FROM q2_avg_percentage a, q2_avg_percentage b
WHERE a.username = b.username AND a.assignment_due_date < b.assignment_due_date AND a.avg_percentage < b.avg_percentage
GROUP BY a.username, a.assignment_id
HAVING count(*) = (
SELECT count(*)
FROM q2_avg_percentage c
WHERE c.username = a.username AND c.assignment_id = a.assignment_id
GROUP BY c.username, c.assignment_id
); 

-- to calculate overall average for each grader i.e. including all assignments
CREATE VIEW q2_total_avg_grader(username, total_average) AS
SELECT username,(SUM(percentage)/SUM(groupStrength))
FROM q2_percentage
GROUP BY username;

-- to apply constraints to TA, i.e. apply our above three constraints
CREATE VIEW required_ta_names(username) AS
SELECT constraint_one.username
FROM constraint_one, constraint_two, constaint_third
WHERE constraint_one.username = constraint_two.username AND constraint_two.username = constraint_third.username;

-- to get TA name
CREATE VIEW taNames(username, ta_name) AS
SELECT username, (firstname|| ' '|| surname) as ta_name
FROM MarkusUser;


-- to calculate the increase of grades from first to last assignment for each grader
CREATE VIEW increase(username, grade_increase) AS
SELECT a.username, max(a.avg_percentage)-min(a.avg_percentage)
FROM q2_avg_percentage a, required_ta_names b
WHERE a.username = b.username;

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
