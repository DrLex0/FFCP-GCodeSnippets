#!/usr/bin/perl
# Does post-processing specific to the FFCP or similar printers, on G-code
# files generated by PrusaSlicer (Slic3r), assuming it has been configured
# with my custom G-code snippets.
#
# Alexander Thomas a.k.a. DrLex, https://www.dr-lex.be/
# Thanks to lscotte (https://gitlab.com/lscotte) for help with the WSL stuff.
# Released under Creative Commons Attribution 4.0 International license.
#
# Normal usage: call with G-code file as single argument.
# Run with -h for usage info.
#
# In Linux or Mac OS, you should be able to configure the path to this script
# in PrusaSlicer directly as a post-processing script.
#
# In Windows, you have a few options. Simplest is to install a Perl runtime
# like Strawberry Perl. Then set as post-processing script in PrusaSlicer:
# the path to perl.exe (between "quotes"), followed by a space, then the path
# to this script (again between quotes). For instance:
#     "C:\Strawberry\perl\bin\perl.exe" "C:\path\to\make_fcp_x3g.pl";
#
# An alternative is to use the Windows WSL environment if available: create
# a .BAT file containing the following 4 lines, and specify this .BAT file as
# post-processing script in PrusaSlicer/Slic3r.
#     set fpath=%~1
#     set fpath=%fpath:'='$'\'''%
#     set WSLENV=SLIC3R_PP_OUTPUT_NAME/up
#     bash -c "perl '/your/linux/path/to/make_fcp_x3g.pl' -w '%fpath%'"
# For this to work, there must be a command `wslpath` inside your Linux
# environment that converts Windows paths to their Linux equivalent. This is
# the case if you use Microsoft's WSL images inside Windows 10 version 1803
# or newer. In other cases you need to provide your own `wslpath` script.
#
# This script does the following things in this sequence:
# 1. Ensure the final Z move in the end G-code will not destroy your print,
#    and warn about prints exceeding the maximum Z height.
# 2. Either:
#   - IMPORTANT! Fix incorrect second layer temperature command for single
#     extrusion prints, to work around Slic3r bug #4003 / PrusaSlicer #2210;
#     or:
#   - Optionally run the dualstrusion post-processing script if the file has
#     start G-code for dual extrusion.
# 3. Ensure gcode.ws correctly displays files that use relative E values.
# 4. Optionally run the MightyVariableFan PWM post-processing script.
# 5. Optionally apply my retraction improver hack.
# 6. Optionally run the G-code file through GPX to produce an x3g file.

use strict;
use warnings;
use Fcntl qw(SEEK_CUR SEEK_END);
use File::Basename;
use File::Spec;
use File::Temp qw/tempfile/;
use File::Which;
use Getopt::Std;


### DO NOT EDIT THIS SCRIPT. ###
# Configuration must now be done in a separate text file. By default this
# script will look for a file "make_fcp_x3g.txt" in the same location as this
# script. You can specify a different config file with the -f parameter.
# Run the script with the -c option to check whether you correctly configured
# the text file.

############ No user serviceable parts below ############

our $VERSION = '20211212';

# Defaults. Each variable will be overridden if specified in the config file.
# If an array is specified in the file for a SINGLE-value item, only the first
# element of the array will be considered.
# In theory the script could be run without a config file at all, but I don't
# allow this because it would hide configuration mistakes.
my $EXTRA_PATH = '';
my $KEEP_ORIG = 0;
my $DEBUG = 0;

my $GPX = '';
my @DUALSTRUDE_SCRIPT;
my @PWM_SCRIPT;
my @RETRACT_SCRIPT;

my $Z_MAX = 150;
# Default comment string that marks the final Z move in the end G-code.
my $FINAL_Z_MOVE = '; send Z axis to bottom of machine';
my $MACHINE = 'r1d';


sub HELP_MESSAGE
{
	my $prog = basename($0);
	print <<__END__;
${prog} [-dwPpkv] [-f FILE] [-s S] input.gcode   or:   ${prog} -c
Processes G-code file for the FFCP and optionally converts it to X3G using GPX.
Input file is overwritten and the X3G file is placed next to it, unless the
SLIC3R_PP_OUTPUT_NAME environment variable exists. In the latter case, all
additional files will be created based on the path indicated by that variable.

Options:
  -f FILE: use custom config file. By default, the script looks for a file
      'make_fcp_x3g.txt' in the same directory as the script. A config file
      is mandatory (it may be empty though).
  -c: performs a sanity check on all configured paths, and warns if they do
      not point to executable files. (Nothing will be processed even if other
      arguments are passed.)
  -d: debug mode: performs the sanity check, writes its result to a file
      'make_fcp_x3g_check.txt' in the same directory as the input, and then
      continues processing.
  -w: converts Windows file path to a Linux path inside a WSL environment.
  -P: disables all postprocessing and only runs GPX without -p option.
  -p: enable -p option of GPX even if -P is used.
  -k: keep copy of original file.
  -s S: pause S seconds when exiting, useful for troubleshooting in Windows.
  -v: verbose output.
__END__
}


my $conf_file = File::Spec->catfile(dirname($0), 'make_fcp_x3g.txt');

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %opts;
exit 2 if(! getopts('hf:cdwPpks:v', \%opts));

if($opts{'h'}) {
	HELP_MESSAGE();
	exit;
}
# OK, I lied. The config file can be bypassed with -f 0, but you do so at your own risk.
$conf_file = $opts{'f'} if(defined $opts{'f'} && $opts{'f'} ne '');
my $sanity = $opts{'c'};
my $wsl = $opts{'w'};
my $no_postproc = $opts{'P'};
my $force_progress = $opts{'p'};
my $exit_sleep = $opts{'s'};
my $verbose = $opts{'v'};

my @config_warnings;
read_config($conf_file) if($conf_file);

$KEEP_ORIG = 1 if($opts{'k'});
$DEBUG = 1 if($opts{'d'});

if(defined $exit_sleep && $exit_sleep !~ /^\d?\.?\d+$/) {
	print STDERR "ERROR: argument following -s must be a positive number\n";
	# Since someone is probably trying to add the -s argument to catch an
	# error briefly flashing, sleep with a default to show this error.
	$exit_sleep = 3;
	do_exit(2);
}

if($EXTRA_PATH) {
	if($^O =~ /^MSWin/) {
		$ENV{'PATH'} = "${EXTRA_PATH};$ENV{PATH}";
	}
	elsif($ENV{'PATH'} =~ m!(:|^)/usr/bin:!) {
		$ENV{'PATH'} =~ s!(:|^)/usr/bin:!$1${EXTRA_PATH}:/usr/bin:!;
	}
	else {
		$ENV{'PATH'} = "${EXTRA_PATH}:$ENV{PATH}";
	}
}

if($sanity) {
	sanity_check();
	exit;
}

my $inputfile = shift;
if(! defined $inputfile || $inputfile eq '') {
	print STDERR "ERROR: argument should be the path to a .gcode file\n";
	HELP_MESSAGE();
	do_exit(2);
}

if($wsl) {
	# Although the conversion between Windows and Linux paths seems trivial, it
	# has many quirks so it is better to rely on the dedicated wslpath tool.
	print "Converting incoming Windows path '${inputfile}' to UNIX path\n" if($verbose);
	my $in_esc = shellEscape($inputfile);
	$inputfile = qx(wslpath -a ${in_esc});
	$inputfile =~ s/\n$// if($inputfile);
	if($? || ! defined $inputfile || $inputfile eq '') {
		seppuku("FATAL: 'wslpath' command not found or failed\n");
	}
	print "Converted Windows path to WSL path: '${inputfile}'\n";
}

# In case of WSL, this variable must already be converted to a Linux path.
my $outputfile = $ENV{'SLIC3R_PP_OUTPUT_NAME'} ? $ENV{'SLIC3R_PP_OUTPUT_NAME'} : $inputfile;

my ($i_handle, $o_handle);

if($DEBUG) {
	my $check_out = File::Spec->catfile(dirname($outputfile), 'make_fcp_x3g_check.txt');
	open($o_handle, '>', $check_out) or seppuku("FATAL: cannot write to '${check_out}': $!\n");
	sanity_check($o_handle);
	close($o_handle);
}

if(! -r $inputfile) {
	print STDERR "ERROR: input file not found or not readable: ${inputfile}\n";
	do_exit(2);
}

(my $stripped = $outputfile) =~ s/\.[^.]+$//;
my $origfile = "${stripped}_orig.gcode";
my $warn_file = "${stripped}.WARN.txt";
my $fail_file = "${stripped}.FAIL.txt";

# -p in GPX overrides % display with something that better approximates total
# print time than merely mapping the Z coordinate to a percentage. It still is
# not perfect but at least gives a sensible ballpark figure. For this to work
# properly, cargo cult folklore says that the start GCode block must end with
# "M73 P1 ;@body", although a peek in GPX source code reveals that either
# "M73 P1" or @body will work.
my $arg_p = $force_progress ? '-p' : '';

if(! $no_postproc) {
	$arg_p = '-p';

	unlink($warn_file, $fail_file);
	copy_file('original', $inputfile, $origfile) if($KEEP_ORIG);

	adjust_final_z() if($FINAL_Z_MOVE);

	my ($dualstrude, $left_right, $m104_seen, $m83_seen, $fix_m104);
	open($i_handle, '<', $inputfile) or seppuku("FATAL: cannot read from ${inputfile}: $!\n");
	my $i = 0;
	foreach my $line (<$i_handle>) {
		$dualstrude = 1 if(! $dualstrude && $line =~ /^;- - - Custom G-code for dual extruder printing/);
		$left_right = 1 if(! $left_right && $line =~ /^;- - - Custom G-code for (left|right) extruder printing/);
		$m104_seen = 1 if(! $m104_seen && $line =~ /^M104 S.+ T.+; set temperature$/);
		$m83_seen = 1 if(! $m83_seen && $line =~ /^M83(;|\s|$)/);
	}
	close($i_handle);

	if($dualstrude && postproc_script_valid(@DUALSTRUDE_SCRIPT)) {
		run_script('dualstrusion', $inputfile, @DUALSTRUDE_SCRIPT);
	}
	elsif($left_right && $m104_seen) {
		$fix_m104 = 1;
	}

	if($fix_m104 || $m83_seen) {
		# The fix consists of dropping any T argument in slicer-inserted
		# M104 commands and relying on GPX to apply the command to the
		# currently active tool.
		print "Fixing incorrect M104 command for single-extrusion setup\n" if($fix_m104);
		# Workaround for issue #60 in gCodeViewer (gcode.ws) that messes up
		# rendering if an M83 is followed by a G90.
		print "Ensuring correct display in gcode.ws\n" if($m83_seen);
		my $tmpname;
		($o_handle, $tmpname) = tempfile();
		open($i_handle, '<', $inputfile) or seppuku("FATAL: cannot read from ${inputfile}: $!\n");
		foreach my $line (<$i_handle>) {
			# I am entirely relying here on the assumption that any Slic3r version
			# will keep on printing the code with a comment exactly like this.
			$line =~ s/^M104 S(\S+) (T.*); set temperature$/M104 S$1 ; POSTPROCESS FIX: $2 ARGUMENT REMOVED/ if($fix_m104);
			# Again, I'm assuming Slic3r-alikes will always print the line
			# exactly like this:
			$line =~ s/^(G90 ; use absolute coordinates)$/$1\nM83; POSTPROCESS workaround for relative E in gcode.ws/ if($m83_seen);
			print $o_handle $line;
		}
		close($o_handle);
		close($i_handle);
		copy_file('temporary', $tmpname, $inputfile);
		unlink($tmpname);
	}

	if(postproc_script_valid(@RETRACT_SCRIPT)) {
		run_script('retraction', $inputfile, @RETRACT_SCRIPT);
	}

	if(postproc_script_valid(@PWM_SCRIPT)) {
		run_script('fan PWM post-processing', $inputfile, @PWM_SCRIPT);
	}
}

if(which($GPX) || (-x $GPX && -f $GPX)) {
	print "Invoking GPX...\n";
	# TODO: errors from this command should also be collected. Perhaps filter
	# out the M132 warnings, although they should not appear with properly
	# written start code.
	my $gpx_esc = shellEscape($GPX);
	my $in_esc = shellEscape($inputfile);
	(my $out_esc = $outputfile) =~ s/\.gcode$//gi;
	$out_esc = shellEscape("${out_esc}.x3g");
	print "Executing: ${gpx_esc} ${arg_p} -m \"${MACHINE}\" ${in_esc} ${out_esc}\n" if($verbose);
	my $gpx_out = qx(${gpx_esc} ${arg_p} -m "${MACHINE}" ${in_esc} ${out_esc} 2>&1);
	print $gpx_out if($verbose && $gpx_out);
}

do_exit(0);


#### SUBROUTINES ####

sub seppuku
# Exit with error message, similar to die but with pause if configured.
{
	my $err = $!;
	$err = $? >> 8 if(! $err && $? >> 8);
	$err = 255 if(! $err);
	print STDERR @_;
	sleep($exit_sleep) if($exit_sleep);
	exit $err;
}

sub do_exit
# Exit without error message, with pause if configured.
{
	sleep($exit_sleep) if($exit_sleep);
	exit shift;
}

sub shellEscape
# Turns a file path argument into a double-quoted string that should be safe
# to use as a single unit in shell invocations.
{
	my $path = shift;

	if($^O =~ /^MSWin/) {
		# Fool-proof quoting of arguments in cmd.exe is pretty much
		# impossible, but if input is known to be a file path, then it should
		# suffice to wrap it between double quotes and escape any " inside it.
		$path =~ s/"/\\"/g;
	}
	else {
		# In UNIX-alikes, also wrap between double quotes and escape anything
		# that could be interpolated.
		$path =~ s/([\"\`\\\$])/\\$1/g;
	}
	return "\"${path}\"";
}

sub read_config
# Parse a config file (normally make_fcp_x3g.txt), and set any variables
# defined in it.
{
	my $f_path = shift;

	open(my $f_handle, '<', $f_path) or seppuku("FATAL: cannot read ${f_path}\nPut a readable configuration file at that path, or provide a different one with -f.\n");
	my $n = 0;
	foreach my $line (<$f_handle>) {
		$n++;
		chomp($line);
		next if($line =~ /^\s*(#.*)?$/);

		# Parse the line
		my ($item, $val) = ($line =~ m/^\s*(\S+)\s*=\s*(.*?)\s*$/);
		if(! defined $item || $item eq '') {
			push(@config_warnings, "Ignored malformed line ${n}.");
			next;
		}
		my @vals;
		if($val =~ /^("[^"]*"\s*)*$/) {
			@vals = ($val =~ m/"(.*?)"/g);
		}
		else {
			push(@vals, $val);
			push(@config_warnings, "Double quote(s) found in value for '${item}' but could not parse as ARRAY, hence interpreted as SINGLE.") if($val =~ /"/);
		}

		# Assign the variable. 'eval' is generally evil but OK in this situation.
		if(grep(/^$item$/, ('KEEP_ORIG', 'DEBUG', 'EXTRA_PATH', 'GPX', 'Z_MAX', 'FINAL_Z_MOVE', 'MACHINE'))) {
			if(@vals) {
				eval("\$${item} = \$vals[0];");
				push(@config_warnings, "An array was specified for SINGLE item '${item}', only using first element.") if($#vals > 0);
			}
			else {
				eval("\$${item} = '';");
			}
		}
		elsif(grep(/^$item$/, ('DUALSTRUDE_SCRIPT', 'PWM_SCRIPT', 'RETRACT_SCRIPT'))) {
			eval("\@${item} = \@vals;");
		}
		else {
			push(@config_warnings, "Ignored unknown item '${item}'.");
		}
	}
	close($f_handle);
}

sub append_warning {
	my $msg = shift;

	print "Appending warnings:\n${msg}\n" if($verbose);
	open(my $fh, '>>', $warn_file) or seppuku("FATAL: cannot write to ${warn_file}: $!\n");
	print $fh "${msg}\n";
	close($fh);
}

sub copy_file
{
	my ($in_kind, $in_path, $out_path) = @_;

	open(my $i_handle, '<', $in_path) or seppuku("FATAL: failed to read ${in_kind} file '${in_path}': $!\n");
	open(my $o_handle, '>', $out_path) or seppuku("FATAL: failed to write to file '${out_path}': $!\n");
	my $chunk;
	my $chars = 0;
	do {
		$chars = read($i_handle, $chunk, 32768);
		print $o_handle $chunk if($chars);
	}
	while($chars);
	close($o_handle);
	close($i_handle);
}

sub gpx_insane
{
	my $o_handle = shift;

	unless(which($GPX) || (-x $GPX && -f $GPX)) {
		print $o_handle "Check failed: the 'GPX' path was specified but does not point to an executable file: ${GPX}\n";
		return 1;
	}
	my $gpx_esc = shellEscape($GPX);
	my $junk = qx(${gpx_esc} -? 2>&1);
	if($?) {
		print $o_handle "Check failed: got unexpected result code when running gpx with -? argument: $?\n";
		return 1;
	}
	$junk = qx(echo T0 | ${gpx_esc} -i -m "${MACHINE}" 2>&1);
	if($?) {
		print $o_handle "Check failed: got error when running gpx with '${MACHINE}' machine type. Make sure this is supported. If not, try setting MACHINE to 'r1d'.\n";
		return 1;
	}
	return 0;
}

sub postproc_script_insane
# Check a postprocessing script that is possibly explicitly invoked through an interpreter.
# The script is expected to do nothing and cleanly exit when invoked with -h argument.
{
	my ($o_handle, $name, @script_config) = @_;

	my $exc = $script_config[0];
	unless(which($exc) || (-x $exc && -f $exc)) {
		print $o_handle "Check failed: the first element in the '${name}' list does not point to an executable file: ${exc}\n";
		return 1;
	}
	# Check existence of .py and .perl script files after interpreter
	if($#script_config > 0 && $script_config[1] =~ /\.p[ly]$/i) {
		if(! -r $script_config[1] || ! -f $script_config[1]) {
			print $o_handle "Check failed: the second element in the '${name}' list does not point to a readable script: ${script_config[1]}\n";
			return 1;
		}
	}

	my $cmd = join(' ', map(shellEscape($_), @script_config));
	my $junk = qx(${cmd} -h 2>&1);
	if($?) {
		print $o_handle "Check failed: got unexpected result code when running ${name} with -h argument.\n";
		return 1;
	}
	return 0;
}

sub postproc_script_valid
# Lightweight variation on postproc_script_insane that only checks whether
# it seems like a usable script is configured.
{
	my @script_config = @_;

	return 0 if(! @script_config);
	my $exc = $script_config[0];
	unless(which($exc) || (-x $exc && -f $exc)) {
		print "'${exc}' is not (an) executable, ignoring.\n" if($verbose);
		return 0;
	}
	if($#script_config > 0 && $script_config[1] =~ /\.p[ly]$/i) {
		if(! -r $script_config[1] || ! -f $script_config[1]) {
			print "'${script_config[1]}' is not a readable script file, ignoring.\n" if($verbose);
			return 0;
		}
	}
	return 1;
}

sub wsl_insane
{
	my $o_handle = shift;

	open(my $proc_f, '<', '/proc/version') or return 0;
	my @proc_version = <$proc_f>;
	close($proc_f);
	return 0 if(! grep(/(Microsoft|WSL)/, @proc_version));
	print "WSL detected\n" if($verbose);
	my $try_path = qx(wslpath -a 'C:\\Test\\file.zip');
	if($? || ! defined $try_path || $try_path eq '') {
		print $o_handle "Check failed: you seem to be inside a WSL environment but the 'wslpath' command is not available or is broken.\n";
		print $o_handle "Make sure you have at least Windows 10 version 1803, and 'wslpath' can be run from a bash shell.\n";
		return 1;
	}
	return 0;
}

sub sanity_check
{
	my $o_handle = shift;
	$o_handle = \*STDERR if(! $o_handle);

	print $o_handle "Running sanity check for script version ${VERSION}.\nPATH is:\n${ENV{'PATH'}}\n\n";

	if($ENV{'SLIC3R_PP_OUTPUT_NAME'}) {
		print $o_handle "SLIC3R_PP_OUTPUT_NAME is defined:\n${ENV{'SLIC3R_PP_OUTPUT_NAME'}}\n\n";
	}
	my $fail;
	if($GPX) {
		$fail = 1 if(gpx_insane($o_handle));
	}
	if(@DUALSTRUDE_SCRIPT) {
		$fail = 1 if(postproc_script_insane($o_handle, 'DUALSTRUDE_SCRIPT', @DUALSTRUDE_SCRIPT));
	}
	if(@PWM_SCRIPT) {
		$fail = 1 if(postproc_script_insane($o_handle, 'PWM_SCRIPT', @PWM_SCRIPT));
	}
	if(@RETRACT_SCRIPT) {
		$fail = 1 if(postproc_script_insane($o_handle, 'RETRACT_SCRIPT', @RETRACT_SCRIPT));
	}
	if(-r '/proc/version') {
		$fail = 1 if(wsl_insane($o_handle));
	}

	if(@config_warnings) {
		print $o_handle "WARNING: found the following suspect things in the configuration file at '${conf_file}'. Please check the correctness of that file.\n";
		print $o_handle join("\n", @config_warnings) ."\n";
	}
	else {
		print $o_handle "All checks seem OK!\n" if(! $fail);
	}
}

sub run_script
# Runs a script that can write output to a file given as -o argument.
# The script is expected not to output anything on stdout or stderr when
# everything went fine.
# If the script exits with an error code, combined stdout and stderr will be
# written to $fail_file and all processing will be aborted. Otherwise,
# anything appearing on stdout or stderr is written to $warn_file.
# The original gcode file is overwritten.
{
	my ($name, $gcode, @cmd) = @_;

	print "Running ${name} script...\n";
	my ($o_handle, $tmpname) = tempfile();
	# File will not be unlinked because we requested the file name.
	close($o_handle);

	my $cmd = join(' ', map(shellEscape($_), @cmd));
	my $tmpname_esc = shellEscape($tmpname);
	my $gcode_esc = shellEscape($gcode);
	my $err_out;

	print "Executing: ${cmd} -o ${tmpname_esc} ${gcode_esc}\n" if($verbose);
	my $warnings = qx(${cmd} -o ${tmpname_esc} ${gcode_esc} 2>&1);
	if($?) {
		$warnings = "The ${name} script failed ($?), but without any output.\n" if(! $warnings);
		open($o_handle, '>>', $fail_file) or seppuku("FATAL: failed to write to '${fail_file}'\n");
		print $o_handle $warnings;
		close($o_handle);
		print STDERR "FATAL: running ${name} script failed, aborting postprocessing.\n";
		do_exit(1);
	}
	# Instead of using File::Copy, just read and write the data so we don't
	# need to care about permissions of the tempfile.
	copy_file('temporary', $tmpname, $gcode);
	unlink($tmpname);

	append_warning($warnings) if($warnings);
}

sub adjust_final_z
# Finds the highest Z value in a G1 command from the last 2048 lines of
# $inputfile, and if it is higher than the command in the line containing
# FINAL_Z_MOVE, it updates that line to prevent the move from ramming the
# nozzle into the print.
{
	open(my $f_handle, '+<', $inputfile) or seppuku("FATAL: cannot open '${inputfile}' for reading+writing.\n");
	my @lines;
	my $chunk;
	my $chunk_size = 16384;
	my $partial_line = '';
	seek($f_handle, 0, SEEK_END);
	while($#lines < 2048 && tell($f_handle) > 0) {
		$chunk_size = tell($f_handle) if(tell($f_handle) < $chunk_size);
		seek($f_handle, -$chunk_size, SEEK_CUR);
		my $c_read = read($f_handle, $chunk, $chunk_size);
		seek($f_handle, -$c_read, SEEK_CUR);
		# 'unlimited' limit to include trailing separators
		my @more_lines = split("\n", $chunk, -1);
		$more_lines[-1] .= $partial_line;
		$partial_line = shift(@more_lines);
		unshift(@lines, @more_lines);
	}
	if(tell($f_handle) <= 0) {
		unshift(@lines, $partial_line);
		undef $partial_line;
	}

	my $highest_z = -1;
	my $final_z = -1;
	my $final_index = -1;
	my $i = 0;
	foreach my $line (@lines) {
		if($line =~ /^G1 [^;]*Z(\d*\.?\d+)/) {
			$highest_z = $1 if($1 > $highest_z);
		}
		if($line =~ /^G1 [^;]*Z(\d*\.?\d+).*\Q${FINAL_Z_MOVE}\E/) {
			$final_z = $1;
			$final_index = $i;
		}
		$i++;
	}

	print "Highest Z coordinate found: ${highest_z}\n" if($verbose);
	if($highest_z == -1) {
		append_warning('WARNING: could not find highest Z coordinate. If this is a valid G-code file, the make_fcp_x3g script needs updating.');
		close($f_handle);
		return;
	}
	if($highest_z > $Z_MAX) {
		append_warning("WARNING: Z coordinates in this file exceed the maximum: ${highest_z} > ${Z_MAX}. This print will likely end in disaster.");
	}
	if($highest_z > $final_z) {
		print "Updating final Z move\n" if($verbose);
		$lines[$final_index] =~ s/^(G1 [^;]*Z)\d*\.?\d+(.*)$/$1${highest_z}$2 ; EXTENDED!/;
		# Overwrite the file at the current read/write pointer
		print $f_handle "${partial_line}\n" if(defined $partial_line);
		print $f_handle join("\n", @lines);
		truncate($f_handle, tell($f_handle));
	}
	close($f_handle);
}
