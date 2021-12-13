package org.wso2.dbresponemeasure;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.Properties;


public class ReadConfigFile {
    private Properties properties = new Properties();

    public ReadConfigFile() {
        try {
            InputStream input = new FileInputStream("config.properties");
            Throwable localThrowable3 = null;
            try {
                this.properties.load(input);
            } catch (Throwable localThrowable1) {
                localThrowable3 = localThrowable1;
                throw localThrowable1;
            } finally {
                if (input != null) if (localThrowable3 != null) try {
                    input.close();
                } catch (Throwable localThrowable2) {
                    localThrowable3.addSuppressed(localThrowable2);
                }
                else input.close();
            }
        } catch (IOException e) {
            System.out.println("Can't find/read 'config.properties' file.");
            e.printStackTrace();
        }
    }


    public String getProperty(String key) {
        return this.properties.getProperty(key);
    }
}
