terraform {
  required_providers {
    scaleway = {
        source = "scaleway/scaleway"
    }

    tailscale = {
        source = "tailscale/tailscale"
        version = "0.19.0"
    } 
  }

  required_version = ">= 0.13.0"
}

// --------------------------
// -- provider setup
// --------------------------

provider "scaleway" {
  // using the defaults from .config/scw/config.yaml
  project_id = var.scw_project_id
}

provider "tailscale" {
  oauth_client_id = var.tailscale_client_id
  oauth_client_secret = var.tailscale_client_secret
  scopes = [ "auth_keys" ]
}

// --------------------------
// -- datasources
// --------------------------

data "scaleway_block_snapshot" "persistent_data" {
  // this is a snapshot of the persistent data volume
  // and has to be created before the first terraform usage.
  // it's fine to create a dummy block volume and take an empty snapshot!
  name = var.scw_persistent_data_name
}

// --------------------------
// -- resources managed by terraform
// --------------------------

resource "tailscale_tailnet_key" "pre_auth" {
  // create an ephemeral auth-key for our tailnet
  reusable = false
  ephemeral = true
  preauthorized = true
  expiry = 300

  description = "${var.tailscale_host_hostname} terraform ephemeral auth"
  tags = var.tailscale_host_tags
}

resource "scaleway_block_volume" "persistent_data" {
  iops = 5000
  snapshot_id = data.scaleway_block_snapshot.persistent_data.id
}

resource "scaleway_instance_security_group" "fw1" {
  inbound_default_policy = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    port = 41641
    protocol = "UDP"
    action = "accept"
  }
}

resource "scaleway_instance_server" "devbox" {
  type = var.scw_instance_type
  image = "ubuntu_noble"
  
  tags = [ "terraform", "ephemeral" ]

  root_volume {
    size_in_gb = 14
  }

  additional_volume_ids = [
    scaleway_block_volume.persistent_data.id
  ]

  enable_dynamic_ip = true

  zone = scaleway_block_volume.persistent_data.zone

  security_group_id = scaleway_instance_security_group.fw1.id

  user_data = {
    cloud-init = templatefile("${path.module}/cloud-init.yaml", {
      tailscale_auth_key = tailscale_tailnet_key.pre_auth.key
      tailscale_hostname = var.tailscale_host_hostname
      devbox_user        = var.persistent_data_user
      crypt_home_key     = var.persistent_data_key
    })
  }
}

// cleanup to update the persistent snapshot
resource "null_resource" "snapshot_update" {
  triggers = {
    volume        = scaleway_block_volume.persistent_data.id
    snapshot_id   = data.scaleway_block_snapshot.persistent_data.id
    snapshot_name = var.scw_persistent_data_name
  }

  depends_on = [ scaleway_block_volume.persistent_data ]

  provisioner "local-exec" {
    // remove the old snaphot
    when = destroy
    command = "scw block snapshot delete $SCW_SNAPSHOT_ID"
    environment = {
      SCW_SNAPSHOT_ID = split("/", self.triggers.snapshot_id)[1]
    }
  }

  provisioner "local-exec" {
    // create a fresh snapshot with the same name and wait for it to be stable
    when = destroy
    command = "scw block snapshot wait $(scw block snapshot create volume-id=$SCW_VOLUME_ID name=$SCW_SNAPSHOT_NAME | awk '/^ID/{ print $2 }')"
    environment = {
      SCW_VOLUME_ID = split("/", self.triggers.volume)[1]
      SCW_SNAPSHOT_NAME = self.triggers.snapshot_name
    }
  }
}
