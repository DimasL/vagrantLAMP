Vagrant.configure("2") do |config|
	config.vm.hostname = "site"
	config.vm.box = "ubuntu/xenial64"
	#config.vm.box_check_update = true
	config.vm.provision :shell, path: "bootstrap.sh"
  
	config.vm.network "private_network", ip: "192.168.33.60"
	
	config.vm.synced_folder "./site", "/var/www/html/site", type:"nfs", :nfs => { :mount_options => ["dmode=777","fmode=777", "owner=vagrant", "group=www-data"] }

	config.vm.provider "virtualbox" do |v|
		v.memory = 2048
		v.cpus = 2
		v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
	end
end