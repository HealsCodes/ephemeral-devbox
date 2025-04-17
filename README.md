## Ephemeral DevBox with persistent $HOME on Scaleway + terraform + Tailscale

This little toy repo implements an ephemeral development system with a peristent,
encrypted $HOME and secure access via Tailscale.

I built it as a more flexible alternative to GitPod / CodeSpaces since a good deal
of the time I might have my iPad around but not my MacBook and having access (mosh/ssh/vscode-tunnel!)
to a full fleged linux system while on-the-go withough having to permanantly rent
a server and creating only monthly costs in the <1ct range if unused seemed like a fun idea.


### Prerequisites
- Accounts:
  - Scaleway
  - Tailscale

- Local tools:
  - scaleway-cli
  - terraform / opentofu

- Credentials:
  - Scaleway API-Key/Secret
  - Tailscale OAuth-Client Key/Secret with "auth_keys" scope

#### Checkout prep
After cloning the repositoty you neeed to initialise terraform once:

`terraform init`

Next, rename `terraform.tfvars.example` to `terraform.tfvars` and ajust the values to match your setup.

Finally, run `terraform plan` (this step needs to be repeated whenever you change the .tfvars)

#### Scaleway prep
The one step I clound't automate yet is the required initial snapshot used to
setup the user's persistent $HOME.

This can however easily be done using the scaleway cli (make sure to use the same name as you set for scw_persistent_data_name):

```bash
# create a temporary block storage volume the the desired size for your $HOME
# and set tmp_block_id to it's UUID
# In this case it'll be 5k IOPS and 25G in size - adjust as desired

tmp_block_id=$(scw block volume create perf-iops=5000 from-empty.size=25G | awk '/^ID/{ print $2 }')

# create the initial - empty - snapshot from our storage

scw block snapshot create volume_id=$tmp_block_id name=same-as-scw_persistent_data_name

# remove the block volume
scw block volume delete $tmp_block_id
```

### Usage

To start the devbox instance run `terraform apply -auto-approve`.
If terraform reported no issues it should only take a minute or two until your devbox appears in you tailnet and accessible via tailnet-SSH.

To destroy the devbox instance run `terraform destroy -auto-approve`.

_It might take a few minutes for the devbox to be removed from your tailnet and starting a new instance in the meantime
might lead to <hostname>-2, <hostname>-3, ... situations._

_I'm looking into improving this behaviour_

### Optional extras

#### VSCode Tunnel
cloud-init will take care of preparing the system and also installs vscode-cli with an enabled code-tunnel service.

For this to be usable you will have to authenticate the tunnel once by performing these steps:

- run `terrafrom plan && terraform apply` if you haven't yet
- log into the devbox
- `sudo systemctl stop code-tunnel@$USER`
- `/snap/bin/code tunnel`
- follow the on-screen instructions to authenticate the tunnel
- Ctrl+C to stop code-tunnel
- `sudo systemctl start code-tunnel@$USER`

After these steps your code tunnel shoul be up and reachable as https://vscode.dev/tunnel/$HOST-$USER (so depending on whatever you set as variables for terraform).
This state is als persisted in the user's home directory and will survive restarts of the environment.

### Security Stuff

> Is the instance exposed to the internet in any way?

No, the only open port is the default wireguard port for tailscale.

> Is the data inside of my $HOME safe?

As safe as you make the `persistent_data_key` in your terraform.tfvars.
On first lauch the block volume serving your $HOME is formatted using cyptsetup LUKS2 before anything is stored in it.
While the devbox is offline all data for that volume resides in an encrypted snapshot on Scaleway's datacenter in Paris.
