###################################################################################################
# ESXi Configuration Variables
###################################################################################################

esxi_hostname = ""
esxi_hostport = "22"
esxi_hostssl = "443"
esxi_username = ""
esxi_password = ""


###################################################################################################
# vSphere Configuration Variables
###################################################################################################

vsphere_user        = ""
vsphere_password    = ""
vsphere_server      = ""
vsphere_datacenter  = ""
vsphere_host        = ""
vsphere_datastores = ["DS1", "DS2", "DS3"]

###################################################################################################
# Network Configuration Variables
###################################################################################################

# vswitches
vswitches =  {
    ## Physical Interfaces
    "CATC-ISE-to-FUSION" = { uplink = true, uplink_name = "vmnic2", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "FUSION-to-TRANSIT"  = { uplink = true, uplink_name = "vmnic3", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "FUSION-to-SJ-FIAB"  = { uplink = true, uplink_name = "vmnic4", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "FUSION-to-NY-FIAB"  = { uplink = true, uplink_name = "vmnic5", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "FUSION-to-SJ-WLC"   = { uplink = true, uplink_name = "vmnic6", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "FUSION-to-NY-WLC"   = { uplink = true, uplink_name = "vmnic7", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    
    ## Logical Interfaces
    "SJ-FIAB-to-TRANSIT" = { uplink = false, uplink_name = "", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "TRANSIT-to-NY-FIAB" = { uplink = false, uplink_name = "", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "SJ-FIAB-to-WSIM"    = { uplink = false, uplink_name = "", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
    "NY-FIAB-to-WSIM"    = { uplink = false, uplink_name = "", promiscuous_mode = true, mac_changes = true, forged_transmits = true }
  }

# port groups
port_groups = {
    ## Physical Interfaces
    "CATC-ISE-to-FUSION" = { vlan_id = "" }
    "FUSION-to-TRANSIT"  = { vlan_id = "" }
    "FUSION-to-SJ-FIAB"  = { vlan_id = "4095" }
    "FUSION-to-NY-FIAB"  = { vlan_id = "4095" }
    "FUSION-to-SJ-WLC"   = { vlan_id = "4095" }
    "FUSION-to-NY-WLC"   = { vlan_id = "4095" }

    ## Logical Interfaces
    "SJ-FIAB-to-TRANSIT" = { vlan_id = "" }
    "TRANSIT-to-NY-FIAB" = { vlan_id = "" }
    "SJ-FIAB-to-WSIM"    = { vlan_id = "4095" }
    "NY-FIAB-to-WSIM"    = { vlan_id = "4095" }
  }


vm_configurations = [
    {
      vm_name              = "Catalyst-Center"
      network_adapters     = { "adapter1" = "CATC-ISE-to-FUSION", "adapter2" = "VM Network"}
      datastore_name       = "DS3"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "false"}
    },
    {
      vm_name              = "ISE"
      network_adapters     = { "adapter1" = "VM Network", "adapter2" = "CATC-ISE-to-FUSION"}
      datastore_name       = "DS2"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "false"}
    },
    {
      vm_name              = "SJ-FIAB"
      network_adapters     = { "adapter1" = "VM Network", "adapter2" = "FUSION-to-SJ-FIAB", "adapter3" = "SJ-FIAB-to-TRANSIT", "adapter4" = "SJ-FIAB-to-WSIM" }
      datastore_name       = "DS2"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "true", "serial_port" = "2002"}
    },
    {
      vm_name              = "NY-FIAB"
      network_adapters     = { "adapter1" = "VM Network", "adapter2" = "FUSION-to-NY-FIAB", "adapter3" = "TRANSIT-to-NY-FIAB" }
      datastore_name       = "DS2"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "true", "serial_port" = "2003"}
    },
    {
      vm_name              = "TRANSIT"
      network_adapters     = { "adapter1" = "FUSION-to-TRANSIT", "adapter2" = "SJ-FIAB-to-TRANSIT", "adapter3" = "TRANSIT-to-NY-FIAB"}
      datastore_name       = "DS2"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "true", "serial_port" = "2004"}
    },
    {
      vm_name              = "SJ-WLC"
      network_adapters     = { "adapter1" = "FUSION-to-SJ-WLC"}
      datastore_name       = "DS2"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "true", "serial_port" = "2005"}
    },
    {
      vm_name              = "NY-WLC"
      network_adapters     = { "adapter1" = "FUSION-to-NY-WLC"}
      datastore_name       = "DS2"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "true", "serial_port" = "2006"}
    },
    {
      vm_name              = "SJ-WSIM"
      network_adapters     = { "adapter1" = "VM Network", "adapter2" = "SJ-FIAB-to-WSIM"}
      datastore_name       = "DS2"
      remote_ova_file_path = ""
      serial_conn         = {"is_serial_required" = "false"}
    },
  ]
 