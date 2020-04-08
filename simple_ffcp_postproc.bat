:: This is a rudimentary equivalent of the make_fcp_x3g Bash script for using under Windows without a WSL environment.
:: It is preferable to use the Bash script if you can, it can do more than this BAT script.

:: Before you can use this, you need to do the following:
:: 1. Install Perl, e.g. through Strawberry Perl or Cygwin.
:: 2. Adjust the path to the perl.exe binary below. Depending on your installation, perhaps just 'perl' may work, otherwise use the full path (example is for 64-bit cygwin).
:: 3. Adjust the path to gpx.exe below.

set fpath=%~1
find /c ";- - - Custom G-code for left extruder printing" %fpath%
if %errorlevel% equ 1 goto rungpx

:: Apply the workaround for Slic3r's assumption that any single-extruder printer profile uses T0 only.
:: This assumes that any version of Slic3r will keep on printing the M104 command in exactly the same format.
:: ADJUST PERL PATH HERE:
C:\cygwin64\bin\perl.exe -pi -e "s/^M104 S(\S+) (T.*); set temperature/M104 S$1 ; POSTPROCESS FIX: $2 ARGUMENT REMOVED/" %fpath%
:: Some editions of Perl in Windows cannot do in-place editing without making a backup file, so delete if there is one.
if exist %fpath%.bak del %fpath%.bak

:rungpx
:: ADJUST GPX PATH HERE: (or comment out this line if you want to run gpx manually)
C:\Where\you\installed\gpx.exe -m r1d %fpath%
