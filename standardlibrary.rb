#!/usr/bin/ruby
require 'syslog'
require 'net/smtp'

def send_email(to,opts={})
  opts[:server]      ||= 'inbound.smtp.vt.edu'
  opts[:from]        ||= 'vmbackup@vt.edu'
  opts[:from_alias]  ||= 'Magneto VM Backup'
  opts[:subject]     ||= "VM Backup Completed Succesfully"
  opts[:body]        ||= "Important stuff!"
 
  msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}
 
#{opts[:body]}
END_OF_MESSAGE
 
  Net::SMTP.start(opts[:server]) do |smtp|
    smtp.send_message msg, opts[:from], to
  end
end

def log(message, critical=false)
  # $0 is the current script name
  Syslog.open(APP_NAME)
  unless critical
    Syslog.notice(message)
  else
    Syslog.crit(message)
  end
  Syslog.close
end

def put_log(input, growl=false)
  puts input
  log(input)
  if growl
    system("/usr/local/bin/growlnotify #{APP_NAME} -m \"#{input}\"")
  end
end

def log_call(name, input, growl=false)
  puts name
  if growl
    system("/usr/local/bin/growlnotify #{APP_NAME} -m \"#{name}\"")
  end
  unless system(input)
    log(input + " failed", true)
    $errors<<input
  else
    log(name)
  end
end


def send_wrap_up_mail
  if $errors.count > 0
    #send mail that we had errors
    body ="The following errors occured during backup.  \n"
    for error in $errors
      body += error + "\n"
    end
    body += "Please check and see whats going on ASAP!"
    send_email("gdraper@vt.edu", :body=>body, :subject=>"VM Backup Failed")
  else
    #send mail w/ no errors
    send_email("gdraper@vt.edu", :body=>"All backups completed succesfully at #{Time.now.localtime}")
  end
end
