# Post-processing scripts for Using PrusaSlicer (Slic3r) with the Flashforge Creator Pro

This directory currently only contains one script. It can be optionally configured in the main `make_fcp_x3g` script.

The script is written in Perl, so you need a *Perl interpreter* to run it (which is not a problem in Linux or Mac OS X, but in Windows you'll need to install something extra).

## retraction-improver.pl
This is a kind of a *hack* to counteract two different instances of consistent under-extrusion I observed when printing with the FlashForge Creator Pro:

1. **An obvious under-extrusion at the start of each print,** when the skirt is being printed after the initial priming extrusion performed by my start G-code. I cannot explain why this happens but I have found that pushing through 0.6 mm of extra filament will usually almost completely eliminate this. Due to glitches in PrusaSlicer, sometimes the travel move from the priming line to the skirt has no retractions. The script will detect this and add the missing retraction to ensure the workaround can be applied as well.
2. **Consistent extruder lag immediately after long retracted travel moves,** which gets worse with increased travel length. This manifests itself as gaps in the print at the start of perimeters. When printing with at least 2 perimeters, this usually is not that big of a deal, but it can ruin single-walled structures or fine details. It seems this is simply caused by the extruder not reacting immediately to pressure changes. The JKN advance algorithm in the firmware is supposed to compensate for extruder lag, but apparently it only does so for continuous extrusions and does nothing against lag after retracted travel moves.

The remedy for the second problem is the same as for the first: push some extra filament during the un-retract to quickly re-pressurize the extruder. The amount varies with travel length according to a guesstimated formula derived from some test prints. This strategy is not ideal because it will consume more material than theoretically needed. Ideally this should be compensated for by consuming less material elsewhere. It probably makes sense to also stop extruding a little early before the travel move, I believe this is what the ‘coast’ feature in Simplify3D does. The script currently does not do this, I might add it some day.

This strategy also incurs a risk of causing *over-extrusion* in certain situations. Because my guesstimated formula is not perfect and its parameters would probably need to be re-tuned for each filament and print settings, sometimes too much extra material is added after travels, and this can become visible when printing for instance two thin solid pillars. If you anticipate that this may be a problem for a particular print, either disable the script or reduce the `thresholdSlope` parameter.

The default parameters in the script should work well enough, they seem to work fine for both the stock extruder and my Micro Swiss all-metal hot-end. If you do want to tweak them, look in the script for instructions.