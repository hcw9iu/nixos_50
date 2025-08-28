# Attic setup
## Structure

```
.
├── attic-server-0.1.0/
│   ├── atticd
│   └── atticadm 
├── ...
└── attic-0.1.0/
    ├── attic
    ├── atticd (optional)
    └── atticadm (optional)
```
1. `attic-server-0.1.0` is nixos built in.
2. `attic-0.1.0` is downloaded.
3. Download daemon, admin tools for external storage, debug, etc.

## Download attic client
In `flake.nix` modules :

```nix
inputs{
    ...
    # atticd
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ...
}
...

modules = [
{
  nixpkgs.overlays = [ 
    inputs.attic.overlays.default # for attic
  ];
  _module.args = { inherit inputs; };
}  
({ pkgs, inputs, ... }: {
  environment.systemPackages = [ 
    inputs.attic.packages.${pkgs.system}.attic-client # for attic
    #inputs.attic.packages.${pkgs.system}.attic # for full set 
  ];
})
```
- *`.attic` : full*
- *`.atticd` : server*
- *`.atticadm` : admin tools*

## Config
### Config server key
```bash
openssl genrsa -traditional 4096 | base64 -w0 > private.base64
```
Setup `environment.env` in one line.
```txt
 ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=<private.base64>
```

### Config system server
In `attic.nix` import to `configuration.nix`

```nix
{ config, pkgs, ... }: 
let 
  atticToken = builtins.path {
    name = "secrets";
    path = "<RELATIVE_PATH_TO_private.base64>";
  };
in {
  services.atticd = {
    enable = true;
    user = "<USER_NAME>";
    group = "<GROUP_NAME>";
    environmentFile = "<PATH_TO_environment.env>";
    settings = {
      listen = "[::]:8080";
      jwt.signing = { 
        token-rs256-secret-base64 = pkgs.lib.fileContents atticToken;
      };
      #database = {
      #  url = "sqlite:///xxxxxxx/server.db?mode=rwc";
      #};
      storage = {
        type = "local";
        path = "<PATH_TO_storage>";
      };
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };
  nix.settings = {
    trusted-users = [ "<USER_NAME>" ];
  };
}
```
- Chunk follow official site setting.
- <font color="red">**DO NOT**</font> assign database path in config. Nix wouldn't able to access.
- Check user name with `whoami`


### Config attic client
#### Generate full access token

Navigate to `atticadm` in the same folder with `atticd`. Check with 
`sudo systemctl status atticd`.

```bash
atticadm make-token \
--sub "root" --validity "1y" \
--push "*" \
--pull "*" \
--delete "*" \
--create-cache "*" \
--configure-cache "*"  \
--configure-cache-retention "*" \
--destroy-cache "*" 
```

#### Config attic client

In `~/.config/attic/config.toml` append token just print

```toml
default-server = "local"

[servers.local]
endpoint = "http://localhost:8080"
token = "<FULL_ACCESS_TOKEN>"
```
OR

```bash
attic login <SERVER_TYPE> <SERVER_ENDPOINT> <FULL_ACCESS_TOKEN>
```

## Usage
*Philosophy:*<br>
*Originally nix pull only from https://cache.nixos.org* <br>
*Attic allow user push files , act as alternative source*.<br>
*Ex. `nix-shell` , `nix develop` will search both attic db and nix cache*.

### Caching structure
```text
.
├── cache_1/
│   ├── pkg_1
│   ├── ...
│   └── pkg_N
├── ...
└── cache_2/
    ├── pkg_1
    └── ...
```
Attic manipulation is cache based. 

1. Create cache
   
   ```bash
   attic cache create <CACHE_NAME>
   ``` 
2. Use cache

   ```bash
   attic use <CACHE_NAME>
   ```
   *This write cache to `~/.config/nix/nix.conf`*
   ```nix
   substituters = http://localhost:8080/<CACHE_NAME> https://cache.nixos.org
   trusted-substituters = http://localhost:8080/<CACHE_NAME>
   trusted-public-keys = <CACHE_NAME>:<PUBLIC_KEY>> cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
   netrc-file = /home/<USER_NAME>/.config/nix/netrc
   trusted-users = root <USER_NAME>
   ```
   *Check if public key is correct*
   ```bash
   attic cache info <CACHE_NAME>
   ```
   *Manage priority*
   ```bash
   attic cache configure <CACHE_NAME> --priority <PRIORITY>
   ```
   Default nix cache is 40, lower is higher priority.

### Push files to cache
   
#### System binary

```bash
attic push <CACHE_NAME> $(which PACKAGE)
```
! *<font color="red">**DO NOT**</font> push home manager files to cache, won't resolve dependency when pull.*

#### Python packages
> *Attic cache python package the whole directory*

Find python package path
```bash
find /nix/store -type d -path "*/site-packages/<PACKAGE_NAME>"
```
Push to cache
```bash
attic push <CACHE_NAME> <PATH_TO_PYTHON_PACKAGE>
```

Expecting to see terminal output when run `nix-shell` or `nix develop`
```bash
...
copying path /nix/store/... from https://cache.nixos.org ...
copying path /nix/store/... from http://localhost:8080/<CACHE_NAME> ...
```