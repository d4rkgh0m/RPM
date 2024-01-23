# -*- mode: ruby -*-
# vi: set ft=ruby :
MACHINES = {
  :rpm => {
        :box_name => "generic/centos8s",
        :ip_addr => '192.168.56.55'
  }
}

Vagrant.configure("2") do |config|
  
  config.vm.provision "shell", path: "rpm.sh"

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          box.vm.network "forwarded_port", guest: 80, host: 80

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "250"]
          end
          
          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
          SHELL

      end
  end
end