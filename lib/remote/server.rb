require 'ostruct'
require 'shellwords'

module Remote
  class Server < OpenStruct
    def initialize(name, data)
      super data
      self.host ||= name
      self.commands ||= Hash.new
    end

    def to_s
      host.to_s
    end

    # Construct an SSH command line for the given command.
    def to_cmd(*what)
      hostname = self.user.nil? ? self.host.to_s : "#{self.user}@#{self.host}"

      cmd = [ "ssh", hostname ]
      cmd << "-i #{self.key}" unless self.key.nil?

      remote_cmd = []
      unless self.path.nil?
        remote_cmd << "cd #{self.path}"
      end

      first_command = what.first.split(' ')
      if self.commands.keys.include?(first_command.first)
        remote_cmd << self.commands[first_command.shift].gsub("\n",';').gsub('%s', first_command.join(' '))
      else
        remote_cmd += what
      end

      cmd.join(' ') + ' -- ' + remote_cmd.join(';').shellescape
    end
  end
end
