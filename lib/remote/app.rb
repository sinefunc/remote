require 'yaml'

module Remote
  module App
    extend self
    def config_file
      ENV['REMOTE_CONFIG_FILE'] || 'remotes.yml'
    end

    def config
      @config ||= YAML::load_file(config_file)
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
        #puts "$ #{command}"
        system command
      end
    end
  end
end
