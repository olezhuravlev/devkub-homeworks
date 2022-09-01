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
resource "yandex_resourcemanager_folder" "netology-folder" {
  cloud_id    = var.yandex-cloud-id
  name        = "netology-folder-${terraform.workspace}"
  description = "Netology test folder"
}

# Create service account.
#resource "yandex_iam_service_account" "terraform-netology-sa" {
#  folder_id   = yandex_resourcemanager_folder.netology-folder.id
#  name        = "terraform-netology-sa-${terraform.workspace}"
#  description = "Service account to be used by Terraform"
#}

# Grant permission "container-registry" on folder "yandex-folder-id" for service account.
#resource "yandex_resourcemanager_folder_iam_member" "terraform-netology-storage-editor" {
#  folder_id = yandex_resourcemanager_folder.netology-folder.id
#  role      = "container-registry.admin"
#  member    = "serviceAccount:${yandex_iam_service_account.terraform-netology-sa.id}"
#}

# Create Static Access Keys
#resource "yandex_iam_service_account_static_access_key" "terraform-sa-static-key" {
#  service_account_id = yandex_iam_service_account.terraform-netology-sa.id
#  description        = "Static access key for service account"
#}

# Use keys to create bucket
#resource "yandex_storage_bucket" "netology-bucket" {
#  access_key = yandex_iam_service_account_static_access_key.terraform-sa-static-key.access_key
#  secret_key = yandex_iam_service_account_static_access_key.terraform-sa-static-key.secret_key
#  bucket     = "netology-bucket-${terraform.workspace}"
#  grant {
#    id          = yandex_iam_service_account.terraform-netology-sa.id
#    type        = "CanonicalUser"
#    permissions = ["READ", "WRITE"]
#  }
#}

# Network.
resource "yandex_vpc_network" "netology-network" {
  folder_id   = yandex_resourcemanager_folder.netology-folder.id
  name        = "netology-network"
  description = "Netology network"
}

# Subnets of the network.
resource "yandex_vpc_subnet" "netology-subnet" {
  folder_id      = yandex_resourcemanager_folder.netology-folder.id
  name           = "netology-subnet-0"
  description    = "Netology subnet 0"
  v4_cidr_blocks = ["10.100.0.0/24"]
  zone           = var.yandex-cloud-zone
  network_id     = yandex_vpc_network.netology-network.id
}

#resource "yandex_vpc_security_group" "nodes-ssh-access" {
#
#  name        = "redis-nodes-ssh-access"
#  description = "Connection via SSH. Should be applied only to group of nodes."
#  folder_id   = yandex_resourcemanager_folder.netology-folder.id
#  network_id  = yandex_vpc_network.netology-network.id
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
  folder_id      = yandex_resourcemanager_folder.netology-folder.id
  subnet_id      = yandex_vpc_subnet.netology-subnet.id
  #sec_group_id   = yandex_vpc_security_group.nodes-ssh-access.id
  cores          = local.cores[terraform.workspace]
  boot_disk_size = local.boot_disk_size["container_optimized"]

  image_family = "container-optimized-image"
  users        = "ubuntu"

  # for_each      = toset(["vm-01"])
  for_each      = toset(["vm-01", "vm-02", "vm-03"])
  instance_name = "${each.key}"
  nat           = true
}

locals {
  cores = {
    default = 2
  }
  boot_disk_size = {
    default             = 20
    container_optimized = 30
  }
}
