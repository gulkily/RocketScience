#!/usr/bin/perl -T

use strict;
use 5.010;
use utf8;

sub GetDefault { # $configName
	my $configName = shift;
	chomp $configName;

	$configName = FixConfigName($configName);

	WriteLog('GetDefault: $configName = ' . $configName);
	#todo sanity

	state %defaultLookup;

	if ((exists($defaultLookup{$configName}))) {
		# found in memo
		WriteLog('GetDefault: $defaultLookup already contains value, returning that...');
		WriteLog('GetDefault: $defaultLookup{$configName} is ' . $defaultLookup{$configName});
		return $defaultLookup{$configName};
	}

	if ((-e "default/$configName")) {
		# found a match in default directory
		WriteLog("GetDefault: -e default/$configName returned true, proceeding to GetFile()");
		my $defaultValue = GetFile("default/$configName");
		if (substr($configName, 0, 9) eq 'template/') {
			# do not trim templates
		} else {
			# trim() resulting value (removes whitespace)
			$defaultValue = trim($defaultValue);
		}
		$defaultLookup{$configName} = $defaultValue;
		return $defaultValue;
	} # found in default/
} # GetDefault()

sub FixConfigName { # $configName ; prepend 'setting/' to config paths as appropriate
	my $configName = shift;

	my @notSetting = qw(query res sqlite3 string setting template theme);
	my $notSettingFlag = 0; # should NOT be prefixed with setting/
	for my $notSettingItem (@notSetting) {
		if ($configName ne 'theme' && substr($configName, 0, length($notSettingItem)) eq $notSettingItem) {
			$notSettingFlag = 1;
		}
	}
	if (!$notSettingFlag) {
		WriteLog('GetConfig: adding setting/ prefix to $configName = ' . $configName);
		$configName = 'setting/' . $configName;
	} else {
		WriteLog('GetConfig: NOT adding setting/ prefix to $configName = ' . $configName);
	}

	return $configName;
}

sub GetConfig { # $configName || 'unmemo', $token, [$parameter] ;  gets configuration value based for $key
	# $token eq 'unmemo'
	#    removes memo entry for $token from %configLookup

	# $token eq 'override'
	# 	instead of regular lookup, overrides value
	#		overridden value is stored in local sub memo
	#			this means all subsequent lookups now return $parameter
	#

#	this is janky, and doesn't work as expected
#	eventually, it will be nice for dev mode to not rewrite
#	the entire config tree on every rebuild
#	and also not require a rebuild after a default change
#		note: this is already possible, there's a config for it:
#		$CONFIGDIR/admin/dev/skip_putconfig
#	#todo
#
# CONFUSION WARNING there are two separate "unmemo" features,
# one for the whole thing, another individual keys
#
# new "method": get_memo, returns the whole thing for debug output

	my $configName = shift;
	chomp $configName;
	my $token = shift;
	if ($token) {
		chomp $token;
	} else {
		$token = '';
	}
	my $parameter = shift;
	if ($parameter) {
		chomp $parameter;
	}

	WriteLog('======================================================================');
	WriteLog("GetConfig($configName); \$token = $token; \$parameter = $parameter; caller: " . join(',', caller));

	state $CONFIGDIR = GetDir('config'); # config/
	state $DEFAULTDIR = GetDir('default'); #default/

	state %configLookup;

	if ($configName && ($configName eq 'unmemo')) {
		WriteLog('GetConfig: FULL UNMEMO requested, removing %configLookup');
		#unmemo one particular config
		undef %configLookup;
		return '';
	}

	if ($token && $token eq 'unmemo') {
		WriteLog('GetConfig: unmemo token found');

		my $unmemoCount = 0;
		if (exists($configLookup{'_unmemo_count'})) {
			$unmemoCount = $configLookup{'_unmemo_count'}
		}

		# remove memoized value(s)
		if ($configName) {
			if (exists($configLookup{$configName})) {
				delete($configLookup{$configName});
				$unmemoCount++;
				$configLookup{'_unmemo_count'} = $unmemoCount;
				return '';
				#we return here because otherwise it calls a recursion loop
				#todo this should be fixed in the future when unmemo and no recursion flag can be used together
			} else {
				WriteLog('GetConfig: warning: unmemo requested for unused key. $configName = ' . $configName);
			}
#		} else {
#			WriteLog('GetConfig: unmemo all!');
#			%configLookup = ();
#			$unmemoCount++;
#			$configLookup{'_unmemo_count'} = $unmemoCount;
		}
	}

	#WriteLog('GetConfig: $configName BEFORE FixConfigName() is ' . $configName);
	my $configName = FixConfigName($configName);
	#WriteLog('GetConfig: $configName AFTER FixConfigName() is ' . $configName);

	if ($token && ($token eq 'override')) {
		WriteLog('GetConfig: override token detected');
		if ($parameter || (defined($parameter) && ($parameter eq '' || $parameter == 0))) {
			WriteLog('GetConfig: override: setting $configLookup{' . $configName . '} := ' . $parameter);
			$configLookup{$configName} = $parameter;
		} else {
			WriteLog('GetConfig: warning: $token was override, but no parameter. sanity check failed.');
			return '';
		}
	}

	if (exists($configLookup{$configName})) {
		# found in memo
		#WriteLog('GetConfig: ' . $configName . ' $configLookup already contains value, returning: ' . $configLookup{$configName});
		if (index($configName, 'dragging') != -1) {
			WriteLog('GetConfig: $configLookup{' . $configName . '} is ' . $configLookup{$configName});
		}
		#todo WriteLog() should skip multiline output unless config/debug > 1
		return $configLookup{$configName};
	}

	if ($token ne 'no_theme_lookup') {
		WriteLog("GetConfig: Trying GetThemeAttribute() first...");
		if (
			$configName ne "setting/theme" &&
			substr($configName, 0, 6) ne 'theme/'
		) {
			my $themeAttributeValue = '';
			#$themeAttributeValue = GetThemeAttribute($configName);
			if ($themeAttributeValue) {
				$configLookup{$configName} = $themeAttributeValue;
				return $configLookup{$configName};
			}
		}
	}

	WriteLog("GetConfig: Looking for config value in $CONFIGDIR/$configName ...");

	my $acceptableValues;
	if ($configName eq 'html/clock_format') {
		if (substr($configName, -5) ne '.list') {
			my $configList = GetConfig("$configName.list"); # should this be GetDefault()? arguable
			if ($configList) {
				$acceptableValues = $configList;
			}
		}
	} else {
		$acceptableValues = 0;
	}

	if (-d "$CONFIGDIR/$configName") {
		WriteLog('GetConfig: warning: $configName was a directory, returning');
		return;
	}

	if (-e "$CONFIGDIR/$configName") {
		# found a match in config directory
		WriteLog("GetConfig: -e $CONFIGDIR/$configName returned true, proceeding to GetFile(), set \$configLookup{}, and return \$configValue");

		if (-e "$CONFIGDIR/debug") {
			my @statDefault = stat("$DEFAULTDIR/$configName");
			my @statConfig = stat("$CONFIGDIR/$configName");

			my $timeDefault = $statDefault[9];
			my $timeConfig = $statConfig[9];

			if ($timeDefault > $timeConfig) {
				WriteLog('GetConfig: warning: default is newer than config: ' . $configName);
			}
		}

		my $configValue = GetFile("$CONFIGDIR/$configName");
		if (substr($configName, 0, 9) eq 'template/') {
			# do not trim templates
		} else {
			# trim() resulting value (removes whitespace)
			$configValue = trim($configValue);
		}
		
		if ($acceptableValues) {
			# there is a list of acceptable values
			# check to see if value is in that list
			# if not, issue warning and return 0
			if (index($configValue, $acceptableValues)) {
				$configLookup{$configName} = $configValue;
				return $configValue;
			} else {
				WriteLog('GetConfig: warning: $configValue was not in $acceptableValues');
				return 0; #todo should return default, perhaps via $param='default'
			}
		} else {
			$configLookup{$configName} = $configValue;
			return $configValue;
		}
	} # found in $CONFIGDIR/
	else {
		WriteLog("GetConfig: -e $CONFIGDIR/$configName returned false, looking in defaults...");

		if (-e "$DEFAULTDIR/$configName") {
			# found default, return that
			WriteLog("GetConfig: -e $DEFAULTDIR/$configName returned true, proceeding to GetFile(), etc...");
			my $configValue = GetFile("$DEFAULTDIR/$configName");
			$configValue = trim($configValue);
			$configLookup{$configName} = $configValue;

			if (!GetConfig('admin/dev/skip_putconfig')) {
				# this preserves default settings, so that even if defaults change in the future
				# the same value will remain for current instance
				# this also saves much time not having to run ./clean_dev when developing
				WriteLog('GetConfig: calling PutConfig($configName = ' . $configName . ', $configValue = ' . length($configValue) .'b);');
				PutConfig($configName, $configValue);
			} else {
				WriteLog('GetConfig: skip_putconfig=TRUE, not calling PutConfig()');
			}

			return $configValue;
		} # return $DEFAULTDIR/
		else {
			if (substr($configName, 0, 16) eq 'template/js/lib/') {
				WriteLog('GetConfig: found a missing js library, inflating all');

				my $jsLibSourcePath = $DEFAULTDIR . '/template/js/lib/jslib.tar.gz';
				my $jsLibTargetPath = $CONFIGDIR . '/template/js/lib/';

				EnsureSubdirs($jsLibTargetPath);

				WriteLog('GetConfig: $jsLibSourcePath = ' . $jsLibSourcePath . '; $jsLibTargetPath = ' . $jsLibTargetPath);
				my $tarCommand = "tar -vzxf $jsLibSourcePath -C $jsLibTargetPath";
				WriteLog('GetConfig: $tarCommand = ' . $tarCommand);
				my $tarCommandResult = `$tarCommand`;
				WriteLog('GetConfig: $tarCommandResult = ' . $tarCommandResult);

				return GetConfig($configName);
			}

			if (substr($configName, 0, 6) eq 'theme/' || substr($configName, 0, 7) eq 'string/') {
				WriteLog('GetConfig: no default; $configName = ' . $configName);
				return '';
			} else {
				if ($configName =~ m/\.list$/) {
					# cool
					return '';
				} else {
					WriteLog('GetConfig: warning: Tried to get undefined config with no default; $configName = ' . $configName . '; caller = ' . join (',', caller));
					return '';
				}
			}
		}
	} # not found in $CONFIGDIR/

	WriteLog('GetConfig: warning: reached end of function, which should not happen');
	return '';
} # GetConfig()

sub ConfigKeyValid { #checks whether a config key is valid
	# valid means passes character sanitize
	# and exists in default/
	my $configName = shift;

	if (!$configName) {
		WriteLog('ConfigKeyValid: warning: $configName parameter missing');
		return 0;
	}

	$configName = FixConfigName($configName);

	WriteLog("ConfigKeyValid($configName)");

	if (! ($configName =~ /^[a-z0-9_\/]{1,64}$/) ) {
		WriteLog("ConfigKeyValid: warning: sanity check failed! caller = " . join(',', caller));
		return 0;
	}

	WriteLog('ConfigKeyValid: $configName sanity check passed:');

	#my $CONFIGDIR = GetDir('config');
	my $DEFAULTDIR = GetDir('default');

	if (-e "$DEFAULTDIR/$configName") {
		WriteLog("ConfigKeyValid: $DEFAULTDIR/$configName exists, return 1");
		return 1;
	} else {
		WriteLog("ConfigKeyValid: $DEFAULTDIR/$configName NOT exist, return 0");
		return 0;
	}
} # ConfigKeyValid()

sub ResetConfig { # Resets $configName to default by removing the config/* file
	# Does a ConfigKeyValid() sanity check first
	my $configName = shift;

	my $CONFIGDIR = GetDir('config');

	if (ConfigKeyValid($configName)) {
		unlink("$CONFIGDIR/$configName");
	}
}

sub PutConfig { # $configName, $configValue ; writes config value to config storage
	# $configName = config name/key (file path)
	# $configValue = value to write for key
	# Uses PutFile()
	#
	my $configName = shift;
	my $configValue = shift;

	my $CONFIGDIR = GetDir('config');

	$configName = FixConfigName($configName);

	if (index($configName, '..') != -1) {
		WriteLog('PutConfig: warning: sanity check failed: $configName contains ".."');
		WriteLog('PutConfig: warning: sanity check failed: $configName contains ".."');
		return '';
	}

	chomp $configValue;

	WriteLog('PutConfig: $configName = ' . $configName . ', $configValue = ' . length($configValue) . 'b)');

	my $putFileResult = PutFile("$CONFIGDIR/$configName", $configValue);

	# ask GetConfig() to remove memo-ized value it stores inside
	GetConfig($configName, 'unmemo');

	return $putFileResult;
} # PutConfig()

sub GetConfigListAsArray { # $listName
	my $listName = shift;
	chomp $listName;
	#todo sanity checks

	my @listRaw = split("\n", trim(GetTemplate('list/' . $listName)));
	WriteLog('GetConfigListAsArray: $listName = ' . $listName . '; scalar(@listRaw) = ' . scalar(@listRaw));

	return @listRaw;

	#todo sanity checks and etc
	#	my @listClean;
	#	for(my $i = 0; $i < scalar(@listRaw); $i++) {
	#		if (trim($listRaw[$i]) eq '') {
	#			# nothing, it's blank
	#		} else {
	#			if ($listRaw[$i] =~ m/^([0-9a-zA-Z_])$/) {
	#				my $newItem = $1;
	#				push @listClean, $newItem;
	#			} else {
	#				# nothing, it fails sanity check
	#			}
	#		}
	#	}
	#
	#	return @listClean;
} # GetConfigListAsArray()

sub GetThemeAttribute { # returns theme color from $CONFIGDIR/theme/
# may be CONFUSING:
# additional.css special case:
# values will be concatenated instead of returning first one
	my $attributeName = shift;
	chomp $attributeName;

	WriteLog('GetThemeAttribute(' . $attributeName . ')');

	my $returnValue = '';

	my @activeThemes = split("\n", GetConfig('theme'));
	foreach my $themeName (@activeThemes) {
		my $attributePath = 'theme/' . $themeName . '/' . $attributeName;

		#todo sanity checks
		my $attributeValue = GetConfig($attributePath, 'no_theme_lookup');

		WriteLog('GetThemeAttribute: $attributeName = ' . $attributeName . '; $themeName = ' . $themeName . '; $attributePath = ' . $attributePath);

		if ($attributeValue && trim($attributeValue) ne '') {
			WriteLog('GetThemeAttribute: ' . $attributeName . ' + ' . $themeName . ' -> ' . $attributePath . ' -> length($attributeValue) = ' . length($attributeValue));
			if ($attributeName ne 'additional.css') {
				$returnValue = $attributeValue || '';
				last;
			} else {
				$returnValue .= $attributeValue || '';
				$returnValue .= "\n";
			}
		} # if ($attributeValue)
	} # foreach $themeName (@activeThemes)

	if (trim($returnValue) eq '') {
		if ($attributeName =~ m/^template/) {
			# this is ok
		} else {
			# not ok
			WriteLog('GetThemeAttribute: warning: $returnValue is empty for $attributeName = ' . $attributeName . '; caller = ' . join(',', caller));
		}
	}

	WriteLog('GetThemeAttribute: length($returnValue) = ' . length($returnValue) . '; $attributeName = ' . $attributeName);
	#WriteLog('GetThemeAttribute: $returnValue = ' . $returnValue . '; $attributeName = ' . $attributeName);

	return trim($returnValue);

#
#	if (!ConfigKeyValid("theme/$themeName")) {
#		WriteLog('GetThemeAttribute: warning: ConfigKeyValid("theme/$themeName") was false');
#		$themeName = 'chicago';
#	}
#
#	return trim($attributeValue);
} # GetThemeAttribute()


if (0) { #tests
	require('./utils.pl');
	require_once('./sqlite.pl');
	print "GetConfig('current_version') = " . GetConfig('current_version') . "\n";
	print "GetTemplate('query/related') = " . GetTemplate('query/related') . "\n";
	print "SqliteGetQueryTemplate('related') = " . SqliteGetQueryTemplate('related') . "\n";
	print "GetConfig('setting/html/page_limit') = " . GetConfig('setting/html/page_limit') . "\n";
	print "GetThemeAttribute('setting/html/page_limit') = " . GetThemeAttribute('setting/html/page_limit') . "\n";
}

1;
