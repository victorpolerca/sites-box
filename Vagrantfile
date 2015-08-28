# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"

CONF = YAML.load(File.open(File.join(File.dirname(__FILE__), "config.yaml"), File::RDONLY).read)

Vagrant.configure("2") do |config|

    config.vm.hostname = CONF['vm_hostname']
    config.hostmanager.aliases = Array.new

    # Add each site to our hostmanager aliases, appending the
    # vm's hostname.
    CONF['sites'].each do |site|
      config.hostmanager.aliases.push site['name'] + "." + config.vm.hostname
    end

    # This tells VirtualBox to let our VM use the host DNS.
    # (you probably won't have access to the external internet from
    #  the VM without this).
    # @TODO Add support for other providers (i.e, VMWare)
    config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end

    config.vm.box = "scotch/box"
    config.vm.network "private_network", ip: CONF['vm_ip']
    config.vm.synced_folder "sites/", "/var/www/vhosts", :nfs => { :mount_options => ["dmode=777","fmode=666"] }
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true

    # Format the domains as a comma-separated list
    # to pass into the shell script.
    vhosts = '"' + config.hostmanager.aliases.join(",") + '"';

    config.vm.provision "shell" do |s|
      s.args = vhosts + " " + CONF['vm_ip'] + " " + config.vm.hostname
      s.path = "setup/provision/setup.sh"
    end

    # This is a temporary hack to address sites not loading after the
    # host machine sleeps or is halted and started back up.
    # @TODO Isolate and address the underlying problem here.
    config.vm.provision "shell", inline: "sudo service apache2 restart", run: "always"

end
