output "vm_1_name" {
  description = "Created VM name"
  value       = yandex_compute_instance.vm_1.name
}

output "vm_1_address" {
  description = "Public IPv4 address of the VM"
  value       = yandex_compute_instance.vm_1.network_interface[0].nat_ip_address
}

output "kittygram_url" {
  description = "Kittygram URL for tests.yml"
  value       = "http://${yandex_compute_instance.vm_1.network_interface[0].nat_ip_address}:${var.gateway_port}"
}

output "ssh_command" {
  description = "SSH command for connecting to the VM"
  value       = "ssh ${var.ssh_user}@${yandex_compute_instance.vm_1.network_interface[0].nat_ip_address}"
}
