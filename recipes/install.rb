
bash "install-golang" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    rm -rf go
    rm -rf #{node['go']['install_dir']}/go
    mkdir -p /code/go
    tar -C #{node['go']['install_dir']} -xzf #{node["go"]["filename"]}
  EOH
  action :nothing
end

remote_file File.join(Chef::Config[:file_cache_path], node['go']['filename']) do
  source node['go']['url']
  owner "root"
  mode 0644
  notifies :run, resources(:bash => "install-golang"), :immediately
  not_if "#{node['go']['install_dir']}/go/bin/go version | grep #{node['go']['version']}"
end

cookbook_file "/etc/profile.d/golang.sh" do
  source "golang.sh"
  owner "root"
  group "root"
  mode 0755
end

ruby_block "gopath" do
    block do
        # Add to environment variables
                file = Chef::Util::FileEdit.new("/etc/environment") 
        file.search_file_replace_line("PATH", "export PATH=\"#{ENV['PATH']}:" + node['go']['install_dir'] + "/go/bin\"")
        file.write_file
        
        file = Chef::Util::FileEdit.new("/etc/environment")        
        file.search_file_replace_line("GOROOT", "export GOROOT=\"" + node['go']['install_dir'] + "/go\"")
        file.insert_line_if_no_match("GOROOT", "export GOROOT=\"" + node['go']['install_dir'] + "/go\"")
        file.write_file
        
        file = Chef::Util::FileEdit.new("/etc/environment")        
        file.search_file_replace_line("GOPATH", "export GOPATH=\"/code/go\"")
        file.insert_line_if_no_match("GOPATH", "export GOPATH=\"/code/go\"")
        file.write_file
        
        file = Chef::Util::FileEdit.new("/etc/sudoers") 
        file.insert_line_if_no_match("Defaults env_keep +=\"GOPATH\"", "Defaults env_keep +=\"GOPATH GOROOT\"")
        file.write_file     
    end
end
