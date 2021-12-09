#!/bin/bash

DIR=$(realpath $(dirname "${BASH_SOURCE[0]}"))
FILE=$(basename "${BASH_SOURCE[0]}")

basedir=$(realpath ${DIR}/../../)
#appdir=$(echo ${PWD#$basedir} | sed "s%/$%%g")
appdir=$(echo ${DIR#$basedir} | sed "s%/$%%g")

cp -r "${basedir}/lib/composer" "${DIR}/"

# autoload_classmap.php
file="${DIR}/composer/composer/autoload_classmap.php"
sed -i "s%\$vendorDir = dirname(dirname(__FILE__));%\$vendorDir = dirname(dirname(__FILE__)) . '/../../../..';%g" "$file"

# autoload_static.php
file="${DIR}/composer/composer/autoload_static.php"
sed -i "s%0 => __DIR__ . '/../../..'%0 => __DIR__ . '/../../../..'%g" "$file"
sed -i "s%' => __DIR__ . '/..%' => __DIR__ . '/../../../../lib/composer/composer' . '/..%g" "$file"
find "${DIR}/composer/composer/" -type f | xargs sed -i 's%ComposerStaticInit[a-f0-9]\+%ComposerStaticInitClassOverrides%g'
find "${DIR}/composer/composer/" -type f | xargs sed -i 's%ComposerAutoloaderInit[a-f0-9]\+%ComposerAutoloaderInitClassOverrides%g'


# Every file should have a .sh script to apply patches
for script in $(find "$DIR" -type f -name "*.sh" ! -name install.sh ! -path "${DIR}/lib/AppInfo/*" ! -path "${DIR}/composer/*")
do
  # File being modified
  sourceLib=$(echo "${basedir}/$script" | sed 's/\.sh$/\.php/g')
  sourceLib=${basedir}$(echo ${script#$DIR} | sed 's/\.sh$/\.php/g')

  # Local library
  localLib=$(echo "$script" | sed 's/\.sh$/\.php/g')
  
  cp "$sourceLib" "$localLib"
  bash "$script"
done

for file in $(find "$DIR" -type f -name "*.php" ! -name "autoload.config.php" ! -path "${DIR}/lib/AppInfo/*" ! -path "${DIR}/composer/*")
do
  libPattern=$(echo "${file#$DIR}")  #$(echo "$file" | sed 's/^\.//g')
  newLibPattern="$appdir$libPattern"
  namespace=$(grep "^namespace " $file | cut -d ' ' -f 2 | sed 's/;$//g')

  grep -q "^class " $file
  if [[ $? -eq 1 ]]
  then
    class=$(grep "^interface " $file | cut -d ' ' -f 2)
  else
    class=$(grep "^class " $file | cut -d ' ' -f 2)
  fi
  
  classPattern=$(echo $namespace\\$class | sed "s#\\\\#\\\\\\\\\\\\\\\\#g")
  
  grep -q "$libPattern" "${DIR}/composer/composer/autoload_static.php"
  if [[ $? -eq 1 ]]
  then
    sed -i "s#classMap = array (#classMap = array (\n        '$classPattern' => __DIR__ . '/../../../..' . '$newLibPattern',#g" "${DIR}/composer/composer/autoload_static.php"
  else
    sed -i "s#$libPattern#$newLibPattern#g" "${DIR}/composer/composer/autoload_static.php"
  fi

  grep -q "$libPattern" "${DIR}/composer/composer/autoload_classmap.php"
  if [[ $? -eq 1 ]]
  then
    sed -i "s#return array(#return array(\n    '$classPattern' => \$baseDir . '$newLibPattern',#g" "${DIR}/composer/composer/autoload_classmap.php"
  else
    sed -i "s#$libPattern#$newLibPattern#g" "${DIR}/composer/composer/autoload_classmap.php"
  fi
done

mv "${DIR}/autoload.config.php" "${basedir}/config/autoload.config.php"
rm -rf "$DIR/$FILE" "${DIR}/.git"
