require 'rubygems'
require 'nats/client'
require 'yaml'

["TERM", "INT"].each { |sig| trap(sig) { NATS.stop } }

def usage
  puts "Usage: auth_sub <user> <pass> <subject>"; exit
end

msg = ARGV.first
usage unless msg

config = YAML.load(File.open('./config.yml'))

uri = config['uri']
subject = config['subject']

NATS.on_error { |err| puts "Server Error: #{err}"; exit! }

NATS.start(:uri => uri) do
  NATS.publish(subject, msg)
  NATS.stop
end

puts "Published on [#{subject}] : '#{msg}'"
