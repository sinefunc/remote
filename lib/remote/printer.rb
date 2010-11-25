module Remote
module Printer
  def log(str)
    $stderr << "#{str}\n"
  end

  def status(where, what)
    c1 = "\033[0;30m"
    c2 = "\033[0;33m"
    c0 = "\033[0m"
    log "#{c1}[#{where}]$#{c2} #{what}#{c0}"
  end
end
end
