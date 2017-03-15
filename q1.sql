-- Distributions

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q1;

-- You must not change this table definition.
CREATE TABLE q1 (
	assignment_id integer,
	average_mark_percent real, 
	num_80_100 integer DEFAULT 0, 
	num_60_79 integer DEFAULT 0, 
	num_50_59 integer DEFAULT 0, 
	num_0_49 integer DEFAULT 0
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS every_group_grade_for_every_assignment CASCADE;
DROP VIEW IF EXISTS grades CASCADE;
DROP VIEW IF EXISTS percentages CASCADE;
DROP VIEW IF EXISTS avg_percentage_by_assignment CASCADE;
DROP VIEW IF EXISTS first_region CASCADE;
DROP VIEW IF EXISTS second_region CASCADE;
DROP VIEW IF EXISTS third_region CASCADE;
DROP VIEW IF EXISTS fourth_region CASCADE;
DROP VIEW IF EXISTS final_table_q1 CASCADE;
DROP VIEW IF EXISTS fourth_region_count CASCADE;

-- Define views for your intermediate steps here.

-- create a view for every grade by every group for every assignment
CREATE VIEW every_group_grade_for_every_assignment(assignment_id, group_id, rubric_id, weight, out_of, grade) AS
SELECT RubricItem.assignment_id, Grade.group_id, RubricItem.rubric_id, RubricItem.weight, RubricItem.out_of, Grade.grade
FROM RubricItem FULL JOIN Grade ON RubricItem.rubric_id = Grade.rubric_id; 

-- create a view to calculate total mark and grades got
CREATE VIEW grades(assignment_id,total_mark, grade_recieved) AS
SELECT assignment_id,SUM(weight*out_of) as total_mark, SUM(weight*grade) as grade_recieved
FROM every_group_grade_for_every_assignment
GROUP BY assignment_id, group_id;

-- creata a view for percentage
CREATE VIEW percentages(assignment_id, percentage) AS
SELECT assignment_id, (grade_recieved/total_mark)*100 as percentage
FROM grades;

--create a view for avg percentage
CREATE VIEW avg_percentage_by_assignment(assignment_id, average_mark_percent) AS
SELECT assignment_id, ((SUM(percentage))/(count(percentage))) as average_mark_percent
FROM percentages
GROUP BY assignment_id
HAVING count(percentage) > 1;

--we will now create views for all different regions needed
--create a view for 0-49 region aka first_region
CREATE VIEW first_region(assignment_id, num_0_49) AS
SELECT assignment_id,COALESCE(count(percentage),0) 
FROM percentages
GROUP BY assignment_id,percentage
HAVING percentage<50;

--create a view for 50-59 region aka second_region
CREATE VIEW second_region(assignment_id, num_50_59) AS
SELECT assignment_id, COALESCE(count(percentage),0)
FROM percentages
GROUP BY assignment_id,percentage
HAVING (percentage>=50 AND percentage <=59);

--create a view for 60-79 region aka third_region
CREATE VIEW third_region(assignment_id, num_60_79) AS
SELECT assignment_id, COALESCE(count(percentage),0) as num_60_79
FROM percentages
--WHERE (percentage >= 60 AND percentage <= 79)
GROUP BY assignment_id,percentage
HAVING (percentage>= 60 AND percentage <= 79);

--create a view for 80_100 region aka fourth_region
CREATE VIEW fourth_region(assignment_id,num_80_100) AS
SELECT assignment_id, COALESCE(count(percentage),0)
FROM percentages
GROUP BY assignment_id,percentage
HAVING (percentage>=80 AND percentage <=100);


-- Time to join all the above regions and avg percenage

CREATE VIEW final_table_q1(assignment_id, average_mark_percent, num_80_100, num_60_79, num_50_59, num_0_49) AS
SELECT avg_percentage_by_assignment.assignment_id, avg_percentage_by_assignment.average_mark_percent, fourth_region.num_80_100, third_region.num_60_79, second_region.num_50_59, first_region.num_0_49
FROM avg_percentage_by_assignment NATURAL JOIN first_region NATURAL JOIN second_region NATURAL JOIN third_region NATURAL JOIN fourth_region; 




-- Final answer.
INSERT INTO q1(assignment_id, average_mark_percent, num_80_100, num_60_79, num_50_59, num_0_49)
(SELECT assignment_id, average_mark_percent, num_80_100, num_60_79, num_50_59, num_0_49
from final_table_q1);	 
