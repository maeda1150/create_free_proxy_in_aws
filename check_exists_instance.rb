require 'aws-sdk'
require 'optparse'
require 'json'
require 'yaml'
require 'erb'
require 'pry'
Dir.glob("#{File.expand_path('../classes', __FILE__)}/*.rb").each { |f| require f }

# Set Config

aws_configs = Util.load_yaml('aws_configs.yml', 'aws_config')
ec2_config = Util.load_yaml('ec2_config.yml')
regions    = Util.load_yaml('regions.yml')

# start EC2
start_time = Time.now
puts 'Start EC2 task.'
puts '=' * 25

aws_configs.each do |aws_config|
  puts aws_config['account_name']
  credentials = Aws::Credentials.new(aws_config['access_key_id'], aws_config['secret_access_key'])
  regions.each do |key, region|
    Aws.config.update(region: region, credentials: credentials)
    ec2 = EC2.new(ec2_config, region)
    puts " #{Util.optimize_line(key, 12)} : #{ec2.running_instance_count} "
  end
  puts '=' * 25
end

puts 'EC2 check exists complete.'
puts "EC2 cost time : #{Time.now - start_time} second"
