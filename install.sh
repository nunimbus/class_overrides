#!/bin/bash

basedir=$(realpath $(pwd)/../../)
appdir=$(echo ${PWD#$basedir} | sed "s%/$%%g")

cp -r "${basedir}/lib/composer" .

# autoload_classmap.php
file="./composer/composer/autoload_classmap.php"
sed -i "s%\$vendorDir = dirname(dirname(__FILE__));%\$vendorDir = dirname(dirname(__FILE__)) . '/../../../..';%g" "$file"

# autoload_static.php
file="./composer/composer/autoload_static.php"
sed -i "s%0 => __DIR__ . '/../../..'%0 => __DIR__ . '/../../../..'%g" "$file"
sed -i "s%' => __DIR__ . '/..%' => __DIR__ . '/../../../../lib/composer/composer' . '/..%g" "$file"
find ./composer/composer/ -type f | xargs sed -i 's%ComposerStaticInit[a-f0-9]\+%ComposerStaticInitClassOverrides%g'
find ./composer/composer/ -type f | xargs sed -i 's%ComposerAutoloaderInit[a-f0-9]\+%ComposerAutoloaderInitClassOverrides%g'


# Every file should have a .sh script to apply patches
for script in $(find -type f -name "*.sh" ! -name install.sh ! -path "./lib/AppInfo/*" ! -path "./composer/*")
do
  # File being modified
  sourceLib=$(echo "${basedir}/$script" | sed 's/\.sh$/\.php/g')
  
  # Local library
  localLib=$(echo "$script" | sed 's/\.sh$/\.php/g')
  
  cp "$sourceLib" "$localLib"
  bash "$script"
done

for file in $(find -type f -name "*.php" ! -path "./lib/AppInfo/*" ! -path "./composer/*")
do
  libPattern=$(echo "$file" | sed 's/^\.//g')
  newLibPattern="$appdir$libPattern"
  namespace=$(grep "^namespace " $file | cut -d ' ' -f 2 | sed 's/;$//g')
  echo $newLibPattern
  
  grep -q "^class " $file
  if [[ $? -eq 1 ]]
  then
    class=$(grep "^interface " $file | cut -d ' ' -f 2)
  else
    class=$(grep "^class " $file | cut -d ' ' -f 2)
  fi
  
  classPattern=$(echo $namespace\\$class | sed "s#\\\\#\\\\\\\\\\\\\\\\#g")
  
  grep -q "$libPattern" ./composer/composer/autoload_static.php
  if [[ $? -eq 1 ]]
  then
    sed -i "s#classMap = array (#classMap = array (\n        '$classPattern' => __DIR__ . '/../../../..' . '$newLibPattern',#g" ./composer/composer/autoload_static.php
  else
    sed -i "s#$libPattern#$newLibPattern#g" ./composer/composer/autoload_static.php
  fi

  grep -q "$libPattern" ./composer/composer/autoload_classmap.php
  if [[ $? -eq 1 ]]
  then
    sed -i "s#return array(#return array(\n    '$classPattern' => \$baseDir . '$newLibPattern',#g" ./composer/composer/autoload_classmap.php
  else
    sed -i "s#$libPattern#$newLibPattern#g" ./composer/composer/autoload_classmap.php
  fi
done

mv autoload.config.php "${basedir}/config/autoload.config.php"
rm -rf install.sh .git

