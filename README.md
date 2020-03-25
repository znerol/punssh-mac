# PunSSH client for macOS 10.13 and later

Fully automated setup of SSH tunnels towards a [znerol/punssh][1] server.
Tunnel endpoints are managed with user defaults (a plist file) optionally
deployed using an MDM. Port forwarding configuration is pulled from a PunSSH
server. Thus no local setup is required.

## Build

Requires swift 5.1 during build time, macOS 10.13 during runtime.

Build `punssh-defaults` and `punssh-status` from sources:

    make build

Build an installer package:

    make pkg

## Configuration

Plist file in `/Library/Preferences/ch.znerol.punssh.plist`. It consists of an
`array` of `dict`s in the `tunnels` toplevel key. Each `dict` has the following
key value pairs:

- **name** (string): Tunnel name. May contain a %ComputerName% placeholder
  which is replaced by the client host name.
- **destination** (string): SSH destination, e.g., `user@host.tld`.
- **hostkeys** (array of string): SSH host keys for the destination. Copy them
  from `/etc/ssh/ssh_host_*.pub` on the destination or use `ssh-keyscan`.
- **user** (string): Unix user on the client used to start the `ssh` process.
- **group** (string): Unix group on the client used to start the `ssh` process.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>tunnels</key>
	<array>
		<dict>
			<key>name</key>
			<string>%ComputerName%.example-tunnel</string>
			<key>destination</key>
			<string>punssh@ssh.example.com</string>
			<key>hostkeys</key>
			<array>
				<string>ssh.example.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC3/rZLS1R1WuWy9h4jh/go3Qwc4KhLWbHgvjvDbHaBCRiLheFKNNksw5ozx4mkM1lY03zeg+EfZTiKV9nqsyjI=</string>
				<string>ssh.example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8GbFDZjFuyoIvq9Yohv+A8UDbKJ+Zbr55H4uLy7cTO</string>
				<string>ssh.example.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZGi+FU9q+b+JCWQyfIi/GkeRUXAEvWken74n1Og8nP/mMqNszOqd2jcG5dkbIngRAsnuUgnisZXEpljYV6oKVoGgmOcVnAQicWEHXdzomTf13XmHbbd1IFKLiq4yOixmnER9i1Unr1ddjZj+VjaVwC7VvPRhuyhv48XiA9zz/+1FJed1PCKo8XJXg2MDbT5HUHB20ZrLTK9xKsqU2nXIJzodJJwdkViSzNJAWMNs0zFEYV9tEsrJdE3KEmHekopTOfbdd85wyDWgAcRmoTeoutdCNhxNHcBPo9E4jKFGtV7ZmimqleAQKZEuVKHr/scguE57gyqGQeQ7DxaJrc5Hx</string>
			</array>
			<key>user</key>
			<string>_punssh</string>
			<key>group</key>
			<string>_punssh</string>
		</dict>
	</array>
</dict>
</plist>
```

## Monitoring

* Use `punssh-status` to gather tunnel status in JSON format.
* Use [znerol/munkireport-punssh][2] to integrate it into Munkireport.

## License

[GPLv3 or later](https://www.gnu.org/licenses/licenses.html#GPL)

[1]: https://github.com/znerol/punssh
[2]: https://github.com/znerol/munkireport-punssh
