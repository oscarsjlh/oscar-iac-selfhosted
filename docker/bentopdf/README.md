# BentoPDF

Privacy-first PDF toolkit at <https://pdf.oscarcorner.com>, using the upstream
self-hosted build (`bentopdf-simple`). PDF processing runs in the browser; some
features download WASM/OCR assets from external CDNs. No persistent volumes or
application credentials are required. This configuration adds no authentication.

## Deployment

The remote Ansible Docker role automatically discovers this directory, copies it
to `/home/oscar/bentopdf`, and starts the Compose project. Deploy from the repo root:

```sh
make deploy_docker_remote
```

This synchronizes all remote Docker projects, not only BentoPDF. Do not run local
Compose to deploy to the remote server.

DNS for `pdf.oscarcorner.com` must resolve to the server's ingress. The service
uses the existing external `reverse-proxy-network`, Traefik's `websecure`
entrypoint, and the `route53` certificate resolver. No host port is published.
The image digest is pinned for reproducible deployments.

## Verification

After deployment, check the container on the remote host and the HTTPS headers:

```sh
ssh ci@192.168.1.231 'sudo docker inspect --format "{{.State.Health.Status}}" bentopdf'
curl -I https://pdf.oscarcorner.com
```

Expect a healthy container and these response headers, required for Office
conversions using SharedArrayBuffer:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Open the site over HTTPS and test PDF and Office conversions in a browser.

Upstream instructions: <https://www.bentopdf.com/docs/self-hosting/docker>
