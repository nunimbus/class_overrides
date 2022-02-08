<?php

foreach (\OC::$composerAutoloader->getRegisteredLoaders() as $path=>$loader) {
	if (isset ($loader->getPrefixesPsr4()['OC\\']) || array_key_exists('OC\\', $loader->getPrefixesPsr4())) {
		$loader->unregister();
		require_once __DIR__ . '/../apps/class_overrides/composer/composer/autoload_real.php';
		\OC::$composerAutoloader = ComposerAutoloaderInitClassOverrides::getLoader();
	}
}
