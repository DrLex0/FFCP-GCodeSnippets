#!/usr/bin/perl
# Post-processing script that adds extra length after retract depending on travel distance.
# In theory, the pressure advance algorithm in the Sailfish firmware should perform this kind of
#   compensation, but either it doesn't or is insufficient. Hence this quick hack, which offers
#   a significant quality improvement for very little effort.
# This also compensates for the typical extrusion delay when the print starts, that causes a gap
#   in the skirt.
# Beware: this script will cause obvious over-extrusion in certain situations, for instance when
#   printing two thin solid pillars with considerable distance between them. In that case you
#   may want to disable the script or lower $thresholdSlope.
#
# Alexander Thomas a.k.a. DrLex, https://www.dr-lex.be/
# Released under Creative Commons Attribution 4.0 International license.
#
# Run with -h for usage information.
#
# The script requires relative extruder coordinates because this makes the implementation much
#   more sane. The start G-code *must* contain an M83 command before the '@body' marker. If not,
#   it will warn on stderr and output the unmodified file.
#
# The idea behind it:
# I noticed that the extruder seems to require an increasingly long time to rebuild pressure,
#   the longer the time between a retraction and resuming printing. Also, longer travels mean more
#   ooze, which also means a small gap when resuming. Therefore this script adds extra length on
#   resume that increases according to the length of the travel move.
# From some quick & dirty experiments and severe wet-finger guessing, I ended up with a logarithmic
#   function as the relation between travel distance and the required amount of extra extrusion.
#   This makes some sense because the nozzle can accelerate more during long travels, therefore the
#   time increase per distance is below linear; moreover the loss of pressure will stabilise over
#   time as well.
# The equation is ln((x + a - th)/a) / flatness
#   with x        = the distance travelled,
#        th       = the threshold distance above which compensation is applied,
#        flatness = the overall rate at which the compensation curve flattens,
#        slope_th = the desired slope of the curve for x = th.
#   Therefore: a = 1/(slope_th * flatness)  or  slope_th = 1/(a * flatness)
#
# TODO: it is obvious that this risks causing over-extrusion. Usually it isn't a problem but when
#   printing e.g. thin solid pillars spaced far apart, they will become too thick due to extra
#   material dumped into them. To make it correct, the added material after the unretract should
#   be removed elsewhere, except for maybe a tiny fraction to cater for material lost due to
#   oozing/stringing. I would remove part from the last few mm before doing the retract (making
#   this similar to S3D 'coast'), and also part from the first few mm after resuming. Removing
#   pressure before retract could also help considerably with oozing and stringing.
#   Beware: wipe-on-retract will make this more complicated.
# TODO: this doesn't work for Cura because it formats its G-code differently. Should make parser
#   more generic. However, Cura doesn't support relative E coordinates, so the only sane way to
#   make it work is to first convert the file to relative E.

use strict;
use warnings;
use File::Basename;
use Getopt::Std;


#### Configurable options ####

# Initial unretract compensation hack: squirt out this much extra filament when unretracting for
# the first time after the start G-code. I have NO idea why this is necessary but without it, the
# first bit of the skirt is always horribly under-extruded.
my $extraFirstUnretract = 0.6;

# The following values are tweaked for a retraction of about 1mm at about 10mm/s. Optimal values
# will probably vary per retraction settings and filament type.

# The travel distance in mm below which no additional un-retract will be added ('th' in equations).
# To disable unretract compensation entirely, set this to a negative value.
my $distanceThreshold = 10;
# The rate around the point of distanceThreshold, at which extra extrusion is added per mm beyond
# distanceThreshold ('slope_th' in equations). Must be greater than 0.
my $thresholdSlope = 1/400;  # or 0.025mm extra per cm
# The overall flatness of the compensation curve. Larger values will more quickly decrease the rate
# of extra extrusion as we go further away from distanceThreshold, i.e. cause a flatter curve.
# Must be greater than 0.
my $flatness = 10;

# The line that indicates printing has ended, statistics will be inserted right after this.
# This avoids messing up the terribly fragile feature of PrusaSlicer to load configs from gcode
# files. If the marker cannot be found, the info will be at the end and you will need to remove it
# if you want to load config from the file.
my $gcodeEndMarker = ';- - - End finish printing G-code - - -';

# Will be prepended as program identifier to log messages
my $progId = 'retr-impr';

# Maximum number of tools. It makes sense to set this to the number of tools your printer supports.
my $maxTools = 2;


###### No user serviceable parts below ######
our $VERSION = '0.8';

sub HELP_MESSAGE
{
	my $prog = basename($0);
	print <<__END__;
Usage: ${prog} [-hds] inputFile > output
   or: ${prog} [-hds] -o output inputFile
Retraction-improver version ${VERSION}
Options:
  -h: show usage information and exit
  -d: debug mode (extra spam on stderr)
  -s: stats mode: print statistics on stderr
  -o FILE: write to FILE instead of stdout.
Never use the same file for both inputFile and output!
__END__
}


###### MAIN ######
my ($DEBUG, $INFO, $WARNING, $ERROR, $FATAL) = (10, 20, 30, 40, 50);
my %logLevelNames = (10 => 'DEBUG', 20 => 'INFO', 30 => 'WARNING', 40 => 'ERROR', 50 => 'FATAL');

my $logLevel = $INFO;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %opts;
exit 2 if(! getopts('hdso:', \%opts));

if($opts{'h'}) {
	HELP_MESSAGE();
	exit;
}
if($opts{'d'}) {
	$logLevel = $DEBUG;
	logMsg($DEBUG, 'Debug output enabled, prepare to be spammed');
}
my $statsMode = $opts{'s'};

my $inFile = shift;
seppuku(2, 'No input file specified') if(!$inFile);
if(defined $opts{'o'} && $opts{'o'} ne '') {
	die "ERROR: output file cannot be the same as input file\n" if($opts{'o'} eq $inFile);
}

if($thresholdSlope * $flatness == 0) {
	seppuku(2, 'Both thresholdSlope and flatness parameters must be greater than 0');
}

my $a = 1/($thresholdSlope * $flatness);

my ($isHeaderPart1, $isHeaderPart2, $isFooter, $inToolChangeCode) = (1, 0, 0, 0);
my ($retractLength, $retractSpeed, $travelSpeed);  # For stupid bug workaround
my $firstRetract = 1;  # For stupid bug workaround
my $relativeE = 0;  # The file uses relative E coordinates (M83 command): mandatory!
my $firstUnretract = 1;  # For skirt under-extrusion hack in case of relative E
my $lineNumber = 0;

my $activeTool;
# How much was extruded by the original file at the current input line. Only used for statistics.
my @originalE = (0) x $maxTools;
# How much extra filament this script has pushed out. Also only used for statistics.
my @offsetE   = (0) x $maxTools;
# How far the extruders are currently retracted. These values can only be negative or 0.
my @retracted = (0) x $maxTools;
my @travel = (0) x $maxTools;  # How far the extruder has moved since the last retract.
my ($lastX, $lastY);

my $fHandle;
open($fHandle, '<', $inFile) or seppuku(1, "Cannot read file '${inFile}': $!");
my @output;
my $modified = 0;
my $totalTravel = 0.0;
foreach my $line (<$fHandle>) {
	$lineNumber++;
	chomp($line);

	# When we have reached the footer, we don't care for anything that happens in it.
	if($isFooter) {
		push(@output, $line);
		next;
	}

	# Always detect tool changes. Unlike the dualstrusion script, we cannot make any assumptions.
	if($line =~ /^T(0|1)/) {  # Tool change
		my $previousTool = $activeTool;
		$activeTool = $1;
		if($logLevel <= $DEBUG) {
			if(defined($previousTool)) {
				logMsg($DEBUG, "Tool change from ${previousTool} to ${activeTool}");
			}
			else {
				logMsg($DEBUG, "Initial tool set to ${activeTool}");
			}
		}
		# Unlike the dualstrusion script, we don't really care how many tools are being used.
		# The only limitation is the size of our arrays.
		seppuku(1, "More than ${maxTools} tools not supported.") if($activeTool >= $maxTools);
		if(defined($previousTool) && $previousTool == $activeTool) {
			logMsg($DEBUG, "tool change to same tool detected at line ${lineNumber}");
		}
		else {
			# This should always be a null operation, however do it anyway just to be sure.
			$travel[$activeTool] = 0;
		}
		push(@output, $line);
		next;
	}

	if($isHeaderPart1) {
		# Unconditionally treat everything up to the "@body" marker as header.
		if($line =~ /^[^;]*;\@body(\s|;|$)/) {
			$isHeaderPart1 = 0;
			$isHeaderPart2 = 1;
			logMsg($DEBUG, 'Reached end of header part 1');
		}
		elsif($line =~ /^;travel speed = (\d*\.?\d+)/) {
			$travelSpeed = $1 * 60.0;
			logMsg($DEBUG, "Found travel feedrate ${travelSpeed}");
		}
		elsif($line =~ /^;retract speed(?: \(right\))? = (\d*\.?\d+)/) {
			# Only consider first extruder if dualstrusion, this hack is complicated enough already
			$retractSpeed = $1 * 60.0;
			logMsg($DEBUG, "Found retract feedrate ${retractSpeed}");
		}
		elsif($line =~ /^;retract length(?: \(right\))? = (\d*\.?\d+)/) {
			$retractLength = $1 * 1.0;
			logMsg($DEBUG, "Found retract length ${retractLength}");
		}
		elsif($line =~ /^M83(;|\s|$)/) {
			$relativeE = 1;
			logMsg($DEBUG, 'M83 command for relative E coordinates detected, good');
		}
		elsif($line =~ /^M82(;|\s|$)/) {
			$relativeE = 0;
			logMsg($DEBUG, 'M82 command for absolute E coordinates detected, bad');
		}
		push(@output, $line);
		next;
	}
	elsif($isHeaderPart2) {
		# Then look for the point where the main code has 'moved' to the first layer height.
		if($line =~ /^G1 Z(\S+)([ ;]|$)/) {
			$isHeaderPart2 = 0;
			logMsg($DEBUG, 'Reached end of header part 2');
			if(! $relativeE) {
				logMsg($ERROR, 'Relative E coordinates are required for the retraction-improver script. The file will be left unmodified.');
				$isFooter = 1;
			}
		}
		elsif($line =~ /^G1 E(\S+) .*/) {
			# Retract or unretract. Don't do anything yet, just record the retract state
			$firstRetract = 0 if($1 < 0);
			$retracted[$activeTool] += $1;
			$retracted[$activeTool] = 0 if($retracted[$activeTool] > 0);
		}
		push(@output, $line);
		next;
	}
	elsif($line =~ /^;- - - Custom finish printing G-code/) {
		$isFooter = 1;
		logMsg($DEBUG, 'Reached footer G-code');
		push(@output, $line);
		next;
	}

	# We're in the main body of the G-code now. Look for retraction moves, and modify unretracts
	# based on travel since the retract position.
	if($line =~ /^G1 (Z\S+ )?X(\S+) Y(\S+) E(\S+)($|;.*|\s.*)/) {
		# Print move. The extra Z argument occurs during spiral vase mode prints.
		my ($z, $x, $y, $e, $extra) = ($1, $2, $3, $4, $5);
		push(@output, $line);
		if($e > 0) {
			# Keep track of this just for the statistics (also a good sanity check for correctness
			# of the script)
			$originalE[$activeTool] += $e;
		}
		else {
			# When 'wipe on retract' is enabled, the retract is spread across the wipe move(s),
			# followed by a final pure retract that is 5% of the total retract distance.
			# (At least, that's is how it is in Prusa3D 1.38.4.)
			# We consider the start of the travel move the final wipe position, not the first.
			$retracted[$activeTool] += $e;
		}
		$lastX = $x;
		$lastY = $y;
	}
	elsif($line =~ /^G1 X(\S+) Y(\S+)(\s+F\S+)?($|;.*|\s.*)/) {
		# Travel move while either retracted or not.
		# (Recent versions of Slic3r drop the F argument on successive travel moves.)
		my ($x, $y) = ($1, $2);

		if($firstRetract) {
			# Yet another random bug in Slic3r: sometimes there is no retract during the travel
			# towards the skirt. I could report this, but the motivation to convince the developers
			# of this random glitch is very low. Therefore I implement this kludge instead.
			my $bugWarn = "RANDOM SLIC3R BUG DETECTED: missing retract during move to skirt at line ${lineNumber}.";
			if(! (defined($retractLength) && defined($retractSpeed) && defined($travelSpeed))) {
				logMsg($WARNING, $bugWarn);
				logMsg($ERROR, '... but cannot apply workaround because parameters were not found in start G-code!');
			}
			elsif($retractLength > 0) {  # Of course not a problem if retraction not enabled.
				logMsg($WARNING, $bugWarn);
				logMsg($WARNING, 'Workaround: adding the missing retract. Feel free to file an issue on Slic3r GitHub if you feel brave enough to report this totally random bug.');
				($firstRetract, $firstUnretract) = (0, 0);
				push(@output, "G1 E-${retractLength} F${retractSpeed}; ${progId}: added missing retract");
				$line .= " F${travelSpeed}" if(! $3);
				push(@output, $line);
				my $xLength = $retractLength + $extraFirstUnretract;
				if($extraFirstUnretract) {
					$line = "G1 E${xLength} F${retractSpeed}; ${progId}: additional ${extraFirstUnretract} unretract to counteract initial extruder lag";
				}
				else {
					$line = "G1 E${xLength} F${retractSpeed}; ${progId}: added missing unretract";
				}
			}
		}

		if($retracted[$activeTool]) {
			# Travel move while retracted: record the distance.
			# The very first move should be from whatever position the start G-code ended with, to
			# the start of the skirt. The lastX and Y coordinates should still be undefined at that
			# point because we didn't track moves in the start code, so nothing will be compensated
			# aside from the $firstUnretract hack. This is good enough since the skirt is supposed
			# to prime the nozzle anyway.
			my $dist = defined($lastX) ? sqrt(($x - $lastX)**2 + ($y - $lastY)**2) : 0.0;
			$travel[$activeTool] += $dist;
			$totalTravel += $dist;
		}
		elsif(defined($lastX)) {
			$totalTravel += sqrt(($x - $lastX)**2 + ($y - $lastY)**2);
		}
		$lastX = $x;
		$lastY = $y;
		push(@output, $line);
	}
	elsif($line =~ /^G1 E(\S+) (.*)/) {
		# Retract or unretract
		my ($e, $extra) = ($1, $2);
		$firstRetract = 0 if($e < 0);
		# If positive, should correspond to 'extra length on restart' in Slic3r
		my $extraLength = $e + $retracted[$activeTool];
		$originalE[$activeTool] += $extraLength if($extraLength > 0);

		my $extraUnretract = 0;
		if($e > 0) {  # unretract, this is where the interesting stuff happens
			# Assumption: the code will never try something exotic like a partial unretract.
			# If this is an unretract move, it must be a complete unretract.
			if($firstUnretract) {
				$e += $extraFirstUnretract;
				$firstUnretract = 0;
				$extra .= "; ${progId}: additional ${extraFirstUnretract} unretract to counteract initial extruder lag";
			}
			$extraUnretract = extraRetractDistance($travel[$activeTool]);
			$modified = 1 if($extraUnretract);
			if($extraUnretract) {
				logMsg($DEBUG, sprintf("Added %.5f of unretract for %.3fmm move", $extraUnretract, $travel[$activeTool]));
			}
			$offsetE[$activeTool] += $extraUnretract;
			$travel[$activeTool] = 0;
		}
		$retracted[$activeTool] += $e;
		$retracted[$activeTool] = 0 if($retracted[$activeTool] > 0);
		$e += $extraUnretract;

		if($extraUnretract) {
			push(@output, sprintf('G1 E%.5f %s; %s: added %.5f unretract', $e, $extra, $progId, $extraUnretract));
		}
		else {
			push(@output, sprintf('G1 E%.5f %s', $e, $extra));
		}
	}
	else {
		push(@output, $line);
		# Sanity checks in case Slic3r output format changes or contains stuff I didn't consider.
		logMsg($WARNING, "Unrecognized line with E argument at ${lineNumber}") if($line =~ /^[^;]+ E(\d*\.?\d+)/);
		logMsg($WARNING, "Unrecognized line with X or Y argument at ${lineNumber}: $line") if($line =~ /^[^;]+ [XY](\d*\.?\d+)/);
	}
}
close($fHandle);

if($modified) {
	# Add some statistics to the file
	my @info = ("; Post-processed by DrLex retraction improver script v${VERSION}. Threshold=${distanceThreshold}, slope_th=${thresholdSlope}, flatness=${flatness}");
	push(@info, sprintf(';   Total distance in travel moves: %.5fmm', $totalTravel));
	for(my $i=0; $i<=$#offsetE; $i++) {
		if($offsetE[$i]) {
			my $percent = 100.0 * $offsetE[$i] / $originalE[$i];
			my $message = sprintf(';   Added %.5fmm (%.4f%% of %.5f) for extruder %d',
			                      $offsetE[$i], $percent, $originalE[$i], $i);
			push(@info, $message);
			logMsg($DEBUG, "${message}");
		}
	}
	push(@info, '');

	my @where = grep { $output[$_] eq $gcodeEndMarker } 0..$#output;
	if(@where) {
		my $here = 1 + pop(@where);
		splice(@output, $here, 0, @info);
	} else {
		push(@output, @info);
	}
}

my $outHandle = \*STDOUT;
my $outFileHandle;
if(defined $opts{'o'} && $opts{'o'} ne '') {
	open($outFileHandle, '>', $opts{'o'}) or die "ERROR: cannot write to '$opts{o}': $!\n";
	$outHandle = $outFileHandle;
}

print $outHandle join("\n", @output);
logMsg($INFO, sprintf('Total distance in travel moves: %.5fmm', $totalTravel)) if($statsMode);
close($outFileHandle) if($outFileHandle);


###### SUBROUTINES ######
sub logMsg
{
	my ($level, $msg) = @_;
	return if($level < $logLevel);
	my $levelStr = $logLevelNames{$level};
	print STDERR "[${progId}] ${levelStr}: ${msg}\n";
}

sub seppuku
{
	my ($code, $msg) = @_;
	logMsg($FATAL, $msg);
	exit $code;
}

sub extraRetractDistance
# The extra unretract distance to add depending on travelled distance.
{
	my $traveled = shift;
	return 0 if($distanceThreshold < 0 || $traveled <= $distanceThreshold);
	# First attempt, proved too crude.
	#return $slope * ($traveled - $distanceThreshold);

	# This still is crude as it is based on wild guesses, but should be better than the linear
	#   equation because it fits my experimental data.
	# Remember, Perl's 'log' is natural logarithm.
	return log(($traveled + $a - $distanceThreshold) / $a) / $flatness;
}
