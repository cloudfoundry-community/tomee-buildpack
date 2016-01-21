# EJB Example
The TomEE Buildpack can run Java EE Web Profile-based applications provided that they are packaged as a WAR file.

## Gradle
The following example shows how deploy the sample application located in the [Java Test Applications][j].
The example uses PostgreSQL as database. Any other database can be configured when creating a service using `DB_SERVICE` and `PLAN`.

```bash
$ gradle build
$ cf create-service DB_SERVICE PLAN db-service
$ cf push -f manifest.yml -b https://github.com/cloudfoundry-community/tomee-buildpack.git

-----> Downloading Open Jdk JRE 1.8.0_65 from https://.../openjdk/lucid/x86_64/openjdk-1.8.0_65.tar.gz (0.0s)
       Expanding Open Jdk JRE to .java-buildpack/open_jdk_jre (0.0s)
-----> Downloading Postgresql JDBC 9.4.1206 from https://.../postgresql-jdbc/postgresql-jdbc-9.4.1206.jar (0.0s)
-----> Downloading Tomee Instance 1.7.2 from https://.../tomee/tomee-1.7.2.tar.gz (0.0s)
       Expanding Tomee Instance to .java-buildpack/tomee (0.0s)
-----> Downloading Tomee Resource Configuration 1.0.0_RELEASE from https://.../tomee-resource-configuration/tomee-resource-configuration-1.0.0_RELEASE.jar (0.0s)
       Modifying /WEB-INF/resources.xml for Resource Configuration (0.0s)
-----> Downloading Tomcat Lifecycle Support 2.4.0_RELEASE from https://.../tomcat-lifecycle-support/tomcat-lifecycle-support-2.4.0_RELEASE.jar (0.0s)
-----> Downloading Tomcat Logging Support 2.4.0_RELEASE from https://.../tomcat-logging-support/tomcat-logging-support-2.4.0_RELEASE.jar (0.0s)
-----> Downloading Tomcat Access Logging Support 2.4.0_RELEASE from https://.../tomcat-access-logging-support/tomcat-access-logging-support-2.4.0_RELEASE.jar (0.0s)
-----> Uploading droplet (85M)

$ curl ...cfapps.io
ok
```

[j]: https://github.com/cloudfoundry/java-test-applications/tree/master/ejb-application
