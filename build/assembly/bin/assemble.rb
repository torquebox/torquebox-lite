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
    doc = REXML::Document.new(File.read(config_file))

    remove_extensions(doc)
    remove_subsystems(doc)
    adjust_socket_bindings(doc)
    disable_management(doc)
    disable_remote_naming(doc)

    open(config_file, 'w') do |file|
      doc.write(file, 4)
    end
  end

  def transform_modules
    jts_module = "#{@jboss_dir}/modules/org/jboss/jts/main/module.xml"
    doc = REXML::Document.new(File.read(jts_module))
    doc.root.delete_element("dependencies/module[@name='org.hornetq']")
    open(jts_module, 'w') do |file|
      doc.write(file, 4)
    end
  end

  def transform_standalone_conf
    conf_file = "#{@jboss_dir}/bin/standalone.conf"
    contents = File.read(conf_file)
    contents.sub!(/-XX:MaxPermSize=\d+./, '-XX:MaxPermSize=128m')
    File.open(conf_file, 'w') do |file|
      file.write(contents)
    end

    conf_file = "#{@jboss_dir}/bin/standalone.conf.bat"
    contents = File.read(conf_file)
    contents.sub!(/-XX:MaxPermSize=\d+./, '-XX:MaxPermSize=128m')
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

    modules_dir = File.join(@jboss_dir, 'modules')
    FileUtils.rm_rf(File.join(modules_dir, 'com', 'google'))
    FileUtils.rm_rf(File.join(modules_dir, 'com', 'h2database'))
    FileUtils.rm_rf(File.join(modules_dir, 'com', 'sun', 'jsf-impl', '1.2'))
    FileUtils.rm_rf(File.join(modules_dir, 'com', 'sun', 'xml'))
    FileUtils.rm_rf(File.join(modules_dir, 'javax', 'faces', 'api', '1.2'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'antlr'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'cxf'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'httpcomponents'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'james'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'juddi'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'neethi'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'velocity'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'ws'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'apache', 'xml-resolver'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'codehaus'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'dom4j'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jaxen'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'cmp'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'ejb3'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'console'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'jaxrs'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'jpa'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'mail'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'osgi'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'web', 'main', 'lib'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'webservices'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'weld'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'as', 'xts'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'osgi'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'resteasy', 'resteasy-yaml'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'weld'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'ws'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jboss', 'xts'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'jdom'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'hibernate', 'commons-annotations'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'hibernate', 'envers'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'hibernate', 'main'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'hornetq'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'picketlink'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'projectodd', 'polyglot'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'python'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'torquebox', 'cdi'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'torquebox', 'jobs'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'torquebox', 'messaging'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'torquebox', 'security'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'torquebox', 'services'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'torquebox', 'stomp'))
    FileUtils.rm_rf(File.join(modules_dir, 'org', 'yaml'))
    FileUtils.rm_rf(File.join(modules_dir, 'nu'))

    FileUtils.rm_rf(File.join(@jboss_dir, 'welcome-content'))
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
