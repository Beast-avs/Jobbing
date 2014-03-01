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

public class CsGet {
	private static final Logger LOGGER = Logger.getLogger(CsGet.class);

	private static String configurationFileName = "./etc/config.properties";

	private static final String TestName = "CsGet";
	
	private static String AccountName = null;
	private static String AccountMSISDN = null;
	private static Long AccountID = null;
	private static String AccountNumber = null;
	private static String AccountICCID = null;
	private static String AccountIMSI = null;

	public CsGet(){ }

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
		options.addOption("b", "account-name", true, "set account name for test.");
		options.addOption("z", "account-msisdn", true, "set account MSISDN for test.");
		options.addOption("a", "account-id", true, "set account ID for test.");
		options.addOption("d", "account-number", true, "set account number for test.");
		options.addOption("e", "account-iccid", true, "set account name for test.");
		options.addOption("f", "account-imsi", true, "set account name for test.");

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
			 */
			if(line.hasOption("b")){
				AccountName = line.getOptionValue("b");
			}
			if(line.hasOption("z")){
				AccountMSISDN = line.getOptionValue("z");
			}
			if(line.hasOption("a")){
				AccountID = Long.parseLong(line.getOptionValue("a"));
			}
			if(line.hasOption("d")){
				AccountNumber = line.getOptionValue("d");
			}
			if(line.hasOption("e")){
				AccountICCID = line.getOptionValue("e");
			}
			if(line.hasOption("f")){
				AccountIMSI = line.getOptionValue("f");
			}
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
		System.out.println("AccountName: " + AccountName);
		System.out.println("AccountMSISDN: " + AccountMSISDN);
		System.out.println("AccountID: " + AccountID);
		System.out.println("AccountNumber: " + AccountNumber);
		System.out.println("AccountICCID: " + AccountICCID);
		System.out.println("AccountIMSI: " + AccountIMSI);
		System.out.println("=====================================");
		/*
		 *
		 * Here write own logic with the parameters which recived via CLI
		 * 
		 */

		ArrayList<CsAPI> calls = new ArrayList<CsAPI>();

		if (null != AccountMSISDN) {
			calls.add(CsAPI.accountByMSISDN(AccountMSISDN));
		}
		if (null != AccountID) {
			calls.add(CsAPI.accountByAccountId(AccountID));
		}
		if (null != AccountName) {
			calls.add(CsAPI.accountByAccountName(AccountName));
		}
		if (null != AccountNumber) {
			calls.add(CsAPI.accountByAccountNumber(AccountNumber, null));
		}
		if (null != AccountICCID) {
			calls.add(CsAPI.accountByICCID(AccountICCID));
		}
		if (null != AccountIMSI) {
			calls.add(CsAPI.accountByIMSI(AccountIMSI));
		}

		try {
			for (int i = 0; i < calls.size(); i++){
				System.out.println("\n===== " + i + ": ");
				calls.get(i).beginTransaction();
				calls.get(i).get("B");
				System.out.println("     Balances: " + calls.get(i).accountBalances);
				calls.get(i).get("F");
				System.out.println("     Personal Options: " + calls.get(i).personalOptions);
				calls.get(i).get("X");
				System.out.println("     Attributes: " + calls.get(i).accountAttributes.toString());
				System.out.println("     AccountID: " + calls.get(i).systemAttributes.getAccountId() +
						";\n     CustomerID: " + calls.get(i).systemAttributes.getCustomerId() +
						";\n     TopLevelAccountId: " + calls.get(i).systemAttributes.getTopLevelAccountId()
						);
				calls.get(i).accountBalances.getSpendingLimit();
				calls.get(i).accountBalances.getUsedSpendingLimit();
				calls.get(i).get("P");
				System.out.println("     SoldProducts: " + calls.get(i).soldProducts);
				calls.get(i).get("L");
				System.out.println("     LifeCycle: " + calls.get(i).lifeCycleEntries);
				calls.get(i).get("S");
				System.out.println("     SimCard: " + calls.get(i).simCard);
				calls.get(i).commitTransaction();
			}
		}catch (Throwable e) {
			for (int i = 0; i < calls.size(); i++){
				calls.get(i).rollbackTransaction();
				e.printStackTrace();
				LOGGER.error(e.getMessage());
			}
		}
	}

	public static void main(String[] args) {
		CsGet client = new CsGet();

		try {
			client.initConfiguration(args);
			client.readConfigurationFile(configurationFileName);
			client.execute();
		} catch(Exception e){
			e.printStackTrace();
			LOGGER.error(e.getMessage());
		}
	}
}
