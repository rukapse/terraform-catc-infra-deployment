
# ---------------------------------------------------------------------------------------------------------------------------------
# ESXi Resources
# ---------------------------------------------------------------------------------------------------------------------------------

# Define ESXi vswitch resources for each vswitch in the vswitches variable
resource "esxi_vswitch" "vswitch" {
  for_each = var.vswitches

  # Name of the vswitch
  name = each.key

  # Conditionally set uplink only if specified
  dynamic "uplink" {
    for_each = each.value.uplink ? [1] : []

    content {
      name = each.value.uplink_name
    }
  }

  # Security settings for the vswitch
  promiscuous_mode = each.value.promiscuous_mode
  mac_changes      = each.value.mac_changes
  forged_transmits = each.value.forged_transmits
}

# Define ESXi port group resources for each port group in the port_groups variable
resource "esxi_portgroup" "portgroup" {
  for_each = var.port_groups

  # Name of the port group
  name    = each.key
  # Associated vswitch
  vswitch = esxi_vswitch.vswitch[each.key].name

  # Conditionally set VLAN only if specified
  vlan = each.value.vlan_id != "" ? each.value.vlan_id : null
}

output "portgroup_names" {
  value = { for k, v in esxi_portgroup.portgroup : k => v.name }
}

# ---------------------------------------------------------------------------------------------------------------------------------
# vSphere Resources
# ---------------------------------------------------------------------------------------------------------------------------------

# Retrieve the vSphere datacenter
data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

# Retrieve the vSphere host within the datacenter
data "vsphere_host" "host" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# Retrieve the vSphere resource pool for the host
data "vsphere_resource_pool" "resource_pool" {
  name          = "${data.vsphere_host.host.name}/Resources/"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# Retrieve data for each datastore in the vsphere_datastores list
data "vsphere_datastore" "datastores" {
  for_each = toset(var.vsphere_datastores)

  name          = each.value
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# ---------------------------------------------------------------------------------------------------------------------------------
# Wait Condition - To complete dependent resources creation
# ---------------------------------------------------------------------------------------------------------------------------------

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 20"
  }

  depends_on = [
    esxi_portgroup.portgroup,
    esxi_vswitch.vswitch
  ]
}

# ---------------------------------------------------------------------------------------------------------------------------------
# VM Deployments
# ---------------------------------------------------------------------------------------------------------------------------------

# First, flatten the list of all network configurations for each VM
locals {
  flattened_networks = flatten([
    for config in var.vm_configurations : [
      for adapter_key, network_name in config.network_adapters : {
        vm_name = config.vm_name
        adapter_key = adapter_key
        network_name = network_name
      }
    ]
  ])
}

# Create a data source for each network using the flattened list
data "vsphere_network" "networks" {
  for_each = {
    for entry in local.flattened_networks : 
    "${entry.vm_name}_${entry.adapter_key}" => entry.network_name
  }

  name          = each.value
  datacenter_id = data.vsphere_datacenter.datacenter.id
  depends_on = [
    esxi_vswitch.vswitch,
    esxi_portgroup.portgroup,
    null_resource.delay
  ]
}

resource "vsphere_virtual_machine" "vm" {
  for_each = { for idx, config in var.vm_configurations : idx => config }

  name             = each.value.vm_name
  datacenter_id    = data.vsphere_datacenter.datacenter.id
  host_system_id   = data.vsphere_host.host.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool.id
  datastore_id     = data.vsphere_datastore.datastores[each.value.datastore_name].id

  ovf_deploy {
    remote_ovf_url    = lookup(each.value, "remote_ova_file_path", null)
    disk_provisioning = "thin"
  }

  dynamic "network_interface" {
    for_each = [for adapter_key, network_name in each.value.network_adapters : { key = adapter_key, network = network_name } if network_name != ""]

    content {
      network_id  = data.vsphere_network.networks["${each.value.vm_name}_${network_interface.value.key}"].id
      ovf_mapping = "Network adapter ${replace(network_interface.value.key, "adapter", "")}"
    }
  }

  # Add a CD-ROM device
  cdrom {
    client_device = true
  }

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  depends_on = [
    esxi_vswitch.vswitch,
    esxi_portgroup.portgroup
  ]
}

# ---------------------------------------------------------------------------------------------------------------------------------
# Add Serial Ports
# ---------------------------------------------------------------------------------------------------------------------------------

resource "null_resource" "manage_serial_port" {
  for_each = {
    for idx, config in var.vm_configurations : idx => config
    if config.serial_conn.is_serial_required
  }

  triggers = {
    vm_uuid = vsphere_virtual_machine.vm[each.key].id
  }

  provisioner "local-exec" {
    command = <<EOPS
  

      Function New-SerialPort {
          Param(
            [string]$vmName,
            [string]$prt
          )
        $dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $dev.operation = "add"
        $dev.device = New-Object VMware.Vim.VirtualSerialPort
        $dev.device.key = -1
        $dev.device.backing = New-Object VMware.Vim.VirtualSerialPortURIBackingInfo
        $dev.device.backing.direction = "server"
        $dev.device.backing.serviceURI = "telnet://:$prt"
        $dev.device.connectable = New-Object VMware.Vim.VirtualDeviceConnectInfo
        $dev.device.connectable.connected = $true
        $dev.device.connectable.StartConnected = $true
        $dev.device.yieldOnPoll = $true

        $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $spec.DeviceChange += $dev

        $vm = Get-VM -Name $vmName
        Stop-VM $VM -Confirm:$False
        $vm.ExtensionData.ReconfigVM($spec)
        Start-VM $VM -Confirm:$False
      }

      # Enable verbose output
      $VerbosePreference = "Continue"

      # Ignore SSL Certificate warnings
      Write-Host "Configuring PowerCLI to ignore SSL warnings..."
      Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

      # Connect to vSphere
      Write-Host "Connecting to vSphere server at ${var.vsphere_server}..."
      Connect-VIServer -Server ${var.vsphere_server} -User ${var.vsphere_user} -Password ${var.vsphere_password}

      # Add the serial port
      Write-Host "Adding the serial port"
      New-SerialPort "${each.value.vm_name}" "${each.value.serial_conn.serial_port}"

      # Example script to set serial port as console (depends on the guest OS and its capabilities)
      Write-Host "Setting serial port as console (if applicable)..."
      Invoke-VMScript -VM $vm -ScriptText "Set-SerialPortAsConsole" -GuestCredential (Get-Credential)

      # Disconnect from vSphere
      Disconnect-VIServer -Confirm:$false
    EOPS
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    vsphere_virtual_machine.vm
  ]
}