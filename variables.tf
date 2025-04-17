// --------------------------
// -- Scaleway related vars
// --------------------------

variable "scw_project_id" {
    type = string
    description = "Scaleway Project Identifier"
}

variable "scw_instance_type" {
    type = string
    description = "Scalewat Instance type to create"
    default = "DEV1-M"
}

variable "scw_persistent_data_name" {
    type = string
    description = "Scaleway Persistant Storage Snapshot name"
    default = "devbox-persistent-snapshot"
}

// --------------------------
// -- Tailscale related vars
// --------------------------

variable "tailscale_client_id" {
    type = string
    sensitive = true
    description = "Tailscale OAuth Client ID - required auth_keys scope access"
}

variable "tailscale_client_secret" {
    type = string
    sensitive = true
    description = "Tailscale OAuth Client Secret"
}

variable "tailscale_host_tags" {
    type = list(string)
    description = "Tailscale Tags to apply to the host"
    default = []
}

variable "tailscale_host_hostname" {
    type = string
    description = "Tailnet and system hostname to use"
    default = "devbox"
}


// --------------------------
// -- Misc other vars
// --------------------------

variable "persistent_data_key" {
    type = string
    sensitive = true
    description = "Crypt LUKS key used to format and unlock the persisten storage"
}

variable "persistent_data_user" {
    type = string
    description = "Name of the default non-root user to which the persistent storage data belongs"
}

