#!/bin/bash
# Run python-matter-server (stable)
# -v persists commissioned device data across restarts

docker run -d \
  --name matter-server \
  --restart=always \
  -p 5580:5580 \
  -v $(pwd)/matter-data:/data \
  ghcr.io/home-assistant-libs/python-matter-server:stable
