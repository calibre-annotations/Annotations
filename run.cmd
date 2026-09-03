del "..\Annotations.zip"
"c:\Program Files\7-Zip\7z.exe" a "..\Annotations.zip" *.py developer_notes.txt dialogs\*.py help\* images\*.png plugin-import-name-annotations.txt readers\*.py -x!readers\_* README.md about.txt run.cmd translations/*.po translations/*.mo
mode 165,15999 
calibre-customize -a "..\Annotations.zip"
SET CALIBRE_DEVELOP_FROM=E:\Development\GitHub\calibre\src
calibre-debug  -s
calibre-debug  -g
