# G-code Snippets, Config and Scripts for Using PrusaSlicer (formerly Slic3r) with the Flashforge Creator Pro

This is a set of configuration bundles and post-processing scripts that allow to use the FlashForge Creator Pro 3D printer and compatible clones with PrusaSlicer. [On my website](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) I explain why you should use these files, and how to use PrusaSlicer after installing them. This repository contains the actual software and installation instructions. If you didn't come from that page already, [read the webpage itself](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) for the full story, it will link back here at the appropriate moment.

These configs and G-code are made specifically for *PrusaSlicer.* They might work in the original Slic3r from which PrusaSlicer was forked, but I give no guarantees, and I give no support if you use this with anything else than PrusaSlicer.

Since PrusaSlicer version 2.2, I'm now making releases for these configs with the same version as the PrusaSlicer version they were made for. If for some reason you are using an older version of PrusaSlicer, you should take the .ini file from the release of my configs with the same older version, to avoid backwards compatibility issues.

This repository contains four things:

1. **ConfigBundles:** the main PrusaSlicer config bundle. This is the bare minimum to get things working, but you should preferably also install the next thing:
2. **`make_fcp_x3g.pl`:** a post-processing script that can automate the essential GCode-to-X3G conversion for you, as well as work around an annoying bug in PrusaSlicer, and optionally also invoke certain extra post-processing scripts. You can make do without this script, but it can make your workflow a lot easier.
3. **Optional-postprocessing-scripts:** what the name says. See the README inside that directory for more info.
4. **GCode:** the same G-code snippets that are already embedded into the config bundles, strictly spoken you can ignore this. It is possible that I will make small updates to these snippets without updating the whole config bundles, because that's kind of a hassle. If you see more recent commits in this **GCode** folder than inside the **ConfigBundles** folder and you want the latest and greatest, [follow the instructions on my site](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html#gcode) to update them.


## A warning in advance

**Be careful with the temperatures in the filament presets!** Most likely you will need to reduce certain temperatures because I tweaked them on a Micro Swiss all-metal hot-end with glass bed + hairspray and hardened steel nozzle, and this setup requires higher temperatures than the stock hot-ends. The temperatures for PLA and ABS are safe, but especially the temperatures for PETG, flexible filaments, and obviously polycarbonate, are well above the 240°C limit for the stock hot-ends with their teflon liners.

You should never exceed 240°C for longer than a few minutes if you have not upgraded your hot-ends to all-metal. For PETG you should be able to get decent results at 240°C but I do recommend an all-metal hot-end with a pointy nozzle and higher temperatures to obtain good results with PETG.


# Installation and Setup Instructions

If you have a question, please go through both [the companion webpage](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html) and this README (again). I will most likely not answer any mails that ask something already clearly explained on any of those two pages. If you think parts of this README can be improved, the best thing you can do is provide the improved text, for instance by creating a new GitHub issue or maybe even a pull request, or just by sending the remarks through the contact page of [my website](https://www.dr-lex.be/).

If you are truly stuck and need to contact me, make sure to mention what operating system you are using, and any other possibly relevant information that could help with troubleshooting.


## Step 1: install the `make_fcp_x3g.pl` script

This script can do many things, but its core functions are to apply an important workaround for a certain bug in PrusaSlicer, and then invoke the GPX program to convert the G-code produced by PrusaSlicer into x3g files that the printer understands. This script will be directly or indirectly configured as a *post-processing script* in PrusaSlicer to be run automatically after slicing. It will make your workflow easier.

You can choose not to use this and do the GPX conversion and bug workarounds all manually and tediously. In that case, skip to step 2 below, but I recommend you do not.

If you are using OctoPrint, you don't need GPX because it does the x3g conversion for you. Otherwise, you do need GPX: first [obtain the GPX binary](https://github.com/markwal/GPX) and install it somewhere. Use the most recent GPX build you can find. Do not use 2.0-alpha, it is broken. In Mac OS X, gpx can be installed through [homebrew](https://brew.sh/).\
Important: if you are going to use the WSL Linux environment in Windows, do not install the Windows EXE. Instead, install the Linux GPX executable inside the Linux WSL environment. If you are using Ubuntu 18.04 or newer, running “`sudo apt install gpx`” in a Linux terminal will do the job. Otherwise, manually install the gpx binary and ensure it has executable permissions.

As for the post-processing script itself, you need it regardless of whether you use OctoPrint or not. Your options are:

1. **You are running Linux or Mac OS X:** open the `make_fcp_x3g.pl` Perl script in an editor, and modify it according to its instructions until you hit the “`No user serviceable parts`” line. When done, ensure the file is executable (`chmod a+x make_fcp_x3g.pl`) and remember the **full absolute path** to where you placed it. This will be referred to as `PATH` below. A suitable location would be a ‘bin’ folder in your home directory where you might also store other personal executable files. (An easy way to obtain the absolute path in Mac OS and many recent Linux UIs, is to drag the file into a terminal window.)\
   Try running the script with `-c` argument to see whether you configured it correctly. In Linux, you may need to install the `File::Which` Perl module (Debian or Ubuntu package `libfile-which-perl`).\
   You can now move to *step 2.*
2. **You use a Perl interpreter in Windows:** this is the easiest way to use the script in Windows. I recommend [Strawberry Perl](https://strawberryperl.com/). Copy the script to a location where you have write permissions, and open it in an editor (I recommend [Notepad++](https://notepad-plus-plus.org/)). Modify the script according to its instructions until you hit the “`No user serviceable parts`” line. When done, figure out the full paths to both the Perl executable and the script. To obtain what will be referred to as `PATH` below, put the `perl.exe` path between double quotes, followed by a space, then the script path between double quotes. For instance if you installed Strawberry Perl in its default location, then `PATH` would look like:\
   `"C:\Strawberry\perl\bin\perl.exe" "C:\path\to\make_fcp_x3g.pl"`\
   or if you would be using 64-bit Cygwin:\
   `"C:\cygwin64\bin\perl.exe" "C:\path\to\make_fcp_x3g.pl"`\
   You can now move to *step 2.*
3. **You are running WSL inside Windows:** this is more complicated but if you already have WSL, then it makes more sense to rely on its Perl interpreter than to install yet another one in Windows. You need the `make_fcp_x3g.pl` script, but also a BAT wrapper script to invoke it from within Windows. Follow the *‘WSL instructions’* subsection below.

The above list is sorted from most to least recommended when it comes to ease and functionality. This indeed means that if you have the choice between either, then Linux or Mac OS are preferable over Windows when it comes to running PrusaSlicer with these post-processing scripts.

### WSL instructions

This is only relevant if you want to run the scripts inside WSL. Otherwise, skip to step 2.

For this to work, inside your WSL environment you must have a command `wslpath` that converts Windows paths to their Linux equivalent. This is automatically the case if you have Windows 10 version 1803 or newer with a standard WSL image. If not, follow the instructions in the file `poor_mans_wslpath.txt`. Your WSL version must also support the `WSLPATH` variable, which should be the case for any recent build.

Open the `make_fcp_x3g.pl` script in a text editor and modify it according to its instructions until you hit the “`No user serviceable parts`” line. Important: each time you need to specify the path to a program or script, specify the *Linux file path* where you placed that program (e.g. gpx) or script inside the WSL Linux environment.

When done, save the modified `make_fcp_x3g.pl` inside the Linux filesystem. Ensure both the script and gpx binary (if needed) are executable (`chmod a+x make_fcp_x3g.pl`).

You should now run the script with `-c` argument to check whether it works. It is possible you will have to install the `File::Which` Perl module, which can be done in Ubuntu with:
```
sudo apt install libfile-which-perl
```

Now create a BAT wrapper script in your Windows filesystem, any text editor will do. Save the following content under the file name `slic3r_postprocess.bat`:
```
set fpath=%~1
set fpath=%fpath:'='$'\'''%
set WSLENV=SLIC3R_PP_OUTPUT_NAME/up
bash -c "perl '/your/linux/path/to/make_fcp_x3g.pl' -w '%fpath%'"
```

In the above lines, replace “`/your/linux/path/to`” with the full UNIX style path where you placed the `make_fcp_x3g.pl` script inside the Linux environment. Avoid having spaces, quotes, `$`, or other terminal-unfriendly characters in this path unless you know how to deal with them. (Regarding special characters: the cryptic second line in the BAT file makes it safe to use spaces and `'` quotes in G-code file names, but you should still avoid characters like `$`.)

Now remember the full absolute Windows path to this `slic3r_postprocess.bat` file, you will need it in the next step. This will be referred to as `PATH` below. For instance if your Windows account name is *Foobar* and you placed the file `slic3r_postprocess.bat` in your documents folder on your C drive, then `PATH` is:
```
"C:\Users\Foobar\Documents\slic3r_postprocess.bat"
```
Now you can move to *step 2.*

### A note about Cygwin

It is possible to make this work with [Cygwin](https://www.cygwin.com/), but since I expect the number of Cygwin users to be rather small, you're pretty much on your own. As with WSL, you need to ensure `File::Which` is installed. The most difficult thing is not to get confused between Windows, UNIX, and cygdrive paths. It is best to specify full paths everywhere.


## Step 2: modify the config bundles

In the folder **ConfigBundles** you will find two variations: most likely you will need the regular config bundle. The other one (with ‘MVF’ in its name) is only to be used if you have upgraded your printer with the [MightyVariableFan system](https://github.com/DrLex0/MightyVariableFan).

You need to modify the .ini file before loading it into PrusaSlicer. The steps are described below, but I provide [a webpage that does everything for you](https://www.dr-lex.be/software/ffcp-slic3r-ini-helper.html). This page needs 2 things as input: the `PATH` value as described in the previous steps, and the appropriate config bundle ini file.

Remember, `PATH` must be one of the following, as described in the previous steps:
* if you are running PrusaSlicer in Linux or Mac OS X: the absolute UNIX-style path to the `make_fcp_x3g.pl` script;
* if you use a Perl interpreter in Windows: the absolute Windows-style paths to both `perl.exe` and the `make_fcp_x3g.pl` script, both between double quotes and with a space in between;
* if you run `make_fcp_x3g.pl` inside WSL: the absolute Windows-style path to `slic3r_postprocess.bat`;
* if you opted to skip step 1: nothing, empty (again, not recommended).

Follow the instructions [on the page](https://www.dr-lex.be/software/ffcp-slic3r-ini-helper.html) to obtain the transformed ini file, and then go to step 3.

### Manually preparing the .ini file

In case the helper webpage is unavailable, or you simply crave doing low-level editing of config files, open the appropriate .ini file in a text editor and do a find & replace on all occurrences of the following line, or use `sed` if you are a Linux/UNIX wizard:
```
post_process = /You-need-to-update-print-configs/see-https://bit.ly/3l13MrN
```
Replace all these lines with:
```
post_process = trans_PATH
```
Where you substitute `trans_PATH` with the transformed value of `PATH` as follows. Do the following operations on `PATH` in this order to end up with `trans_PATH`:
1. replace every backslash `\` with a double backslash: `\\`
2. prepend every double quote `"` with one backslash: `\"`
3. put the whole thing between double quotes.

Example: if your `PATH` was:<br>
```"C:\Strawberry\perl\bin\perl.exe" "C:\Stuff\script.pl"```

then the lines in the .ini file must become:<br>
```post_process = "\"C:\\Strawberry\\perl\\bin\\perl.exe\" \"C:\\Stuff\\script.pl\""```

Even if you skipped step 1, you must still update the ini file. The line must be “`post_process = `” in this case. 


## Step 3: load the config bundles in PrusaSlicer

If you open PrusaSlicer for the first time, try to bypass its config wizard and don't select any specific printer type. The way to do this seems to change with every release. If the wizard did create any Print, Filament, or Printer settings, delete them before loading the config bundle.

Now import the .ini file you prepared in step 2. PrusaSlicer will overwrite existing configs with the same names, other ones will be left untouched. If you have nothing custom, it is better to first wipe everything before importing so you don't accumulate old cruft. If you make modifications to a config and you want to preserve them, save it as a new config with a unique name to prevent it from being overwritten in a future update.

You can discard the .ini file, it is no longer needed unless you want to keep it as a backup.

Now would be a good time to [return to the main article](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html#using) to read how to use PrusaSlicer with this config bundle.


## Troubleshooting

If the `make_fcp_x3g.pl` script does not seem to work or produce correct output, the first thing you should try is to manually invoke it with the `-c` parameter to run a ‘sanity check’. If this does not show obvious problems, the next thing to try is to enable the same check when PrusaSlicer invokes the script. This can be done by either adding a `-d` parameter to the invocation of `make_fcp_x3g.pl` in PS itself or in the BAT file, or setting `$DEBUG` to 1 in the script. This will create a file ‘`make_fcp_x3g_check.txt`’ containing the same sanity check report. If this file is not even being created, then the problem happens even before the script is being called.

In Windows, the script is run inside a command window but this window is closed immediately regardless of success or failure. To catch any warnings or error messages, you can cause the window to stay open for a while. For instance to keep it open for 10 seconds, add `-s 10` to the invocation of the `make_fcp_x3g.pl` script, or if you are using WSL, add this extra line at the end of the BAT file:
```
timeout /t 10
```
The Mac OS version of PrusaSlicer doesn't show this kind of output window and I'm not sure whether the Linux version does, so in those cases you have to resort to the `-c` and `-d` options, or start PrusaSlicer from a terminal to see all of its output.


## For the perfectionists

You should calibrate your home offsets to be able to use the entire surface of the print bed. In a nutshell, make sure that the initial priming extrusion is at exactly 3 mm of the front edge of the bed. It is also possible that you can print taller objects than the theoretical 150 mm limit. For more details, [see my FFCP hints webpage](https://www.dr-lex.be/3d-printing/print3d-ffcp.html#hint_calib).



## License
These files are released under a Creative Commons Attribution 4.0 International license.
