resource "yandex_vpc_network" "infra_network" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "infra_subnet" {
  count          = length(var.net_cidr)
  name           = var.net_cidr[count.index].name
  zone           = var.net_cidr[count.index].zone
  v4_cidr_blocks = [var.net_cidr[count.index].prefix]
  network_id     = yandex_vpc_network.infra_network.id
}

resource "yandex_vpc_security_group" "infra_sg" {
  name       = "${var.vpc_name}-sg"
  network_id = yandex_vpc_network.infra_network.id

  egress {
    description    = "Allow all outbound traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow SSH access"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow Kittygram gateway HTTP access"
    protocol       = "TCP"
    port           = var.gateway_port
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
