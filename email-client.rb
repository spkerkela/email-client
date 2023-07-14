:require 'net/smtp'
require 'net/imap'
require 'io/console'

class TerminalEmailClient
  def initialize
    load_config
  end
  
  def run
    login_prompt
    main_menu
  end

  private

  def load_config
    config = {}
    File.readlines('.emailrc').each do |line|
      next if line.start_with? "#"
      key, value = line.strip.split('=', 2)
      config[key.strip] = value.strip if key && value
    end
    @smtp_server = config['smtp_server']
    @smtp_port  = config['smtp_port'].to_i
    @imap_server = config['imap_server']
    @imap_port  = config['imap_port'].to_i
    @email = config['email']
    @password = config['password']
  end


  def login_prompt
    return if @email and @password
    print 'Email: '
    @email = gets.chomp

    print 'Password: '
    @password = STDIN.noecho(&:gets).chomp
    puts "\n"
  end

  def main_menu
    loop do
      puts 'Select an option:'
      puts '1. Compose and send an email'
      puts '2. Check inbox'
      puts '3. Quit'

      choice = gets.chomp.to_i

      case choice
      when 1
        compose_email
      when 2
        check_inbox
      when 3
        break
      else
        puts 'Invalid choice. Try again.'
      end
    end
  end

  def compose_email
    print 'To: '
    to = gets.chomp

    print 'Subject: '
    subject = gets.chomp

    print 'Body: '
    body = gets.chomp

    send_email(to, subject, body)
  end

  def send_email(to, subject, body)
    smtp = Net::SMTP.new(@smtp_server, @smtp_port)
    smtp.enable_starttls_auto

    smtp.start(@smtp_server, @email, @password, :login) do |smtp|
      smtp.send_message(email_message(to, subject, body), @email, to)
      puts 'Email sent successfully!'
    end
  end

  def email_message(to, subject, body)
    <<~EMAIL
      From: #{@email}
      To: #{to}
      Subject: #{subject}

      #{body}
    EMAIL
  end

  def check_inbox
    imap = Net::IMAP.new(@imap_server, @imap_port, usessl: true)
    imap.login(@email, @password) if @email and @password

    imap.select('INBOX')
    message_ids = imap.search(['ALL'])

    message_ids.each do |message_id|
      envelope = imap.fetch(message_id, 'ENVELOPE')[0].attr['ENVELOPE']
      puts "From: #{envelope.from[0].name} <#{envelope.from[0].mailbox}@#{envelope.from[0].host}>"
      puts "Subject: #{envelope.subject}"
      puts "Date: #{envelope.date}\n\n"
    end

    imap.logout
    imap.disconnect
  end
end

client = TerminalEmailClient.new
client.run

