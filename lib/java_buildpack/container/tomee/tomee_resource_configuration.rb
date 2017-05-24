# Cloud Foundry TomEE Buildpack
# Copyright 2013-2017 the original author or authors.
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

      def mutate_resources_xml
        with_timing 'Modifying /WEB-INF/resources.xml for Resource Configuration' do
          document = read_xml resources_xml
          @logger.debug { "  Original resources.xml: #{document}" }

          resources  = REXML::XPath.match(document, '/resources').first
          resources  = document.add_element 'resources' if resources.nil?

          relational_services_as_resources resources

          write_xml resources_xml, document
          @logger.debug { "  Modified resources.xml: #{document}" }
        end
      end

      def relational_services_as_resources(resources)
        @application.services.each do |service|
          next unless service['tags'].include? 'relational'
          add_relational_resource service, resources
        end
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

      def resources_xml
        @droplet.root + 'WEB-INF/resources.xml'
      end

      def read_xml(file)
        File.open(file, 'a+') { |f| REXML::Document.new f }
      end

    end

  end
end
