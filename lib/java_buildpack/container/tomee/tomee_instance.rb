# frozen_string_literal: true

# Cloud Foundry TomEE Buildpack
# Copyright 2013-2019 the original author or authors.
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

require 'fileutils'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_instance'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for the TomEE instance.
    class TomeeInstance < TomcatInstance

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download(@version, @uri) { |file| expand file }
        link_to(@application.root.children, root)

        if ear?
          link_to((@application.root + 'drivers').children, lib_folder) if drivers?
        elsif tomcat_datasource_jar.exist?
          @droplet.additional_libraries << tomcat_datasource_jar
        end

        @droplet.additional_libraries.link_to lib_folder
      end

      protected

      # (see JavaBuildpack::Container::TomcatInstance#tomcat_7_compatible)
      def tomcat_7_compatible
        @version < TOMEE_7
      end

      private

      TOMEE_7 = JavaBuildpack::Util::TokenizedVersion.new('7.0.0').freeze

      private_constant :TOMEE_7

      def drivers?
        (@application.root + 'drivers/').exist?
      end

      def ear?
        (@application.root + 'META-INF/application.xml').exist?
      end

      def lib_folder
        ear? ? tomcat_lib : web_inf_lib
      end

    end

  end
end
