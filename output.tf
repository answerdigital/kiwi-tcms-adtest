output "kiwi_ip" {
  value = module.kiwi_tcms.instance_public_ip_address
}

output "kiwi_private_key" {
  value     = module.kiwi_tcms.private_key
  sensitive = true
}

output "itertools_ip" {
  value = module.it_tools.instance_public_ip_address
}

output "itertools_private_key" {
  value     = module.it_tools.private_key
  sensitive = true
}

output "sorrycypress_ip" {
  value = module.sorry_cypress.instance_public_ip_address
}

output "sorrycypress_key" {
  value     = module.sorry_cypress.private_key
  sensitive = true
}