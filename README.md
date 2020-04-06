# G-code Snippets, Config and Scripts for Using PrusaSlicer (Slic3r) with the Flashforge Creator Pro

This is a set of configuration bundles and post-processing scripts that allow to use the FlashForge Creator Pro and compatible clones with PrusaSlicer. [On my website](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) I explain in detail how to install and use these files. This page contains the actual software and a short summary of the instructions. [Read the webpage itself](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) if you are doing this for the first time.

These configs and G-code are made specifically for *PrusaSlicer.* They might work in the original Slic3r from which PrusaSlicer was forked, but I give no guarantees.

This repository contains four things:

1. **Slic3r-configBundles:** the main PrusaSlicer config bundle. This is the bare minimum to get things working, but you should preferably also install the next thing:
2. **`make_fcp_x3g`:** a post-processing script that can automate the essential GCode-to-X3G conversion for you, as well as work around an annoying bug in PrusaSlicer, and optionally also invoke certain extra post-processing scripts. You can make do without this script, but it can make your life a lot easier.
3. **Postprocessing-scripts:** a set of optional post-processing scripts, see the README inside that directory for more info.
4. **Slic3r-GCode:** the same G-code snippets that are already embedded into the config bundles, strictly spoken you can ignore this. It is possible that I will make small updates to these snippets without updating the whole config bundles, because that's kind of a hassle. If you see more recent commits in this *Slic3r-GCode* folder than inside the **Slic3r-configBundles** folder and you want the latest and greatest, copy those snippets into the PrusaSlicer printer profiles to update them.


## A warning in advance

**Be careful with the temperatures in the filament presets!** Most likely you will need to reduce certain temperatures because I tweaked them on a Micro Swiss all-metal hot-end with glass bed + hairspray and hardened steel nozzle, and this setup requires higher temperatures than the stock hot-ends. The temperatures for PLA and ABS are safe, but especially the temperatures for PETG, flexible filaments, and obviously polycarbonate, are well above the 240°C limit for the stock hot-ends with their teflon liners.

You should never exceed 240°C for longer than a few minutes if you have not upgraded your hot-ends to all-metal. For PETG you should be able to get decent results at 240°C but I do recommend an all-metal hot-end with a pointy nozzle and higher temperatures to obtain good results with PETG.


# Concise instructions

Again, the following is just a quick reminder for those who have installed these files before. Others should definitely [read the webpage with detailed instructions first](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html). If you don't care about the intro, at the least read [this section of the page](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html#config). If you mail me with questions that are answered on that webpage, do not expect an answer.

## Step 1: install either the `make_fcp_x3g` script or the simpler BAT script

You can choose not to use this (although you really should) and do the GPX conversion and bug workarounds all manually and tediously. In that case, skip this and move to step 2.

Whatever variant of the script you will be using, it will be configured as *post-processing script* in PrusaSlicer to be run automatically after slicing. The script applies some workarounds for a certain bug in PrusaSlicer, and then invokes the GPX program for you, to convert the G-Code produced by PrusaSlicer into x3g files that the printer understands.

To automatically invoke GPX, you must first [obtain the GPX binary](https://github.com/markwal/GPX) and install it somewhere. Important: if you are going to use the WSL Linux environment in Windows, do not install the Windows EXE of GPX. Instead, install its Linux executable inside the Linux WSL environment.

As for the post-processing script itself, your options are:

1. **You are running Linux or Mac OS X:** you need the `make_fcp_x3g` Bash script. Open the script in an editor and edit at least the `GPX` path to point at where the gpx binary resides. Optionally edit the other values, follow the instructions in the file's comments. When done, ensure the file is executable (`chmod a+x make_fcp_x3g`) and remember the full path to where you placed it. You can now move to step 2.
2. **You are running WSL inside Windows:** you need the `make_fcp_x3g` Bash script, but also a BAT wrapper script to invoke it from within Windows. Follow the *WSL instructions* subsection below.
3. **You are running Windows but have no WSL:** you need the `simple_ffcp_postproc.bat` script. Follow the *Fallback BAT script* instructions below. This BAT script only does the bare minimum to use PrusaSlicer with the FFCP, it is much recommended to use `make_fcp_x3g` instead if you can.

### WSL instructions

For this to work, inside your WSL environment you must have a command `wslpath` that converts Windows paths to their Linux equivalent. This is automatically the case if you have Windows 10 version 1803 or newer with a standard WSL image. If not, follow the instructions in the file `poor_mans_wslpath.txt`.

Open the `make_fcp_x3g` script in a text editor and set `GPX` to the *Linux file path* pointing to the *Linux gpx binary* you installed before. You could optionally edit the other parameters if you know what you're doing. Then save this modified script inside the Linux filesystem. Ensure both the script and gpx binary are executable (`chmod a+x make_fcp_x3g`).

Then, create a BAT wrapper script, any text editor will do. Save the following content under the file name `slic3r_postprocess.bat`:
```
set fpath=%~1
set fpath=%fpath:'='"'"'%
bash /your/linux/path/to/make_fcp_x3g -w '%fpath%'
```

In the above lines, replace “`/your/linux/path/to`” with the full UNIX style path inside the Linux environment of where you placed the *make_fcp_x3g* script.

Now remember the full path to the `slic3r_postprocess.bat` file, you will need it in the next step. For instance if your Windows account name is *Foobar* and you placed the file `slic3r_postprocess.bat` in your documents folder on your C drive, then its full path is: “`C:\Users\Foobar\Documents\slic3r_postprocess.bat`”. Now you can move to step 2.

### Fallback BAT script

Only needed if you cannot get WSL working in Windows. The `simple_ffcp_postproc.bat` script only mimics the two most essential functions of the `make_fcp_x3g` script, namely the tool temperature bug workaround and invoking GPX. It requires Windows binaries of both **Perl** and **GPX**.

1. Install Perl, e.g. through Strawberry Perl or Cygwin.
2. Open the `simple_ffcp_postproc.bat` script file in a text editor.
3. Figure out what the full path to `perl.exe` is, and enter this path in the script under the comment line “`ADJUST PERL PATH HERE`”. Depending on your installation, perhaps just 'perl' may work, otherwise use the full path (the default in the script is for 64-bit cygwin).
4. Figure out the full path where gpx.exe was installed. Enter this path in the script under the comment line “`ADJUST GPX PATH HERE`”.

Now remember the full path to this BAT file, you will need it in the next step. For instance if your Windows account name is *Foobar* and you placed the file `simple_ffcp_postproc.bat` in your documents folder on your C drive, then its full path is: “`C:\Users\Foobar\Documents\simple_ffcp_postproc.bat`”. Now you can move to step 2.


## Step 2: modify the config bundles

There are two variations on the config bundle: most likely you will need the regular one. The other one (with ‘MVF’ in its name) is only to be used if you have upgraded your printer with the [MightyVariableFan system](https://github.com/DrLex0/MightyVariableFan).

Open the appropriate .ini file in a text editor and do a find & replace on these lines, or use `sed` if you are a Linux/UNIX wizard:
```
post_process = /You-need-to-update-print-configs/see-https://bit.ly/2MsxdV2
```
Replace them with:
```
post_process = PATH
```
Where `PATH` is either:
* The UNIX-style path to the `make_fcp_x3g` script if you are running PrusaSlicer in Linux or Mac OS X;
* The Windows-style path to `slic3r_postprocess.bat` if you run `make_fcp_x3g` inside WSL inside Windows;
* The Windows-style path to `simple_ffcp_postproc.bat` if you deployed this inside Windows instead.
* Nothing, empty, if you opted to skip step 1 (the line would then be “`post_process = `”). Again, to be avoided.


## Step 3: load the config bundles in PrusaSlicer

If you open PrusaSlicer for the first time, try to bypass its config wizard. The way to do this seems to change with every release. If the wizard did make any Print, Filament, or Printer settings, delete them before loading the config bundle.

Now import the .ini file you edited before. PrusaSlicer will overwrite existing configs with the same names, other ones will be left untouched. If you have nothing custom, it is better to first wipe everything before importing so you don't accumulate old cruft. If you make modifications to a config and you want to preserve them, save it as a new config with a unique name to prevent it from being overwritten in a future update.


## Finishing touches

You should calibrate your home offsets to be able to use the entire surface of the print bed. In a nutshell, make sure that the initial priming extrusion is at exactly 3 mm of the front edge of the bed. For more details, [see my FFCP hints webpage](https://www.dr-lex.be/info-stuff/print3d-ffcp.html#hint_calib).



## License
These files are released under a Creative Commons Attribution 4.0 International license.
