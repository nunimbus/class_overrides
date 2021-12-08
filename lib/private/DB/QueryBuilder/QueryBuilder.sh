#!/bin/bash

cwd=$(realpath $(dirname "${BASH_SOURCE[0]}"))
file="${cwd}/QueryBuilder.php"

patch "$file" ${cwd}/QueryBuilder.patch

rm ${cwd}/QueryBuilder.patch
rm ${cwd}/QueryBuilder.sh
