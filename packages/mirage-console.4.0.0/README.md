## mirage-console -- implementations of Mirage consoles, for Unix and Xen

v4.0.0
 
The Unix version of the console currently uses standard output. The code is in

  unix/console.{ml,mli}

The Xen kernel version of the console uses the primary PV console ring. The
code is in

  xen/console.{ml,mli}

There is also a Unix userspace utility which creates and services Xen consoles
("console backends"):

Connect a console to a VM like this:

```
[root@st30 ~]# ./mirage-console connect trusty
Operating on VM domain id: 19
Creating device 1 (linux device /dev/tty1)
{ ref = 128; event_channel = 13 }
```

Then inside the guest:

```
[root@trusty ~]# cat > /dev/hvc1
hello
there
```

And observe in dom0:

```
hello
there
```

Then hit Control+C and it all cleans up.
