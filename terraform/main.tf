terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

locals {
  cluster_name         = "${var.cluster_name}-${var.environment}"
  resource_group_name  = "${local.cluster_name}-rg"
  workspace_id         = var.enable_log_analytics ? azurerm_log_analytics_workspace.aks[0].id : null
  workspace_name       = var.enable_log_analytics ? azurerm_log_analytics_workspace.aks[0].name : null
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.cluster_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

# Subnet
resource "azurerm_subnet" "aks" {
  name                 = "${local.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}

# Network Security Group
resource "azurerm_network_security_group" "aks" {
  name                = "${local.cluster_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Log Analytics Workspace (optional)
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = "${local.cluster_name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# User-Assigned Managed Identity
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${local.cluster_name}-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                         = local.cluster_name
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  dns_prefix                   = local.cluster_name
  kubernetes_version           = var.kubernetes_version
  private_cluster_enabled      = var.enable_private_cluster

  default_node_pool {
    name                = "system"
    node_count          = var.enable_auto_scaling ? null : var.node_count
    min_count           = var.enable_auto_scaling ? var.min_node_count : null
    max_count           = var.enable_auto_scaling ? var.max_node_count : null
    vm_size             = var.vm_size
    os_disk_size_gb     = 30
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = var.enable_auto_scaling

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
  }

  oms_agent {
    log_analytics_workspace_id = local.workspace_id
  }

  role_based_access_control_enabled = true

  tags = merge(var.tags, {
    Environment = var.environment
  })

  depends_on = [azurerm_subnet_network_security_group_association.aks]
}

# Output kubeconfig for GitHub Actions
locals {
  kubeconfig = azurerm_kubernetes_cluster.aks.kube_config_raw
}
