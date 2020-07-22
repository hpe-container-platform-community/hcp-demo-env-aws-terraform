# How to use Wireshark to inspect API calls at the wire level

- Deploy HPECP with this project using: `install_with_ssl = false` in `etc/bluedata_infra.tfvars`
- Install Wireshark
- Bind Wireshark
- Install `tcpdump` on the controller

```
./generated/ssh_controller.sh sudo yum install -y tcpdump 
```

- Run `tcpdump` and pipe output over ssh to wireshark:

```
# MAC OSX
./generated/ssh_controller.sh sudo tcpdump -i lo -U -s0 -w - 'port 8080' | sudo /Applications/Wireshark.app/Contents/MacOS/Wireshark  -k -i -
```

- Make API call.
- Filter wireshark, e.g.

  - `http`
  - `http.request.method == "POST" or http.request.method == "GET"`
  - `http.request.uri == "/api/v1/user"`
  - `http.request.uri matches "k8skubeconfig"`

- Right click stream, and select follow HTTP Stream
