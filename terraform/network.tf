# Сеть для нашей инфраструктуры

resource "yandex_vpc_network" "project_net" {
  name = "my_net"
}

# Подсеть в регионе а 

resource "yandex_vpc_subnet" "project_a" {
  name           = "my_subnet_ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.project_net.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

# Подсеть в регионе b 

resource "yandex_vpc_subnet" "project_b" {
  name           = "my_subnet_ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.project_net.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

# Шлюз для выхода в интернет

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "gateway"
  shared_egress_gateway {}
}

# Сетевой маршрут для выхода в интернет через шлюз

resource "yandex_vpc_route_table" "rt" {
  name       = "my-route-table"
  network_id = yandex_vpc_network.project_net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}


# Группы безопасности(firewall)


# FW для бастион-сервера

resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion"
  network_id = yandex_vpc_network.project_net.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

# FW для облачной сети

resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN"
  network_id = yandex_vpc_network.project_net.id
  ingress {
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}


# FW для web серверов

resource "yandex_vpc_security_group" "web_fw" {
  name       = "web_fw"
  network_id = yandex_vpc_network.project_net.id


  ingress {
    description    = "Allow HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }


}


# FW для Prometheus

resource "yandex_vpc_security_group" "prometheus" {
  name       = "prometheus_vm"
  network_id = yandex_vpc_network.project_net.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}


# FW для Grafana

resource "yandex_vpc_security_group" "grafana" {
  name       = "grafana_vm"
  network_id = yandex_vpc_network.project_net.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}









