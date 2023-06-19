Reformat Kicad 7 bom/cpl files for jlcpcb (https://jlcpcb.com/).

Follow https://support.jlcpcb.com/article/194-how-to-generate-gerber-and-drill-files-in-kicad-6 to generate Gerber and Drill.

Export bom from Kicad. Suppose this is called project.csv

Export cpl using the settings provided here:
https://support.jlcpcb.com/article/84-how-to-generate-the-bom-and-centroid-file-from-kicad to generate
You don't need to make any changes. Export both top/bottom layers to one file.
Suppose this is called project-pos.csv

You can process these files like this:

bominator.pl --bom project.csv --cpl project-pos.csv

Files ending in jlcpcb.csv will be generated.

Note: If you have set an LCSC value in the schematic, Kicad 7 doesn't seem to export this in the bom. 
Therefore, those items need to be set manually. Any tips on how to fix this (and whether it can be fixed
are appreciated).

(Note that you'll need to install some perl packages for this to work. If you're not familiar with perl, post an issue and I'll amend instructions. 2023-06-19)
