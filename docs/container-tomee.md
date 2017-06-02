# TomEE Container
The TomEE Container provides Java EE 7 Web Profile.  Applications are run as the root web application in a TomEE container.

<table>
  <tr>
    <td><strong>Detection Criterion</strong></td>
    <td>Existence of a <tt>WEB-INF/</tt> folder in the application directory and <a href="container-java_main.md">Java Main</a> not detected. 
    If a <tt>META-INF/application.xml</tt> file is present then the application is considered an ear file. Note that TomEE supports only the JEE 7 [Web Profile](http://tomee.apache.org/comparison.html).
    </td>
  </tr>
  <tr>
    <td><strong>Tags</strong></td>
    <td><tt>tomee-instance=&lang;version&rang;</tt>, <tt>tomcat-lifecycle-support=&lang;version&rang;</tt>, <tt>tomcat-logging-support=&lang;version&rang;</tt>, <tt>tomcat-redis-store=&lang;version&rang;</tt> <i>(optional)</i>, <tt>tomcat-external_configuration=&lang;version&rang;</tt> <i>(optional)</i>, <tt>tomee-resource-configuration=&lang;version&rang;</tt> <i>(optional)</i></td>
  </tr>
</table>
Tags are printed to standard output by the buildpack detect script

If the application uses Spring, [Spring profiles][] can be specified by setting the [`SPRING_PROFILES_ACTIVE`][] environment variable. This is automatically detected and used by Spring. The Spring Auto-reconfiguration Framework will specify the `cloud` profile in addition to any others.

## Configuration
For general information on configuring the buildpack, including how to specify configuration values through environment variables, refer to [Configuration and Extension][].

The container can be configured by modifying the [`config/tomee.yml`][] file in the buildpack fork.  The container uses the [`Repository` utility support][repositories] and so it supports the [version syntax][] defined there.

| Name | Description
| ---- | -----------
| `access_logging_support.repository_root` | The URL of the Tomcat Access Logging Support repository index ([details][repositories]).
| `access_logging_support.version` | The version of Tomcat Access Logging Support to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomcat-access-logging-support/index.yml).
| `access_logging_support.access_logging` | Set to `enabled` to turn on the access logging support. Default is `disabled`.
| `lifecycle_support.repository_root` | The URL of the Tomcat Lifecycle Support repository index ([details][repositories]).
| `lifecycle_support.version` | The version of Tomcat Lifecycle Support to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomcat-lifecycle-support/index.yml).
| `logging_support.repository_root` | The URL of the Tomcat Logging Support repository index ([details][repositories]).
| `logging_support.version` | The version of Tomcat Logging Support to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomcat-logging-support/index.yml).
| `redis_store.connection_pool_size` | The Redis connection pool size.  Note that this is per-instance, not per-application.
| `redis_store.database` | The Redis database to connect to.
| `redis_store.repository_root` | The URL of the Redis Store repository index ([details][repositories]).
| `redis_store.timeout` | The Redis connection timeout (in milliseconds).
| `redis_store.version` | The version of Redis Store to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/redis-store/index.yml).
| `resource-configuration.repository_root` | The URL of the TomEE Resources Auto Configuration repository index ([details][repositories]).
| `resource-configuration.version` | The version of TomEE Resources Auto Configuration to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomee-resource-configuration/index.yml).
| `resource-configuration.enabled` | Set to `false` to turn off the resources auto configuration. Default is `true`.
| `tomee.context_path` | The context path to expose the application at.
| `tomee.repository_root` | The URL of the TomEE repository index ([details][repositories]).
| `tomee.version` | The version of TomEE to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomee/index.yml).
| `tomee.external_configuration_enabled` | Set to `true` to be able to supply an external TomEE configuration. Default is `false`.
| `external_configuration.version` | The version of the External TomEE Configuration to use. Candidate versions can be found in the the repository that you have created to house the External TomEE Configuration. Note: It is required the external configuration to allow symlinks.
| `external_configuration.repository_root` | The URL of the External TomEE Configuration repository index ([details][repositories]).

### Common configurations
The version of TomEE can be configured by setting an environment variable.

```
$ cf set-env my-application JBP_CONFIG_TOMEE '{tomee: { version: 1.7.+ }}'
```

The context path that an application is deployed at can be configured by setting an environment variable.

```
$ cf set-env my-application JBP_CONFIG_TOMEE '{tomee: { context_path: /first-segment/second-segment }}'
```


### Additional Resources
The container can also be configured by overlaying a set of resources on the default distribution.  To do this follow one of the options below.

#### Buildpack Fork
Add files to the `resources/tomee` directory in the buildpack fork.  For example, to override the default `logging.properties` add your custom file to `resources/tomee/conf/logging.properties`.

#### External TomEE Configuration
Supply a repository with an external TomEE configuration.

Example in a manifest.yml
```
env:
  JBP_CONFIG_TOMEE: "{ tomee: { external_configuration_enabled: true }, external_configuration: { repository_root: \"http://repository...\" } }"
```

The artifacts that the repository provides must be in TAR format and must follow the TomEE archive structure:

```
tomee
|__conf
   |__context.xml
   |__server.xml
   |__web.xml
   |...
```

Notes:
* It is required the external configuration to allow symlinks. For more information check [Tomcat 7 configuration].

## Session Replication
By default, the TomEE instance is configured to store all Sessions and their data in memory.  Under certain circumstances it my be appropriate to persist the Sessions and their data to a repository.  When this is the case (small amounts of data that should survive the failure of any individual instance), the buildpack can automatically configure TomEE to do so by binding an appropriate service.

### Redis
To enable Redis-based session replication, simply bind a Redis service containing a name, label, or tag that has `session-replication` as a substring.

## Managing Entropy
Entropy from `/dev/random` is used heavily to create session ids, and on startup for initializing `SecureRandom`, which can then cause instances to fail to start in time (see the [Tomcat wiki]). Also, the entropy is shared so it's possible for a single app to starve the DEA of entropy and cause apps in other containers that make use of entropy to be blocked.
If this is an issue then configuring `/dev/urandom` as an alternative source of entropy may help. It is unlikely, but possible, that this may cause some security issues which should be taken in to account.

Example in a manifest.yml
```
env:
  JAVA_OPTS: -Djava.security.egd=file:///dev/urandom
```

## Supporting Functionality
Additional supporting functionality can be found in the [`java-buildpack-support`][] Git repository.

## TomEE Resources Auto Configuration
TomEE Resources Auto Configuration functionality causes an application to be automatically reconfigured to work with configured cloud services.
If a `/WEB-INF/resources.xml` file does not exist, it will be created. If it exists it will be modified.
Preconfigured `Resource` definition will be added to this file for every relational data service.

```
<Resource id='jdbc/...' type='DataSource' properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider' />
```

This configuration consists of:
* id - `jdbc/` prefix combined with the cloud service name
* type - `DataSource`
* properties provider - `org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider` that will supply the configuration properties for the corresponding cloud service.

This functionality can be found in the [`tomee-buildpack-resource-configuration`][] Git repository.

## Support for Deploying an ear(Enterprise Application aRchive) file
TomEE buildpack supports the deployment of an [ear file](https://en.wikipedia.org/wiki/EAR_(file_format)) conforming to the Java EE 7 Web Profile. The expectation is that an ear file package a `META-INF/application.xml`, the deployment descriptor specifying all the modules packaged in the ear.
Any external resources that the application requires can be specified in a [`META-INF/resources.xml`](http://tomee.apache.org/application-resources.html) file and is modified as described in [Resources Auto Configuration](#tomee-resources-auto-configuration) section.
If the application requires any additional drivers for resources specified in the `META-INF/resources.xml` file then it can be packaged into a `drivers` folder and any file present here will be available for use by TomEE classloaders. 
A sample structure of the ear with `META-INF/application.xml`, `drivers` and `META-INF/resources.xml` is the following:

```
sample.ear
|____drivers
| |____h2-1.4.193.jar
|____eartest-ejb-impl-1.0.jar
|____eartest-war1-1.0.war
|____eartest-war2-1.0.war
|____lib
| |____eartest-ejb-api-1.0.jar
|____META-INF
| |____application.xml
| |____resources.xml
|____war-with-resource-1.0.war

```


[Configuration and Extension]: ../README.md#configuration-and-extension
[`config/tomee.yml`]: ../config/tomee.yml
[`java-buildpack-support`]: https://github.com/cloudfoundry/java-buildpack-support
[repositories]: extending-repositories.md
[Spring profiles]:http://blog.springsource.com/2011/02/14/spring-3-1-m1-introducing-profile/
[`SPRING_PROFILES_ACTIVE`]: http://docs.spring.io/spring/docs/4.0.0.RELEASE/javadoc-api/org/springframework/core/env/AbstractEnvironment.html#ACTIVE_PROFILES_PROPERTY_NAME
[Tomcat wiki]: http://wiki.apache.org/tomcat/HowTo/FasterStartUp
[version syntax]: extending-repositories.md#version-syntax-and-ordering
[Tomcat 7 configuration]: http://tomcat.apache.org/tomcat-7.0-doc/config/context.html#Standard_Implementation
[`tomee-buildpack-resource-configuration`]: https://github.com/cloudfoundry-community/tomee-buildpack-resource-configuration
