-- If there is already any data in these tables, empty it out.

TRUNCATE TABLE Result CASCADE;
TRUNCATE TABLE Grade CASCADE;
TRUNCATE TABLE RubricItem CASCADE;
TRUNCATE TABLE Grader CASCADE;
TRUNCATE TABLE Submissions CASCADE;
TRUNCATE TABLE Membership CASCADE;
TRUNCATE TABLE AssignmentGroup CASCADE;
TRUNCATE TABLE Required CASCADE;
TRUNCATE TABLE Assignment CASCADE;
TRUNCATE TABLE MarkusUser CASCADE;


-- Now insert data from scratch.

INSERT INTO MarkusUser VALUES ('i1', 'iln1', 'ifn1', 'instructor');
INSERT INTO MarkusUser VALUES ('s1', 'sln1', 'sfn1', 'student');
INSERT INTO MarkusUser VALUES ('s2', 'sln2', 'sfn2', 'student');
INSERT INTO MarkusUser VALUES ('s3', 'sln3', 'sfn3', 'student');
INSERT INTO MarkusUser VALUES ('s4', 'sln4', 'sfn4', 'student');
INSERT INTO MarkusUser VALUES ('t1', 'tln1', 'tfn1', 'TA');
INSERT INTO MarkusUser VALUES ('t2', 'tln2', 'tfn2', 'TA');

INSERT INTO Assignment VALUES (1000, 'a1', '2017-02-08 20:00', 1, 1);
INSERT INTO Assignment VALUES (2000, 'a2', '2017-02-08 20:00', 1, 2);

INSERT INTO Required VALUES (1000, 'A1.pdf');

INSERT INTO AssignmentGroup VALUES (1000, 1000, 'repo_url');
INSERT INTO AssignmentGroup VALUES (2000, 1000, 'repo_url2');
INSERT INTO AssignmentGroup VALUES (3000, 1000, 'repo_url3');
INSERT INTO AssignmentGroup VALUES (4000, 1000, 'repo_url3');
INSERT INTO AssignmentGroup VALUES (5000, 2000, 'repo_url');
INSERT INTO AssignmentGroup VALUES (6000, 2000, 'repo_url');


INSERT INTO Membership VALUES ('s1', 1000);
INSERT INTO Membership VALUES ('s2', 2000);
INSERT INTO Membership VALUES ('s3', 3000);
INSERT INTO Membership VALUES ('s4', 4000);
INSERT INTO Membership VALUES ('s1', 5000);
INSERT INTO Membership VALUES ('s2', 5000);
INSERT INTO Membership VALUES ('s3', 6000);
INSERT INTO Membership VALUES ('s4', 6000);

INSERT INTO Submissions VALUES (1000, 'A1.pdf', 's1', 1000, '2017-02-08 19:59');
INSERT INTO Submissions VALUES (2000, 'A1.pdf', 's2', 2000, '2017-02-08 19:59');
INSERT INTO Submissions VALUES (3000, 'A1.pdf', 's3', 3000, '2017-02-08 19:59');
INSERT INTO Submissions VALUES (4000, 'A1.pdf', 's4', 4000, '2017-02-08 19:59');
INSERT INTO Submissions VALUES (5000, 'A12.pdf', 's3', 3000, '2017-02-09 19:59');
INSERT INTO Submissions VALUES (6000, 'A12.pdf', 's4', 4000, '2017-02-10 19:59');

INSERT INTO Grader VALUES (1000, 't1');
INSERT INTO Grader VALUES (2000, 't1');
INSERT INTO Grader VALUES (3000, 't1');
INSERT INTO Grader VALUES (4000, 't1');
INSERT INTO Grader VALUES (5000, 't2');


INSERT INTO RubricItem VALUES (4000, 1000, 'style', 4, 0.25);
INSERT INTO RubricItem VALUES (4001, 1000, 'tester', 12, 0.75);

INSERT INTO RubricItem VALUES (5000, 2000, 'style', 4, 0.25);
INSERT INTO RubricItem VALUES (5001, 2000, 'tester', 12, 0.75);

INSERT INTO Grade VALUES (1000, 4000, 3);
INSERT INTO Grade VALUES (1000, 4001, 9);

INSERT INTO Grade VALUES (2000, 4000, 4);
INSERT INTO Grade VALUES (2000, 4001, 10);

INSERT INTO Grade VALUES (5000, 4000, 4);
INSERT INTO Grade VALUES (5000, 4001, 12);

INSERT INTO Result VALUES (2000, 12, true);
INSERT INTO Result VALUES (3000, 12, true);
INSERT INTO Result VALUES (4000, 12, true);
