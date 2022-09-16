# Base Terraform definition.
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

# Define provider.
provider "yandex" {
  cloud_id = var.yandex-cloud-id
  zone     = var.yandex-cloud-zone
}

# Create folder.
resource "yandex_resourcemanager_folder" "kubernetes-folder" {
  cloud_id    = var.yandex-cloud-id
  name        = "kubernetes-folder"
  description = "Kubernetes cluster folder"
}

# Create service account.
#resource "yandex_iam_service_account" "kubernetes-iam-sa" {
#  folder_id   = yandex_resourcemanager_folder.kubernetes-folder.id
#  name        = "kubernetes-iam-sa-${terraform.workspace}"
#  description = "Service account to be used by Terraform"
#}

# Grant permission "container-registry" on folder "yandex-folder-id" for service account.
#resource "yandex_resourcemanager_folder_iam_member" "iam-member-storage-editor" {
#  folder_id = yandex_resourcemanager_folder.kubernetes-folder.id
#  role      = "container-registry.admin"
#  member    = "serviceAccount:${yandex_iam_service_account.kubernetes-iam-sa.id}"
#}

# Create Static Access Keys
#resource "yandex_iam_service_account_static_access_key" "terraform-sa-static-key" {
#  service_account_id = yandex_iam_service_account.kubernetes-iam-sa.id
#  description        = "Static access key for service account"
#}

# Use keys to create bucket
#resource "yandex_storage_bucket" "kubernetes-bucket" {
#  access_key = yandex_iam_service_account_static_access_key.terraform-sa-static-key.access_key
#  secret_key = yandex_iam_service_account_static_access_key.terraform-sa-static-key.secret_key
#  bucket     = "kubernetes-bucket-${terraform.workspace}"
#  grant {
#    id          = yandex_iam_service_account.kubernetes-iam-sa.id
#    type        = "CanonicalUser"
#    permissions = ["READ", "WRITE"]
#  }
#}

# Network.
resource "yandex_vpc_network" "kubernetes-network" {
  folder_id   = yandex_resourcemanager_folder.kubernetes-folder.id
  name        = "kubernetes-net"
  description = "Kubernetes cluster network"
}

# Subnets of the network.
resource "yandex_vpc_subnet" "kubernetes-subnet" {
  folder_id      = yandex_resourcemanager_folder.kubernetes-folder.id
  name           = "kubernetes-subnet"
  description    = "Default Kubernetes cluster subnet"
  v4_cidr_blocks = [var.ipv4_cidr_blocks]
  zone           = var.yandex-cloud-zone
  network_id     = yandex_vpc_network.kubernetes-network.id
}

#resource "yandex_vpc_security_group" "nodes-ssh-access" {
#
#  name        = "redis-nodes-ssh-access"
#  description = "Connection via SSH. Should be applied only to group of nodes."
#  folder_id   = yandex_resourcemanager_folder.kubernetes-folder.id
#  network_id  = yandex_vpc_network.kubernetes-network.id
#
#  ingress {
#    protocol       = "TCP"
#    description    = "Allow connection via SSH from designated nodes."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    port           = 22
#  }
#
#  ingress {
#    protocol       = "ANY"
#    description    = "Redis Cluster client connections."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    port           = 6379
#  }
#
#  ingress {
#    protocol       = "ANY"
#    description    = "Redis Cluster bus connections."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    port           = 16379
#  }

#  ingress {
#    protocol       = "ANY"
#    description    = "All incoming traffic allowed."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    from_port      = 0
#    to_port        = 65535
#  }
#
#  egress {
#    protocol       = "ANY"
#    description    = "All outgoing traffic allowed."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    from_port      = 0
#    to_port        = 65535
#  }
#}

module "vm-for-each" {

  source         = "./modules/instance"
  folder_id      = yandex_resourcemanager_folder.kubernetes-folder.id
  subnet_id      = yandex_vpc_subnet.kubernetes-subnet.id
  #sec_group_id   = yandex_vpc_security_group.nodes-ssh-access.id
  cores          = local.cores["${each.key}"]
  memory         = local.memory["${each.key}"]
  boot_disk_size = local.boot_disk_size["${each.key}"]
  boot_disk_type = "network-hdd"

  image_family = "ubuntu-2004-lts"
  users        = "ubuntu"

  #for_each      = toset(["cp1"])
  #for_each      = toset(["cp1", "node1"])
  #for_each      = toset(["cp1", "node1", "node2"])
  for_each      = toset(["cp1", "node1", "node2", "node3", "node4"])
  instance_name = "${each.key}"
  nat           = true
  ipv4_internal = local.ipv4_internals["${each.key}"]
}

locals {

  # CPU total 32 max!
  cores = {
    cp1   = 4
    node1 = 2
    node2 = 2
    node3 = 2
    node4 = 2
  }

  # RAM total 128Gb max!
  memory = {
    cp1   = 4
    node1 = 2
    node2 = 2
    node3 = 2
    node4 = 2
  }

  # HDD total 500Gb max!
  boot_disk_size = {
    cp1   = 51
    node1 = 51
    node2 = 51
    node3 = 51
    node4 = 51
  }

  ipv4_internals = {
    cp1   = "10.128.10.1"
    node1 = "10.128.20.1"
    node2 = "10.128.20.2"
    node3 = "10.128.20.3"
    node4 = "10.128.20.4"
  }
}
