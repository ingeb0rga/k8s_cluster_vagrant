# Worker nodes quantity
NODES=2
# SUB + DOT + MASTER_IP = IP4 address of the master node.
# Please check your VirtualBox host network IP4 Address/mask settings.
# Define one of the available IP4 addresses from your subnet for Control Plane IP4 address in SUB and MASTER_IP variables.
# Workers nodes IP4 address will be assigned automatically.
SUB="192.168.56"
MASTER_IP=130
# Vagrant box. Supported only Ubuntu releases
OS="ubuntu/focal64"
# Master node memory (MB)
MEM_MASTER="2048"
# Master node cpus
CPU_MASTER="2"
# Master node memory (MB)
MEM_WORKER="4096"
# Master node cpus
CPU_WORKER="2"

Vagrant.configure("2") do |config|
  config.vm.provision "shell", env: {"SUB" => SUB, "MASTER_IP" => MASTER_IP, "NODES" => NODES}, inline: <<-SHELL
      echo "$SUB.$MASTER_IP master" >> /etc/hosts
      for ((i=1;i<=$NODES;i++)); do
        echo "$SUB.$((MASTER_IP + i)) node0$i" >> /etc/hosts
      done
  SHELL

  config.vm.box = "#{OS}"
  config.vm.box_check_update = false

  config.vm.define "master" do |master|
    if Vagrant.has_plugin?("vagrant-vbguest") then
        master.vbguest.auto_update = false
    end
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: SUB + "." + "#{MASTER_IP}"
    master.vm.provider "virtualbox" do |vb|
        vb.memory = "#{MEM_MASTER}"
        vb.cpus = "#{CPU_MASTER}"
    end
    master.vm.provision "shell", path: "scripts/master.sh", privileged: false
  end

  (1..NODES).each do |i|

  config.vm.define "node0#{i}" do |node|
    if Vagrant.has_plugin?("vagrant-vbguest") then
        node.vbguest.auto_update = false
    end
    node.vm.hostname = "node0#{i}"
    node.vm.network "private_network", ip: SUB + "." + "#{MASTER_IP + i}"
    node.vm.provider "virtualbox" do |vb|
        vb.memory = "#{MEM_WORKER}"
        vb.cpus = "#{CPU_WORKER}"
    end
    node.vm.provision "shell", path: "scripts/node.sh", privileged: false
  end

  end
end 
