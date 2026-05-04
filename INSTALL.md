> [!Note]
> This exciter is now included at my `mightymic`, so if you already use it, you may prefer it to this standalone installation.

Checks:
------
I've tested with Archlinux. Sorry, don't know how it will work for others.

Install:
-------
1. 

    pacman -S lv2 boost faust
    mkdir /usr/local/lib/lv2

2. Then, please see at top of `.dsp` file.

Uninstall:
---------
    rm -rvf /usr/local/lib/lv2/tracingexciter.lv2/ 
