# TorqueBox Lite

This is a smaller, web-only version of [TorqueBox][]. The main goal is
to provide a reliable and maintained JRuby web server option with a
small footprint and very simple usage.

TorqueBox Lite is designed to only run a single application at a time
- the application in the current directory. It creates a
`torquebox-lite` directory inside this application to hold session
data, temporary files, and server logs.

## Usage

* jruby -S gem install torquebox-lite

* cd /path/to/your_app

* torquebox-lite


[torquebox]: http://torquebox.org
