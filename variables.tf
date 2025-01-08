###################################################################################################
# ESXi Configuration Variables
###################################################################################################

variable "esxi_hostname" {
  description = "Hostname or IP address of the ESXi server."
  type        = string
}

variable "esxi_hostport" {
  description = "Port used for connecting to the ESXi server, typically 22 for SSH."
  type        = string
}

variable "esxi_hostssl" {
  description = "SSL port used for secure connections to the ESXi server, typically 443."
  type        = string
}

variable "esxi_username" {
  description = "Username for authenticating with the ESXi server."
  type        = string
}

variable "esxi_password" {
  description = "Password for authenticating with the ESXi server."
  type        = string
}

###################################################################################################
# vSphere Configuration Variables
###################################################################################################

variable "vsphere_user" {
  description = "Username for authenticating with the vSphere server."
  type        = string
}

variable "vsphere_password" {
  description = "Password for authenticating with the vSphere server. Set to sensitive for security."
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "IP address or hostname of the vSphere server."
  type        = string
}

variable "vsphere_datacenter" {
  description = "Name of the vSphere datacenter."
  type        = string
}

variable "vsphere_host" {
  description = "Name of the vSphere host."
  type        = string
}

variable "vsphere_datastores" {
  description = "List of datastore names to retrieve."
  type        = list(string)
}

###################################################################################################
# Network Configuration Variables
###################################################################################################

variable "vswitches" {
  description = "Configuration for vSwitches, including physical and logical interfaces."
  type = map(object({
    uplink            = bool
    uplink_name       = string
    promiscuous_mode  = bool
    mac_changes       = bool
    forged_transmits  = bool
  }))
}

variable "port_groups" {
  description = "Configuration for port groups, including VLAN IDs."
  type = map(object({
    vlan_id = string
  }))
}

# #########################################
# # VM Deployment Variables
# #########################################

variable "vm_configurations" {
  description = "List of VM configurations to deploy"
  type = list(object({
    vm_name              = string
    network_adapters     = map(string)
    datastore_name       = string
    remote_ova_file_path = string
    serial_conn = object({
      is_serial_required = bool
      serial_port        = optional(string)
    })
  }))
}

