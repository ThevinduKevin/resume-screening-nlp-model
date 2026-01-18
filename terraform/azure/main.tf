terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"  # Use stable 3.x version to avoid 4.x bugs
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "ml-benchmark-rg"
  location = var.location

  timeouts {
    create = "10m"
    delete = "30m"
  }
}

# Wait for resource group to fully propagate in Azure API
resource "time_sleep" "wait_for_rg" {
  depends_on      = [azurerm_resource_group.rg]
  create_duration = "30s"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ml-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [time_sleep.wait_for_rg]

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# Wait for VNet to fully propagate
resource "time_sleep" "wait_for_vnet" {
  depends_on      = [azurerm_virtual_network.vnet]
  create_duration = "15s"
}

resource "azurerm_subnet" "subnet" {
  name                 = "ml-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [time_sleep.wait_for_vnet]

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "azurerm_public_ip" "ip" {
  name                = "ml-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [time_sleep.wait_for_rg]

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "ml-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ML-API"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [time_sleep.wait_for_rg]

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "ml-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "ml-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(file("${path.module}/startup.sh"))

  timeouts {
    create = "30m"
    delete = "30m"
  }
}
