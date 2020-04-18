Coming soon based on ...

- https://github.com/halo/macosvpn
- https://www.softether.org/
- https://hub.docker.com/r/siomiz/softethervpn/

Run on RDP Server:

```
docker run -d --cap-add NET_ADMIN -e USERS=csnow:pass123 -p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp -p 1194:1194/udp -p 5555:5555/tcp siomiz/softethervpn
```

