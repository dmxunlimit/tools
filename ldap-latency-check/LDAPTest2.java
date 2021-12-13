import javax.naming.Context;
import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Hashtable;

public class LDAPTest2 {

        private static String LDAP_URL = "ldaps://<hostname>:389";

        private static String LDAP_USER = "cn=admin,dc=example,dc=com";

        private static String LDAP_PASSWORD = "";

        private static String LDAP_SEARCH_BASE = "ou=People,dc=example,dc=com";

        private static String KEYSTORE = "";

        private static int noOfIterations = 10;

        public static void main(String[] args){


        if(args != null  && args.length == 2) {
            LDAP_PASSWORD = args[0];
            KEYSTORE = args[1];
        }

        System.out.println("Trust store location :  " + KEYSTORE);

        System.setProperty("javax.net.ssl.trustStore", KEYSTORE);
        System.setProperty("javax.net.ssl.trustStorePassword", "wso2carbon");

        System.out.println("============  Test is started  ================");

        Hashtable<String, String > environment = new Hashtable<String, String >();

        environment.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
        environment.put(Context.SECURITY_AUTHENTICATION, "simple");
        environment.put(Context.REFERRAL, "follow");
        environment.put(Context.PROVIDER_URL, LDAP_URL);
        environment.put(Context.SECURITY_PRINCIPAL, LDAP_USER);
        environment.put(Context.SECURITY_CREDENTIALS, LDAP_PASSWORD);

        DirContext ctx = null;
        NamingEnumeration<SearchResult> results = null;
        long t1, t2;
            try {

                while (true) {

                    for (int count = 1; count % noOfIterations != 0; count++) {

                        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd,yyyy HH:mm:ss.SSSZ");

                        t1 = System.currentTimeMillis();
                        ctx = new InitialDirContext( environment );

                        t2 = System.currentTimeMillis();
                        System.out.println("Dir context is finished within : " + (t2 - t1) + " millis");

                        t1 = System.currentTimeMillis();
                        String searchFilter = "(&(objectClass=person)(cn=admin*))";
                        SearchControls searchControls = new SearchControls();
                        searchControls.setSearchScope( SearchControls.SUBTREE_SCOPE );

                        results = ctx.search(LDAP_SEARCH_BASE, searchFilter, searchControls);
                        System.out.println("First LDAP Search done at : " + sdf.format( new Date( System.currentTimeMillis())));

                        if (results.hasMore()) {
                            SearchResult searchResult = null;
                            try {
                                searchResult = results.next();
                                System.out.println("Name: " + searchResult.getNameInNamespace());
                            } catch (Exception e) {
                                System.out.println("ERROR is occurred with Next");
                                e.printStackTrace();
                            }
                        }
                        t2 = System.currentTimeMillis();
                        System.out.println("LDAP Search finished with 1st result : " + (t2 - t1) + " millis \n");
                        try {
                            Thread.sleep( 1000 );
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }

                    if (ctx != null) {
                        try {
                            System.out.println("============  Closing LDAP connection  ================");
                            t1 = System.currentTimeMillis();
                            ctx.close();
                            t2 = System.currentTimeMillis();
                            System.out.println("Connection closed within: " + (t2 - t1) + " millis \n");
                        } catch (NamingException e) {
                            e.printStackTrace();
                        }
                    }
                }

        } catch (NamingException e) {
            System.out.println("ERROR is occurred with HasMore");
            e.printStackTrace();
        }finally {
            if(results != null) {
                try {
                    results.close();
                } catch (NamingException e) {
                    e.printStackTrace();
                }
            }
            if(ctx != null) {
                try {
                    ctx.close();
                } catch (NamingException e) {
                    e.printStackTrace();
                }
            }
        }

        System.out.println("============  Test is finished  ================");
        System.exit(0);
    }


}
