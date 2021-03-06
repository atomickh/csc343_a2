import java.sql.*;

// Remember that part of your mark is for doing as much in SQL (not Java) 
// as you can. At most you can justify using an array, or the more flexible
// ArrayList. Don't go crazy with it, though. You need it rarely if at all.
//check
import java.util.ArrayList;

public class Assignment2 {

    // A connection to the database
    Connection connection;

    Assignment2() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
	  
            e.printStackTrace();
        }
    }

    /**
     * Connects to the database and sets the search path.
     * 
     * Establishes a connection to be used for this session, assigning it to the
     * instance variable 'connection'. In addition, sets the search path to
     * markus.
     * 
     * @param url
     *            the url for the database
     * @param username
     *            the username to be used to connect to the database
     * @param password
     *            the password to be used to connect to the database
     * @return true if connecting is successful, false otherwise
     */
    public boolean connectDB(String URL, String username, String password) {

	try {
	  connection = DriverManager.getConnection(URL, username, password);

	  if (connection != null) {
	      String queryString = "SET search_path TO markus;";
	      Statement s = connection.createStatement();
	      boolean o = s.execute(queryString);
	      
	      return true;
	  }
	  return false;
	} catch (SQLException e) {
	  e.printStackTrace();
	  return false;
	}
    }

    /**
     * Closes the database connection.
     * 
     * @return true if the closing was successful, false otherwise
     */
    public boolean disconnectDB() {
	  try {
	    connection.close();
	    return connection.isClosed();
	  } catch (SQLException e) {
		e.printStackTrace();
		return false;
	  }
    }

    /**
     * Assigns a grader for a group for an assignment.
     * 
     * Returns false if the groupID does not exist in the AssignmentGroup table,
     * if some grader has already been assigned to the group, or if grader is
     * not either a TA or instructor.
     * 
     * @param groupID
     *            id of the group
     * @param grader
     *            username of the grader
     * @return true if the operation was successful, false otherwise
     */
    public boolean assignGrader(int groupID, String grader) {

	try{
	    PreparedStatement pStatement;
	    ResultSet rs;
	    String queryString;
	    // Check if grader exists and is a ta 
	    queryString = "SELECT * FROM MarkusUser WHERE username = ?";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setString(1, grader);
	    rs = pStatement.executeQuery();

	    if (rs.next()) {
			String role = rs.getString("type");
			if (!(role.equals("TA") || role.equals("instructor"))){
				System.out.println("Guy isn't a ta");
				return false;
			}
	    } else {
		System.out.println("Not in Markus System");
		return false;
	    }
	    
	    // Check if group exists in AssignmentGroup 
	    queryString = "SELECT * FROM AssignmentGroup WHERE AssignmentGroup.group_id =  ? ";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setInt(1, groupID);
	    rs = pStatement.executeQuery();
	    
	    if (!rs.next()) {
		System.out.println("Group Doesn't Exist");
		return false;
	    }
	    
	    // Check if group is already assigned
	    queryString = "SELECT * FROM Grader WHERE group_id = ?";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setInt(1, groupID);
	    rs = pStatement.executeQuery();
	    
	    if (rs.next()) {
		System.out.println("Grader already exists");
		return false;
	    }
	    
	    // Insert row into Grader
	    queryString = "INSERT INTO Grader (group_id, username) VALUES (?, ?);";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setInt(1, groupID);
	    pStatement.setString(2, grader);
	    int updateRes = pStatement.executeUpdate();	    
	    
	    return true;
	} catch (SQLException e) {
		e.printStackTrace();
		System.out.println("Exception");
		return false;
	}

    }

    /**
     * Adds a member to a group for an assignment.
     * 
     * Records the fact that a new member is part of a group for an assignment.
     * Does nothing (but returns true) if the member is already declared to be
     * in the group.
     * 
     * Does nothing and returns false if any of these conditions hold: - the
     * group is already at capacity, - newMember is not a valid username or is
     * not a student, - there is no assignment with this assignment ID, or - the
     * group ID has not been declared for the assignment.
     * 
     * @param assignmentID
     *            id of the assignment
     * @param groupID
     *            id of the group to receive a new member
     * @param newMember
     *            username of the new member to be added to the group
     * @return true if the operation was successful, false otherwise
     */
    public boolean recordMember(int assignmentID, int groupID, String newMember) {
		try{
			PreparedStatement pStatement;
			ResultSet rs;
			String queryString;		
			// Check if member is already in group and get number of members in group,
			queryString = "SELECT * FROM Membership "+
				  "NATURAL JOIN AssignmentGroup "+
				  "WHERE group_id = ? "+
				  "AND assignment_id = ? ;";
			pStatement = connection.prepareStatement(queryString);
			pStatement.setInt(1, groupID);
			pStatement.setInt(2, assignmentID);
			rs = pStatement.executeQuery();
			Integer num_ppl = 0;
			Boolean already_assigned = false;
			while(rs.next()){
				num_ppl += 1;
				if (rs.getString("username") == newMember) {
				  already_assigned = true;
				  break;
				}
			}
			
			// Check if assignment and group exists and group is not at capacity
			queryString = "SELECT * FROM Assignment "+
				  "NATURAL JOIN AssignmentGroup "+
				  "WHERE (group_id = ? "+
				  "AND assignment_id = ? );";
			pStatement = connection.prepareStatement(queryString);
			pStatement.setInt(1, groupID);
			pStatement.setInt(2, assignmentID);
			rs = pStatement.executeQuery();
			if(rs.next()){
				if (num_ppl >= rs.getInt("group_max")){
					return false;
				}
			} else {
				return false;
			}
			
			// Check if newMember is a student
			queryString = "SELECT * FROM MarkusUser"+
				  "WHERE username = ? ;";
			pStatement = connection.prepareStatement(queryString);
			pStatement.setString(1, newMember);
			rs = pStatement.executeQuery();
			if(rs.next()){
				if (rs.getString("type") != "student"){
					return false;
				}
			} else {
				return false;
			}
			
			// If already assigned and no errors
			if (already_assigned) {
				return true;
			}
			
			// Insert new row into Membership
			queryString = "INSERT INTO Membership (username, group_id)"+
				  "VALUES (?, ?);";
			pStatement = connection.prepareStatement(queryString);
			pStatement.setString(1, newMember);
			pStatement.setInt(2, groupID);
			int updateRes = pStatement.executeUpdate();	    
			
			return true;
		} catch (SQLException e) {
			e.printStackTrace();
			return false;
		}


    }

    /**
     * Creates student groups for an assignment.
     * 
     * Finds all students who are defined in the Users table and puts each of
     * them into a group for the assignment. Suppose there are n. Each group
     * will be of the maximum size allowed for the assignment (call that k),
     * except for possibly one group of smaller size if n is not divisible by k.
     * Note that k may be as low as 1.
     * 
     * The choice of which students to put together is based on their grades on
     * another assignment, as recorded in table Results. Starting from the
     * highest grade on that other assignment, the top k students go into one
     * group, then the next k students go into the next, and so on. The last n %
     * k students form a smaller group.
     * 
     * In the extreme case that there are no students, does nothing and returns
     * true.
     * 
     * Students with no grade recorded for the other assignment come at the
     * bottom of the list, after students who received zero. When there is a tie
     * for grade (or non-grade) on the other assignment, takes students in order
     * by username, using alphabetical order from A to Z.
     * 
     * When a group is created, its group ID is generated automatically because
     * the group_id attribute of table AssignmentGroup is of type SERIAL. The
     * value of attribute repo is repoPrefix + "/group_" + group_id
     * 
     * Does nothing and returns false if there is no assignment with ID
     * assignmentToGroup or no assignment with ID otherAssignment, or if any
     * group has already been defined for this assignment.
     * 
     * @param assignmentToGroup
     *            the assignment ID of the assignment for which groups are to be
     *            created
     * @param otherAssignment
     *            the assignment ID of the other assignment on which the
     *            grouping is to be based
     * @param repoPrefix
     *            the prefix of the URL for the group's repository
     * @return true if successful and false otherwise
     */

    public class assignment_grades {
    public int assignment_id;
    public String username;
    public float grade;
 
    }

    public boolean createGroups(int assignmentToGroup, int otherAssignment,
            String repoPrefix) {
        return false;
    }

    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
	Assignment2 assign;
	
	try {
	    assign = new Assignment2();
	    
	    // Q1
	    String testURL = "jdbc:postgresql://localhost:5432/csc343h-huanian";
	    String testUser = "huanian";
	    String testPass = "";
	    System.out.println("q1");
	    boolean q1 = assign.connectDB(testURL, testUser, testPass);        
	    System.out.println(q1);
	    
	    //Q3
	    /*
	    int testID = 9000;
	    String testGrader1 = "t2";
	    String testGrader2 = "t5";
	    
	    System.out.println("q3");
	    boolean q3a = assign.assignGrader(testID, testGrader1);        
	    System.out.println(q3a);
	    boolean q3b = assign.assignGrader(6000, testGrader2);        
	    System.out.println(q3b);
	    */
	    //Q4
	    int testID = 9000;
	    String testGrader1 = "t2";
	    String testGrader2 = "t5";
	    
	    System.out.println("q3");
	    boolean q3a = assign.assignGrader(testID, testGrader1);        
	    System.out.println(q3a);
	    boolean q3b = assign.assignGrader(6000, testGrader2);        
	    System.out.println(q3b);	    
	    
	    //Q2
	    System.out.println("q2");
	    boolean q2 = assign.disconnectDB();        
	    System.out.println(q2);
	    	    
	    
	    System.out.println("Boo!");
        } catch (SQLException e) {
	    e.printStackTrace();
        }
        
    }
}