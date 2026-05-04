variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud availability zone for the VM"
  type        = string
  default     = "ru-central1-a"
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
  default     = "kittygram-network"
}

variable "net_cidr" {
  description = "Subnets to create in the VPC"
  type = list(object({
    name   = string
    zone   = string
    prefix = string
  }))
  default = [
    { name = "kittygram-subnet-a", zone = "ru-central1-a", prefix = "10.129.1.0/24" },
    { name = "kittygram-subnet-b", zone = "ru-central1-b", prefix = "10.130.1.0/24" },
    { name = "kittygram-subnet-d", zone = "ru-central1-d", prefix = "10.131.1.0/24" },
  ]
}

variable "vm_1_name" {
  description = "Compute instance name"
  type        = string
  default     = "vm-kittygram"
}

variable "platform_id" {
  description = "Yandex Compute platform ID"
  type        = string
  default     = "standard-v3"
}

variable "image_family" {
  description = "Boot image family"
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "cores" {
  description = "Number of vCPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM size in GB"
  type        = number
  default     = 4
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "network-ssd"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 40
}

variable "nat" {
  description = "Attach public IP address to the VM"
  type        = bool
  default     = true
}

variable "ssh_user" {
  description = "Linux user created by cloud-init"
  type        = string
  default     = "user"
}

variable "ssh_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "gateway_port" {
  description = "Public HTTP port of the gateway service"
  type        = number
  default     = 8080
}
