package org.wso2.dbresponemeasure;

import java.io.File;
import java.io.PrintStream;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;
import java.net.URLClassLoader;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.SQLException;


public class DBConnection {
    private static Connection connection = null;


    public static Connection getConnection(String url, String username, String password) {
        try {
            connection = DriverManager.getConnection(url, username, password);
        } catch (SQLException e) {
            System.out.println("Unable to connect to database.");
            e.printStackTrace();
            return null;
        }
        return connection;
    }


    public static void loadDBDriver(String driverLoacation, String jdbcConnectionClass) {
        File file = new File(driverLoacation);
        URL url = null;
        try {
            url = file.toURI().toURL();
        } catch (MalformedURLException e) {
            System.out.printf("Unablto open url.", new Object[0]);
            e.printStackTrace();
        }
        URLClassLoader ucl = new URLClassLoader(new URL[]{url});
        Driver driver = null;
        try {
            driver = (Driver) Class.forName(jdbcConnectionClass, true, ucl).newInstance();
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
        try {
            DriverManager.registerDriver(new DriverShim(driver));
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
