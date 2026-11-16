#!/bin/bash
# Stop on errors, unset variables, or failures in a pipeline.
set -euo pipefail

# Compute Engine exposes instance template settings through its metadata server.
# app-url must point to a tar.gz containing the project files at its root.
METADATA=http://metadata.google.internal/computeMetadata/v1/instance/attributes
APP_DIR=/opt/icp3-app
NODE_VERSION=22.17.0

# Skip installation on later boots once the build has completed successfully.
if [ ! -f "$APP_DIR/.installed" ]; then
  # Install the tools needed to download and extract Node.js and the app.
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl xz-utils

  # Install Node.js for the VM's x86-64 architecture.
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/icp3-node.tar.xz
  tar -xJf /tmp/icp3-node.tar.xz -C /usr/local --strip-components=1
  rm -f /tmp/icp3-node.tar.xz

  # Read the archive URL from instance metadata and extract the app.
  APP_URL=$(curl -fsS -H 'Metadata-Flavor: Google' "$METADATA/app-url")
  mkdir -p "$APP_DIR"
  curl -fsSL "$APP_URL" -o /tmp/icp3-app.tar.gz
  tar -xzf /tmp/icp3-app.tar.gz -C "$APP_DIR" --strip-components=1
  rm -f /tmp/icp3-app.tar.gz
  cd "$APP_DIR"
  # Install the locked dependencies and build the production application.
  npm ci
  npm run build
  # Only mark installation complete after all previous steps succeed.
  touch "$APP_DIR/.installed"
fi

# Define a Linux service so the app starts on boot and restarts if it exits.
# npm start runs the production server on port 80 (as configured in package.json).
cat > /etc/systemd/system/icp3-app.service <<'SERVICE'
[Unit]
Description=ICP3 Next.js web application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/icp3-app
ExecStart=/usr/local/bin/npm start
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SERVICE

# Reload the service definition, enable it on boot, and start it now.
systemctl daemon-reload
systemctl enable --now icp3-app.service
