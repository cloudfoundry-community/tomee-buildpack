# Encoding: utf-8
# Cloud Foundry TomEE Buildpack
# Copyright 2013-2016 the original author or authors.
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

      protected

      TOMEE_7 = JavaBuildpack::Util::TokenizedVersion.new('7.0.0').freeze

      private_constant :TOMEE_7

      # Checks whether TomEE instance is Tomcat 7 compatible
      def tomcat_7_compatible
        @version < TOMEE_7
      end

    end

  end
end
