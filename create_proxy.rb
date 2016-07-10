require 'aws-sdk'
require 'optparse'
require 'json'
require 'yaml'
require 'erb'
require 'pry'
Dir.glob("#{File.expand_path('../classes', __FILE__)}/*.rb").each do |file|
  require file
end

whole_start_time = Time.now

# Set Config

aws_config = Util.load_yaml('aws_config.yml', 'aws_config')
basic_auth = Util.load_yaml('basic_auth.yml', 'aws_config') if File.exist?('./aws_config/basic_auth.yml')
basic_auth = nil unless basic_auth['user'] && basic_auth['pass']
default    = Util.load_yaml('default.yml')
ec2_config = Util.load_yaml('ec2_config.yml')
regions    = Util.load_yaml('regions.yml')
params     = ARGV.getopts('gs', 'region:', 'port:')

if params['region'] && !regions.keys.include?(params['region'])
  puts "#{params['region']} is invalid region."
  puts 'Please type "cat config/regions.yml"'
  exit
end

allowed_ip = params['g'] ? '0.0.0.0/0' : "#{`curl ipecho.net/plain`}/32"
proxy_port = params['port'] || default['proxy_port']
region     = regions[params['region']] || regions['tokyo']

credentials = Aws::Credentials.new(aws_config['access_key_id'], aws_config['secret_access_key'])
Aws.config.update(region: region, credentials: credentials)

# start CloudFormation
start_time = Time.now
puts 'Start CloudFormation task.'

template = Util.load_yaml('proxy_vpc.yml').to_json
cf = CloudFormation.new(template)

cf.create_or_update_proxy_stack

puts "CloudFormation cost time : #{Time.now - start_time} second"

# start EC2
puts 'Start EC2 task.'

start_time = Time.now

key_name = "#{region}_proxy"
full_key_name = "./aws_config/#{key_name}.pem"
ec2 = EC2.new(ec2_config, region, key_name, full_key_name)
ec2.run_proxy_instance

puts 'EC2 create complete.'
puts "EC2 cost time : #{Time.now - start_time} second"

# execute itamae
start_time = Time.now
puts 'Start execute itamae.'

system "bundle exec itamae ssh -h #{ ec2.public_ip_address } -u ec2-user -i #{ full_key_name } #{ '-y aws_config/basic_auth.yml' if basic_auth } itamae/recipe.rb 1>/dev/null 2>/dev/null"

puts 'Execute itamae complete.'
puts "Itamae cost time : #{Time.now - start_time} second"

# puts result
puts '-----------------------------------'
puts "ip address   : #{ ec2.public_ip_address }"
puts "port         : #{ proxy_port }"
puts "global       : #{ params['g'] }"
puts "connect host : ssh -i #{ full_key_name } ec2-user@#{ ec2.public_ip_address }"
puts "region       : #{ params['region'] || 'tokyo' }"
puts "proxy user   : #{ basic_auth.nil? ? 'user' : basic_auth['user'] }"
puts "proxy pass   : #{ basic_auth.nil? ? 'pass' : basic_auth['pass'] }"
puts '-----------------------------------'

puts "Whole cost time : #{Time.now - whole_start_time} second"

`afplay ./assets/finish.mov` unless params['s']
