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
GROUP BY assignment_id;

--we will now create views for all different regions needed
--create a view for 0-49 region aka first_region
CREATE VIEW first_region(assignment_id, num_0_49) AS
SELECT assignment_id,count(percentage)
FROM (SELECT * FROM percentages
WHERE percentage < 50 and percentage>=0) temp
GROUP BY assignment_id;

--create a view for 50-59 region aka second_region
CREATE VIEW second_region(assignment_id, num_50_59) AS
SELECT assignment_id,count(percentage)
FROM (SELECT * FROM percentages
WHERE percentage <=59  and percentage>=50) temp
GROUP BY assignment_id;

--create a view for 60-79 region aka third_region
CREATE VIEW third_region(assignment_id, num_60_79) AS
SELECT assignment_id,count(percentage)
FROM (SELECT * FROM percentages
WHERE percentage <=79 and percentage>=60) temp
GROUP BY assignment_id;

--create a view for 80_100 region aka fourth_region
CREATE VIEW fourth_region(assignment_id,num_80_100) AS
SELECT assignment_id,count(percentage)
FROM (SELECT * FROM percentages
WHERE percentage <= 100 and percentage>=80) temp
GROUP BY assignment_id;


-- Time to join all the above regions and avg percenage

CREATE VIEW final_table_q1(assignment_id, average_mark_percent, num_80_100, num_60_79, num_50_59, num_0_49) AS
SELECT avg_percentage_by_assignment.assignment_id, avg_percentage_by_assignment.average_mark_percent, coalesce(num_80_100,0) ,coalesce(num_60_79,0) ,coalesce(num_50_59,0), coalesce(num_0_49,0)
FROM avg_percentage_by_assignment NATURAL FULL JOIN first_region NATURAL FULL JOIN second_region NATURAL FULL JOIN third_region NATURAL FULL JOIN fourth_region;




-- Final answer.
INSERT INTO q1(assignment_id, average_mark_percent, num_80_100, num_60_79, num_50_59, num_0_49)
(SELECT assignment_id, average_mark_percent, num_80_100, num_60_79, num_50_59, num_0_49
from final_table_q1);
