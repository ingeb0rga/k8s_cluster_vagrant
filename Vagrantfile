# Worker nodes quantity
NODES=2
# IP_SUB + IP_START = IP address of the master node
IP_SUB="192.168.56."
IP_START=130
# Ubuntu vagrnat box. Supported only Ubuntu distributives
OS="ubuntu/focal64"
# Master node memory
MEM_MASTER="2048"
# Master node cpus
CPU_MASTER="2"
# Master node memory
MEM_WORKER="4096"
# Master node cpus
CPU_WORKER="2"


Vagrant.configure("2") do |config|
  config.vm.provision "shell", env: {"IP_SUB" => IP_SUB, "IP_START" => IP_START, "NODES" => NODES}, inline: <<-SHELL
      echo "$IP_SUB$IP_START master" >> /etc/hosts
      for ((i=1;i<=$NODES;i++)); do
        echo "$IP_SUB$((IP_START + i)) node0$i" >> /etc/hosts
      done
  SHELL

  config.vm.box = "#{OS}"
  config.vm.box_check_update = false

  config.vm.define "master" do |master|
    if Vagrant.has_plugin?("vagrant-vbguest") then
        master.vbguest.auto_update = false
    end
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: IP_SUB + "#{IP_START}"
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
    node.vm.network "private_network", ip: IP_SUB + "#{IP_START + i}"
    node.vm.provider "virtualbox" do |vb|
        vb.memory = "#{MEM_WORKER}"
        vb.cpus = "#{CPU_WORKER}"
    end
    node.vm.provision "shell", path: "scripts/node.sh", privileged: false
  end

  end
end 
