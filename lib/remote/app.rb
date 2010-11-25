require 'yaml'

module Remote
  class App
    include Printer

    # Returns the config file location.
    def config_file
      config_file_locations.detect { |f| File.exists? (f) }
    end

    # Returns a list of where configuration files are expected to be present.
    def config_file_locations
      ['config/remotes.yml', 'remotes.yml']
    end

    # Returns the configuration hash.
    def config
      verify_config
      @config ||= YAML::load_file(config_file)
    end

    def servers
      return @servers  unless @servers.nil?
      @servers = Hash.new
      config.each { |name, data| @servers[name] = Server.new(name, data) }
      @servers
    end

    def list
      servers.keys.each { |name| log "  #{name}" }
    end

    def run(to, *cmd)
      verify_config
      [to].flatten.each do |server_name|
        svr = servers[server_name]
        if svr.nil?
          log "Unknown server '#{server_name}'. Available servers are:"
          list
          log "See #{config_file} for more information."
          exit
        end

        command = svr.to_cmd(*cmd)
        what = cmd.any? ? cmd.join(' ') : 'console'
        status svr.to_s, what
        system command
      end
    end

    def write_sample
      unless config_file.nil?
        log "A configuration file already exists in #{config_file}."
        return
      end

      fname = config_file_locations.last
      begin
        File.open(fname, 'w') { |f| f.write(sample_data) }
        log "Wrote #{fname}."
      rescue => e
        log "Error: unable to save to #{fname}."
      end
    end

    def help(cmd)
      log "Executes a command at a remote server."
      log "Usage: #{cmd} <server> [<command>]"
      log "       #{cmd} <server>,<server2>,<serverN> <command>"
      log "       #{cmd} --sample"
      log ""
      log "Servers are defined in a config file. Use `#{cmd} --sample` to"
      log "create a sample config file."
      log ""

      if config_file.nil?
        log "Config files are searched for in:"
        log "  " + config_file_locations.join(", ")
      else
        log "Your configuration file is in #{config_file}."
      end

      log ""
      log "Examples"
      log "--------"
      log ""
      log "1) Executes 'irb -r./init' in the server called 'live'."
      log "    #{cmd} live irb -r./init"
      log ""
      log "2) Starts a console for the 'live' server."
      log "    #{cmd} live"
      log ""
    end

  protected
    def verify_config
      if config_file.nil?
        log "Error: no config file is present."
        exit
      end
    end

    def sample_data
      <<-adios.gsub(/^ {6}/, '')
        staging: &defaults
          host: staging.myserver.com
          # Everything below are optional.
          user: rsc
          path: /home/rsc/app/current
          key: ~/.ssh/id_rsa.pub
          commands:
            # These are optional aliases.
            # Typing 'remoter staging rake x' will execute this, with %s replaced by 'x'.
            rake: 'bin/rake %s'

            # Typing 'remoter staging deploy' will execute this script.
            deploy: |
              echo Deploying...
              git pull
              echo Done!

        # This is an example of how to define another server via inheritance.
        live:
          <<: *defaults
          path: /home/rsc/app
          host: www.myserver.com
      adios
    end
  end
end
