package 'squid' do
  action :install
end

remote_file '/etc/squid/squid.conf' do
  source "files/squid.conf"
end

execute 'create auth file' do
  command "printf \"#{ node['user'] || 'user' }:$(openssl passwd -crypt #{ node['pass'] || 'pass' })\" > /etc/httpd/conf.d/squid.conf"
  user 'root'
end

service 'squid' do
  action [:enable, :restart]
end
