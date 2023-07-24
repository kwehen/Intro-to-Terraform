resource "azurerm_resource_group" "test-rg" {
  name     = "test-resources"
  location = "East Us"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "test-vnet" {
  name                = "test-vnet"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "test-subnet" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.test-rg.name
  virtual_network_name = azurerm_virtual_network.test-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "test-private-subnet" {
  name                 = "test-priv-subnet"
  resource_group_name  = azurerm_resource_group.test-rg.name
  virtual_network_name = azurerm_virtual_network.test-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "test-sg" {
  name                = "test-sg1"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "test-sg-rule-1" {
  name                        = "test-sq-rule-1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "75.15.184.198/32"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.test-rg.name
  network_security_group_name = azurerm_network_security_group.test-sg.name
}

resource "azurerm_network_security_group" "test-sg2" {
  name                = "test-sg2"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "web_rule" {
  name                        = "test-sq-rule-2"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.test-rg.name
  network_security_group_name = azurerm_network_security_group.test-sg2.name
}

resource "azurerm_network_security_rule" "management_rule" {
  name                        = "test-sq-rule-3"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = ["home.ip.address", "10.0.0.0/16"]
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.test-rg.name
  network_security_group_name = azurerm_network_security_group.test-sg2.name
}

resource "azurerm_subnet_network_security_group_association" "test-sg-assoc" {
  subnet_id                 = azurerm_subnet.test-subnet.id
  network_security_group_id = azurerm_network_security_group.test-sg.id
}

resource "azurerm_subnet_network_security_group_association" "priv-sg-assoc" {
  subnet_id                 = azurerm_subnet.test-private-subnet.id
  network_security_group_id = azurerm_network_security_group.test-sg2.id
}

resource "azurerm_public_ip" "test-ip" {
  name                = "test-ip"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_public_ip" "load-pub-ip" {
  name                = "load-pub-ip"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "test-nic" {
  name                = "test-nic"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name

  ip_configuration {
    name                          = "dev-test"
    subnet_id                     = azurerm_subnet.test-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "test-int-nic1" {
  name                = "test-int-nic1"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name

  ip_configuration {
    name                          = "dev-test1"
    subnet_id                     = azurerm_subnet.test-private-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "test-int-nic2" {
  name                = "test-int-nic2"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name

  ip_configuration {
    name                          = "dev-test2"
    subnet_id                     = azurerm_subnet.test-private-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_linux_virtual_machine" "test-vm" {
  name                = "test-vm"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.test-nic.id,
  ]

  custom_data = filebase64("customerdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tf-azure-key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("ssh-config.tpl", {
      hostname     = self.public_ip_address
      user         = "adminuser"
      identityfile = "~/.ssh/tf-azure-key"
    })
    interpreter = ["bash", "-c"]
  }
}

resource "azurerm_linux_virtual_machine" "test-vm-priv1" {
  name                = "test-vm-priv1"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.test-int-nic1.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tf-azure-key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "test-vm-priv2" {
  name                = "test-vm-priv2"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.test-int-nic2.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tf-azure-key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_availability_set" "test-set" {
  name = "test-set"
  location = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
  platform_fault_domain_count = 3
  platform_update_domain_count = 3
}

resource "azurerm_lb" "test-load-bal" {
  name                = "test-load-bal"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "front-pub-addr"
    public_ip_address_id = azurerm_public_ip.load-pub-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "Pool1" {
  loadbalancer_id = azurerm_lb.test-load-bal.id
  name            = "Pool1"
}

resource "azurerm_lb_backend_address_pool_address" "test-priv1" {
  name                    = "test-priv1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.Pool1.id
  virtual_network_id      = azurerm_virtual_network.test-vnet.id
  ip_address              = azurerm_network_interface.test-int-nic1.private_ip_address
}

resource "azurerm_lb_backend_address_pool_address" "test-priv2" {
  name                    = "test-priv2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.Pool1.id
  virtual_network_id      = azurerm_virtual_network.test-vnet.id
  ip_address              = azurerm_network_interface.test-int-nic2.private_ip_address
}

resource "azurerm_lb_probe" "test-lb-probe" {
  loadbalancer_id = azurerm_lb.test-load-bal.id
  name            = "Probe1"
  port            = 80
}

resource "azurerm_lb_rule" "LB-Rule1" {
  loadbalancer_id                = azurerm_lb.test-load-bal.id
  name                           = "LB-Rule1"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "front-pub-addr"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.Pool1.id]
  probe_id = azurerm_lb_probe.test-lb-probe.id
}
