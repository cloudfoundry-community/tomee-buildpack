# frozen_string_literal: true

# Cloud Foundry TomEE Buildpack
# Copyright 2013-2018 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_utils'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for TomEE resources configuration.
    class TomeeResourceConfiguration < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#initialize)
      def initialize(context)
        super(context)
        @logger = JavaBuildpack::Logging::LoggerFactory.instance.get_logger TomeeResourceConfiguration
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_jar(jar_name, tomcat_lib)
        return unless @configuration['enabled']
        mutate_resources_xml
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release; end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      private

      def jar_name
        "tomee_resource_configuration-#{@version}.jar"
      end

      CRED_PARAM_FLAG = 'includeInResources'.freeze

      def mutate_resources_xml
        with_timing "Modifying #{resources_xml} for Resource Configuration" do
          document = read_xml resources_xml
          @logger.debug { "  Original resources.xml: #{document}" }

          resources  = REXML::XPath.match(document, '/resources').first
          resources  = document.add_element 'resources' if resources.nil?

          relational_services_as_resources resources
          services_as_resources resources

          write_xml_transitive resources_xml, document
          @logger.debug { "  Modified resources.xml: #{document}" }
        end
      end

      def relational_services_as_resources(resources)
        @application.services.each do |service|
          if (service['tags'].include? 'relational') || well_known_jdbc_schema?(service['credentials'])
            add_relational_resource service, resources
          end
        end
      end

      def well_known_jdbc_schema?(creds)
        creds.key?('jdbcUrl') &&
          creds['jdbcUrl'].start_with?('jdbc:mysql', 'jdbc:postgresql', 'jdbc:oracle', 'jdbc:db2', 'jdbc:sqlserver')
      end

      def add_relational_resource(service, resources)
        resource = REXML::XPath.match(resources, "//*[@id = 'jdbc/#{service['name']}']").first
        if resource.nil?
          resource = resources.add_element 'Resource',
                                           'id' => "jdbc/#{service['name']}",
                                           'type' => 'DataSource'
        end
        resource.add_attribute 'properties-provider',
                               'org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'
      end

      def services_as_resources(resources)
        @application.services.each do |service|
          next unless (service.include? 'credentials') &&
            (service['credentials'].include? CRED_PARAM_FLAG) &&
            (service['credentials'][CRED_PARAM_FLAG] == 'true')
          add_resource service, resources
        end
      end

      def add_resource(service, resources)
        attribute_array = ['id', 'type', 'class-name', 'provider', 'factory-name',
                           'classpath', 'aliases',
                           'post-construct', 'pre-destroy', 'Lazy']

        creds_hash = Hash[service['credentials'].map { |key, value| [key, value] } ]

        # split the hash into two pieces:  one where they should be included as attributes
        # and one where they should be included as properties
        creds_as_attributes = creds_hash.select { |x| attribute_array.include? x }
        #creds_as_properties = creds_hash.reject { |x| attribute_array.include? x }

        # remove the flag param as a property
        #creds_as_properties = creds_as_properties.reject { |x| (x == CRED_PARAM_FLAG) }

        resource = resources.add_element 'Resource', creds_as_attributes
        resource.add_attribute 'properties-provider',
                               'org.cloudfoundry.reconfiguration.tomee.GenericServicePropertiesProvider'

        #creds_as_properties.each do |key, value|
        #  resource.add_text REXML::Text.new((key + ' = ' + value + "\n"), true)
        #end
      end

      def resources_xml
        ear? ? @droplet.root + 'META-INF/resources.xml' : @droplet.root + 'WEB-INF/resources.xml'
      end

      def read_xml(file)
        File.open(file, 'a+') { |f| REXML::Document.new f }
      end

      def ear?
        (@application.root + 'META-INF/application.xml').exist?
      end

    end

  end
end
