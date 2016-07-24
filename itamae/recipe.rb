package 'squid' do
  action :install
end

template '/etc/squid/squid.conf' do
  owner 'root'
  group 'root'
  mode '644'
  source 'templates/squid.conf.erb'
end

execute 'create auth file' do
  command "printf \"#{ node['user'] }:$(openssl passwd -crypt #{ node['pass'] })\" > /etc/httpd/conf.d/squid.conf"
  user 'root'
end

service 'squid' do
  action [:enable, :restart]
end
