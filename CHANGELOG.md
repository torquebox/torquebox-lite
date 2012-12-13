## 0.2.0

* Upgrade to TorqueBox 2.2.0

* Add torquebox-configure dependency so torquebox.rb files get parsed
properly

## 0.1.5

* Fix Ruby load path issue when running under bundler standalone or
  deployment mode with binstubs

* Gem sized reduced from 47MB to 42MB by getting rid of a few more
  unnecessary JBoss modules in the TorqueBox distribution

## 0.1.4

* Fall back to locating $TORQUEBOX_HOME via Ruby load path

## 0.1.3

* Build against a TorqueBox 2.1.2 snapshot but still depend on the
  TorqueBox 2.1.1 gems

* Disable the creation of XA datasources since
  `torquebox-transactions` is not used with `torquebox-lite`

* Help is now listed by `torquebox-lite --help` instead of
  `torquebox-lite help run`

## 0.1.2

* Disable JSP support in underlying jbossweb

* Fix bug in JRUBY_OPTS parsing with -J options

* Change Thor dependency to `>= 0.14.6` instead of `= 0.14.6`

* Add options for specifying bounded runtimes on the command-line via
  `torquebox-lite --min-runtimes=M --max-runtimes=N`

## 0.1.1

* Depend on TorqueBox 2.1.1 since 2.1.2 isn't released yet.

## 0.1.0

* Initial release