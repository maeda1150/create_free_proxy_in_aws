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

default    = Util.load_yaml('default.yml')
regions    = Util.load_yaml('regions.yml')
aws_config = Util.load_yaml('aws_config.yml', 'aws_config') if File.exist?('./aws_config/aws_config.yml')
ec2_config = Util.load_yaml('ec2_config.yml')
basic_auth = Util.load_yaml('basic_auth.yml', 'aws_config') if File.exist?('./aws_config/basic_auth.yml')
basic_auth = { 'user' => default['auth_user'], 'pass' => default['auth_pass'] } unless basic_auth['user'] && basic_auth['pass']
basic_auth = { 'user' => 'user', 'pass' => 'pass' } unless basic_auth['user'] && basic_auth['pass']
params     = ARGV.getopts('gs', 'region:', 'port:')

unless aws_config['access_key_id'] && aws_config['secret_access_key']
  puts 'Please set aws_key_id & aws_secret_key to "aws_config/aws_config.yml"'
  exit
end

if params['region'] && !regions.keys.include?(params['region'])
  puts "#{params['region']} is invalid region."
  puts 'Please type "cat config/regions.yml"'
  exit
end

allowed_ip = params['g'] ? '0.0.0.0/0' : "#{`curl ipecho.net/plain`}/32"
port = params['port'] || default['port'] || 8080
region     = regions[params['region']] || regions[default['region']] || regions['tokyo']

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

key_name      = "#{ region }_proxy"
full_key_name = "./aws_config/#{ key_name }.pem"
ec2 = EC2.new(ec2_config, region, key_name, full_key_name)
ec2.run_proxy_instance

puts 'EC2 create complete.'
puts "EC2 cost time : #{ Time.now - start_time } second"

# execute itamae
start_time = Time.now
puts 'Start execute itamae.'

system 'rm -rf itamae/config'
system 'mkdir itamae/config'

## for basic auth settings
system "echo 'user: #{ basic_auth['user'] }' >> itamae/config/params.yml"
system "echo 'pass: #{ basic_auth['pass'] }' >> itamae/config/params.yml"
system "echo 'port: #{ port }' >> itamae/config/params.yml"

## for tmux settings
## https://github.com/sue445/itamae-plugin-recipe-tmux
## http://sue445.hatenablog.com/entry/2016/02/25/120832
system "echo 'tmux:' >> itamae/config/params.yml"
system "echo '  prefix: /usr/local' >> itamae/config/params.yml"
system "echo '  version: 2.1' >> itamae/config/params.yml"
system "echo 'libevent:' >> itamae/config/params.yml"
system "echo '  version: 2.0.22' >> itamae/config/params.yml"
system "echo 'ncurses:' >> itamae/config/params.yml"
system "echo '  version: 6.0' >> itamae/config/params.yml"

system "bundle exec itamae ssh -h #{ ec2.public_ip_address } -u ec2-user -i #{ full_key_name } -y itamae/config/params.yml itamae/recipe.rb 1>/dev/null 2>/dev/null"

system 'rm -rf itamae/config'

puts 'Execute itamae complete.'
puts "Itamae cost time : #{ Time.now - start_time } second"

# puts result
puts '-----------------------------------'
puts "ip address   : #{ ec2.public_ip_address }"
puts "port         : #{ port }"
puts "global       : #{ params['g'] }"
puts "connect host : ssh -i #{ full_key_name } ec2-user@#{ ec2.public_ip_address }"
puts "region       : #{ regions.key(region) }"
puts "proxy user   : #{ basic_auth['user'] }"
puts "proxy pass   : #{ basic_auth['pass'] }"
puts '-----------------------------------'

puts "Whole cost time : #{Time.now - whole_start_time} second"

`afplay ./assets/finish.mov` unless params['s']
