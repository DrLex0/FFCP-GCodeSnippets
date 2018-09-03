# G-code Snippets and Scripts for Using Slic3r with the Flashforge Creator Pro

This repository contains two things:

## G-code snippets
To be used in combination with my Slic3r profiles as can be found on Thingiverse ([Thing:2367215](https://www.thingiverse.com/thing:2367215)). These are also published separately in [Thing:2367350](https://www.thingiverse.com/thing:2367350) for convenience. Look on those Thing pages for instructions.

## The *make_fcp_x3g* script
This script can be configured as a post-processing script in Slic3r to run specific post-processing scripts and finally generate an X3G file by invoking [GPX](https://github.com/markwal/GPX). This is a Bash script and can also be used with the WSL Linux environment in recent versions of Windows. To do this, create a BAT file that contains the following:
```
bash /your/linux/path/to/make_fcp_x3g -w '%1'
```
Update the path to the actual path inside the Linux environment where you placed the *make_fcp_x3g* script (and make sure it is executable). Finally in Slic3r, configure the Windows path to the .BAT file in all your *Print Settings* → *Output options* → *Post-processing scripts*.


## License
These files are released under a Creative Commons Attribution 4.0 International license.

