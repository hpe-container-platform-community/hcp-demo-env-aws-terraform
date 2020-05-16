# Mac OSX

- Install Wireshark
- Bind Wireshark

```
./generated/ssh_controller.sh sudo yum install -y tcpdump 
./generated/ssh_controller.sh sudo tcpdump -i lo -U -s0 -w - 'port 8080' | sudo /Applications/Wireshark.app/Contents/MacOS/Wireshark  -k -i -
```

- Make API call.
- Filter wireshark, e.g.

```
http.request.method == POST
```

or 

```
http.request.method == GET
```

- Right click stream, and select follow HTTP Stream
