httpd_service node['httpd']['service_name'] do
  action :reload
end
