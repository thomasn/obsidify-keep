
# obsidify-keep

**Convert Google Keep notes to Obsidian Markdown**

A Google Keep repository can be exported using [Google Takeout](https://takeout.google.com/settings/takeout)

 This generates a zip file. When extracted, it holds a `Takeout/Keep` directory containing:

 * `*.json`: the primary textual content, processed and output to vault
 * `Labels.txt`: list of label (tag) names used - added to report 
 * audio/video files: copied to vault/media
 * `*.html`: ignored unless JSON processing fails, in which case the corresponding html is copied
 * other files: copied to vault and added to report file

