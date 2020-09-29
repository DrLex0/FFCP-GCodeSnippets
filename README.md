# G-code Snippets, Config and Scripts for Using PrusaSlicer (Slic3r) with the Flashforge Creator Pro

This is a set of configuration bundles and post-processing scripts that allow to use the FlashForge Creator Pro 3D printer and compatible clones with PrusaSlicer. [On my website](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) I explain why you should use these files, and how to use PrusaSlicer after installing them. This repository contains the actual software and installation instructions. If you didn't come from that page already, [read the webpage itself](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) for the full story, it will link back here at the appropriate moment.

These configs and G-code are made specifically for *PrusaSlicer.* They might work in the original Slic3r from which PrusaSlicer was forked, but I give no guarantees.

This repository contains four things:

1. **Slic3r-configBundles:** the main PrusaSlicer config bundle. This is the bare minimum to get things working, but you should preferably also install the next thing:
2. **`make_fcp_x3g`:** a post-processing script that can automate the essential GCode-to-X3G conversion for you, as well as work around an annoying bug in PrusaSlicer, and optionally also invoke certain extra post-processing scripts. For users of old Windows versions there is a simplified BAT file that mimics the minimal required functionality of `make_fcp_x3g`. You can make do without this script, but it can make your life a lot easier.
3. **Optional-postprocessing-scripts:** what the name says. See the README inside that directory for more info.
4. **Slic3r-GCode:** the same G-code snippets that are already embedded into the config bundles, strictly spoken you can ignore this. It is possible that I will make small updates to these snippets without updating the whole config bundles, because that's kind of a hassle. If you see more recent commits in this *Slic3r-GCode* folder than inside the **Slic3r-configBundles** folder and you want the latest and greatest, [follow the instructions on my site](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html#gcode) to update them.


## A warning in advance

**Be careful with the temperatures in the filament presets!** Most likely you will need to reduce certain temperatures because I tweaked them on a Micro Swiss all-metal hot-end with glass bed + hairspray and hardened steel nozzle, and this setup requires higher temperatures than the stock hot-ends. The temperatures for PLA and ABS are safe, but especially the temperatures for PETG, flexible filaments, and obviously polycarbonate, are well above the 240°C limit for the stock hot-ends with their teflon liners.

You should never exceed 240°C for longer than a few minutes if you have not upgraded your hot-ends to all-metal. For PETG you should be able to get decent results at 240°C but I do recommend an all-metal hot-end with a pointy nozzle and higher temperatures to obtain good results with PETG.


# Installation and Setup Instructions

If you have a question, please go through both [the companion webpage](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) and this README (again). I will most likely not answer any mails that ask something already clearly explained on any of those two pages. If something is poorly explained, the best thing you can do is create an issue in the GitHub project itself, or maybe even a pull request.

## Step 1: install either the `make_fcp_x3g` script or the simpler BAT script

Either of these two scripts applies an important workaround for a certain bug in PrusaSlicer, and then invokes the GPX program for you, to convert the G-Code produced by PrusaSlicer into x3g files that the printer understands. Whatever variant of the script you will be using, it will be configured as *post-processing script* in PrusaSlicer to be run automatically after slicing. It will make your workflow easier.

You can choose not to use this and do the GPX conversion and bug workarounds all manually and tediously. In that case, skip this and move to step 2, but I recommend you don't.

If you are using OctoPrint, you don't need GPX because it does the x3g conversion for you. Otherwise, you do need GPX: first [obtain the GPX binary](https://github.com/markwal/GPX) and install it somewhere. Use the most recent GPX build you can find. Do not use 2.0-alpha, it is broken. In OS X, gpx can be installed through [homebrew](https://brew.sh/). Important: if you are going to use the WSL Linux environment in Windows, do not install the Windows EXE. Instead, install the Linux GPX executable inside the Linux WSL environment (quite likely, running “`sudo apt install gpx`” in a Linux terminal will do the job).

As for the post-processing script itself, you need it regardless of whether you use OctoPrint or not. Your options are:

1. **You are running Linux or Mac OS X:** you need the `make_fcp_x3g` Bash script. Open the script in an editor, and modify it according to its instructions until you hit the “`No user serviceable parts`” line. When done, ensure the file is executable (`chmod a+x make_fcp_x3g`) and remember the full path to where you placed it. A suitable location would be a ‘bin’ folder in your home directory where you might also store other personal executable files. You can now move to *step 2.*
2. **You are running WSL inside Windows:** you need the `make_fcp_x3g` Bash script, but also a BAT wrapper script to invoke it from within Windows. Follow the *WSL instructions* subsection below.
3. **You are running Windows but have no WSL:** you need the `simple_ffcp_postproc.bat` script. Follow the *Fallback BAT script* instructions below. This BAT script only does the bare minimum to use PrusaSlicer with the FFCP, it is much recommended to use `make_fcp_x3g` instead if you can.

If it isn't obvious: setting up PrusaSlicer is much easier on Linux or OS X. If you have the choice between either these platforms or Windows, do yourself a favour and pick the first.

### WSL instructions

For this to work, inside your WSL environment you must have a command `wslpath` that converts Windows paths to their Linux equivalent. This is automatically the case if you have Windows 10 version 1803 or newer with a standard WSL image. If not, follow the instructions in the file `poor_mans_wslpath.txt`.

Open the `make_fcp_x3g` script in a text editor and modify it according to its instructions until you hit the “`No user serviceable parts`” line. Important: each time you need to specify the path to a program or script, specify the *Linux file path* where you placed that program (e.g. gpx) or script inside the WSL Linux environment.

When done, save the modified `make_fcp_x3g` inside the Linux filesystem. Ensure both the script and gpx binary (if needed) are executable (`chmod a+x make_fcp_x3g`).

Then, create a BAT wrapper script in your Windows filesystem, any text editor will do. Save the following content under the file name `slic3r_postprocess.bat`:
```
set fpath=%~1
set fpath=%fpath:'='"'"'%
bash /your/linux/path/to/make_fcp_x3g -w '%fpath%'
```

In the above lines, replace “`/your/linux/path/to`” with the full UNIX style path inside the Linux environment where you placed the *make_fcp_x3g* script.

Now remember the full Windows path to this `slic3r_postprocess.bat` file, you will need it in the next step. For instance if your Windows account name is *Foobar* and you placed the file `slic3r_postprocess.bat` in your documents folder on your C drive, then its full path is: “`C:\Users\Foobar\Documents\slic3r_postprocess.bat`”. Now you can move to *step 2.*

### Fallback BAT script

Only needed if you cannot get WSL working in Windows. The `simple_ffcp_postproc.bat` script only mimics the two most essential functions of the `make_fcp_x3g` script, namely the tool temperature bug workaround and invoking GPX. It requires Windows binaries of both **Perl** and (unless you're using Octoprint) **GPX**.

1. Install Perl, e.g. through Strawberry Perl or Cygwin.
2. Open the `simple_ffcp_postproc.bat` script file in a text editor.
3. Figure out what the full path to `perl.exe` is, and enter this path in the script under the comment line “`ADJUST PERL PATH HERE`”. Depending on your installation, perhaps just 'perl' may work, otherwise use the full path (the default in the script is for 64-bit cygwin).
4. Figure out the full path where gpx.exe was installed. Enter this path in the script under the comment line “`ADJUST GPX PATH HERE`”.

Now remember the full path to this BAT file, you will need it in the next step. For instance if your Windows account name is *Foobar* and you placed the file `simple_ffcp_postproc.bat` in your documents folder on your C drive, then its full path is: “`C:\Users\Foobar\Documents\simple_ffcp_postproc.bat`”. Now you can move to *step 2.*


## Step 2: modify the config bundles

There are two variations on the config bundle: most likely you will need the regular one. The other one (with ‘MVF’ in its name) is only to be used if you have upgraded your printer with the [MightyVariableFan system](https://github.com/DrLex0/MightyVariableFan).

Open the appropriate .ini file in a text editor and do a find & replace on all occurrences of the following line, or use `sed` if you are a Linux/UNIX wizard:
```
post_process = /You-need-to-update-print-configs/see-https://bit.ly/3l13MrN
```
Replace all these lines with:
```
post_process = PATH
```
Where `PATH` is either:
* the UNIX-style path to the `make_fcp_x3g` script if you are running PrusaSlicer in Linux or Mac OS X;
* the Windows-style path to `slic3r_postprocess.bat` if you run `make_fcp_x3g` inside WSL inside Windows;
* the Windows-style path to `simple_ffcp_postproc.bat` if you deployed this inside Windows instead;
* nothing, empty, if you opted to skip step 1 (the line would then be “`post_process = `”). Again, not recommended.


## Step 3: load the config bundles in PrusaSlicer

If you open PrusaSlicer for the first time, try to bypass its config wizard and don't select any specific printer type. The way to do this seems to change with every release. If the wizard did make any Print, Filament, or Printer settings, delete them before loading the config bundle.

Now import the .ini file you edited before. PrusaSlicer will overwrite existing configs with the same names, other ones will be left untouched. If you have nothing custom, it is better to first wipe everything before importing so you don't accumulate old cruft. If you make modifications to a config and you want to preserve them, save it as a new config with a unique name to prevent it from being overwritten in a future update.

Now would be a good time to [return to the main article](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html#using) to read how to use PrusaSlicer with this config bundle.


## For the perfectionists

You should calibrate your home offsets to be able to use the entire surface of the print bed. In a nutshell, make sure that the initial priming extrusion is at exactly 3 mm of the front edge of the bed. For more details, [see my FFCP hints webpage](https://www.dr-lex.be/info-stuff/print3d-ffcp.html#hint_calib).



## License
These files are released under a Creative Commons Attribution 4.0 International license.
