#!/bin/bash

DIR=$(realpath $(dirname "${BASH_SOURCE[0]}"))
FILE=$(basename "${BASH_SOURCE[0]}")

sourceFilePart=$(echo "$FILE" | sed "s%\.sh$%%g")
sourceFile="${DIR}/${sourceFilePart}.php"
patchFile="${DIR}/${sourceFilePart}.patch"

patch "$sourceFile" "$patchFile"
if [ $? -eq 1 ]
  then exit
fi

rm "${DIR}/${FILE}"
rm "$patchFile"
