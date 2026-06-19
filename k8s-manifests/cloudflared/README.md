Named Cloudflare Tunnel (Kubernetes)
===================================

Steps to create a named Cloudflare Tunnel and run it in the `mijil` namespace.

1) On your workstation (local), install `cloudflared` and log in to Cloudflare:

   ```bash
   cloudflared login
   ```

2) Create a named tunnel (replace `<NAME>`):

   ```bash
   cloudflared tunnel create <NAME>
   ```

   This writes a credentials JSON file named like `<TUNNEL-UUID>.json` to your local `.cloudflared/` directory.

3) Create the Kubernetes Secret from that file (do NOT commit the file into git):

   ```bash
   kubectl -n mijil create secret generic cloudflared-tunnel-credentials --from-file=credentials.json=~/.cloudflared/<TUNNEL-UUID>.json
   ```

4) Edit `cloudflared-configmap.yaml`: replace `<TUNNEL-UUID>` with the tunnel id from the credentials JSON and confirm the `hostname` in the ingress block is correct.

5) Apply the manifests:

   ```bash
   kubectl -n mijil apply -f k8s-manifests/cloudflared/cloudflared-configmap.yaml
   kubectl -n mijil apply -f k8s-manifests/cloudflared/named-tunnel-secret-example.yaml
   kubectl -n mijil apply -f k8s-manifests/cloudflared/cloudflared-deployment-named.yaml
   ```

6) Wait for the `cloudflared-named` pod to be Running and check logs for tunnel connection and hostname mapping.

7) DNS: In your Cloudflare dashboard, add a CNAME or set the hostname in the tunnel's ingress mapping as needed. Follow Cloudflare docs for routing traffic to tunnel-hosted services.

Security notes:
- Keep the credentials JSON private.
- Use RBAC and limit who can read the secret.
- Consider running 2 replicas and a ServiceMonitor for metrics.
