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