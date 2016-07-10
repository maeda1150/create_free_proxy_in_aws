require 'aws-sdk'
require 'optparse'
require 'json'
require 'yaml'
require 'erb'
require 'pry'
Dir.glob("#{File.expand_path('../classes', __FILE__)}/*.rb").each { |f| require f }

# Set Config

aws_config = Util.load_yaml('aws_config.yml', 'aws_config')
ec2_config = Util.load_yaml('ec2_config.yml')
regions    = Util.load_yaml('regions.yml')

credentials = Aws::Credentials.new(aws_config['access_key_id'], aws_config['secret_access_key'])

# start EC2
puts 'Start EC2 task.'

start_time = Time.now

puts '=' * 25
puts " #{Util.optimize_line('region', 12)} : exists "
puts '-' * 25

regions.each do |key, region|
  Aws.config.update(region: region, credentials: credentials)
  ec2 = EC2.new(ec2_config, region)
  puts " #{Util.optimize_line(key, 12)} : #{ec2.exists_proxy_instance?} "
end

puts '=' * 25

puts 'EC2 check exists complete.'
puts "EC2 cost time : #{Time.now - start_time} second"
