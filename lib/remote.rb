module Remote
  PREFIX = File.expand_path(File.join(File.dirname(__FILE__), 'remote'))

  autoload :Server,  "#{PREFIX}/server"
  autoload :App,     "#{PREFIX}/app"
  autoload :Printer, "#{PREFIX}/printer"
end
