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

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/container/tomee/tomee_resource_configuration'

describe JavaBuildpack::Container::TomeeResourceConfiguration do
  include_context 'component_helper'

  let(:component_id) { 'tomee' }

  let(:configuration) { { 'enabled' => true } }

  it 'always detects' do
    expect(component.detect).to eq("tomee-resource-configuration=#{version}")
  end

  it 'copies resources',
     cache_fixture: 'stub-resource-configuration.jar',
     app_fixture: 'container_tomcat' do

    component.compile

    expect(sandbox + "lib/tomee_resource_configuration-#{version}.jar").to exist
  end

  it 'does not create Resource entries if there are no services',
     cache_fixture: 'stub-resource-configuration.jar',
     app_fixture: 'container_tomcat' do

    component.compile

    web_inf = app_dir + 'WEB-INF'
    resources_xml = web_inf + 'resources.xml'
    expect(resources_xml).to exist
    expect(resources_xml).not_to match(/<Resource/)
  end

  context do
    let(:configuration) { { 'enabled' => false } }

    it 'does not create resources.xml if component is disabled',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_tomcat' do

      component.compile

      web_inf = app_dir + 'WEB-INF'
      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).not_to exist
    end
  end

  context do

    before do
      allow(services).to receive(:each).and_yield('name' => 'test',
                                                  'tags' => ['relational'])
    end

    it 'creates resources.xml if not present',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_tomcat' do

      web_inf = app_dir + 'WEB-INF'
      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).not_to exist

      component.compile

      expect(resources_xml).to exist
    end

    it 'adds Resource element to empty resources.xml with root element only',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_tomee_empty_resources_xml' do

      web_inf = app_dir + 'WEB-INF'
      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test' type='DataSource' \
properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

    it 'adds Resource element to non-empty resources.xml',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_tomee_nonempty_resources_xml' do

      web_inf = app_dir + 'WEB-INF'
      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='My Test Resource' type='my.test.Resource' \
provider='my.test#Provider'/>})
      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test' type='DataSource' \
properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

    it 'updates Resource element in resources.xml when such element already exists',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_tomee_nonempty_resources_xml_existing_resource' do

      web_inf = app_dir + 'WEB-INF'
      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='My Test Resource' type='my.test.Resource' \
provider='my.test#Provider'/>})
      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test' type='javax.sql.DataSource' \
properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end
  end

  context do

    before do
      allow(services).to receive(:each).and_yield('name' => 'test',
                                                  'tags' => ['relational'])
    end

    it 'creates resources.xml in ear packages if not present',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_ear_structure' do

      meta_inf = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).not_to exist

      component.compile

      expect(resources_xml).to exist
    end

    it 'adds Resource element to empty resources.xml with root element only in ear packages',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_ear_structure_empty_resource' do

      meta_inf = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test' type='DataSource' \
properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

    it 'adds Resource element to non-empty resources.xml',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture: 'container_ear_structure_with_resource' do

      meta_inf = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='My Test Resource' type='my.test.Resource' \
provider='my.test#Provider'/>})
      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test' type='DataSource' \
properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end
  end

  context do
    let(:vcap_services) do
      {
        'test-service-relational-tag' => [{ 'name'        => 'test-service-relational-tag', 'label' => 'label-1',
                                            'tags'        => %w[tag1 relational], 'plan' => 'test-plan',
                                            'credentials' => { 'uri' => 'test-uri' } }]
      }
    end

    it 'adds resource element for services tagged with relational',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture:   'container_ear_structure_empty_resource' do
      meta_inf      = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test-service-relational-tag' type='DataSource' \
properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end
  end

  context do
    let(:vcap_services) do
      {
        'test-service-mysql-schema' => [{ 'name'        => 'test-service-mysql-schema',
                                          'tags'        => [],
                                          'credentials' => {
                                            'jdbcUrl': 'jdbc:mysql://auser:apass@hostname.com:3306/mydb'
                                          } }]
      }
    end

    it 'adds resource element for services with jdbcUrl starting with jdbc:mysql',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture:   'container_ear_structure_empty_resource' do
      meta_inf      = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test-service-mysql-schema' type='DataSource' \
properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

  end

  context do
    let(:vcap_services) do
      {
        'test-service-postgresql-schema' => [{ 'name'        => 'test-service-postgresql-schema',
                                               'tags'        => [],
                                               'credentials' => {
                                                 'jdbcUrl': 'jdbc:postgresql://auser:apass@hostname.com:1521/mydb'
                                               } }]
      }
    end

    it 'adds resource element for services with jdbcUrl starting with jdbc:postgresql',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture:   'container_ear_structure_empty_resource' do
      meta_inf      = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test-service-postgresql-schema' \
type='DataSource' properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

  end

  context do
    let(:vcap_services) do
      {
        'test-service-oracle-schema' => [{ 'name'        => 'test-service-oracle-schema',
                                           'tags'        => [],
                                           'credentials' => {
                                             'jdbcUrl': 'jdbc:oracle://auser:apass@hostname.com:432/mydb'
                                           } }]
      }
    end

    it 'adds resource element for services with jdbcUrl starting with jdbc:oracle',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture:   'container_ear_structure_empty_resource' do
      meta_inf      = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test-service-oracle-schema' \
type='DataSource' properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

  end

  context do
    let(:vcap_services) do
      {
        'test-service-db2-schema' => [{ 'name'        => 'test-service-db2-schema',
                                        'tags'        => [],
                                        'credentials' => {
                                          'jdbcUrl': 'jdbc:db2://auser:apass@hostname.com:543/mydb'
                                        } }]
      }
    end

    it 'adds resource element for services with jdbcUrl starting with jdbc:db2',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture:   'container_ear_structure_empty_resource' do
      meta_inf      = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test-service-db2-schema' \
type='DataSource' properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

  end

  context do
    let(:vcap_services) do
      {
        'test-service-sqlserver-schema' => [{ 'name'        => 'test-service-sqlserver-schema',
                                              'tags'        => [],
                                              'credentials' => {
                                                'jdbcUrl': 'jdbc:sqlserver://auser:apass@hostname.com:4407/mydb'
                                              } }]
      }
    end

    it 'adds resource element for services with jdbcUrl starting with jdbc:sqlserver',
       cache_fixture: 'stub-resource-configuration.jar',
       app_fixture:   'container_ear_structure_empty_resource' do
      meta_inf      = app_dir + 'META-INF'
      resources_xml = meta_inf + 'resources.xml'
      expect(resources_xml).to exist

      component.compile

      expect(resources_xml.read).to match(%r{<Resource id='jdbc/test-service-sqlserver-schema' \
type='DataSource' properties-provider='org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'/>})
    end

  end
end
