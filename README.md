# ParseCSVFile

#!/bin/sh
#to C++Class file：../tools/ParseCSVFile/ParseCSVFile/ParseCSVFile -r ../Resources/config -o "$exportPath" -m class
#to Lua table file：../tools/ParseCSVFile/ParseCSVFile/ParseCSVFile -r ../Resources/config -o "$exportPath" -m lua
exportPath="../CSVExport"
resourcePath="../Classes/GameNet/protos/csv/config"
desPath="../Classes/GameNet/protos/csv/csv_class"
../tools/ParseCSVFile/ParseCSVFile/ParseCSVFile -r "$resourcePath" -o "$exportPath" -m class
fileList=`ls "$exportPath"`
for file1 in $fileList; do
    mv "$exportPath"/"$file1" "$desPath"/"$file1"
done
rm -fr "$exportPath"


#please use command of --help

#you use ParseCSVFile.sh file.
