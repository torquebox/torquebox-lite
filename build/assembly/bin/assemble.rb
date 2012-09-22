#!/usr/bin/env ruby

$: << File.dirname( __FILE__ ) + '/../lib'

require 'assembly_tool'
require 'fileutils'
require 'java'
require 'optparse'
require 'rbconfig'
require 'rexml/document'

java_import java.lang.System

class Assembler

  def initialize(cli)
    @base_dir = File.expand_path(File.dirname(__FILE__) + '/..')
    @build_dir = "#{@base_dir}/target/stage"
    @torquebox_dir = "#{@build_dir}/torquebox"
    @jboss_dir = "#{@torquebox_dir}/jboss"

    @torquebox_version = System.getProperty('version.torquebox')

    @m2_repo = cli.maven_repo_local
    if @m2_repo.nil?
      if ENV['M2_REPO']
        @m2_repo = ENV['M2_REPO']
      else
        @m2_repo = "#{ENV['HOME']}/.m2/repository"
      end
    end

    @use_unzip = cli.unzip

    @torquebox_zip = "#{@m2_repo}/org/torquebox/torquebox-dist/#{@torquebox_version}/torquebox-dist-#{@torquebox_version}-bin.zip"
    @tool = AssemblyTool.new
  end

  def assemble
    prepare
    lay_down_torquebox
    # install_gems
    transform_config
    transform_modules
    transform_standalone_conf
    clean_filesystem
  end

  def prepare
    FileUtils.mkdir_p @build_dir
  end

  def lay_down_torquebox
    unless File.exist?(@torquebox_dir)
      puts "Laying down TorqueBox"
      Dir.chdir(File.dirname(@torquebox_dir)) do
        unzip(@torquebox_zip)
        original_dir = File.expand_path(Dir['torquebox-*'].first)
        FileUtils.mv(original_dir, @torquebox_dir)
      end
    end
  end

  def install_gems
    # Install gems in order specified by modules in gems/pom.xml
    gem_pom = REXML::Document.new(File.read(@base_dir + '/../../gems/pom.xml'))
    gem_dirs = gem_pom.get_elements("project/modules/module").map { |m| m.text }

    gem_dirs.each do |gem_dir|
      Dir[@base_dir + '/../../gems/' + gem_dir + '/target/*.gem'].each do |gem_package|
        puts "Install gem: #{gem_package}"
        @tool.install_gem(gem_package)
      end
    end
  end

  def transform_config
    config_file = "#{@jboss_dir}/standalone/configuration/standalone.xml"
    edit_xml_file(config_file) do |doc|
      remove_extensions(doc)
      remove_subsystems(doc)
      adjust_socket_bindings(doc)
      disable_management(doc)
      disable_remote_naming(doc)
      disable_jsp(doc)
    end
  end

  def transform_modules
    org_dir = "#{@jboss_dir}/modules/org"
    edit_xml_file("#{org_dir}/jboss/jts/main/module.xml") do |doc|
      doc.root.delete_element("dependencies/module[@name='org.hornetq']")
    end

    edit_xml_file("#{org_dir}/torquebox/core/main/module.xml") do |doc|
      doc.root.delete_element("dependencies/module[@name='org.jboss.as.connector']")
    end

    edit_xml_file("#{org_dir}/jboss/as/server/main/module.xml") do |doc|
      doc.root.delete_element("dependencies/module[@name='org.jboss.as.domain-http-interface']")
    end
  end

  def transform_standalone_conf
    conf_file = "#{@jboss_dir}/bin/standalone.conf"
    contents = File.read(conf_file)
    # contents.sub!(/-XX:MaxPermSize=\d+./, '-XX:MaxPermSize=128m')
    File.open(conf_file, 'w') do |file|
      file.write(contents)
    end

    conf_file = "#{@jboss_dir}/bin/standalone.conf.bat"
    contents = File.read(conf_file)
    # contents.sub!(/-XX:MaxPermSize=\d+./, '-XX:MaxPermSize=128m')
    File.open(conf_file, 'w') do |file|
      file.write(contents)
    end
  end

  def clean_filesystem
    FileUtils.rm_rf(File.join(@jboss_dir, 'appclient'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bundles'))

    FileUtils.rm_rf(File.join(@jboss_dir, 'docs', 'examples'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'docs', 'schema'))

    FileUtils.rm_rf(File.join(@jboss_dir, 'domain'))

    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'appclient.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'appclient.conf.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'appclient.conf'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'appclient.sh'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'client'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'domain.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'domain.conf'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'domain.conf.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'domain.sh'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'jconsole.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'jconsole.sh'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'jdr.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'jdr.sh'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'run.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'run.sh'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'wsconsume.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'wsconsume.sh'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'wsprovide.bat'))
    FileUtils.rm_rf(File.join(@jboss_dir, 'bin', 'wsprovide.sh'))

    remove_module('asm')
    remove_module('com', 'google')
    remove_module('com', 'h2database')
    remove_module('com', 'sun', 'jsf-impl', '1.2')
    remove_module('com', 'sun', 'xml')
    remove_module('gnu')
    remove_module('javax', 'faces', 'api', '1.2')
    remove_module('javax', 'wsdl4j')
    remove_module('jline')
    remove_module('org', 'antlr')
    remove_module('org', 'apache', 'cxf')
    remove_module('org', 'apache', 'httpcomponents')
    remove_module('org', 'apache', 'james')
    remove_module('org', 'apache', 'juddi')
    remove_module('org', 'apache', 'neethi')
    remove_module('org', 'apache', 'santuario')
    remove_module('org', 'apache', 'velocity')
    remove_module('org', 'apache', 'ws')
    remove_module('org', 'apache', 'xml-resolver')
    remove_module('org', 'codehaus')
    remove_module('org', 'dom4j')
    remove_module('org', 'jaxen')
    remove_module('org', 'jboss', 'as', 'aggregate')
    remove_module('org', 'jboss', 'as', 'appclient')
    remove_module('org', 'jboss', 'as', 'cli')
    remove_module('org', 'jboss', 'as', 'cmp')
    remove_module('org', 'jboss', 'as', 'connector')
    remove_module('org', 'jboss', 'as', 'ejb3')
    remove_module('org', 'jboss', 'as', 'configadmin')
    remove_module('org', 'jboss', 'as', 'console')
    remove_module('org', 'jboss', 'as', 'domain-add-user')
    remove_module('org', 'jboss', 'as', 'domain-http-error-context')
    remove_module('org', 'jboss', 'as', 'domain-http-interface')
    remove_module('org', 'jboss', 'as', 'host-controller')
    remove_module('org', 'jboss', 'as', 'jaxr')
    remove_module('org', 'jboss', 'as', 'jaxrs')
    remove_module('org', 'jboss', 'as', 'jdr')
    remove_module('org', 'jboss', 'as', 'jpa')
    remove_module('org', 'jboss', 'as', 'jsr77')
    remove_module('org', 'jboss', 'as', 'mail')
    remove_module('org', 'jboss', 'as', 'management-client-content')
    remove_module('org', 'jboss', 'as', 'messaging')
    remove_module('org', 'jboss', 'as', 'modcluster')
    remove_module('org', 'jboss', 'as', 'osgi')
    remove_module('org', 'jboss', 'as', 'pojo')
    remove_module('org', 'jboss', 'as', 'sar')
    remove_module('org', 'jboss', 'as', 'web', 'main', 'lib')
    remove_module('org', 'jboss', 'as', 'webservices')
    remove_module('org', 'jboss', 'as', 'weld')
    remove_module('org', 'jboss', 'as', 'xts')
    remove_module('org', 'jboss', 'iiop-client')
    remove_module('org', 'jboss', 'jaxbintros')
    remove_module('org', 'jboss', 'osgi')
    remove_module('org', 'jboss', 'resteasy', 'resteasy-yaml')
    remove_module('org', 'jboss', 'shrinkwrap')
    remove_module('org', 'jboss', 'weld')
    remove_module('org', 'jboss', 'ws')
    remove_module('org', 'jboss', 'xb')
    remove_module('org', 'jboss', 'xts')
    remove_module('org', 'jdom')
    remove_module('org', 'hibernate', 'commons-annotations')
    remove_module('org', 'hibernate', 'envers')
    remove_module('org', 'hibernate', 'main')
    remove_module('org', 'hornetq')
    remove_module('org', 'picketlink')
    remove_module('org', 'projectodd', 'polyglot')
    remove_module('org', 'python')
    remove_module('org', 'torquebox', 'cdi')
    remove_module('org', 'torquebox', 'jobs')
    remove_module('org', 'torquebox', 'messaging')
    remove_module('org', 'torquebox', 'security')
    remove_module('org', 'torquebox', 'services')
    remove_module('org', 'torquebox', 'stomp')
    remove_module('org', 'yaml')
    remove_module('nu')

    FileUtils.rm_rf(File.join(@jboss_dir, 'welcome-content'))
  end

  def remove_module(*args)
    FileUtils.rm_rf(File.join(@jboss_dir, 'modules', args))
  end

  def remove_extensions(doc)
    necessary_extensions = %w{
      org.jboss.as.deployment-scanner
      org.jboss.as.ee
      org.jboss.as.logging
      org.jboss.as.naming
      org.jboss.as.security
      org.jboss.as.transactions
      org.jboss.as.web
      org.torquebox.bootstrap
      org.torquebox.core
      org.torquebox.web
    }

    extensions = doc.root.get_elements('extensions').first
    all_extensions = extensions.elements.map { |extension| extension.attributes['module'] }
    unnecessary_extensions = all_extensions - necessary_extensions
    unnecessary_extensions.each do |extension|
      extensions.delete_element("extension[@module='#{extension}']")
    end
  end

  def remove_subsystems(doc)
    necessary_subsystems = %w{
      logging
      deployment-scanner
      ee
      naming
      security
      transactions
      web
      torquebox-bootstrap
      torquebox-core
      torquebox-web
    }

    profiles = doc.root.get_elements('profile')
    profiles.each do |profile|
      all_subsystems = profile.get_elements('subsystem').map do |subsystem|
        xmlns = subsystem.attributes['xmlns']
        xmlns.sub(/urn:jboss:domain:(.+):.+/, '\1')
      end
      unnecessary_subsystems = all_subsystems - necessary_subsystems
      unnecessary_subsystems.each do |subsystem|
        profile.delete_element("subsystem[contains(@xmlns, 'urn:jboss:domain:#{subsystem}:')]")
      end
    end
  end

  def adjust_socket_bindings(doc)
    necessary_bindings = %w{
      http
      https
      txn-recovery-environment
      txn-status-manager
    }
    socket_binding_group = doc.root.get_elements('socket-binding-group').first
    socket_binding_group.delete_element('outbound-socket-binding')
    socket_bindings = socket_binding_group.elements.map { |e| e.attributes['name'] }
    socket_bindings.each do |socket_binding|
      unless necessary_bindings.include?(socket_binding)
        socket_binding_group.delete_element("socket-binding[@name='#{socket_binding}']")
      end
    end
    http_binding = socket_binding_group.get_elements("socket-binding[@name='http']").first
    http_binding.attributes['port'] = '${torquebox.http.port:8080}'
  end

  def disable_management(doc)
    doc.root.delete_element('management')
  end

  def disable_remote_naming(doc)
    profiles = doc.root.get_elements('profile')
    profiles.each do |profile|
      naming_subsystem = profile.get_elements("subsystem[contains(@xmlns, 'urn:jboss:domain:naming:')]").first
      naming_subsystem.delete_element('remote-naming')
    end
  end

  def disable_jsp(doc)
    profiles = doc.root.get_elements('profile')
    profiles.each do |profile|
      web_subsystem = profile.get_elements("subsystem[contains(@xmlns, 'urn:jboss:domain:web:')]").first
      configuration = web_subsystem.get_elements('configuration').first
      if configuration.nil?
        configuration = web_subsystem.add_element('configuration')
      end
      jsp_configuration = configuration.get_elements('jsp-configuration').first
      if jsp_configuration.nil?
        jsp_configuration = configuration.add_element('jsp-configuration', 'disabled' => 'true')
      end
    end
  end

  def unzip(path)
    if windows?
      `jar.exe xf #{path}`
    elsif !@use_unzip
      `jar xf #{path}`
    else
      `unzip -q #{path}`
    end
  end

  def windows?
    RbConfig::CONFIG['host_os'] =~ /mswin/
  end

  def edit_xml_file(path)
    doc = REXML::Document.new(File.read(path))
    yield doc
    open(path, 'w') do |file|
      doc.write(file, 4)
    end
  end

end

class CLI

  def self.parse!(args)
    CLI.new.parse!(args)
  end

  attr_accessor :maven_repo_local
  attr_accessor :unzip

  def initialize
    @maven_repo_local = ENV['M2_REPO'] || File.join( ENV['HOME'], '.m2/repository' )
    @unzip = true
  end

  def parse!(args)
    opts = OptionParser.new do |opts|
      opts.on( '--[no-]unzip', 'Use unzip when making assemblage (default: true)' ) do |i|
        self.unzip = i
      end
      opts.on( '-m MAVEN_REPO_LOCAL', 'Specify local maven repository' ) do |m|
        self.maven_repo_local = m
      end
    end
    opts.parse! args
    self
  end
end

if __FILE__ == $0 || '-e' == $0 # -e == called from mvn
  Assembler.new(CLI.parse!(ARGV)).assemble
end
