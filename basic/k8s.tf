
resource "azurerm_resource_group" "k8s" {
    name     = var.rg_name
    location = var.location
}

resource "azurerm_kubernetes_cluster" "k8s" {
    name                = var.cluster_name
    location            = azurerm_resource_group.k8s.location
    resource_group_name = azurerm_resource_group.k8s.name
    dns_prefix          = var.dns_prefix
    kubernetes_version  = var.kubernetes_version

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_B2s"
    }

    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }

    tags = {
        Environment = "Development"
    }

    # Active Directory related
    role_based_access_control {
        enabled = true
        azure_active_directory {
            server_app_id     = var.rbac_server_app_id
            server_app_secret = var.rbac_server_app_secret
            client_app_id     = var.rbac_client_app_id
            tenant_id         = var.tenant_id
        }
    }    
    #
}