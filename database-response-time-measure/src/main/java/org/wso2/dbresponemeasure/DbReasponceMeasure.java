package org.wso2.dbresponemeasure;

import java.io.PrintStream;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;


public class DbReasponceMeasure
        extends SecurityManager {
    static long totalTime = 0L;
    static long totalExecutionTime = 0L;
    static long totalConnectionTime = 0L;
    static long totalConnectionCloseTime = 0L;
    static long iternations = 0L;
    static int connctionIteration = 0;
    static boolean runForever = false;
    static long index = 0L;

    public static void main(String[] args) {
        ReadConfigFile configs = new ReadConfigFile();
        String url = configs.getProperty("CONNECTION.URL");
        String username = configs.getProperty("CONNECTION.USERNAME");
        String password = configs.getProperty("CONNECTION.PASSWORD");
        String driverClass = configs.getProperty("CONNECTION.DRIVERCLASS");
        String driverLocation = configs.getProperty("CONNECTION.JDBCDRIVER");
        String querytorun = configs.getProperty("SQL.QUERYTOEXECUTE");
        int threadSllepTime = 500;
        iternations = 100L;
        connctionIteration = 10;


        if (configs.getProperty("RUN.THREADSLEEPTIME") != null) {
            threadSllepTime = Integer.parseInt(configs.getProperty("RUN.THREADSLEEPTIME"));
        }
        DBConnection.loadDBDriver(driverLocation, driverClass);
        Statement statement = null;

        long startTime = 0L;
        long completedTime = 0L;

        Connection connection = null;

        if (configs.getProperty("CONNECTION.ITERATIONS.PER.SQL") != null) {
            connctionIteration = Integer.parseInt(configs.getProperty("CONNECTION.ITERATIONS.PER.SQL"));
        }

        if (querytorun == null) {
            querytorun = "SELECT 1";
        }
        if (configs.getProperty("SQL.ITERATIONS") != null) {
            iternations = Integer.parseInt(configs.getProperty("SQL.ITERATIONS"));

            if (iternations <= 0L) {
                runForever = true;
            }
        }

        startTime = System.currentTimeMillis();
        connection = DBConnection.getConnection(url, username, password);
        completedTime = System.currentTimeMillis();

        totalConnectionTime += completedTime - startTime;

        if (connection != null) {
            System.out.println("-----------------------------------------------------------------------------------------------------------------");
            System.out.println("                              Connected to database and query execution started                                  ");
            System.out.println("-----------------------------------------------------------------------------------------------------------------\n");
            System.out.println("Time taken GetConnection = " + (completedTime - startTime) + " ms.");
        }


        for (; ; ) {
            try {
                if ((index >= connctionIteration) && (0L == index % connctionIteration)) {
                    if (!connection.isClosed()) {
                        try {
                            startTime = System.currentTimeMillis();
                            connection.close();
                            completedTime = System.currentTimeMillis();
                            totalConnectionCloseTime += completedTime - startTime;
                            System.out.println("Time taken CloseConnection = " + (completedTime - startTime) + " ms.");
                        } catch (SQLException ex) {
                            ex.printStackTrace();
                        }
                        try {
                            startTime = System.currentTimeMillis();
                            connection = DBConnection.getConnection(url, username, password);
                            completedTime = System.currentTimeMillis();
                            totalConnectionTime += completedTime - startTime;

                            System.out.println("\nTime taken GetConnection = " + (completedTime - startTime) + " ms.");
                        } catch (Exception ex) {
                            ex.printStackTrace();
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }

            try {
                startTime = System.currentTimeMillis();
                statement = connection.createStatement();
                ResultSet tempResultset = statement.executeQuery(querytorun);

                if (tempResultset.next()) {
                    System.out.println("Query Executed : " + querytorun);
                    completedTime = System.currentTimeMillis();
                    totalExecutionTime += completedTime - startTime;
                    System.out.println("Time taken ExecuteQuery = " + (completedTime - startTime) + " ms.");

                    while (tempResultset.next()) {
                    }
                }
                statement.close();
                completedTime = System.currentTimeMillis();
                totalTime += completedTime - startTime;
                System.out.println("Time taken QueryWithResultset = " + (completedTime - startTime) + " ms.");
            } catch (SQLException e) {
                System.out.println("Unable to execute query.");
                e.printStackTrace();
                try {
                    connection.close();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            try {
                Thread.sleep(threadSllepTime);
            } catch (InterruptedException e) {
                e.printStackTrace();
                try {
                    connection.close();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }

            index += 1L;
            if ((!runForever) && (index == iternations)) {
                break;
            }
        }

        System.out.println("\n\n-----------------------------------------------------------------------------------------------------------------");
        System.out.println("                       AverageGetConnectionTime = " + totalConnectionTime * 1.0D / (iternations / connctionIteration) + " ms.");
        System.out.println("-----------------------------------------------------------------------------------------------------------------");

        System.out.println("\n-----------------------------------------------------------------------------------------------------------------");
        System.out.println("                       AverageQueryTimeExecution = " + totalExecutionTime * 1.0D / iternations + " ms.");
        System.out.println("-----------------------------------------------------------------------------------------------------------------");

        System.out.println("\n-----------------------------------------------------------------------------------------------------------------");
        System.out.println("                       AverageQueryTimeWithResultSet = " + totalTime * 1.0D / iternations + " ms.");
        System.out.println("-----------------------------------------------------------------------------------------------------------------");

        System.out.println("\n-----------------------------------------------------------------------------------------------------------------");
        System.out.println("                       AverageCloseConnectionTime = " + totalConnectionCloseTime * 1.0D / (iternations / connctionIteration) + " ms.");
        System.out.println("-----------------------------------------------------------------------------------------------------------------");
        try {
            connection.close();
        } catch (SQLException e) {
            e.printStackTrace();
        } catch (NullPointerException e) {
            e.printStackTrace();
        }
    }

}
