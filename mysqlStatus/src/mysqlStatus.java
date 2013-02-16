import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.io.*;
import java.util.*;
import org.apache.commons.cli.*;

public class mysqlStatus {

	public static String configFile = "./config.properties";
	public static String dbConnection;
	public static String dbUserName;
	public static String dbUserPassword;
	public static String filePath;
	public static String fileFormat;
	public static String resultFileName;

	private static String initConfig(String[] args){
		String result = new String();
		CommandLineParser parser = new PosixParser();

		Options options = new Options();
		options.addOption("c", "config-file", true, "set configuration file.");
		options.addOption("h", "help", false, "print usage.");

		try{
			CommandLine line = parser.parse(options, args);

			if(line.hasOption("c")){
				configFile = line.getOptionValue("c");
				result = configFile;
			}
			if(line.hasOption("h")){
				HelpFormatter help = new HelpFormatter();
				help.printHelp("mysqlStatus", options);
				result = "";
			}
		}
		catch(ParseException e){
			e.printStackTrace();
		}

		return result;
	}

	private static void readConfig(String configFileName){
		Properties configFile = new Properties();
		InputStream is;

		try{
			is = new FileInputStream(configFileName);
			configFile.load(is);
			dbConnection = configFile.getProperty("DB_CONNECTION");
			dbUserName = configFile.getProperty("DB_LOGIN");
			dbUserPassword = configFile.getProperty("DB_PASSWORD");
			filePath = configFile.getProperty("OUTPUT_PATH");
			fileFormat = configFile.getProperty("FILE_FORMAT");
			resultFileName = configFile.getProperty("RESULT_FILE_NAME");
		}
		catch (IOException e){
			e.printStackTrace();
		}
	}

	private static String getInnoDBStatus(Connection connection){
		String result = "";

		try{
			String query1 = "SHOW VARIABLES WHERE Variable_name = 'hostname'";
			String query2 = "SHOW INNODB STATUS";
			Statement stmt = connection.createStatement();
			ResultSet rs1 = stmt.executeQuery(query1);

			while (rs1.next()) {
				// java.sql.SQLException: Column Index out of range, 4 > 3.
				// How to obtain this number of columns?
				result += "Status for " + rs1.getString(2) + "\n";
			}

			ResultSet rs2 = stmt.executeQuery(query2);

			while (rs2.next()) {
				// java.sql.SQLException: Column Index out of range, 4 > 3.
				// How to obtain this number of columns?
				result += "|" + rs2.getString(1) + "|\n" +"|" + rs2.getString(3) + "|";
			}
		}
		catch (SQLException e) {
			e.printStackTrace();
		}

		return result;
	}

	private static void fileAppend(String fileName, String data){
		try {
			FileWriter fstream = new FileWriter(fileName);
			BufferedWriter out = new BufferedWriter (fstream);
			out.write(data);
			out.close();
		}
		catch (Exception e){
			e.printStackTrace();
		}
	}

	private static String generateResultFilePath(String filePath){
		DateFormat dateFormat = new SimpleDateFormat(fileFormat);
		Date date = new Date();

		return filePath + dateFormat.format(date) + resultFileName;
	}

	public static void main(String[] args){
		// Read configuration
		readConfig(initConfig(args));

		Connection connection;
		String InnoDBStatus = "EMPTY due to ERROR";

		try{
			Class.forName("com.mysql.jdbc.Driver");

			// Create a connection to DB;
			connection = DriverManager.getConnection(dbConnection,dbUserName,dbUserPassword);
			InnoDBStatus = getInnoDBStatus(connection);
			connection.close();

			// Write the result into file
			fileAppend(generateResultFilePath(filePath), InnoDBStatus);
		}
		catch (ClassNotFoundException e) {
			e.printStackTrace();
		}
		catch (SQLException e) {
			e.printStackTrace();
		}
	}
}