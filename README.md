# ICP 3 web application

A Next.js application with two uncached HTTP endpoints. `GET /` returns the serving VM's hostname; `GET /work` performs one million PBKDF2-SHA256 iterations on Node's worker pool before returning the hostname. Requests can overlap, and CPU work does not block the HTTP event loop. The worker pool queues excess work (Node defaults to four worker threads).

Requires Node.js 20.9 or newer and npm.

```sh
npm ci
npm run build
npm start
```

The production server listens on `0.0.0.0:80`. On Linux, binding port 80 normally requires root or the `CAP_NET_BIND_SERVICE` capability. For local testing without port 80 privileges, run `npx next start -H 0.0.0.0 -p 3000` after building.

```sh
curl http://localhost:3000/
curl http://localhost:3000/work
```

## VM startup script

`startup-script.sh` targets an x86-64 Debian Compute Engine VM. It installs Node.js, downloads and builds the app, and enables a systemd service on port 80. On subsequent boots it reuses the completed installation. If installation fails before completion, the next boot retries it.

Create a source archive from the project root (the archive must contain `package.json` at its root):

```sh
tar -czf /tmp/icp3-app.tar.gz --exclude=node_modules --exclude=.next --exclude=.git --exclude='*.tsbuildinfo' .
```

Upload the archive to a URL that each VM can download without interactive authentication. The VM also needs outbound access to nodejs.org and the npm registry. Supply that URL and the script when creating the instance template:

```sh
gcloud compute instance-templates create icp3-web-template \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --metadata=app-url=YOUR_ARCHIVE_HTTPS_URL \
  --metadata-from-file=startup-script=./startup-script.sh
```

Replace `YOUR_ARCHIVE_HTTPS_URL` with the actual URL. Do not put credentials in instance metadata. To deploy changes, publish a new archive and create a new template; existing installed VMs do not update automatically. On a VM, inspect startup logs with `sudo journalctl -u google-startup-scripts.service` and application logs with `sudo journalctl -u icp3-app.service`.
