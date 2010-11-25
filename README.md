Remote
======

SSH helpers.

Getting started
---------------

First, install it.

    gem install remote

Then, create a sample config file.

    remote --sample

This generates a file called `remotes.yml`. Edit this sample file. (Tip: you can also put this in `config/remotes.yml` -- useful for Rails/Sinatra projects.)

    # remotes.yml
    live:
      host: foo.mysite.com
      user: app
      key: ~/.ssh/id_rsa
      path: /home/app/myapp
      # (user, key and path are all optional.)

Now, you may easily run commands on your given servers.

    remote live rake db:migrate
    # Equivalent to running `ssh -i ~/.ssh/id_rsa app@foo.mysite.com -- cd /home/app/myapp && rake db:migrate`

Going further
-------------

You may even define aliases for complicated commands.

    # remotes.yml
    live:
      host: foo.mysite.com
      commands:
        deploy: |
          git pull
          thin -C config/thin.yml restart
          rake cdn:propogate
          echo Deployed new version `rake app:version`

You may then run it easily with one command:

    remote live deploy
    # Runs the deploy script you've defined in the config file

You may also define aliases than take arguments.

    # remotes.yml
    live:
      host: foo.mysite.com
      commands:
        rake: env RACK_ENV=production rake %s

So then you may:

    remote live rake app:version 
    # Executes 'env RACK_ENV=production rake app:version' on the remote server
     
Multiple servers
----------------

Since the config file is in YAML, defining multiple servers can take
advantage of YAML's built-in inheritance solution.

    # remotes.yml
    live1: &defaults
      host: www.mysite.com
      user: myapp
      commands:
        deploy: #some semi-complicated stuff here
        #...

    live2:
      <<: *defaults
      host: www2.mysite.com

    live3:
      <<: *defaults
      host: www3.mysite.com

    # and so on

You may then issue commands to multiple hosts like so:

    remote live1,live2,live3 deploy

Using in Ruby
-------------

These will come in handy when creating Thor or Rake tasks:

    require 'remote'

    r = Remote::App.new
    r = Remote::App.new(:config => 'servers.yml')  # Optional

    r.run 'live', 'ls'    # Same as 'remote live ls'
    r.servers             #=> [<Server 'development'>, <Server 'production'>, ...]
    r.write_sample        # same as 'remote --sample'

    r = Remote::App.new(:console => true)
    r.list    # Same as 'remote --list'
    r.help    # Same as 'remote --help'

Authors
-------

Remote is authored and maintained by Rico Sta. Cruz of Sinefunc, Inc.
See more of our work on [www.sinefunc.com](http://www.sinefunc.com)!

Copyright
---------

(c) 2010 Rico Sta. Cruz and Sinefunc, Inc. See the LICENSE file for more details.
