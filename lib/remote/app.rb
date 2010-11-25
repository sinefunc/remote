require 'yaml'

module Remote
  class App
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
      servers.keys.each { |name| puts "  #{name}" }
    end

    def run(to, *cmd)
      verify_config
      [to].flatten.each do |server_name|
        svr = servers[server_name]
        if svr.nil?
          puts "Unknown server '#{server_name}'. Available servers are:"
          list
          puts "See #{config_file} for more information."
          exit
        end

        command = svr.to_cmd(*cmd)
        puts "#{svr.to_s}$ #{cmd.join(' ')}"
        system command
      end
    end

    def write_sample
      begin
        File.open(Remote::App.config_file, 'w') { |f| f.write(sample_data) }
        puts "Wrote #{Remote::App.config_file}."
      rescue => e
        puts "Error: unable to save to #{Remote::App.config_file}."
      end
    end

  protected
    def verify_config
      if config.nil?
        puts "Error: no config file is present."
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
