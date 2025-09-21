# docker-firmware-selector-openwrt

# Introduction
Docker Image for firmware-selector-openwrt

# Requirements
You need to first clone the Common https://github.com/luckylinux/container-build-tools somewhere in your System first, as I didn't want to over-complicate the Setup with `git subtree` or `git submodule`).

Then Symlink the Directory within this Repository to the "includes" Target:
```
git clone https://github.com/luckylinux/docker-firmware-selector-openwrt.git
cd docker-firmware-selector-openwrt
ln -s /path/to/container-build-tools includes
```

# Build
The Container can simply be built using:
```
./build.sh
```

Edit the Options to your liking.

# Run
The NGINX Container listens on Port 8080.

In this Way, it's possible to run a Reverse Proxy in front of it (e.g. Caddy or Traefik) without resulting in a Port Conflict.

## Testing
One-Liner for Testing:
```
podman run --replace -d --name docker-firmware-selector-openwrt -p 8080:8080 -v ./misc:/usr/share/nginx/html/misc localhost/docker-firmware-selector-openwrt:nginx-latest
```

## Production
Using Podman Quadlets:
```
[Unit]
Description=OpenWRT Firmware Selector GUI

# The Requires & After Lines are Optional in case you have a Reverse Proxy in front of this
Requires=openwrt-firmware-selector-caddy.service
After=openwrt-firmware-selector-caddy.service

[Container]
ContainerName=openwrt-firmware-selector-server

Pod=openwrt-firmware-selector.pod
StartWithPod=true

Image=localhost/docker-firmware-selector-openwrt:nginx-v5.0.3
Pull=missing

# Only needed for direct Access without Reverse Proxy
#PublishPort=8080:8080

# Using Caddy Proxy
Network=container:openwrt-firmware-selector-caddy

# Using the Default "podman" Network
#Network=podman

# In case you want to use traefik Reverse Proxy
#Label=traefik.enable=true
#Label=traefik.http.routers.openwrt-firmware-selector-server-router.rule=Host(`openwrt-firmware-selector.MYDOMAIN.TLD`)
#Label=traefik.http.routers.openwrt-firmware-selector-server-router.middlewares=openwrt-firmware-selector-headers
#Label=traefik.http.middlewares.openwrt-firmware-selector-server-headers.headers.customrequestheaders.Connection=Upgrade
#Label=traefik.http.services.openwrt-firmware-selector-server-service.loadbalancer.server.port=8080
#Label=traefik.docker.network=traefik

#Network=traefik

Volume=/home/podman/containers/data/openwrt-firmware-selector/server/misc:/usr/share/nginx/html/misc:ro,Z
Volume=/home/podman/containers/log/openwrt-firmware-selector/server:/var/log/nginx:rw,Z

# If you want to pass any additional Configuration to NGINX
#Volume=/home/podman/containers/config/openwrt-firmware-selector/server/nginx.conf:/etc/nginx/nginx.conf:ro,Z

# Automatically restart Service if crashed
[Service]
Restart=always

# Start automatically after System Boot
[Install]
WantedBy=default.target
```

Using Docker Compose:
```
services:
  openwrt-firmware-selector-server:
    image: nginx:latest
    pull_policy: "missing"
    container_name: openwrt-firmware-selector-server
    volumes:
      - /home/podman/containers/data/openwrt-firmware-selector/server/misc:/usr/share/nginx/html/misc:ro
      - /home/podman/containers/log/openwrt-firmware-selector/server:/var/log/nginx

      # If you want to pass any additional Configuration to NGINX
      - /home/podman/containers/config/openwrt-firmware-selector/server/nginx.conf:/etc/nginx/nginx.conf:ro

    # Only needed for direct Access without Reverse Proxy
    #ports:
    #  - 8080:8080

    # Using Caddy Proxy
    network_mode: "service:openwrt-firmware-selector-caddy"

    #networks:
    # Using the Default "podman" Network
    #  - podman
    #
    # In case you want to use traefik Reverse Proxy
    #  - traefik

    # In case you want to use traefik Reverse Proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.openwrt-firmware-selector-server-router.rule=Host(`openwrt-firmware-selector.MYDOMAIN.TLD`)"
      - "traefik.http.routers.openwrt-firmware-selector-server-router.middlewares=openwrt-firmware-selector-headers"
      - "traefik.http.middlewares.openwrt-firmware-selector-server-headers.headers.customrequestheaders.Connection=Upgrade"
      - "traefik.http.services.openwrt-firmware-selector-server-service.loadbalancer.server.port=8080"
      - "traefik.docker.network=traefik"


# Using the default "podman" Network
# networks:
#  podman:
#    external: true

# If you want to use traefik
#networks:
#  traefik:
#    external: true

```
