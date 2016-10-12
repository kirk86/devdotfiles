# Quick linux dev environment setup
*Notice*: Unfortunately requires root privilege access. I'm afraid no easy way around that!

1. installs prerequisite packages
2. installs lxde-core as minimal gui
3. installs tigervncserver for rdp
4. installs openblas
5. installs theano and torch depending your choice

*Todo:*

2. port it for OS X

*Tested:*
- Not tested yet.

*Notice:*

- It's always as good idea to tunnel your connection to your vnc.  VNC
  connections are considered as insecure connection as they are not
  encrypted. To perform the tunnel, we'll need the login user, port
  and password of the user. Here's the command to perform the
  tunneling in our client machine.

  ```shell
  ssh -L 5901:127.0.0.1:5901 -N -f -l vncuser 128.199.234.106
  ```
