# Run ngate-client with Docker Compose

Use [`ngate-client/docker-compose.yaml`](ngate-client/docker-compose.yaml) to
connect to a CryptoPro NGate gateway without typing the full `docker run`
command. The file runs the published
[ngate-client](../reference/ngate-client.md) image with the same host
requirements: rootful Docker, NetworkManager on the host, host networking,
`CAP_NET_ADMIN`, `/dev/net/tun`, and the host system D-Bus socket.

1. Copy the file into a local directory outside the repository, so filled-in
   credentials are never committed:

   ```bash
   mkdir -p ~/ngate-client/ca
   cp docs/how-to/ngate-client/docker-compose.yaml ~/ngate-client/
   ```

2. Fill in the `environment` section. `CRYPTOPRO_USERNAME` and
   `CRYPTOPRO_PASSWORD` are needed only for the CSP installation on the first
   start. Leave `NGATE_OTP` empty unless the gateway asks to choose a
   confirmation method.

3. Put the root certificates of the gateway chain into `~/ngate-client/ca`.

4. Start the connection and approve the push on the device:

   ```bash
   cd ~/ngate-client
   docker compose up
   ```

`docker compose up` keeps the client output in the terminal, and `Ctrl+C`
stops the connection. `docker compose down` removes the container, so the next
start installs CSP again and needs the cryptopro.ru credentials.

The image tag in the repository copy is updated by Renovate. To move a local
copy to a new release, change its `image:` tag to the one from the repository
copy.
