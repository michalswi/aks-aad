
variable "client_id" {}
variable "client_secret" {}

# Active Directory related
variable "tenant_id" {}
variable "rbac_server_app_id" {}
variable "rbac_server_app_secret" {}
variable "rbac_client_app_id" {}
# 

variable rg_name {
    default = "aadk8srg"
}

variable location {
    default = "westeurope"
}

variable "dns_prefix" {
    default = "aadk8s"
}

variable cluster_name {
    default = "aadk8s"
}

variable "agent_count" {
    default = 1
}

variable "kubernetes_version" {
  default = "1.15.10"
}
