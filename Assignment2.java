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
		String pathURL;
        try {
	    pathURL = URL+"searchpath=markus";
            connection = DriverManager.getConnection(pathURL, username, password);
            return true;
        } catch (SQLException ex) {
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
			if (rs != null){
				rs.close();
			}
		} catch (Exception ex){}
		try {
			if (pStatement != null){
				pStatement.close();
			}
		} catch (Exception ex){}
        try {
			if (connection != null){
				connection.close();
			}
		} catch (Exception ex){
			System.out.print(ex);
			return false;
		}
		return true;
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
	PreparedStatement pStatement;
	ResultSet rs;
	String queryString;
	try{
	    // Check if grader exists and is a ta 
	    queryString = "SELECT * FROM MarkusUser WHERE username = ?";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setString(1, grader);
	    rs = pStatement.executeQuery();

	    if (rs.next()) {
			String role = rs.getString("type");
			if (role != "ta" && role != "instructor"){
				return false;
			}
	    } else {
			return false;
	    }
	    
	    
	    // Check if group exists in AssignmentGroup
	    queryString = "SELECT * FROM AssignmentGroup WHERE group_id = ?";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setString(1, Integer.toString(groupID));
	    rs = pStatement.executeQuery();
	    
	    if (!rs.next()) {
			return false;
	    }
	    
	    // Check if group is already assigned
	    queryString = "SELECT * FROM Grader WHERE group_id = ?";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setString(1, Integer.toString(groupID));
	    rs = pStatement.executeQuery();
	    
	    if (rs.next()) {
			return false;
	    }
	    
	    // Insert row into Grader
	    queryString = "INSERT INTO Grader (group_id, username) VALUES (?, ?);";
	    pStatement = connection.prepareStatement(queryString);
	    pStatement.setString(1, Integer.toString(groupID));
	    pStatement.setString(2, grader);
	    int updateRes = pStatement.executeUpdate();	    
	    rs.close();
		pStatement.close90;
	    return true;
	} catch (SQLException ex) {
	    rs.close();
		pStatement.close90;
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
		PreparedStatement pStatement;
		ResultSet rs;
		String queryString;
		try{
			// Check if member is already in group and get number of members in group,
			queryString = "SELECT * FROM Membership "+
				  "NATURAL JOIN AssignmentGroup "+
				  "WHERE group_id = ? "+
				  "AND assignment_id = ? ;";
			pStatement = connection.prepareStatement(queryString);
			pStatement.setString(1, Integer.toString(groupID));
			pStatement.setString(2, Integer.toString(assignmentID));
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
			pStatement.setString(1, Integer.toString(groupID));
			pStatement.setString(2, Integer.toString(assignmentID));
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
			pStatement.setString(2, Integer.toString(groupID));
			int updateRes = pStatement.executeUpdate();	    
			
			return true;
		} catch (SQLException ex) {
			System.out.print(ex);
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
        // Replace this return statement with an implementation of this method!

     // array list to hold  student grades from otherAssignment
    ArrayList<assignment_grades> assignment_grades_arraylist = new ArrayList<assignment_grades>();
    PreparedStatement pStatement;
    ResultSet rs;
    String queryString;

    Statement st = conn.createStatement();
    queryString = "SELECT assignment_id, username, grade " +
                  "FROM AssignmentGroup NATURAL JOIN Membership NATURAL JOIN Result "
                  "WHERE Result.released = true;" ;
    ResultSet rs = st.executeQuery(queryString);
     
    while (rs.next()) {
    //storing in class assignment_grades
    assignment_grades student_record = new assignment_grades();
    student_record.assignment_id = rs.getInt("assignment_id");
    student_record.username = rs.getString("username");
    student_record.grade = rs.getFloat("grade");
    //adding to assignment_grades_arraylist
    assignment_grades_arraylist.add(person);
/* If the tuple also had a float and another int  
attribute, you’d get them by calling   worths.getFloat(2) and worths.getInt(3). 
Or you can look up values by attribute name.  Example: worths.getInt(netWorth) 
*/
   /* OMITTED: Process this net worth */
}

        return false;
    }

    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
        System.out.println("Boo!");
    }
}