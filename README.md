
# obsidify-keep

**Convert Google Keep notes to Obsidian Markdown**

A Google Keep repository can be exported using [Google Takeout][]

 This generates a zip file, which, when extracted, holds a `Takeout/Keep` directory containing:

 * `*.json`: the primary textual content, processed and output to vault
 * `Labels.txt`: list of label (tag) names used - added to report 
 * audio/video files: copied to vault/media
 * `*.html`: ignored
 * other files: copied to vault

## Status

See [GitHub Issues](./issues) for known problems.

## Usage

Until this gets bundled into a package, try the following (tested on ArchWSL2 and on Windows 10/PowerShell 7.1.3). 

In each case a "vault" directory is created, containing the generated Markdown; media assets will be copied to a "media" subfolder of this vault. Copy this folder into, say, "Documents\Obsidian\KeepVault" or "~/data/obsidian/keepvault"

This "KeepVault" folder can now be added as a new vault in Obsidian. Text, images and links from your Keep account will be indexed and available, and can be merged with an existing vault by copying the folders across.

### Windows
In [Powershell 7][]:

- Install [scoop](https://scoop.sh/)
- cd
scoop install git julia
- mkdir code
- cd code
- git clone git@github.com:thomasn/obsidify-keep
- Grind yourself a fresh [Google Takeout][] zipfile
- Extract the zip file to somewhere\Takeout\Keep
- cd $HOME\code\obsidify-keep
- julia src\obsidify-keep.jl --input-dir=somewhere\Takeout\Keep --output-dir=. --verbose=true



[Google Takeout]: https://takeout.google.com/settings/takeout
[Powershell 7]: https://github.com/PowerShell/powershell/releases

### Arch
- read Windows instructions
- clone repo
- see obsidify.sh

### Other tools are available...

**Note**: This code has been written entirely to familiarize myself with Julia -  the other projects below may be considerably more robust! Ones I've come across:

- [Keep-It-Markdown](https://github.com/djsudduth/keep-it-markdown) aka KIM: actively maintained, uses Python, uses an undocumented API for access
- [google-keep-exporter](https://github.com/vHanda/google-keep-exporter): uses Node
- [keep-to-markdown](https://github.com/erikelisath/keep-to-markdown): Python, may have support for i18n/UTF-8 (not tested in this project)



Please let me know of any problems!

-- T

