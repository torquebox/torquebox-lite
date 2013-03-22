# TorqueBox Lite

This is a smaller, web-only version of [TorqueBox][]. The main goal is
to provide a reliable and maintained JRuby web server option with a
small footprint and very simple usage. Scheduled jobs, messaging,
Backgroundable, long-running services, distributed transactions,
Infinispan caching, and clustering from TorqueBox will NOT work with
TorqueBox Lite.

TorqueBox Lite is designed to only run a single application at a time -
the application in the current directory. It creates a
`torquebox-lite` directory inside this application to hold session
data, temporary files, and server logs.

The underlying bits are identical to those in TorqueBox, except that
many things have been removed. You can still create a `torquebox.yml`
or `torquebox.rb` file to configure Ruby versions, environment
variables, shared vs bounded JRuby pooling, web context, and various
other things. See the [TorqueBox documentation][] for more details
there.


## Basic Usage

### Installation

    jruby -S gem install torquebox-lite

### Starting

    cd /path/to/your_app
    torquebox-lite

### Stopping

Use `CTRL+C` to kill the foreground process. You can also use `kill
<pid>` if you started it in the background.

### Bundler

If using Bundler, add `torquebox-lite` to your `Gemfile` instead of
installing it via `gem install` and then run `bundle exec
torquebox-lite` to boot the server.

### Hot deployment (redeploying without restarting the server)

    touch $APP_ROOT/torquebox-lite/deployments/<app_name>-knob.yml.dodeploy

The <app_name> is usually the name of the application's directory -
take a look at the other files under that deployments directory to see
what it should be.


## More Usage Examples

### Run in production mode with JRuby 1.9 compatibility

    JRUBY_OPTS="--1.9" RAILS_ENV=production torquebox-lite

### Run with a larger JVM heap size

    JRUBY_OPTS="-J-Xmx1024m" torquebox-lite

### Bind to 0.0.0.0 instead of localhost and port 3000

    torquebox-lite -b 0.0.0.0 -p 3000

### Use multiple JRuby runtimes for non-threadsafe applications

    torquebox-lite --min-runtimes=3 --max-runtimes=5

### Get a listing of all torquebox-lite options

    torquebox-lite --help


## Need help?

Get in touch with us via the regular [TorqueBox community][] channels -
IRC, mailing lists, or Twitter.


## Found a bug? Have a suggestion?

Because TorqueBox Lite has a separate release cycle and codebase from
TorqueBox itself, please use GitHub Issues to file bugs and feature
requests instead of the TorqueBox JIRA.


## Want to contribute?

Pull requests are more than welcome. There are really just two Ruby
files that contain the majority of the code.

* build/assembly/bin/assemble.rb - Transform the stock TorqueBox
  distribution into our slimmed down version

* gems/torquebox-lite/bin/torquebox-lite - The `torquebox-lite`
  command which boots TorqueBox Lite

Building TorqueBox Lite requires Maven 3. From the project's root
directory, just run `mvn install`.


[torquebox]: http://torquebox.org
[torquebox documentation]: http://torquebox.org/documentation/current/
[torquebox community]: http://torquebox.org/community/
