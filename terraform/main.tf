terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}


provider "scaleway" {
  access_key      = var.access_key
  secret_key      = var.secret_key
  organization_id = var.organization_id
  project_id      = var.project_id
}


resource "scaleway_vpc" "this" {
  name = format("${local.name}-vpc-%s", var.env)
  tags = local.tags
}

resource "scaleway_vpc_private_network" "this" {
  name   = format("${local.name}-pn-%s", var.env)
  vpc_id = scaleway_vpc.this.id

  tags = local.tags
}

resource "scaleway_instance_ip" "public_ip" {}

resource "scaleway_instance_server" "app" {
  name        = "app-instance"
  image       = "ubuntu_jammy"
  type        = "DEV1-S"
  tags        = ["demo"]
  zone        = var.scaleway_zone
  ip_id = scaleway_instance_ip.public_ip.id
  root_volume {
    size_in_gb = 20
  }
  private_network {
    pn_id = scaleway_vpc_private_network.this.id
  }
  provisioner "remote-exec" {
    inline = [
      "apt-get update -y",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.private_key_path)
      host        = self.public_ips[0].address
    }
  }
}
resource "scaleway_registry_namespace" "app" {
  name        = "app-registry"
  description = "App container registry"
  is_public   = false
}

resource "scaleway_lb_ip" "v4" {
}
resource "scaleway_lb_ip" "v6" {
  is_ipv6 = true
}
resource "scaleway_lb" "app" {
  ip_ids = [scaleway_lb_ip.v4.id]
  name   = "app"
  type   = "LB-S"
  private_network {
    private_network_id = scaleway_vpc_private_network.this.id
  }
}

resource "scaleway_lb_backend" "backend01" {
  lb_id            = scaleway_lb.app.id
  name             = "backend01"
  forward_protocol = "http"
  forward_port     = "80"
  server_ips = [ scaleway_instance_ip.public_ip.address ]
}

# resource scaleway_lb_certificate cert01 {
  # lb_id = scaleway_lb.app.id
  # name  = "test-cert-front-end"
  # letsencrypt {
    # common_name = "${replace(scaleway_lb_ip.v4.ip_address, ".", "-")}.lb.${scaleway_lb.app.region}.scw.cloud"
  # }
  # Make sure the new certificate is created before the old one can be replaced
  # lifecycle {
    # create_before_destroy = true
  # }
# }
# resource scaleway_lb_frontend frt01 {
  # lb_id           = scaleway_lb.lb01.id
  # backend_id      = scaleway_lb_backend.bkd01.id
  # inbound_port    = 443
  # certificate_ids = [scaleway_lb_certificate.cert01.id]
# }
resource "scaleway_lb_frontend" "frontend01" {
  lb_id        = scaleway_lb.app.id
  backend_id   = scaleway_lb_backend.backend01.id
  name         = "frontend01"
  inbound_port = "80"
}

resource "local_file" "ansible_inventory" {
  content = <<EOF
[app]
${scaleway_instance_server.app.public_ips[0].address} ansible_user=root ansible_ssh_private_key_file=${var.private_key_path}
EOF

  filename = "${path.module}/../ansible/inventory.ini"
}

output "instance_ip" {
  value = scaleway_instance_server.app.public_ips[0].address
}

output "registry_endpoint" {
  value = scaleway_registry_namespace.app.endpoint
}

output "lb_ip" {
  value = scaleway_lb.app.private_ips[0].address
}

output "instance_volume_id" {
  value = scaleway_instance_server.app.root_volume[0].volume_id
}