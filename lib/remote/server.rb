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

      [ cmd.join(' '), translate(*what) ].compact.join(' -- ')
    end

    # Translates a given set of commands, taking into account aliases.
    #
    # translate('git pull', 'thor app:restart') #=> "cd ~/x; git pull; env RACK_ENV=production thor app:restart" 
    def translate(*cmds)
      return nil  if cmds.empty?

      ret = []
      ret << "cd #{self.path}"  unless self.path.nil?
      cmds.each { |full_cmd| ret << translate_single(full_cmd) }
      ret.flatten.compact.join(';').shellescape
    end

    # Translates a single command by resolving aliases.
    def translate_single(full_cmd)
      key, *args = full_cmd.split(' ')
      command_alias = self.commands[key]
      unless command_alias.nil?
        command_alias.gsub("\n",';').gsub('%s', args.join(' '))
      else
        full_cmd
      end
    end
  end
end
