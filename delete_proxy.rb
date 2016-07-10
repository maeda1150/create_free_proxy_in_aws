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
default    = Util.load_yaml('default.yml')
regions    = Util.load_yaml('regions.yml')
ec2_config = Util.load_yaml('ec2_config.yml')
params     = ARGV.getopts('sad', 'region:')
credentials = Aws::Credentials.new(aws_config['access_key_id'], aws_config['secret_access_key'])

if params['region'] && !regions.keys.include?(params['region'])
  puts "#{params['region']} is invalid region."
  puts "#{params['region']} is invalid region."
  puts 'Please type "cat config/regions.yml"'
  exit
end

def delete_ec2(ec2_config, region, demon)
  start_time = Time.now

  key_name = "#{region}_proxy"
  full_key_name = "./aws_config/#{key_name}.pem"
  ec2 = EC2.new(ec2_config, region, key_name, full_key_name)
  ec2.terminate_proxy_instance(demon)

  puts " #{Util.optimize_line('EC2 cost time', 25)} : #{Time.now - start_time} second"
end

def delete_cf(demon)
  start_time = Time.now

  CloudFormation.new.delete_proxy_stack(demon)

  puts " #{Util.optimize_line('CloudFormation cost time', 25)} : #{Time.now - start_time} second"
end

target_regions = []
target_regions << regions[params['region']] || regions['tokyo']
target_regions = regions.values if params['a']

target_regions.each do |region|
  puts '=' * 50
  puts " #{Util.optimize_line('region', 25)} : #{ regions.key(region) } "
  Aws.config.update(region: region, credentials: credentials)
  delete_ec2(ec2_config, region, params['d'])
  delete_cf(params['d'])
end

puts '=' * 50

puts "Whole cost time : #{Time.now - whole_start_time} second"

`afplay ./assets/finish.mov` unless params['s']
