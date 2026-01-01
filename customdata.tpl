#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Use sudo."
  exit 1
fi

echo "==> Updating package index"
apt-get update -y

echo "==> Installing prerequisite packages"
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

echo "==> Adding Docker GPG key"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "==> Adding Docker APT repository"
ARCH=$(dpkg --print-architecture)
RELEASE=$(lsb_release -cs)

echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  ${RELEASE} stable" \
  > /etc/apt/sources.list.d/docker.list

echo "==> Updating package index (Docker repo)"
apt-get update -y

echo "==> Installing Docker Engine"
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "==> Enabling and starting Docker"
systemctl enable docker
systemctl start docker

# Optional: add invoking user to docker group
if [[ -n "${SUDO_USER:-}" ]]; then
  echo "==> Adding user '${SUDO_USER}' to docker group"
  usermod -aG docker "${SUDO_USER}"
  echo "==> You must log out and back in for group changes to take effect"
fi

echo "==> Verifying Docker installation"
docker --version
docker compose version

echo "==> Docker installation completed successfully"
