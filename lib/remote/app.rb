require 'yaml'

module Remote
  class App
    include Printer

    def config_file
      ENV['REMOTE_CONFIG_FILE'] || 'remotes.yml'
    end

    def config_file_locations
      ['config/remotes.yml', config_file]
    end

    def config
      config_file_locations.each do |f|
        begin
          @config ||= YAML::load_file(f)
        rescue ::Errno::ENOENT
        end
      end
      @config
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
      begin
        File.open(Remote::App.config_file, 'w') { |f| f.write(sample_data) }
        log "Wrote #{Remote::App.config_file}."
      rescue => e
        log "Error: unable to save to #{Remote::App.config_file}."
      end
    end

    def help
      log "Executes a command at a remote server."
      log "Usage: #{cmd} <server> [<command>]"
      log "       #{cmd} <server>,<server2>,<serverN> <command>"
      log "       #{cmd} --sample"
      log ""
      log "Servers are defined in #{app.config_file}. Use `#{cmd} --sample` to"
      log "create a sample config file."
      log ""
      log "Example:"
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
      if config.nil?
        log "Error: no config file is present."
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
