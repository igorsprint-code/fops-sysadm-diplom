data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}


# ВМ-бастион

resource "yandex_compute_instance" "bastion" {
  name        = "bastion" 
  hostname    = "bastion" 
  platform_id = "standard-v3"
  zone        = "ru-central1-a" 

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.project_a.id 
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id]
  }
}


# ВМ-web-сервер 1


resource "yandex_compute_instance" "web_1" {
  name        = "web-1" 
  hostname    = "web-1" 
  platform_id = "standard-v3"
  zone        = "ru-central1-a" 


  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.project_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_fw.id]
  }
}

# ВМ-web-сервер 2


resource "yandex_compute_instance" "web_2" {
  name        = "web-2" 
  hostname    = "web-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.project_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_fw.id]

  }
}




# prometheus server

resource "yandex_compute_instance" "prometheus_vm" {
  name        = "prometheus" 
  hostname    = "prometheus" 
  platform_id = "standard-v3"
  zone        = "ru-central1-a" 

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.project_a.id 
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id]
  }
}



# Grafana server

# resource "yandex_compute_instance" "grafana_vm" {
#   name        = "grafana" 
#   hostname    = "grafana" 
#   platform_id = "standard-v3"
#   zone        = "ru-central1-a" 

#   resources {
#     cores         = 2
#     memory        = 1
#     core_fraction = 20
#   }

#   boot_disk {
#     initialize_params {
#       image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
#       type     = "network-hdd"
#       size     = 10
#     }
#   }

#   metadata = {
#     user-data          = file("./cloud-init.yml")
#     serial-port-enable = 1
#   }

#   scheduling_policy { preemptible = true }

#   network_interface {
#     subnet_id          = yandex_vpc_subnet.project_a.id 
#     nat                = true
#     security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.grafana.id]
#   }
# }




resource "local_file" "inventory" {
  content  = <<-XYZ
  [bastion]
  ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

  [prometheus_server]
  ${yandex_compute_instance.prometheus_vm.network_interface.0.ip_address}
  [prometheus_server:vars]
  ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'

 

  [webservers]
  ${yandex_compute_instance.web_1.network_interface.0.ip_address}
  ${yandex_compute_instance.web_2.network_interface.0.ip_address}
  [webservers:vars]
  ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
  XYZ
  filename = "../ansible/hosts.ini"
}