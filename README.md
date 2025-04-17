## Ephemeral DevBox with persistent $HOME using Scaleway + Tailscale and Terraform

This little toy repo implements an ephemeral development system with a peristent,
encrypted $HOME and secure access via Tailscale.

I built it as a more flexible alternative to GitPod / CodeSpaces since a good deal
of the time I might have my iPad around but not my MacBook and having access (mosh/ssh/vscode-tunnel!)
to a full fleged linux system while on-the-go withough having to permanantly rent
a server and creating only monthly costs in the <1ct range is unused seemed like a fun idea.


#### Prerequisites
- Accounts:
  - Scaleway
  - Tailscale

- Local tools:
  - scaleway-cli
  - terraform / opentofu

- Credentials:
  - Scaleway API-Key/Secret
  - Tailscale OAuth-Client Key/Secret with "auth_keys" scope


##### Scaleway prep
The one step I clound't automate yet is the required initial snapshot used to
setup the user's persistent $HOME.

This can however easily be done using the scaleway cli (make sure to use the same name as you set for scw_persistent_data_name):

```bash
# create a temporary block storage volume the the desired size for your $HOME
# and set tmp_block_id to it's UUID
# In this case it'll be 5k IOPS and 25G in size - adjust as desired

$ tmp_block_id=$(scw block volume create perf-iops=5000 from-empty.size=25G | awk '/^ID/{ print $2 }')

# create the initial - empty - snapshot from our storage

$ scw block snapshot create volume_id=$tmp_block_id name=same-as-scw_persistent_data_name

# remove the block volume
$ scw block volume delete $tmp_block_id
```

#### Optional extras

##### VSCode Tunnel
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

