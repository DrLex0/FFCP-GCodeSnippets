# Flashforge Creator Pro print bed model and texture

These files are *optional.* You can load them into PrusaSlicer to have a nicer preview. This is not merely cosmetic, it gives a frame of reference that may help to avoid placing things upside down.

Unfortunately it is impossible to automatically load the model and texture while importing the ini bundle. Your options are:

1. Manually load the STL and PNG in all the printer profiles after importing the ini bundle. In each printer profile, use the ‘Set’ button for ‘Bed shape’ and select the 2 files, then save the profile.
2. Specify the full file paths to both files on the [Post-process Config Helper webpage](https://www.dr-lex.be/software/ffcp-slic3r-ini-helper.html) while you're preparing the ini file according to the instructions of the main README.

Do not move the STL or PNG files afterwards, because PrusaSlicer relies on their absolute paths.

The bed model STL was adapted from [Toylerrr's Flashforge-for-Cura repository](https://github.com/Toylerrr/Flashforge-for-Cura). I couldn't find any license for it, so I assume it's *CC-BY* like this very repository.
