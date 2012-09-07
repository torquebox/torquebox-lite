# Copyright 2008-2012 Red Hat, Inc, and individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'rubygems/dependency_installer'

class AssemblyTool

  def initialize
    @base_dir = File.expand_path(File.dirname(__FILE__) + '/..')
    @build_dir = "#{@base_dir}/target/stage"
    @torquebox_dir = "#{@build_dir}/torquebox"
    @gem_repo_dir = "#{@build_dir}/gem-repo"
    @jruby_dir = "#{@torquebox_dir}/jruby"
  end

  def install_gem(gem, update_index=false)
    puts "Installing #{gem}"
    if JRUBY_VERSION =~ /^1\.7/
      install_dir = @jruby_dir + '/lib/ruby/gems/shared'
    else
      install_dir = @jruby_dir + '/lib/ruby/gems/1.8'
    end
    opts = {
      :bin_dir     => @jruby_dir + '/bin',
      :env_shebang => true,
      :install_dir => install_dir,
      :wrappers    => true
    }

    installer = Gem::DependencyInstaller.new(opts)
    installer.install(gem)
    copy_gem_to_repo(gem, update_index) if File.exist?(gem)
  end

  def copy_gem_to_repo(gem, update_index=false)
    FileUtils.mkdir_p @gem_repo_dir + '/gems'
    FileUtils.cp gem, @gem_repo_dir + '/gems'
    update_gem_repo_index if update_index
  end

  def update_gem_repo_index
    puts "Updating index"
    require_rubygems_indexer
    indexer = Gem::Indexer.new(@gem_repo_dir)
    indexer.generate_index
  end

  def require_rubygems_indexer
    begin
      gem 'builder', '3.0.0'
    rescue Gem::LoadError=> e
      puts "Installing builder gem"
      require 'rubygems/commands/install_command'
      installer = Gem::Commands::InstallCommand.new
      installer.options[:args] = ['builder']
      installer.options[:version] = '3.0.0'
      installer.options[:generate_rdoc] = false
      installer.options[:generate_ri] = false
      begin
        installer.execute
      rescue Gem::SystemExitException=>e2
      end
    end
    require 'rubygems/indexer'
  end

  def self.install_gem(gem)
    AssemblyTool.new().install_gem(gem, true)
  end

end
