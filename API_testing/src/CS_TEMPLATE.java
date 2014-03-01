// Standard Java libs
import java.io.*;
import java.util.Calendar;
import java.util.Date;
import java.util.Properties;
import java.util.Map;
import java.util.Vector;
import java.util.Hashtable;
import java.util.Enumeration;
import java.util.Collection;

// Application libs for testing (call) its API
// Removed due to copyright agreement

// Third-party libs
import org.apache.log4j.ConsoleAppender;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;
import org.apache.commons.cli.*;

/**
 * @author beast
 * @created 25-Jun-2013
 */

public class CS_TEMPLATE {
	private static final Logger LOGGER = Logger.getLogger(CS_TEMPLATE.class);

	private static String configurationFileName = "./etc/config.properties";

	private static final String TestName = "CS_TEMPLATE";
	
	/*
	 * Here will be variables which will contain the CLI parameters
	 */

	public CS_TEMPLATE(){ }

	private static void initConfiguration(String[] args) throws Exception {
		CommandLineParser parser = new PosixParser();
		Options options = new Options();
		
		options.addOption("h", "help", false, "print usage.");
		/*
		 * Here is should be definitions of the transmitted parameters via CLI
		 *
		 * Signature:
		 * 	options.addOption(String opt, String longOpt, boolean hasArg, String description);
		 *		
		 *	Parameters:
		 *		opt - Short single-character name of the option.
		 * 		longOpt - Long multi-character name of the option.
		 * 		hasArg - flag signally if an argument is required after this option
		 * 		description - Self-documenting description
		 *
		 * Example:
		 * 	options.addOption("h", "help", false, "print usage.");
		 * 	options.addOption("a", "parameter-a", true, "set value for parameter A.");
		 */

		try {
			CommandLine line = parser.parse(options, args);
			
			if(line.hasOption("h")){
				HelpFormatter help = new HelpFormatter();
				help.printHelp(TestName, options);
				System.exit(1);
			}
			/*
			 * Assign the values of input parameters to valiables.
			 *
			 * Example:
             *      if(line.hasOption("a")){
			 *              Var_1 = line.getOptionValue("a");
			 *      }
			 */
		}
		catch(ParseException e){
			e.printStackTrace();
		}
	}
	
	private static void readConfigurationFile(String configurationFileName) throws Exception {
		Properties configurationFile = new Properties();
		InputStream is;

		try{
			is = new FileInputStream(configurationFileName);
			configurationFile.load(is);

			Properties p = new Properties();
			p.put(CS_CFG_HOSTNAME, configurationFile.getProperty("CS_CFG_HOSTNAME"));
			p.put(CS_CFG_PORT, configurationFile.getProperty("CS_CFG_PORT"));
			p.put(CS_CFG_CS_USER, configurationFile.getProperty("CS_CFG_CS_USER"));
			p.put(CS_CFG_CS_PASSWORD, configurationFile.getProperty("CS_CFG_CS_PASSWORD"));
			p.put(CS_CFG_DOMAIN, configurationFile.getProperty("CS_CFG_DOMAIN"));
			p.put(CS_CFG_TRUSTSTORE_PASSWORD, configurationFile.getProperty("CS_CFG_TRUSTSTORE_PASSWORD"));
			p.put(CS_CFG_TRUSTSTORE_FILE, configurationFile.getProperty("CS_CFG_TRUSTSTORE_FILE"));
			p.put(CONFIG_FILE_PARAM_RELOAD_SUBSCRIPTION_ACTIVATION, configurationFile.getProperty("CONFIG_FILE_PARAM_RELOAD_SUBSCRIPTION_ACTIVATION"));

			System.out.println("\n=========== CS-API " + TestName + " Connection Properties ===========\n");
			System.out.println(p);
			System.out.println("User Dir: " + System.getProperty("user.dir"));
			System.out.println("\n======================================================================\n");

			CsAPI.setupEnvironment(p, new File(System.getProperty("user.dir")));

		}
		catch(IOException e){
			e.printStackTrace();
		}
	}

	private void execute() throws Exception{
		System.out.println("\n======== CLI Parameters: ==========");
		/*
		 *
		 * Here write own logic with the parameters which recived via CLI
		 * 
		 */
		System.out.println("=====================================");

		/*
		 * Put the business logic here.
		 */

	}

	public static void main(String[] args) {
		CS_TEMPLATE client = new CS_TEMPLATE();

		try {
			client.initConfiguration(args);
			client.readConfigurationFile(configurationFileName);
			client.execute();
		}
		catch(Exception e){
			e.printStackTrace();
			LOGGER.error(e.getMessage());
		}

	}

}
