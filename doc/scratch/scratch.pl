#			if (!-e "$HTMLDIR/thumb/squared_42_$fileHash.gif") {
#				my $convertCommand = "convert \"$fileShellEscaped\" -crop 42x42 -strip $HTMLDIR/thumb/squared_42_$fileHash.gif";
#				WriteLog('IndexImageFile: ' . $convertCommand);
#
#				my $convertCommandResult = `$convertCommand`;
#				WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
#			}

	# # make 48x48 thumbnail
	# if (!-e "$HTMLDIR/thumb/thumb_48_$fileHash.gif") {
	# 	my $convertCommand = "convert \"$file\" -thumbnail 48x48 -strip $HTMLDIR/thumb/thumb_48_$fileHash.gif";
	# 	WriteLog('IndexImageFile: ' . $convertCommand);
	#
	# 	my $convertCommandResult = `$convertCommand`;
	# 	WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
	# }

#			if (!-e "$HTMLDIR/thumb/squared_512_$fileHash.gif") {
#				my $convertCommand = "convert \"$fileShellEscaped\" -crop 512x512 -strip $HTMLDIR/thumb/squared_512_$fileHash.gif";
#				WriteLog('IndexImageFile: ' . $convertCommand);
#
#				my $convertCommandResult = `$convertCommand`;
#				WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
#			}

		#my $convertCommand = "convert \"$fileShellEscaped\" -scale 5% -blur 0x25 -resize 5000% -colorspace Gray -blur 0x8 -thumbnail 512x512 -strip $HTMLDIR/thumb/thumb_512_$fileHash.gif";

#			if (!-e "$HTMLDIR/thumb/squared_800_$fileHash.gif") {
#				my $convertCommand = "convert \"$fileShellEscaped\" -crop 800x800 -strip $HTMLDIR/thumb/squared_800_$fileHash.gif";
#				WriteLog('IndexImageFile: ' . $convertCommand);
#
#				my $convertCommandResult = `$convertCommand`;
#				WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
#			}


	# # make 1024x1024 thumbnail
	# if (!-e "$HTMLDIR/thumb/thumb_1024_$fileHash.gif") {
	# 	my $convertCommand = "convert \"$file\" -thumbnail 1024x1024 -strip $HTMLDIR/thumb/thumb_1024_$fileHash.gif";
	# 	WriteLog('IndexImageFile: ' . $convertCommand);
	#
	# 	my $convertCommandResult = `$convertCommand`;
	# 	WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
	# }




if (GetConfig('setting/admin/js/enable') && GetConfig('setting/admin/js/dragging')) {
	#todo add more things to this template and make it not hard-coded
	$htmlStart = str_replace('</head>', '<script src="/dragging.js"></script></head>', $htmlStart);
}






# if (!$statusBar && index($file{'tags_list'}, 'speaker') != -1) {
# 	#$statusBar = $file{'item_title'};
# }



if (GetConfig('admin/expo_site_mode') && $file{'tags_list'} && index($file{'tags_list'}, 'sponsor') != -1) {
	$statusBar = '<a href="' . $file{'item_title'} . '" target=_blank>' . $file{'item_title'} . '</a>';
}




if (GetConfig('admin/expo_site_mode') && !GetConfig('admin/expo_site_edit')) { #expo
	WriteLog('GetItemTemplate: $statusBar expo_site_mode override activated');
	if ($file{'item_title'} =~ m/^http/) {
		my $permalinkHtml = $file{'item_title'};
		$statusBar =~ s/\$permalinkHtml/$permalinkHtml/g;
	}

	if ($file{'no_permalink'}) {
		$statusBar = $file{'item_title'};
	}
} else {



	my @timestampsArray; #todo initialize?



push @timestampsArray, $iaValue;


if (1) { # todo attribute_statistics flag
	$itemAttributesTable .= '<tr><td>';
	$itemAttributesTable .= 'Timestamp Statistics'; #todo GetString('item_attribute/item_score');
	$itemAttributesTable .= '</td><td>';
	$itemAttributesTable .= join(',', @timestampsArray);# todo'';
	$itemAttributesTable .= '</td></tr>';
}

if (1) {
	$itemAttributesTable .= '<tr><td>';
	$itemAttributesTable .= 'Hash Collisions'; #todo GetString('item_attribute/item_score');
	$itemAttributesTable .= '</td><td>';
	$itemAttributesTable .= '0'; #$file{'item_score'};
	$itemAttributesTable .= '</td></tr>';
}




sub GetSecondsHtml {# takes number of seconds as parameter, returns the most readable approximate time unit
	# 5 seconds = 5 seconds
	# 65 seconds = 1 minute
	# 360 seconds = 6 minutes
	# 3600 seconds = 1 hour
	# etc

	my $seconds = shift;

	if (!$seconds) {
		return;
	}

	chomp $seconds;

	my $secondsString = $seconds;

	if ($secondsString >= 60) {
		$secondsString = $secondsString / 60;

		if ($secondsString >= 60 ) {
			$secondsString = $secondsString / 60;

			if ($secondsString >= 24) {
				$secondsString = $secondsString / 24;

				if ($secondsString >= 365) {
					$secondsString = $secondsString / 365;

					$secondsString = floor($secondsString) . ' years';
				}
				elsif ($secondsString >= 30) {
					$secondsString = $secondsString / 30;

					$secondsString = floor($secondsString) . ' months';
				}
				else {
					$secondsString = floor($secondsString) . ' days';
				}
			}
			else {
				$secondsString = floor($secondsString) . ' hours';
			}
		}
		else {
			$secondsString = floor($secondsString) . ' minutes';
		}
	} else {
		$secondsString = floor($secondsString) . ' seconds';
	}
} # GetSecondsHtml()



sub GetVersionPage { # returns html with version information for $version (git commit id)
	#todo refactor to be a call to GetItemPage
	my $version = shift;

	if (!IsSha1($version)) {
		return;
	}

	my $txtPageHtml = '';

	my $pageTitle = "Information page for version $version";

	my $htmlStart = GetPageHeader('version');

	$txtPageHtml .= $htmlStart;

	$txtPageHtml .= GetTemplate('html/maincontent.template');

	my $versionInfo = GetTemplate('html/versioninfo.template');
	my $shortVersion = substr($version, 0, 8);

	$versionInfo =~ s/\$version/$version/g;
	$versionInfo =~ s/\$shortVersion/$shortVersion/g;

	$txtPageHtml .= $versionInfo;

	$txtPageHtml .= GetPageFooter('version');

	$txtPageHtml = InjectJs($txtPageHtml, qw(settings avatar));

	return $txtPageHtml;
} # GetVersionPage()



sub MakeInputExpandable {
#		if (GetConfig('admin/js/enable')) {
#			$html = AddAttributeToTag($html, 'input name=comment', onpaste, "window.inputToChange=this; setTimeout('ChangeInputToTextarea(window.inputToChange); return true;', 100);");
#		} #input_expand_into_textarea

#todo
}


sub MakePage2 {
	my @arg = @_;
	my $useThreads = 0;

	WriteLog('MakePage: $useThreads = ' . $useThreads);

	if ($useThreads) {
		my $thr = threads->create('MakePage2', @arg);
		my $result = $thr->join();
		return $result;
	} else {
		my $result = MakePage2(@arg);
		return $result;
	}
}




WriteMessage('=======================================');
WriteMessage('   Welcome! Please make a selection:   ');
WriteMessage('=======================================');
WriteMessage(' [0] Install dependency packages       ');
WriteMessage(' [1] Local use for taking notes        ');
WriteMessage(' [2] Local development of application  ');
WriteMessage(' [3] Local use, static HTML output     ');
WriteMessage(' [4] Deploy on private server          ');
WriteMessage(' [5] Deploy on public server           ');
WriteMessage(' [6] Deploy with minimal options       ');
WriteMessage(' [7] Deploy with TOR                   ');
WriteMessage('=======================================');

my $installType = GetChoice('Enter a number 1-7: ');



#
#	my $schemaHash = `sqlite3 "$SqliteDbName" ".schema" | sha1sum | awk '{print \$1}' > config/setting/sqlite3_schema_hash`;
#	# this can be used as schema "version"
#	# only problem is first time it changes, now cache must be regenerated
#	# so need to keep track of the previous one and recursively call again or copy into new location



sub WriteIndexedConfig { # writes config indexed in database into config/
# WRITES CONFIG INDEXED IN DATABASE INTO CONFIG/
# this should ideally filter for the "latest" config value in database
# but that's more challenging than i thought using sql
# so instead of that, it filters here, and only prints the topmost value
# for each key

	WriteLog('WriteIndexedConfig() begin');
	WriteLog('WriteIndexedConfig: warning: it is off pending some testing');
	return '';

	# author must be admin or must have completed puzzle
	my @indexedConfig = SqliteQueryHashRef('indexed_config');
	my %configDone;

	shift @indexedConfig;

	foreach my $configLineReference (@indexedConfig) {
		my %configLine = %{$configLineReference};

		my $configLineKey = $configLine{'key'};
		my $configLineValue = $configLine{'value'};
		my $configLineResetFlag = $configLine{'reset_flag'};

		if (!$configDone{$configLineKey}) {
			if ($configLineResetFlag) {
				ResetConfig($configLineKey);
			} else {
				PutConfig($configLineKey, $configLineValue);
			}
			$configDone{$configLineKey} = 1;
		}
	}


#	WriteLog('WriteIndexedConfig: warning: it is skipped, because needs fixing');
#	WriteMessage('WriteIndexedConfig() skipped');
#	print('WriteIndexedConfig() skipped');
#	return '';
#
#	my @indexedConfig = DBGetLatestConfig();
#
#	WriteLog('WriteIndexedConfig: scalar(@indexedConfig) = ' . scalar(@indexedConfig));
#
#	foreach my $configLine(@indexedConfig) {
#		my $configKey = $configLine->{'key'};
#		my $configValue = $configLine->{'value'};
#
#		chomp $configValue;
#		$configValue = trim($configValue);
#
#		if (IsSha1($configValue)) {
#			WriteLog('WriteIndexedConfig: Looking up hash: ' . $configValue);
#
#			if (-e 'cache/' . GetMyCacheVersion() . "/message/$configValue") { #todo make it cleaner
#				WriteLog('WriteIndexedConfig: success: lookup of $configValue = ' . $configValue);
#				$configValue = GetCache("message/$configValue");#todo should this be GetItemMessage?
#			} else {
#				WriteLog('WriteIndexedConfig: warning: no result for lookup of $configValue = ' . $configValue);
#			}
#		}
#
#		if ($configLine->{'reset_flag'}) {
#			ResetConfig($configKey);
#		} else {
#			PutConfig($configKey, $configValue);
#		}
#	}

	WriteLog('WriteIndexedConfig: finished, calling GetConfig(unmemo)');

	GetConfig('unmemo');

	return '';
} # WriteIndexedConfig()




#	if (defined($pageLinks{$pageQuery})) {
#		WriteLog('GetPaginationLinks: $pageLinks{$pageQuery} already exists, doing search and replace');
#
#		my $currentPageTemplate = GetPageLink($currentPageNumber, $itemCount);
#
#		my $currentPageStart = $currentPageNumber * $perPage;
#		my $currentPageEnd = $currentPageNumber * $perPage + $perPage;
#		if ($currentPageEnd > $itemCount) {
#			$currentPageEnd = $itemCount - 1;
#		}
#
#		my $currentPageCaption = $currentPageStart . '-' . $currentPageEnd;
#		my $pageLinksReturn = $pageLinks; # make a copy of $pageLinks which we'll modify
#		$pageLinksReturn = str_replace($currentPageTemplate, '<b>$currentPageCaption</b>', $currentPageTemplate);
#
#		return $pageLinksReturn;
#	} else {
#		# we've ended up here because we haven't generated $pageLinks yet
#		WriteLog('GetPaginationLinks: $itemCount = ' . $itemCount);
#



#use warnings FATAL => 'all';
#
# $SIG{__WARN__} = sub {
# 	if (open (my $fileHandle, ">>", 'log/log.log')) {
# 		say $fileHandle "\n" . time() . " ";
# 		say $fileHandle @_;
# 		say $fileHandle "\n";
# 		close $fileHandle;
# 	}
#
# 	if (-e 'config/debug') {
# 		die `This program does not tolerate warnings like: @_`;
# 	}
# };


sub DBCheckItemSurpass { # $a, $b
	my $a = shift;
	my $b = shift;
	#todo sanity

	state %memo;
	if (exists($memo{$a . $b})) {
		return $memo{$a . $b};
	}

	#todo add weights
	my $querySurpass = "select count(*) FROM item_attribute where attribute = 'surpass' AND
		file_hash = ?";
	my $querySurpassed = "select count(*) FROM item_attribute where attribute = 'surpass' AND
		value = ?";

	my @arrayA = ($a);
	my $valueA = SqliteGetValue($querySurpass, @arrayA) - SqliteGetValue($querySurpassed, @arrayA);


	my @arrayB = ($b);
	my $valueB = SqliteGetValue($querySurpass, @arrayB) - SqliteGetValue($querySurpassed, @arrayB);

	WriteLog('DBCheckItemSurpass: $a = ' . $a . '; $b = ' . $b . '; $valueA = ' . $valueA . '; $valueB = ' . $valueB);

	if ($valueA > $valueB) {
		$memo{$a . $b} = 1;
		return 1;
	} else {
		$memo{$a . $b} = 0;
		return 0;
	}
}


sub DBCheckItemSurpass2 { # $a, $b
	my $a = shift;
	my $b = shift;
	#todo sanity

	state %memo;
	if (exists($memo{$a . $b})) {
		return $memo{$a . $b};
	}

	#todo add weights
	my $query = "select count(*) FROM item_attribute where attribute = 'surpass' AND
		file_hash = ? AND value = ?";
	my @arrayAtoB = ($a, $b);
	my $valueAtoB = SqliteGetValue($query, @arrayAtoB);

	my @arrayBtoA = ($b, $a);
	my $valueBtoA = SqliteGetValue($query, @arrayBtoA);

	WriteLog('DBCheckItemSurpass: $a = ' . $a . '; $b = ' . $b . '; $valueAtoB = ' . $valueAtoB . '; $valueBtoA = ' . $valueBtoA);

	if ($valueBtoA > $valueAtoB) {
		$memo{$a . $b} = 1;
		return 1;
	} else {
		$memo{$a . $b} = 0;
		return 0;
	}
}






	my $pageName = shift;
	if (!$pageName) {
		return;
	}
	chomp $pageName;
	if (!$pageName =~ m/^[a-z]+$/) {
		WriteLog('MakeSimplePage: warning: $pageName failed sanity check');
		return '';
	}







#
#sub SqliteMakeItemFlatTable {
#	state $tableBeenMade;
#	if (!$tableBeenMade) {
#		$tableBeenMade = 1;
#		my $itemFlatQuery = "create temp table item_flat as select * from item_flat_view";
#		SqliteQuery($itemFlatQuery);
#	}
#}

#	SqliteQuery("CREATE UNIQUE INDEX config_unique ON config(key, value, reset_flag);");
#	SqliteQuery("
#   		CREATE VIEW config_latest
#   		AS
#   			SELECT
#   				key,
#   				value,
#   				reset_flag,
#   				file_hash FROM config
#			GROUP BY key
#    	;");
#
#	SqliteQuery("
#		CREATE VIEW config_bestest
#		AS
#			SELECT
#				config.key,
#				config.value,
#				MAX(config.timestamp) config_timestamp,
#				config.reset_flag,
#				config.file_hash,
#				item_score.item_score
#			FROM config
#				 LEFT JOIN item_score ON (config.file_hash = item_score.file_hash)
#			GROUP BY config.key
#			ORDER BY item_score.item_score DESC, timestamp DESC
#	;");
#
#	SqliteQuery("
#		CREATE VIEW config_latest_timestamp
#		AS
#			SELECT
#				key,
#				max(add_timestamp) max_timestamp
#			FROM
#				config
#				LEFT JOIN item_flat ON (config.file_hash = item_flat.file_hash)
#			GROUP BY
#				key
#	");


















		my $message = '';
		if ($isTextart) {
			# if textart, format with extra spacing to preserve character arrangement
			#$message = TextartForWeb($message);

			$message = TextartForWeb(GetFile($file{'file_path'}));
			WriteLog('GetItemTemplate: textart: $message = TextartForWeb(GetFile(' . $file{'file_path'} . ')) = ' . length($message));
		} else {
			# get formatted/post-processed message for this item
			$message = GetItemDetokenedMessage($file{'file_hash'}, $file{'file_path'});

			if (!$message) {
				#message is missing, try to find fallback
				WriteLog('GetItemTemplate: warning: $message is empty, trying original source');

				if (!$sourceFileHasGoneAway && -e $file{'file_path'}) {
					#original file still exists
					$message = GetFile($file{'file_path'});

					if ($message) {
						$isTextart = 1;
					} else {
						WriteLog('GetItemTemplate: warning: $message is empty even after getting file contents!');
						$message = '[Message is blank.]';
					}
				} else {
					WriteLog('GetItemTemplate: warning: $sourceFileHasGoneAway is TRUE');
					$message = '[Unable to retrieve message. Source file has gone away.]';
				}
			}

			$message =~ s/\r//g;

			if (GetConfig('admin/expo_site_mode')) {
				#trim signature/header-footer
				if (index($message, "\n-- \n") != -1) {
					$message = substr($message, 0, index($message, "\n-- \n"));
				}
			}


			if ($file{'remove_token'}) {
				# if remove_token is specified, remove it from the message
				WriteLog('GetItemTemplate: $file{\'remove_token\'} = ' . $file{'remove_token'});

				$message =~ s/$file{'remove_token'}//g;
				$message = trim($message);

				#todo there is a #bug here, but it is less significant than the majority of cases
				#  the bug is that it removes the token even if it is not by itself on a single line
				#  this could potentially be mis-used to join together two pieces of a forbidden string
				#todo make it so that post does not need to be trimmed, but extra \n\n after the token is removed
			} else {
				WriteLog('GetItemTemplate: $file{\'remove_token\'} is not set');
			}

			# if not textart, just escape html characters
			WriteLog('GetItemTemplate: calling FormatForWeb');
			$message = FormatForWeb($message);


			# WriteLog($message);


			if ($file{'item_type'}) {
				$itemType = $file{'item_type'};
			} else {
				$itemType = 'txt';
			}

			if (!$file{'item_title'}) {
				#hack #todo
				$file{'item_title'} = 'Untitled';
				#$file{'item_title'} = '';
			}

			# } elsif ($isSurvey) {
			# 	# if survey, format with text fields for answers
			# 	$message = SurveyForWeb($message);


			#hint GetHtmlFilename()
			#todo verify that the items exist before turning them into links,
			# so that we don't end up with broken links
			# can be done here or in the function (return original text if no item)?
			#$message =~ s/([a-f0-9]{40})/GetItemHtmlLink($1)/eg;
			#$message =~ s/([a-f0-9]{40})/GetItemTemplateFromHash($1)/eg;

			# if format_avatars flag is set, replace author keys with avatars
			if ($file{'format_avatars'}) {
				$message =~ s/([A-F0-9]{16})/GetHtmlAvatar($1)/eg;
			}
		} # NOT $isTextart



				if ($itemType eq 'txt') {
					WriteLog('GetItemTemplate: 2');
					if ($isTextart) {
						$itemText = 'asdfad';
					} else {
						$itemText = $message; # output for item's message (formatted text)
					}

					$itemClass = "txt";


					if ($isSigned) {
						# if item is signed, add "signed" css class
						$itemClass .= ' signed';
					}

					if ($isAdmin) {
						# if item is signed by an admin, add "admin" css class
						$itemClass .= ' byadmin';

						my $adminContainer = GetTemplate('html/item/container/admin.template');

						my $colorAdmin = GetThemeColor('admin') || '#c00000';
						$adminContainer =~ s/\$colorAdmin/$colorAdmin/g;

						$adminContainer =~ s/\$message/$itemText/g;

						$itemText = $adminContainer;
					} # $isAdmin
				} # $itemType eq 'txt'

				if ($itemType eq 'image') {
					if (GetConfig('admin/image/enable')) {
						my $imageContainer = '';
						if ($file{'no_permalink'}) {
							$imageContainer = GetTemplate('html/item/container/image.template');
						} else {
							$imageContainer = GetTemplate('html/item/container/image_with_link.template');
						}

						my $imageUrl = "/thumb/thumb_800_$fileHash.gif"; #todo hardcoding no
						my $imageSmallUrl = "/thumb/thumb_42_$fileHash.gif"; #todo hardcoding no
						my $imageAlt = $itemTitle;

						if ($file{'image_large'}) {
						} else {
						}
		#				my $imageUrl = "/thumb/squared_800_$fileHash.gif"; #todo hardcoding no
		#				my $imageSmallUrl = "/thumb/squared_42_$fileHash.gif"; #todo hardcoding no

						# $imageSmallUrl is a smaller image, used in the "lowsrc" attribute for img tag

						if ($file{'image_large'}) {
							#$imageContainer = AddAttributeToTag($imageContainer, 'img', 'width', '500');
							#$imageContainer = AddAttributeToTag($imageContainer, 'img', 'width', '100%');
						} else {
							if ($file{'item_score'} > 0) {
								$imageUrl = "/thumb/thumb_512_$fileHash.gif"; #todo hardcoding no
							} else {
								$imageUrl = "/thumb/thumb_512_g_$fileHash.gif"; #todo hardcoding no
							}
							$imageContainer = AddAttributeToTag($imageContainer, 'img', 'width', '300');
						}

						$imageContainer =~ s/\$imageUrl/$imageUrl/g;
						$imageContainer =~ s/\$imageSmallUrl/$imageSmallUrl/g;
						$imageContainer =~ s/\$imageAlt/$imageAlt/g;
						$imageContainer =~ s/\$permalinkHtml/$permalinkHtml/g;


						$itemText = $imageContainer;

						$itemClass = 'image';
					} else {
						$itemText = '[image]';
						WriteLog('GetItemTemplate: warning: $itemType eq image, but images disabled');
					}
				} # $itemType eq 'image'


				if ($isTextart) {
					WriteLog('GetItemTemplate: 3');
					# if item is textart, add "item-textart" css class
					#todo this may not be necessary anymore
					$itemClass = 'item-textart';

					#die $itemText;

					my $textartContainer = GetTemplate('html/item/container/textart.template');
					$textartContainer =~ s/\$message/$itemText/g;

					$itemText = $textartContainer;

					$windowBody = GetTemplate('html/item/item.template'); # GetItemTemplate() #textart

					$windowBody =~ s/\$itemName/$itemName/g;
					$windowBody =~ s/\$itemText/$itemText/g;
				} else {

					$windowBody = GetTemplate('html/item/item.template'); # GetItemTemplate() NOT #textart

					$windowBody =~ s/\$itemName/$itemName/g;
					$windowBody =~ s/\$itemText/$itemText/g;
				}


		my $itemHash = $file{'file_hash'}; # file hash/item identifier
		my $gpgKey = $file{'author_key'}; # author's fingerprint

		my $isTextart = 0; # if textart, need extra formatting
		my $isSurvey = 0; # if survey, need extra formatting
		my $isTooLong = 0; # if survey, need extra formatting

		my $alias; # stores author's alias / name
		my $isAdmin = 0; # author is admin? (needs extra styles)

		my $itemType = '';

		my $isSigned = 0; # is signed by user (also if it's a pubkey)
		if ($gpgKey) { # if there's a gpg key, it's signed
			$isSigned = 1;
		} else {
			$isSigned = 0;
		}

		if ($file{'tags_list'}) {
			# if there is a list of tags, check to see if there is a 'textart' tag

			# split the tags list into @itemTags array
			my @itemTags = split(',', $file{'tags_list'});

			# loop through all the tags in @itemTags
			while (scalar(@itemTags)) {
				my $thisTag = pop @itemTags;
				if ($thisTag eq 'textart') {
					$isTextart = 1; # set isTextart to 1 if 'textart' tag is present
				}
				if ($thisTag eq 'survey') {
					$isSurvey = 1; # set $isSurvey to 1 if 'survey' tag is present
				}
				if ($thisTag eq 'toolong') {
					$isTooLong = 1; # set $isTooLong to 1 if 'survey' tag is present
				}
			}
		}
		if ($file{'tags_list'}) {
			# if there is a list of tags, check to see if there is a 'textart' tag

			# split the tags list into @itemTags array
			my @itemTags = split(',', $file{'tags_list'});

			# loop through all the tags in @itemTags
			while (scalar(@itemTags)) {
				my $thisTag = pop @itemTags;
				if ($thisTag eq 'textart') {
					$isTextart = 1; # set isTextart to 1 if 'textart' tag is present
				}
				if ($thisTag eq 'survey') {
					$isSurvey = 1; # set $isSurvey to 1 if 'survey' tag is present
				}
				if ($thisTag eq 'toolong') {
					$isTooLong = 1; # set $isTooLong to 1 if 'survey' tag is present
				}
			}
		}
		my $isTextart = 0; # if textart, need extra formatting
		my $isSurvey = 0; # if survey, need extra formatting
		my $isTooLong = 0; # if survey, need extra formatting

		my $alias; # stores author's alias / name
		my $isAdmin = 0; # author is admin? (needs extra styles)

		my $itemType = '';

		my $isSigned = 0; # is signed by user (also if it's a pubkey)
		if ($gpgKey) { # if there's a gpg key, it's signed
			$isSigned = 1;
		} else {
			$isSigned = 0;
		}

		if ($file{'tags_list'}) {
			# if there is a list of tags, check to see if there is a 'textart' tag

			# split the tags list into @itemTags array
			my @itemTags = split(',', $file{'tags_list'});

			# loop through all the tags in @itemTags
			while (scalar(@itemTags)) {
				my $thisTag = pop @itemTags;
				if ($thisTag eq 'textart') {
					$isTextart = 1; # set isTextart to 1 if 'textart' tag is present
				}
				if ($thisTag eq 'survey') {
					$isSurvey = 1; # set $isSurvey to 1 if 'survey' tag is present
				}
				if ($thisTag eq 'toolong') {
					$isTooLong = 1; # set $isTooLong to 1 if 'survey' tag is present
				}
			}
		}













































































#
#			DBAddItemPage($$replyItem{'file_hash'}, 'item', $file{'file_hash'});
#
#			# use item-small template to display the reply items
#			#$$replyItem{'template_name'} = 'html/item/item.template';
#
#			# if the child item contains a reply token for our parent item
#			# we want to remove it, to reduce redundant information on the page
#			# to do this, we pass the remove_token parameter to GetItemTemplate() below
#			$$replyItem{'remove_token'} = '>>' . $file{'file_hash'};
#
#			# after voting, return to the main thread page
#			$$replyItem{'vote_return_to'} = $file{'file_hash'};
#
#			# trim long text items
#			$$replyItem{'trim_long_text'} = 1;
##
##			if (index(','.$$replyItem{'tags_list'}.',', ','.'notext'.',') != -1) {
##				$$replyItem{'template_name'} = 'html/item/item.template';
##			} else {
##				$$replyItem{'template_name'} = 'html/item/item.template';
##			}
#
#			# Get the reply template
#			my $replyTemplate = GetItemTemplate($replyItem); # GetItemPage()
#
#			# output it to debug
#			WriteLog('$replyTemplate for ' . $$replyItem{'template_name'} . ':');
#			WriteLog($replyTemplate);
#
#			# if the reply item has children also, output the children
#			# threads are currently limited to 2 steps
#			# eventually, recurdsion can be used to output more levels
#			if ($$replyItem{'child_count'}) {
#				my $subRepliesTemplate = ''; # will store the sub-replies html output
#
#				my $subReplyComma = ''; # separator for sub-replies, set to <hr on first use
#
#				my @subReplies = DBGetItemReplies($$replyItem{'file_hash'});
#				foreach my $subReplyItem (@subReplies) {
#					DBAddItemPage($$subReplyItem{'file_hash'}, 'item', $file{'file_hash'});
##
##					if (index(','.$$subReplyItem{'tags_list'}.',', ','.'notext'.',') != -1) {
##						$$subReplyItem{'template_name'} = 'html/item/item.template';
##						# $$subReplyItem{'template_name'} = 'html/item/item-mini.template';
##					} else {
##						$$subReplyItem{'template_name'} = 'html/item/item.template';
##						# $$subReplyItem{'template_name'} = 'html/item/item-small.template';
##					}
#					$$subReplyItem{'remove_token'} = '>>' . $$replyItem{'file_hash'};
#					$$subReplyItem{'vote_return_to'} = $file{'file_hash'};
#
#					WriteLog('$$subReplyItem{\'remove_token\'} = ' . $$subReplyItem{'remove_token'});
#					WriteLog('$$subReplyItem{\'template_name\'} = ' . $$subReplyItem{'template_name'});
#					WriteLog('$$subReplyItem{\'vote_return_to\'} = ' . $$subReplyItem{'vote_return_to'});
#
#					$$subReplyItem{'trim_long_text'} = 1;
#					my $subReplyTemplate = GetItemTemplate($subReplyItem); # GetItemPage()
#					if ($subReplyComma eq '') {
#						$subReplyComma = '<hr size=4>';
#					}
#					else {
#						$subReplyTemplate = $subReplyComma . $replyTemplate;
#					}
#					$subRepliesTemplate .= $subReplyTemplate;
#				}
#
#				# replace replies placeholder with generated html
#				$replyTemplate =~ s/<replies><\/replies>/$subRepliesTemplate/;
#			}
#			else {
#				# there are no replies, so remove replies placeholder
#				$replyTemplate =~ s/<replies><\/replies>//;
#			}
#
#			if ($replyTemplate) {
#				if ($replyComma eq '') {
#					$replyComma = '<hr size=5>';
#					# $replyComma = '<p>';
#				}
#				else {
#					$replyTemplate = $replyComma . $replyTemplate;
#				}
#
#				$allReplies .= $replyTemplate;
#			}
#			else {
#				WriteLog('Warning: replyTemplate is missing for some reason!');
#			}
#		} # foreach my $replyItem (@itemReplies)
#
#		if (GetConfig('reply/enable') && GetConfig('html/reply_form_after_reply_list') && !GetConfig('html/reply_form_before_reply_list')) {
#			# add reply form after replies
#			my $replyForm = GetReplyForm($file{'file_hash'});
#			# start with a horizontal rule to separate from above content
#			$allReplies .= '<hr size=6>';
#			$allReplies .= $replyForm;
#		}
#
#		$itemTemplate =~ s/<replies><\/replies>/$allReplies/;
#		$itemTemplate .= '<hr><br>';
#	} # $file{'child_count'}
#	else {
#		my $allReplies = '';
#		if (GetConfig('reply/enable')) {
#			# add reply form if no existing replies
#
#			{
#				my $voteButtons = GetItemTagButtons($file{'file_hash'});
#				$allReplies .= '<hr>'.GetWindowTemplate($voteButtons, 'Add Tags').'<hr>';
#			}
#
#
#			my $replyForm = GetReplyForm($file{'file_hash'});
#			$allReplies .= $replyForm;
#		}
#		$itemTemplate =~ s/<replies><\/replies>/$allReplies/;
#		$itemTemplate .= '<hr><br>';
#	} # replies and reply form






		$writeForm = str_replace('<span id=write_options></span>', $writeOptions, $writeForm);
		$writeForm = str_replace('<span id=write_options></span>', $writeOptions, $writeForm);





#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use DBD::SQLite;
use DBI;
use Data::Dumper;
use 5.010;

sub GetSqliteDbName {
	state $cacheDir = GetDir('cache');
	my $SqliteDbName = "$cacheDir/index.sqlite3"; # path to sqlite db
	return $SqliteDbName;
}

my $dbh; # handle for sqlite interface

sub SqliteConnect { # Establishes connection to sqlite db
	my $SqliteDbName = GetSqliteDbName();
	EnsureSubdirs($SqliteDbName);
	if (!
		(
			(
				GetConfig('debug')
					&&
				(
					$dbh = DBI->connect(
						"dbi:SQLite:dbname=$SqliteDbName",
						"", # username (unused)
						"", # password (unused)
						{
							RaiseError => 1,
							AutoCommit => 1
						}
					)
				)
			)
				||
			(
				$dbh = DBI->connect(
					"dbi:SQLite:dbname=$SqliteDbName",
					"", # username
					"", # password
					{
						AutoCommit => 1
					}
				)
			)
		) # ! (not)
	) { # if
		WriteLog('SqliteConnect: warning: problem connecting to database: ' . $DBI::errstr);

		state $retries;
		if (!$retries) {
			$retries = 1;
		} else {
			$retries = $retries + 1;
		}

		if ($retries < 5) {
			return SqliteConnect();
		}
	}
}
SqliteConnect();

sub DBMaxQueryLength { # Returns max number of characters to allow in sqlite query
	return 10240;
}

sub DBMaxQueryParams { # Returns max number of parameters to allow in sqlite query
	return 128;
}

sub SqliteUnlinkDb { # Removes sqlite database by renaming it to ".prev"
	my $SqliteDbName = GetSqliteDbName();
	if ($dbh) {
		$dbh->disconnect();
	}
	rename($SqliteDbName, "$SqliteDbName.prev");
	SqliteConnect();
}

sub SqliteMakeTables { # creates sqlite schema
	my $existingTables = SqliteQuery3('.tables');
	if ($existingTables) {
		WriteLog('SqliteMakeTables: warning: tables already exist');
		return;
	}

	# wal
	# this switches to write-ahead log mode for sqlite
	# reduces problems with concurrent access
	SqliteQuery("PRAGMA journal_mode=WAL;");

	# config
	SqliteQuery("CREATE TABLE config(key, value, timestamp, reset_flag, file_hash);");
	SqliteQuery("CREATE UNIQUE INDEX config_unique ON config(key, value, timestamp, reset_flag);");
	SqliteQuery("
		CREATE VIEW config_latest AS
		SELECT key, value, MAX(timestamp) config_timestamp, reset_flag, file_hash FROM config GROUP BY key ORDER BY timestamp DESC
	;");


	my @scripts = qw(setup schema item_attribute item author);
	foreach my $script (@scripts) {
		my $sql = GetConfig($script);
		if ($sql =~ m/(.+)/) {
			$sql = $1;
			#if ($sql =~ m/^[a-zA-Z'\n .. finish this #todo
		}
		SqliteQuery($script);
	}


#
# 	SqliteQuery("
# 		CREATE VIEW item_title_latest AS
# 		SELECT
# 			file_hash,
# 			title,
# 			source_item_hash,
# 			MAX(source_item_timestamp) AS source_item_timestamp
# 		FROM item_title
# 		GROUP BY file_hash
# 		ORDER BY source_item_timestamp DESC
# 	;");
# 	#SqliteQuery("CREATE UNIQUE INDEX item_title_unique ON item_title(file_hash)");

	# item_parent
	SqliteQuery("CREATE TABLE item_parent(item_hash, parent_hash)");
	SqliteQuery("CREATE UNIQUE INDEX item_parent_unique ON item_parent(item_hash, parent_hash)");

	# child_count view
	SqliteQuery("
		CREATE VIEW child_count AS
		SELECT
			parent_hash AS parent_hash,
			COUNT(*) AS child_count
		FROM
			item_parent
		GROUP BY
			parent_hash
	");

#	# tag
#	SqliteQuery("CREATE TABLE tag(id INTEGER PRIMARY KEY AUTOINCREMENT, vote_value)");
#	SqliteQuery("CREATE UNIQUE INDEX tag_unique ON tag(vote_value);");

	# vote
	SqliteQuery("CREATE TABLE vote(id INTEGER PRIMARY KEY AUTOINCREMENT, file_hash, ballot_time, vote_value, author_key, ballot_hash);");
	SqliteQuery("CREATE UNIQUE INDEX vote_unique ON vote (file_hash, ballot_time, vote_value, author_key);");

	# item_page
	SqliteQuery("CREATE TABLE item_page(item_hash, page_name, page_param);");
	SqliteQuery("CREATE UNIQUE INDEX item_page_unique ON item_page(item_hash, page_name, page_param);");

	#SqliteQuery("CREATE TABLE item_type(item_hash, type_mask)");

	# event
	SqliteQuery("CREATE TABLE event(id INTEGER PRIMARY KEY AUTOINCREMENT, item_hash, author_key, event_time, event_duration);");
	SqliteQuery("CREATE UNIQUE INDEX event_unique ON event(item_hash, event_time, event_duration);");

	# location
	SqliteQuery("
		CREATE TABLE location(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			item_hash,
			author_key,
			latitude,
			longitude
		);
	");

	SqliteQuery("
		CREATE TABLE user_agent(
			user_agent_string
		);
	");

	# task
	SqliteQuery("CREATE TABLE task(id INTEGER PRIMARY KEY AUTOINCREMENT, task_type, task_name, task_param, touch_time INTEGER, priority DEFAULT 1);");
	SqliteQuery("CREATE UNIQUE INDEX task_unique ON task(task_type, task_name, task_param);");

	# # task/queue
	# SqliteQuery("CREATE TABLE task(id INTEGER PRIMARY KEY AUTOINCREMENT, action, param, touch_time INTEGER, priority DEFAULT 1);");
	# SqliteQuery("CREATE UNIQUE INDEX task_touch_unique ON task(action, param);");
	#
	# action      param           touch_time     priority
	# make_page   author/abc
	# index_file  path/abc.txt
	# read_log    log/access.log
	# find_new_files
	# make_thumb  path/abc.jpg
	# annotate_votes   (vote starts with valid=0, must be annotated)
	#





	### VIEWS BELOW ############################################
	############################################################

	# parent_count view
	SqliteQuery("
		CREATE VIEW parent_count AS
		SELECT
			item_hash AS item_hash,
			COUNT(parent_hash) AS parent_count
		FROM
			item_parent
		GROUP BY
			item_hash
	");


	SqliteQuery("
		CREATE VIEW
			item_tags_list
		AS
		SELECT
			file_hash,
			GROUP_CONCAT(DISTINCT vote_value) AS tags_list
		FROM vote
		GROUP BY file_hash
	");

	SqliteQuery("
		CREATE VIEW item_flat AS
			SELECT
				item.file_path AS file_path,
				item.item_name AS item_name,
				item.file_hash AS file_hash,
				IFNULL(item_author.author_key, '') AS author_key,
				IFNULL(child_count.child_count, 0) AS child_count,
				IFNULL(parent_count.parent_count, 0) AS parent_count,
				added_time.add_timestamp AS add_timestamp,
				IFNULL(item_title.title, '') AS item_title,
				IFNULL(item_score.item_score, 0) AS item_score,
				item.item_type AS item_type,
				tags_list AS tags_list
			FROM
				item
				LEFT JOIN child_count ON ( item.file_hash = child_count.parent_hash)
				LEFT JOIN parent_count ON ( item.file_hash = parent_count.item_hash)
				LEFT JOIN added_time ON ( item.file_hash = added_time.file_hash)
				LEFT JOIN item_title ON ( item.file_hash = item_title.file_hash)
				LEFT JOIN item_author ON ( item.file_hash = item_author.file_hash)
				LEFT JOIN item_score ON ( item.file_hash = item_score.file_hash)
				LEFT JOIN item_tags_list ON ( item.file_hash = item_tags_list.file_hash )
	");
	SqliteQuery("
		CREATE VIEW event_future AS
			SELECT
				*
			FROM
				event
			WHERE
				event.event_time > strftime('%s','now');
	");
#	SqliteQuery("
#		CREATE VIEW event_future AS
#			SELECT
#				event.item_hash AS item_hash,
#				event.event_time AS event_time,
#				event.event_duration AS event_duration
#			FROM
#				event
#			WHERE
#				event.event_time > strftime('%s','now');
#	");
	SqliteQuery("
		CREATE VIEW item_vote_count AS
			SELECT
				file_hash,
				vote_value AS vote_value,
				COUNT(file_hash) AS vote_count
			FROM vote
			GROUP BY file_hash, vote_value
			ORDER BY vote_count DESC
	");

	SqliteQuery("
		CREATE VIEW
			author_score
		AS
			SELECT
				item_flat.author_key AS author_key,
				SUM(item_flat.item_score) AS author_score
			FROM
				item_flat
			GROUP BY
				item_flat.author_key

	");

	SqliteQuery("
		CREATE VIEW
			author_flat
		AS
		SELECT
			author.key AS author_key,
			author_alias.alias AS author_alias,
			IFNULL(author_score.author_score, 0) AS author_score,
			MAX(item_flat.add_timestamp) AS last_seen,
			COUNT(item_flat.file_hash) AS item_count,
			author_alias.file_hash AS file_hash
		FROM
			author
			LEFT JOIN author_alias
				ON (author.key = author_alias.key)
			LEFT JOIN author_score
				ON (author.key = author_score.author_key)
			LEFT JOIN item_flat
				ON (author.key = item_flat.author_key)
		GROUP BY
			author.key, author_alias.alias, author_alias.file_hash
	");

	#todo deconfusify
	SqliteQuery("
		CREATE VIEW
			item_score
		AS
			SELECT
				vote.file_hash AS file_hash,
				SUM(IFNULL(vote_value.value, 0)) AS item_score
			FROM
				vote
				LEFT JOIN vote_value
					ON (vote.vote_value = vote_value.vote)
			GROUP BY
				vote.file_hash
	");

	my $SqliteDbName = GetSqliteDbName();

	my $schemaHash = `sqlite3 "$SqliteDbName" ".schema" | sha1sum | awk '{print \$1}' > config/sqlite3_schema_hash`;
	# this can be used as cache "version"
	# only problem is first time it changes, now cache must be regenerated
	# so need to keep track of the previous one and recursively call again or copy into new location
} # SqliteMakeTables()

sub SqliteQuery2 { # $query, @queryParams; calls sqlite with query, and returns result as array reference
	WriteLog('SqliteQuery() begin');

	my $query = shift;
	chomp $query;

	my @queryParams = @_;

	if ($query) {
		my $queryOneLine = $query;
		$queryOneLine =~ s/\s+/ /g;

		WriteLog('SqliteQuery2: $query = ' . $queryOneLine);
		WriteLog('SqliteQuery2: @queryParams: ' . join(', ', @queryParams));

		if ($dbh) {
			WriteLog('SqliteQuery2: $dbh was found, proceeding...');

			my $aref;
			my $sth;

			# try {
			#
			# } catch {
			# 	WriteMessage('SqliteQuery2: warning: error');
			# 	WriteMessage('SqliteQuery2: query: ' . $query);
			#
			# 	WriteLog('SqliteQuery2: warning: error');
			# 	WriteLog('SqliteQuery2: query: ' . $query);
			#
			# 	return;
			# };

			$sth = $dbh->prepare($query);
			my $execResult = $sth->execute(@queryParams);

			WriteLog('SqliteQuery2: $execResult = ' . $execResult);

			$aref = $sth->fetchall_arrayref();
			$sth->finish();

			return $aref;
		} else {
			WriteLog('SqliteQuery2: warning: $dbh is missing');
		}
	}
	else {
		WriteLog('SqliteQuery2: warning: $query is missing!');
		return '';
	}
}

sub EscapeShellChars { # $string ; escapes string for including as parameter in shell command
	#todo this is still probably not safe and should be improved upon #security
	my $string = shift;
	chomp $string;

	$string =~ s/([\"|\$`\\])/\\$1/g;
	# chars are: " | $ ` \

	return $string;
} # EscapeShellChars()

sub SqliteQuery { # performs sqlite query via sqlite3 command
#todo add parsing into array?
	my $query = shift;
	if (!$query) {
		WriteLog('SqliteQuery: warning: called without $query');
		return;
	}
	my $queryOneLine = $query;
	$queryOneLine =~ s/\s+/ /g;

	chomp $query;
	$query = EscapeShellChars($query);
	WriteLog('SqliteQuery: $query = ' . $queryOneLine);

	my $SqliteDbName = GetSqliteDbName();

	my $results = `sqlite3 "$SqliteDbName" "$query"`;
	return $results;
} # SqliteQuery()

sub SqliteQuery3 { # performs sqlite query via sqlite3 command
# CacheSqliteQuery { keyword
# #todo add parsing into array?
	my $query = shift;
	if (!$query) {
		WriteLog('SqliteQuery3: warning: called without $query');
		return;
	}
	chomp $query;
	$query = EscapeShellChars($query);
	WriteLog('SqliteQuery3: $query = ' . $query);

	my $cachePath = md5_hex($query);
	if ($cachePath =~ m/^([0-9a-f]{32})$/) {
		$cachePath = $1;
	} else {
		WriteLog('SqliteQuery3: warning: $cachePath sanity check failed');
	}
	my $cacheTime = GetTime();

	# this limits the cache to expiration of 1-100 seconds
	$cacheTime = substr($cacheTime, 0, length($cacheTime) - 2);
	$cachePath = "$cacheTime/$cachePath";

	WriteLog('SqliteQuery3: $cachePath = ' . $cachePath);
	my $results = GetCache("sqlitequery3/$cachePath");

	if ($results) {
		return $results;
	} else {

		my $SqliteDbName = GetSqliteDbName();
		$results = `sqlite3 "$SqliteDbName" "$query"`;
		PutCache('sqlitequery3/'.$cachePath, $results);
		return $results;
	}
} # SqliteQuery3()

#
#sub DBGetVotesTable {
#	my $fileHash = shift;
#
#	if (!IsSha1($fileHash) && $fileHash) {
#		WriteLog("DBGetVotesTable called with invalid parameter! returning");
#		WriteLog("$fileHash");
#		return '';
#	}
#
#	my $query;
#	my @queryParams = ();
#
#	if ($fileHash) {
#		$query = "SELECT file_hash, ballot_time, vote_value, author_key FROM vote_weighed WHERE file_hash = ?;";
#		@queryParams = ($fileHash);
#	} else {
#		$query = "SELECT file_hash, ballot_time, vote_value, author_key FROM vote_weighed;";
#	}
#
#	my $result = SqliteQuery($query, @queryParams);
#
#	return $result;
#}

sub DBGetVotesForItem { # Returns all votes (weighed) for item
	my $fileHash = shift;

	if (!IsSha1($fileHash)) {
		WriteLog("DBGetVotesTable called with invalid parameter! returning");
		WriteLog("$fileHash");
		return '';
	}

	my $query;
	my @queryParams;

	$query = "
		SELECT
			file_hash,
			ballot_time,
			vote_value,
			author_key
		FROM vote
		WHERE file_hash = ?
	";
	@queryParams = ($fileHash);

	my $result = SqliteQuery($query, @queryParams);

	return $result;
}
#
#sub DBGetEvents { #gets events list
#	WriteLog('DBGetEvents()');
#
#	my $query;
#
#	$query = "
#		SELECT
#			item_flat.item_title AS event_title,
#			event.event_time AS event_time,
#			event.event_duration AS event_duration,
#			item_flat.file_hash AS file_hash,
#			item_flat.author_key AS author_key,
#			item_flat.file_path AS file_path
#		FROM
#			event
#			LEFT JOIN item_flat ON (event.item_hash = item_flat.file_hash)
#		ORDER BY
#			event_time
#	";
#
#	my @queryParams = ();
##	push @queryParams, $time;
#
#	my $sth = $dbh->prepare($query);
#	$sth->execute(@queryParams);
#
#	my @resultsArray = ();
#
#	while (my $row = $sth->fetchrow_hashref()) {
#		push @resultsArray, $row;
#	}
#
#	return @resultsArray;
#}

sub DBGetAuthorFriends { # Returns list of authors which $authorKey has tagged as friend
# Looks for vote_value = 'friend' and items that contain 'pubkey' tag
	my $authorKey = shift;
	chomp $authorKey;
	if (!$authorKey) {
		return;
	}
	if (!IsFingerprint($authorKey)) {
		return;
	}

	my $query = "
		SELECT
			DISTINCT item_flat.author_key
		FROM
			vote
			LEFT JOIN item_flat ON (vote.file_hash = item_flat.file_hash)
		WHERE
			vote.author_key = ?
			AND vote_value = 'friend'
			AND ',' || item_flat.tags_list || ',' LIKE '%,pubkey,%'
		;
	";

	my @queryParams = ();
	push @queryParams, $authorKey;

	my $sth = $dbh->prepare($query);
	$sth->execute(@queryParams);

	my @resultsArray = ();

	while (my $row = $sth->fetchrow_hashref()) {
		push @resultsArray, $row;
	}

	return @resultsArray;
}

sub DBGetLatestConfig { # Returns everything from config_latest view
# config_latest contains the latest set value for each key stored
	my $query = "SELECT * FROM config_latest";
	#todo write out the fields

	if ($dbh) {
		my $sth = $dbh->prepare($query);
		$sth->execute();
		my @resultsArray = ();
		while (my $row = $sth->fetchrow_hashref()) {
			push @resultsArray, $row;
		}
		return @resultsArray;
	} else {
		WriteLog('DBGetLatestConfig: warning: $dbh was false');
		return 0;
	}
}


#sub SqliteGetHash {
#	my $query = shift;
#	chomp $query;
#
#	my @results = split("\n", SqliteQuery($query));
#
#	my %hash;
#
#	foreach (@results) {
#		chomp;
#
#		my ($key, $value) = split(/\|/, $_);
#
#		$hash{$key} = $value;
#	}
#
#	return %hash;
#}

sub SqliteGetValue { # Returns the first column from the first row returned by sqlite $query
	#todo perhaps use SqliteQuery() ?
	#todo perhaps add params array?

	my $query = shift;
	chomp $query;

	WriteLog('SqliteGetValue: ' . $query);

	my $sth = $dbh->prepare($query);
	$sth->execute(@_);

	my @aref = $sth->fetchrow_array();

	$sth->finish();

	return $aref[0];
}

sub DBGetAuthorCount { # Returns author count.
# By default, all authors, unless $whereClause is specified

	my $whereClause = shift;

	my $authorCount;
	if ($whereClause) {
		$authorCount = SqliteQueryCachedShell("SELECT COUNT(*) AS author_count FROM author_flat WHERE $whereClause LIMIT 1");
	} else {
		$authorCount = SqliteQueryCachedShell("SELECT COUNT(*) AS author_count FROM author_flat LIMIT 1");
	}
	chomp($authorCount);

	return $authorCount;

}

sub DBGetItemCount { # Returns item count.
# By default, all items, unless $whereClause is specified
	my $whereClause = shift;

	my $itemCount;
	if ($whereClause) {
		$itemCount = SqliteGetValue("SELECT COUNT(*) FROM item_flat WHERE $whereClause");
	} else {
		$itemCount = SqliteGetValue("SELECT COUNT(*) FROM item_flat");
	}
	chomp($itemCount);

	return $itemCount;
}

sub DBGetItemParents {# Returns all item's parents
# $itemHash = item's hash/identifier
# Sets up parameters and calls DBGetItemList
	my $itemHash = shift;

	if (!IsSha1($itemHash)) {
		WriteLog('DBGetItemParents called with invalid parameter! returning');
		return '';
	}

	$itemHash = SqliteEscape($itemHash);

	my %queryParams;
	$queryParams{'where_clause'} = "WHERE file_hash IN(SELECT item_hash FROM item_child WHERE item_hash = '$itemHash')";
	$queryParams{'order_clause'} = "ORDER BY add_timestamp"; #todo this should be by timestamp

	return DBGetItemList(\%queryParams);
}

sub DBGetItemReplies { # Returns replies for item (actually returns all child items)
# $itemHash = item's hash/identifier
# Sets up parameters and calls DBGetItemList
	my $itemHash = shift;
	if (!IsItem($itemHash)) {
		WriteLog('DBGetItemReplies: warning: sanity check failed, returning');
		return '';
	}
	if ($itemHash ne SqliteEscape($itemHash)) {
		WriteLog('DBGetItemReplies: warning: $itemHash contains escapable characters');
		return '';
	}
	WriteLog("DBGetItemReplies($itemHash)");

	my %queryParams;
	$queryParams{'where_clause'} = "WHERE file_hash IN(SELECT item_hash FROM item_parent WHERE parent_hash = '$itemHash') AND ','||tags_list||',' NOT LIKE '%,meta,%'";
	$queryParams{'order_clause'} = "ORDER BY (tags_list NOT LIKE '%hastext%'), add_timestamp";

	return DBGetItemList(\%queryParams);
}

sub SqliteEscape { # Escapes supplied text for use in sqlite query
# Just changes ' to ''
	my $text = shift;

	if (defined $text) {
		$text =~ s/'/''/g;
	} else {
		$text = '';
	}

	return $text;
}

#sub SqliteAddKeyValue {
#	my $table = shift;
#	my $key = shift;
#	my $value = shift;
#
#	$table = SqliteEscape ($table);
#	$key = SqliteEscape($key);
#	$value = SqliteEscape($value);
#
#	SqliteQuery("INSERT INTO $table(key, alias) VALUES ('$key', '$value');");
#
#}

# sub DBGetAuthor {
# 	my $query = "SELECT author_key, author_alias FROM author_flat";
#
# 	my $authorInfo = SqliteQuery($query);
#
# 	return $authorInfo;
# }

sub DBGetItemTitle { # get title for item ($itemhash)
	my $itemHash = shift;

	if (!$itemHash || !IsItem($itemHash)) {
		return;
	}

	my $query = 'SELECT title FROM item_title WHERE file_hash = ?';
	my @queryParams = ();

	push @queryParams, $itemHash;

	my $itemTitle = SqliteGetValue($query, @queryParams);

	return $itemTitle;
}

sub DBGetItemAuthor { # get author for item ($itemhash)
	my $itemHash = shift;

	if (!$itemHash || !IsItem($itemHash)) {
		return;
	}

	chomp $itemHash;

	WriteLog('DBGetItemAuthor(' . $itemHash . ')');

	my $query = 'SELECT author_key FROM item_author WHERE file_hash = ?';
	my @queryParams = ();
	#
	push @queryParams, $itemHash;

	WriteLog('DBGetItemAuthor: $query = ' . $query);

	my $authorKey = SqliteGetValue($query, @queryParams);

	if ($authorKey) {
		return $authorKey;
	} else {
		return;
	}
}

sub DBAddConfigValue { # add value to the config table ($key, $value)
	state $query;
	state @queryParams;

	my $key = shift;

	if (!$key) {
		WriteLog('DBAddConfigValue: warning: sanity check failed');
		return '';
	}

	if ($key eq 'flush') {
		WriteLog("DBAddConfigValue(flush)");

		if ($query) {
			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = '';
			@queryParams = ();
		}

		return;
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		$query = '';
		@queryParams = ();
	}

	my $value = shift;
	my $timestamp = shift;
	my $resetFlag = shift;
	my $sourceItem = shift;

	if ($key =~ m/^([a-z0-9_\/.]+)$/) {
		# sanity success
		$key = $1;
	} else {
		WriteLog('DBAddConfigValue: warning: sanity check failed on $key = ' . $key);
		return '';
	}

	if (!$query) {
		$query = "INSERT OR REPLACE INTO config(key, value, timestamp, reset_flag, file_hash) VALUES ";
	} else {
		$query .= ",";
	}

	$query .= '(?, ?, ?, ?, ?)';
	push @queryParams, $key, $value, $timestamp, $resetFlag, $sourceItem;

	return;
}

sub DBGetTouchedPages { # Returns items from task table, used for prioritizing which pages need rebuild
# index, rss, authors, stats, tags, and top are returned first
	my $touchedPageLimit = shift;

	WriteLog("DBGetTouchedPages($touchedPageLimit)");

	# sorted by most recent (touch_time DESC) so that most recently touched pages are updated first.
	# this allows us to call a shallow update and still expect what we just did to be updated.
	my $query = "
		SELECT
			task_name,
			task_param,
			touch_time,
			priority
		FROM task
		WHERE task_type = 'page' AND priority > 0
		ORDER BY priority DESC, touch_time DESC
		LIMIT ?;
	";

	my @params;
	push @params, $touchedPageLimit;

	my $results = SqliteQuery($query, @params);

	return $results;
} # DBGetTouchedPages()


sub DBAddItemPage { # $itemHash, $pageType, $pageParam ; adds an entry to item_page table
# should perhaps be called DBAddItemPageReference
# purpose of table is to track which items are on which pages

	state $query;
	state @queryParams;

	my $itemHash = shift;

	if ($itemHash eq 'flush') {
		if ($query) {
			WriteLog("DBAddItemPage(flush)");

			if (!$query) {
				WriteLog('Aborting, no query');
				return;
			}

			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = "";
			@queryParams = ();
		}

		return;
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddItemPage('flush');
		$query = '';
		@queryParams = ();
	}

	my $pageType = shift;
	my $pageParam = shift;

	if (!$pageType) {
		WriteLog('DBAddItemPage: warning: called without $pageType');
		return;
	}
	if (!$pageParam) {
		$pageParam = '';
	}

	WriteLog("DBAddItemPage($itemHash, $pageType, $pageParam)");

	if (!$query) {
		$query = "INSERT OR REPLACE INTO item_page(item_hash, page_name, page_param) VALUES ";
	} else {
		$query .= ',';
	}

	$query .= '(?, ?, ?)';
	push @queryParams, $itemHash, $pageType, $pageParam;
}

sub DBResetPageTouch { # Clears the task table
# Called by clean-build, since it rebuilds the entire site
	WriteMessage("DBResetPageTouch() begin");

	my $query = "DELETE FROM task WHERE task_type = 'page'";
	my @queryParams = ();

	SqliteQuery($query, @queryParams);

	WriteMessage("DBResetPageTouch() end");
}

sub DBDeletePageTouch { # $pageName, $pageParam
#todo optimize
	#my $query = 'DELETE FROM task WHERE page_name = ? AND page_param = ?';
	my $query = "UPDATE task SET priority = 0 WHERE task_type = 'page' AND task_name = ? AND task_param = ?";

	my $pageName = shift;
	my $pageParam = shift;

	my @queryParams = ($pageName, $pageParam);

	SqliteQuery($query, @queryParams);
}

sub DBDeleteItemReferences { # delete all references to item from tables
	WriteLog('DBDeleteItemReferences() ...');

	my $hash = shift;
	if (!IsSha1($hash)) {
		return;
	}

	WriteLog('DBDeleteItemReferences(' . $hash . ')');

	#todo queue all pages in item_page ;
	#todo item_page should have all the child items for replies

	#file_hash
	my @tables = qw(
		author_alias
		config
		item
		item_attribute
	);
	foreach (@tables) {
		my $query = "DELETE FROM $_ WHERE file_hash = '$hash'";
		SqliteQuery($query);
	}

	#item_hash
	my @tables2 = qw(event item_page item_parent location);
	foreach (@tables2) {
		my $query = "DELETE FROM $_ WHERE item_hash = '$hash'";
		SqliteQuery($query);
	}

	{
		my $query = "DELETE FROM vote WHERE ballot_hash = '$hash'";
		SqliteQuery($query);
	}

	{
		my $query = "DELETE FROM item_attribute WHERE source = '$hash'";
		SqliteQuery($query);
	}


	#ballot_hash
	my @tables3 = qw(vote);
	foreach (@tables3) {
		my $query = "DELETE FROM $_ WHERE ballot_hash = '$hash'";
		SqliteQuery($query);
	}

	#todo
	#item_attribute.source
	#item_parent (?)
	#item_page (and refresh)
	#
	#
	#

	#todo any successes deleting stuff should result in a refresh for the affected page
} # DBDeleteItemReferences()

sub DBAddPageTouch { # $pageName, $pageParam; Adds or upgrades in priority an entry to task table
# task table is used for determining which pages need to be refreshed
# is called from IndexTextFile() to schedule updates for pages affected by a newly indexed item
# if $pageName eq 'flush' then all the in-function stored queries are flushed to database.
	state $query;
	state @queryParams;

	my $pageName = shift;

	if ($pageName eq 'index') {
		#return;
		# this can be uncommented during testing to save time
		#todo optimize this so that all pages aren't rewritten at once
	}

	if ($pageName eq 'tag') {
		# if a tag page is being updated,
		# then the tags summary page must be updated also
		DBAddPageTouch('tags');
	}

	if ($pageName eq 'flush') {
		# flush to database queue stored in $query and @queryParams
		if ($query) {
			WriteLog("DBAddPageTouch(flush)");

			if (!$query) {
				WriteLog('Aborting DBAddPageTouch(flush), no query');
				return;
			}

			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = "";
			@queryParams = ();
		}

		return;
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddPageTouch('flush');
		$query = '';
		@queryParams = ();
	}

	my $pageParam = shift;

	if (!$pageParam) {
		$pageParam = 0;
	}

	my $touchTime = GetTime();

	if ($pageName eq 'author') {
		# cascade refresh items which are by this author
		#todo probably put this in another function
		# could also be done as
		# foreach (author's items) { DBAddPageTouch('item', $item); }
		#todo this is kind of a hack, sould be refactored, probably

		# touch all of author's items too
		#todo fix awkward time() concat
		my $queryAuthorItems = "
			UPDATE task
			SET priority = (priority + 1), touch_time = " . time() . "
			WHERE
				task_type = 'page' AND
				task_name = 'item' AND
				task_param IN (
					SELECT file_hash FROM item_flat WHERE author_key = ?
				)
		";
		my @queryParamsAuthorItems;
		push @queryParamsAuthorItems, $pageParam;

		SqliteQuery($queryAuthorItems, @queryParamsAuthorItems);
	}
	#
	# if ($pageName eq 'item') {
	# 	# cascade refresh items which are by this author
	# 	#todo probably put this in another function
	# 	# could also be done as
	# 	# foreach (author's items) { DBAddPageTouch('item', $item); }
	#
	# 	# touch all of author's items too
	# 	my $queryAuthorItems = "
	# 		UPDATE task
	# 		SET priority = (priority + 1)
	# 		WHERE
	#			task_type = 'page' AND
	# 			task_name = 'item' AND
	# 			task_param IN (
	# 				SELECT file_hash FROM item WHERE author_key = ?
	# 			)
	# 	";
	# 	my @queryParamsAuthorItems;
	# 	push @queryParamsAuthorItems, $pageParam;
	#
	# 	SqliteQuery($queryAuthorItems, @queryParamsAuthorItems);
	# }

	#todo need to incremenet priority after doing this

	WriteLog("DBAddPageTouch($pageName, $pageParam)");

	if (!$query) {
		$query = "INSERT OR REPLACE INTO task(task_type, task_name, task_param, touch_time) VALUES ";
	} else {
		$query .= ',';
	}

	#todo
	# https://stackoverflow.com/a/34939386/128947
	# insert or replace into poet (_id,Name, count) values (
	# 	(select _id from poet where Name = "SearchName"),
	# 	"SearchName",
	# 	ifnull((select count from poet where Name = "SearchName"), 0) + 1)
	#
	# https://stackoverflow.com/a/3661644/128947
	# INSERT OR REPLACE INTO observations
	# VALUES (:src, :dest, :verb,
	#   COALESCE(
	#     (SELECT occurrences FROM observations
	#        WHERE src=:src AND dest=:dest AND verb=:verb),
	#     0) + 1);


	$query .= "('page', ?, ?, ?)";
	push @queryParams, $pageName, $pageParam, $touchTime;
} # DBAddPageTouch()

sub DBGetVoteCounts { # Get total vote counts by tag value
# Takes $orderBy as parameter, with vote_count being default;
#todo can probably be converted to parameterized query
	my $orderBy = shift;
	if ($orderBy) {
	} else {
		$orderBy = 'ORDER BY vote_count DESC';
	}

	my $query = "
		SELECT
			vote_value,
			vote_count
		FROM (
			SELECT
				vote_value,
				COUNT(vote_value) AS vote_count
			FROM
				vote
			WHERE
				file_hash IN (SELECT file_hash FROM item)
			GROUP BY
				vote_value
		)
		WHERE
			vote_count >= 1
		$orderBy;
	";

	my $sth = $dbh->prepare($query);
	$sth->execute();

	my $ref = $sth->fetchall_arrayref();

	$sth->finish();

	return $ref;
}

sub DBGetTagCount { # Gets number of distinct tag/vote values
	my $query = "
		SELECT
			COUNT(vote_value)
		FROM (
			SELECT
				DISTINCT vote_value
			FROM
				vote
			GROUP BY
				vote_value
		)
	";

	my $result = SqliteGetValue($query);

	if ($result) {
		WriteLog('DBGetTagCount: $result = ' . $result);
	} else {
		WriteLog('DBGetTagCount: warning: no $result, returning 0');
		$result = 0;
	}

	return $result;
} # DBGetTagCount()

sub DBGetItemLatestAction { # returns highest timestamp in all of item's children
# $itemHash is the item's identifier

	my $itemHash = shift;
	my @queryParams = ();

	# this is my first recursive sql query
	my $query = '
	SELECT MAX(add_timestamp) AS add_timestamp
	FROM item_flat
	WHERE file_hash IN (
		WITH RECURSIVE item_threads(x) AS (
			SELECT ?
			UNION ALL
			SELECT item_parent.item_hash
			FROM item_parent, item_threads
			WHERE item_parent.parent_hash = item_threads.x
		)
		SELECT * FROM item_threads
	)
	';

	push @queryParams, $itemHash;

	my $sth = $dbh->prepare($query);
	$sth->execute(@queryParams);

	my @aref = $sth->fetchrow_array();

	$sth->finish();

	return $aref[0];
}

#sub GetTopItemsForTag {
#	my $tag = shift;
#	chomp($tag);
#
#	my $query = "
#		SELECT * FROM item_flat WHERE file_hash IN (
#			SELECT file_hash FROM (
#				SELECT file_hash, COUNT(vote_value) AS vote_count
#				FROM vote WHERE vote_value = '" . SqliteEscape($tag) . "'
#				GROUP BY file_hash
#				ORDER BY vote_count DESC
#			)
#		);
#	";
#
#	return $query;
#}

sub DBAddKeyAlias { # adds new author-alias record $key, $alias, $pubkeyFileHash
	# $key = gpg fingerprint
	# $alias = author alias/name
	# $pubkeyFileHash = hash of file in which pubkey resides

	state $query;
	state @queryParams;

	my $key = shift;

	if ($key eq 'flush') {
		if ($query) {
			WriteLog("DBAddKeyAlias(flush)");

			if (!$query) {
				WriteLog('Aborting, no query');
				return;
			}

			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = "";
			@queryParams = ();
		}

		return;
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddKeyAlias('flush');
		$query = '';
		@queryParams = ();
	}

	my $alias = shift;
	my $pubkeyFileHash = shift;

	if (!$query) {
		$query = "INSERT OR REPLACE INTO author_alias(key, alias, file_hash) VALUES ";
	} else {
		$query .= ",";
	}

	$query .= "(?, ?, ?)";
	push @queryParams, $key, $alias, $pubkeyFileHash;

	ExpireAvatarCache($key); # does fresh lookup, no cache
	DBAddPageTouch('author', $key);
} # DBAddKeyAlias()

sub DBAddItemParent { # Add item parent record. $itemHash, $parentItemHash ;
# Usually this is when item references parent item, by being a reply or a vote, etc.
#todo replace with item_attribute
	state $query;
	state @queryParams;

	my $itemHash = shift;

	if ($itemHash eq 'flush') {
		if ($query) {
			WriteLog('DBAddItemParent(flush)');

			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = '';
			@queryParams = ();
		}

		return;
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddPageTouch('flush');
		DBAddItemParent('flush');
		$query = '';
		@queryParams = ();
	}

	my $parentHash = shift;

	if (!$parentHash) {
		WriteLog('DBAddItemParent: warning: $parentHash missing');
		return;
	}

	if ($itemHash eq $parentHash) {
		WriteLog('DBAddItemParent: warning: $itemHash eq $parentHash');
		return;
	}

	if (!$query) {
		$query = "INSERT OR REPLACE INTO item_parent(item_hash, parent_hash) VALUES ";
	} else {
		$query .= ",";
	}

	$query .= '(?, ?)';
	push @queryParams, $itemHash, $parentHash;

	DBAddPageTouch('item', $itemHash);
	DBAddPageTouch('item', $parentHash);
}

sub DBAddItem2 {
	my $filePath = shift;
	my $fileHash = shift;
	my $itemType = shift;
	return DBAddItem($filePath, '', '', $fileHash, $itemType, 0);
}

sub DBAddItem { # $filePath, $itemName, $authorKey, $fileHash, $itemType, $verifyError ; Adds a new item to database
# $filePath = path to text file
# $itemName = item's 'name' (currently hash)
# $authorKey = author's gpg fingerprint
# $fileHash = hash of item
# $itemType = type of item (currently 'txt', 'image', 'url' supported)
# $verifyError = whether there was an error with gpg verification of item

	state $query;
	state @queryParams;

	my $filePath = shift;

	if ($filePath eq 'flush') {
		if ($query) {
			WriteLog("DBAddItem(flush)");

			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = '';
			@queryParams = ();

			DBAddItemAttribute('flush');
		}

		return '';
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddItem('flush');
		$query = '';
		@queryParams = ();
	}

	my $itemName = shift;
	my $authorKey = shift;
	my $fileHash = shift;
	my $itemType = shift;
	my $verifyError = shift;

	#DBAddItemAttribute($fileHash, 'attribute', 'value', 'epoch', 'source');

	if (!$authorKey) {
		$authorKey = '';
	}
#
#	if ($authorKey) {
#		DBAddItemParent($fileHash, DBGetAuthorPublicKeyHash($authorKey));
#	}

	WriteLog("DBAddItem($filePath, $itemName, $authorKey, $fileHash, $itemType, $verifyError);");

	if (!$query) {
		$query = "INSERT OR REPLACE INTO item(file_path, item_name, file_hash, item_type, verify_error) VALUES ";
	} else {
		$query .= ",";
	}
	push @queryParams, $filePath, $itemName, $fileHash, $itemType, $verifyError;

	$query .= "(?, ?, ?, ?, ?)";

	my $filePathRelative = $filePath;
	state $htmlDir = GetDir('html');
	$filePathRelative =~ s/$htmlDir\//\//;

	WriteLog('DBAddItem: $filePathRelative = ' . $filePathRelative . '; $htmlDir = ' . $htmlDir);

	DBAddItemAttribute($fileHash, 'sha1', $fileHash);
	#DBAddItemAttribute($fileHash, 'md5', md5_hex(GetFile($filePath)));
	DBAddItemAttribute($fileHash, 'item_type', $itemType);
	DBAddItemAttribute($fileHash, 'file_path', $filePathRelative);

	if ($verifyError) {
		DBAddItemAttribute($fileHash, 'verify_error', '1');
	}
}

sub DBAddEventRecord { # add event record to database; $itemHash, $eventTime, $eventDuration, $signedBy
	state $query;
	state @queryParams;

	WriteLog("DBAddEventRecord()");

	my $fileHash = shift;

	if ($fileHash eq 'flush') {
		WriteLog("DBAddEventRecord(flush)");

		if ($query) {
			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = '';
			@queryParams = ();
		}

		return;
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddEventRecord('flush');
		$query = '';
		@queryParams = ();
	}

	my $eventTime = shift;
	my $eventDuration = shift;
	my $signedBy = shift;

	if (!$eventTime || !$eventDuration) {
		WriteLog('DBAddEventRecord() sanity check failed! Missing $eventTime or $eventDuration');
		return;
	}

	chomp $eventTime;
	chomp $eventDuration;

	if ($signedBy) {
		chomp $signedBy;
	} else {
		$signedBy = '';
	}

	if (!$query) {
		$query = "INSERT OR REPLACE INTO event(item_hash, event_time, event_duration, author_key) VALUES ";
	} else {
		$query .= ",";
	}

	$query .= '(?, ?, ?, ?)';
	push @queryParams, $fileHash, $eventTime, $eventDuration, $signedBy;
}


sub DBAddLocationRecord { # $itemHash, $latitude, $longitude, $signedBy ; Adds new location record from latlong token
	state $query;
	state @queryParams;

	WriteLog("DBAddLocationRecord()");

	my $fileHash = shift;

	if ($fileHash eq 'flush') {
		WriteLog("DBAddLocationRecord(flush)");

		if ($query) {
			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = '';
			@queryParams = ();
		}

		return;
	}

	if (
		$query
			&&
		(
			length($query) >= DBMaxQueryLength()
				||
			scalar(@queryParams) > DBMaxQueryParams()
		)
	) {
		DBAddLocationRecord('flush');
		$query = '';
		@queryParams = ();
	}

	my $latitude = shift;
	my $longitude = shift;
	my $signedBy = shift;

	if (!$latitude || !$longitude) {
		WriteLog('DBAddLocationRecord() sanity check failed! Missing $latitude or $longitude');
		return;
	}

	chomp $latitude;
	chomp $longitude;

	if ($signedBy) {
		chomp $signedBy;
	} else {
		$signedBy = '';
	}

	if (!$query) {
		$query = "INSERT OR REPLACE INTO location(item_hash, latitude, longitude, author_key) VALUES ";
	} else {
		$query .= ",";
	}

	$query .= '(?, ?, ?, ?)';
	push @queryParams, $fileHash, $latitude, $longitude, $signedBy;
}

###

sub DBAddVoteRecord { # $fileHash, $ballotTime, $voteValue, $signedBy, $ballotHash ; Adds a new vote (tag) record to an item based on vote/ token
	state $query;
	state @queryParams;

	WriteLog("DBAddVoteRecord()");

	my $fileHash = shift;

	if ($fileHash eq 'flush') {
		WriteLog("DBAddVoteRecord(flush)");

		if ($query) {
			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = '';
			@queryParams = ();
		}

		return;
	}

	if (!$fileHash) {
		WriteLog('DBAddVoteRecord: warning: called without $fileHash');
		return '';
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddVoteRecord('flush');
		DBAddPageTouch('flush');
		$query = '';
	}

	my $ballotTime = shift;
	my $voteValue = shift;
	my $signedBy = shift;
	my $ballotHash = shift;

	if (!$ballotTime) {
		WriteLog('DBAddVoteRecord: warning: missing $ballotTime');
		return '';
	}

#	if (!$signedBy) {
#		WriteLog("DBAddVoteRecord() called without \$signedBy! Returning.");
#	}

	chomp $fileHash;
	chomp $ballotTime;
	chomp $voteValue;

	if ($signedBy) {
		chomp $signedBy;
	} else {
		$signedBy = '';
	}

	if ($ballotHash) {
		chomp $ballotHash;
	} else {
		$ballotHash = '';
	}

	if (!$query) {
		$query = "INSERT OR REPLACE INTO vote(file_hash, ballot_time, vote_value, author_key, ballot_hash) VALUES ";
	} else {
		$query .= ",";
	}

	$query .= '(?, ?, ?, ?, ?)';
	push @queryParams, $fileHash, $ballotTime, $voteValue, $signedBy, $ballotHash;

	DBAddPageTouch('tag', $voteValue);
	DBAddPageTouch('item', $fileHash);
}

sub DBGetItemAttribute { # $fileHash, [$attribute] ; returns all if attribute not specified
	my $fileHash = shift;
	my $attribute = shift;

	if ($fileHash) {
		if ($fileHash =~ m/[^a-f0-9]/) {
			WriteLog('DBGetItemAttribute: warning: sanity check failed on $fileHash');
			return '';
		} else {
			$fileHash =~ s/[^a-f0-9]//g;
		}
	} else {
		return '';
	}
	if (!$fileHash) {
		WriteLog('DBGetItemAttribute: warning: where is $fileHash?');
		return '';
	}

	if ($attribute) {
		$attribute =~ s/[^a-zA-Z0-9_]//g;
		#todo add sanity check
	} else {
		$attribute = '';
	}

	my $query = "SELECT attribute, value FROM item_attribute_latest WHERE file_hash = '$fileHash'";
	if ($attribute) {
		$query .= " AND attribute = '$attribute'";
	}

	my $results = SqliteQuery3($query);
	return $results;
} # DBGetItemAttribute()


sub DBGetItemAttributeValue { # $fileHash, [$attribute] ; returns one value
	my $fileHash = shift;
	my $attribute = shift;

	if ($fileHash) {
		if ($fileHash =~ m/[^a-f0-9]/) {
			WriteLog('DBGetItemAttributeValue: warning: sanity check failed on $fileHash');
			return '';
		} else {
			$fileHash =~ s/[^a-f0-9]//g;
		}
	} else {
		return '';
	}
	if (!$fileHash) {
		WriteLog('DBGetItemAttributeValue: warning: where is $fileHash?');
		return '';
	}

	if ($attribute) {
		$attribute =~ s/[^a-zA-Z0-9_]//g;
		#todo add sanity check
	} else {
		$attribute = '';
	}

	my $query = "SELECT value FROM item_attribute_latest WHERE file_hash = '$fileHash'";
	if ($attribute) {
		$query .= " AND attribute = '$attribute'";
	} else {
		WriteLog('DBGetItemAttributeValue: warning: called without $attribute');
		return '';
	}

	my $result = SqliteGetValue($query);
	return $result;
} # DBGetItemAttributeValue()

sub DBAddItemAttribute { # $fileHash, $attribute, $value, $epoch, $source # add attribute to item
# currently no constraints
	state $query;
	state @queryParams;

	WriteLog("DBAddItemAttribute()");

	my $fileHash = shift;

	if ($fileHash eq 'flush') {
		WriteLog("DBAddItemAttribute(flush)");

		if ($query) {
			$query .= ';';

			SqliteQuery($query, @queryParams);

			$query = '';
			@queryParams = ();
		}

		return;
	}

	if (!$fileHash) {
		WriteLog('DBAddItemAttribute() called without $fileHash! Returning.');
	}

	if ($query && (length($query) > DBMaxQueryLength() || scalar(@queryParams) > DBMaxQueryParams())) {
		DBAddItemAttribute('flush');
		$query = '';
	}

	my $attribute = shift;
	my $value = shift;
	my $epoch = shift;
	my $source = shift;

	if (!$attribute) {
		WriteLog('DBAddItemAttribute: warning: called without $attribute');
		return '';
	}
	if (!defined($value)) {
		WriteLog('DBAddItemAttribute: warning: called without $value, $attribute = ' . $attribute);
		return '';
	}

	chomp $fileHash;
	chomp $attribute;
	chomp $value;

	if (!$epoch) {
		$epoch = '';
	}
	if (!$source) {
		$source = '';
	}

	chomp $epoch;
	chomp $source;

	WriteLog("DBAddItemAttribute($fileHash, $attribute, $value, $epoch, $source)");

	if (!$query) {
		$query = "INSERT OR REPLACE INTO item_attribute(file_hash, attribute, value, epoch, source) VALUES ";
	} else {
		$query .= ",";
	}

	$query .= '(?, ?, ?, ?, ?)';
	push @queryParams, $fileHash, $attribute, $value, $epoch, $source;
}

sub DBGetAddedTime { # return added time for item specified
	my $fileHash = shift;
	if (!$fileHash) {
		WriteLog('DBGetAddedTime: warning: $fileHash missing');
		return;
	}
	chomp ($fileHash);

	if (!IsSha1($fileHash)) {
		WriteLog('DBGetAddedTime: warning: called with invalid parameter! returning');
		return;
	}

	if (!IsSha1($fileHash) || $fileHash ne SqliteEscape($fileHash)) {
		WriteLog('DBGetAddedTime: warning: important sanity check failed! this should never happen: !IsSha1($fileHash) || $fileHash ne SqliteEscape($fileHash)');
		return '';
	} #todo ideally this should verify it's a proper hash too

	my $query = "
		SELECT
			MIN(value) AS add_timestamp
		FROM item_attribute
		WHERE
			file_hash = '$fileHash' AND
			attribute IN ('chain_timestamp', 'gpg_timestamp', 'puzzle_timestamp', 'access_log_timestamp')
	";
	# my $query = "SELECT add_timestamp FROM added_time WHERE file_hash = '$fileHash'";

	WriteLog($query);

	if ($dbh) {
		my $sth = $dbh->prepare($query);
		$sth->execute();

		my @aref = $sth->fetchrow_array();

		$sth->finish();

		my $resultUnHacked = $aref[0];
		#todo do this properly

		return $resultUnHacked;
	} else {
		WriteLog('DBGetAddedTime: warning: $dbh was missing, returning empty-handed');
	}
} # DBGetAddedTime()

sub DBGetItemListByTagList { #get list of items by taglist (as array)
# uses DBGetItemList()
#	my @tagListArray = shift;

#	if (scalar(@tagListArray) < 1) {
#		return;
#	}

	#todo sanity checks

	my @tagListArray = @_;

	my $tagListCount = scalar(@tagListArray);

	my $tagListArrayText = "'" . join ("','", @tagListArray) . "'";

	my %queryParams;
	my $whereClause = "
		WHERE file_hash IN (
			SELECT file_hash FROM (
				SELECT
					COUNT(id) AS vote_count,
						file_hash
				FROM vote
				WHERE vote_value IN ($tagListArrayText)
				GROUP BY file_hash
			) WHERE vote_count >= $tagListCount
		)
	";
	WriteLog("DBGetItemListByTagList");
	WriteLog("$whereClause");

	$queryParams{'where_clause'} = $whereClause;

	#todo this is currently an "OR" select, but it should be an "AND" select.

	return DBGetItemList(\%queryParams);
}

sub DBGetItemList { # get list of items from database. takes reference to hash of parameters
	my $paramHashRef = shift;
	my %params = %$paramHashRef;

	#supported params:
	#where_clause = where clause for sql query
	#order_clause
	#limit_clause

	my $query;
	my $itemFields = DBGetItemFields();
	$query = "
		SELECT
			$itemFields
		FROM
			item_flat
	";

	#todo sanity check: typically, none of these should have a semicolon?
	if (defined ($params{'join_clause'})) {
		$query .= " " . $params{'join_clause'};
	}
	if (defined ($params{'where_clause'})) {
		$query .= " " . $params{'where_clause'};
	}
	if (defined ($params{'group_by_clause'})) {
		$query .= " " . $params{'group_by_clause'};
	}
	if (defined ($params{'order_clause'})) {
		$query .= " " . $params{'order_clause'};
	}
	if (defined ($params{'limit_clause'})) {
		$query .= " " . $params{'limit_clause'};
	}

	#todo bind params and use hash of parameters

	WriteLog('DBGetItemList: $query = ' . $query);

	my $sth = $dbh->prepare($query);
	$sth->execute();

	my @resultsArray = ();

	while (my $row = $sth->fetchrow_hashref()) {
		push @resultsArray, $row;
	}

	return @resultsArray;
} # DBGetItemList()

sub DBGetAllAppliedTags { # return all tags that have been used at least once
	my $query = "
		SELECT DISTINCT vote_value FROM vote
		JOIN item ON (vote.file_hash = item.file_hash)
	";

	my $sth = $dbh->prepare($query);

	my @ary;

	$sth->execute();

	$sth->bind_columns(\my $val1);

	while ($sth->fetch) {
		push @ary, $val1;
	}

	return @ary;
}

sub DBGetItemListForAuthor { # return all items attributed to author
	my $author = shift;
	chomp($author);

	if (!IsFingerprint($author)) {
		WriteLog('DBGetItemListForAuthor called with invalid parameter! returning');
		return;
	}
	$author = SqliteEscape($author);

	my %params = {};

	$params{'where_clause'} = "WHERE author_key = '$author'";

	return DBGetItemList(\%params);
}

sub DBGetAuthorList { # returns list of all authors' gpg keys as array
	my $query = "SELECT key FROM author";

	my $sth = $dbh->prepare($query);

	$sth->execute();

	my @resultsArray = ();

	while (my $row = $sth->fetchrow_hashref()) {
		push @resultsArray, $row;
	}

	return @resultsArray;
}

sub DBGetAuthorAlias { # returns author's alias by gpg key
	my $key = shift;
	chomp $key;

	if (!IsFingerprint($key)) {
		WriteLog('DBGetAuthorAlias: warning: called with invalid parameter! returning');
		return;
	}

	$key = SqliteEscape($key);

	if ($key) {
		my $query = "SELECT alias FROM author_alias WHERE key = '$key'";
		return SqliteGetValue($query);
	} else {
		return "";
	}
}

sub DBGetAuthorScore { # returns author's total score
# score is the sum of all the author's items' scores
# $key = author's gpg key
	my $key = shift;
	chomp ($key);

	if (!IsFingerprint($key)) {
		WriteLog('Problem! DBGetAuthorScore called with invalid parameter! returning');
		return;
	}

	state %scoreCache;
	if (exists($scoreCache{$key})) {
		return $scoreCache{$key};
	}

	$key = SqliteEscape($key);

	if ($key) { #todo fix non-param sql
		my $query = "SELECT author_score FROM author_score WHERE author_key = '$key'";
		$scoreCache{$key} = SqliteGetValue($query);
		return $scoreCache{$key};
	} else {
		return "";
	}
}

sub DBGetAuthorItemCount { # returns number of items attributed to author identified by $key
# $key = author's gpg key
	my $key = shift;
	chomp ($key);

	if (!IsFingerprint($key)) {
		WriteLog('DBGetAuthorItemCount: warning: called with non-fingerprint parameter, returning');
		return 0;
	}
	if ($key ne SqliteEscape($key)) {
		# should be redundant, but what the heck
		WriteLog('DBGetAuthorItemCount: warning: $key != SqliteEscape($key)');
		return 0;
	}

	state %scoreCache;
	if (exists($scoreCache{$key})) {
		return $scoreCache{$key};
	}

	if ($key) {
		my $query = "SELECT COUNT(file_hash) file_hash_count FROM (SELECT DISTINCT file_hash FROM item_flat WHERE author_key = ?)";
		$scoreCache{$key} = SqliteGetValue($query, $key);
		return $scoreCache{$key};
	} else {
		return 0;
	}

	WriteLog('DBGetAuthorItemCount: warning: unreachable reached');
	return 0;
} # DBGetAuthorItemCount()

sub DBGetAuthorLastSeen { # return timestamp of last item attributed to author
# $key = author's gpg key
	my $key = shift;
	chomp ($key);

	if (!IsFingerprint($key)) {
		WriteLog('Problem! DBGetAuthorLastSeen called with invalid parameter! returning');
		return;
	}

	state %lastSeenCache;
	if (exists($lastSeenCache{$key})) {
		return $lastSeenCache{$key};
	}

	$key = SqliteEscape($key);

	if ($key) { #todo fix non-param sql
		my $query = "SELECT MAX(item_flat.add_timestamp) AS last_seen FROM item_flat WHERE author_key = '$key'";
		$lastSeenCache{$key} = SqliteGetValue($query);
		return $lastSeenCache{$key};
	} else {
		return "";
	}
}


sub DBGetAuthorPublicKeyHash { # Returns the hash/identifier of the file containing the author's public key
# $key = author's gpg fingerprint
# cached in hash called %authorPubKeyCache

	my $key = shift;
	chomp ($key);

	if (!IsFingerprint($key)) {
		WriteLog('Problem! DBGetAuthorPublicKeyHash called with invalid parameter! returning');
		return;
	}

	state %authorPubKeyCache;
	if (exists($authorPubKeyCache{$key}) && $authorPubKeyCache{$key}) {
		WriteLog('DBGetAuthorPublicKeyHash: returning from memo: ' . $authorPubKeyCache{$key});
		return $authorPubKeyCache{$key};
	}

	$key = SqliteEscape($key);

	if ($key) { #todo fix non-param sql
		my $query = "SELECT MAX(author_alias.file_hash) AS file_hash FROM author_alias WHERE key = '$key'";
		my $fileHashReturned = SqliteGetValue($query);
		if ($fileHashReturned) {
			$authorPubKeyCache{$key} = SqliteGetValue($query);
			WriteLog('DBGetAuthorPublicKeyHash: returning ' . $authorPubKeyCache{$key});
			return $authorPubKeyCache{$key};
		} else {
			WriteLog('DBGetAuthorPublicKeyHash: database drew a blank, returning 0');
			return 0;
		}
	} else {
		return "";
	}
} # DBGetAuthorPublicKeyHash()

sub DBGetItemFields { # Returns fields we typically need to request from item_flat table
	my $itemFields =
		"item_flat.file_path file_path,
		item_flat.item_name item_name,
		item_flat.file_hash file_hash,
		item_flat.author_key author_key,
		item_flat.child_count child_count,
		item_flat.parent_count parent_count,
		item_flat.add_timestamp add_timestamp,
		item_flat.item_title item_title,
		item_flat.item_score item_score,
		item_flat.tags_list tags_list,
		item_flat.item_type item_type";

	return $itemFields;
}

sub DBGetTopAuthors { # Returns top-scoring authors from the database
	WriteLog('DBGetTopAuthors() begin');

	my $query = "
		SELECT
			author_key,
			author_alias,
			author_score,
			last_seen,
			item_count
		FROM author_flat
		ORDER BY author_score DESC
		LIMIT 1024;
	";

	my @queryParams = ();

	my $sth = $dbh->prepare($query);
	$sth->execute(@queryParams);

	my @resultsArray = ();

	while (my $row = $sth->fetchrow_hashref()) {
		push @resultsArray, $row;
	}

	return @resultsArray;
}

sub DBGetTopItems { # get top items minus flag (hard-coded for now)
	WriteLog('DBGetTopItems()');

	my %queryParams;
	$queryParams{'where_clause'} = "WHERE item_score > 0";
	$queryParams{'order_clause'} = "ORDER BY add_timestamp DESC";
	$queryParams{'limit_clause'} = "LIMIT 100";
	my @resultsArray = DBGetItemList(\%queryParams);

	return @resultsArray;
}

sub DBGetItemsByPrefix { # $prefix ; get items whose hash begins with $prefix
	my $prefix = shift;
	if (!IsItemPrefix($prefix)) {
		WriteLog('DBGetItemsByPrefix: warning: $prefix sanity check failed');
		return '';
	}

	my $itemFields = DBGetItemFields();
	my $whereClause;
	$whereClause = "
		WHERE
			(file_hash LIKE '%$prefix')

	"; #todo remove hardcoding here

	my $query = "
		SELECT
			$itemFields
		FROM
			item_flat
		$whereClause
		ORDER BY
			add_timestamp DESC
		LIMIT 50;
	";

	WriteLog('DBGetItemsByPrefix: $query = ' . $query);
	my @queryParams;

	my $sth = $dbh->prepare($query);
	$sth->execute(@queryParams);

	my @resultsArray = ();
	while (my $row = $sth->fetchrow_hashref()) {
		push @resultsArray, $row;
	}

	WriteLog('DBGetItemsByPrefix: scalar(@resultsArray) = ' . @resultsArray);

	return @resultsArray;
} # DBGetItemsByPrefix()

sub DBGetItemVoteTotals { # get tag counts for specified item, returned as hash of [tag] -> count
	my $fileHash = shift;
	if (!$fileHash) {
		WriteLog('DBGetItemVoteTotals: warning: $fileHash missing, returning');
		return 0;
	}

	chomp $fileHash;

	if (!IsItem($fileHash)) {
		WriteLog('DBGetItemVoteTotals: warning: sanity check failed, returned');
		return;
	}

	WriteLog("DBGetItemVoteTotals($fileHash)");

	my $query = "
		SELECT
			vote_value,
			COUNT(vote_value) AS vote_count
		FROM
			vote
		WHERE
			file_hash = ?
		GROUP BY
			vote_value
		ORDER BY
			vote_count DESC;
	";

	my @queryParams;
	push @queryParams, $fileHash;

	my $sth = $dbh->prepare($query);
	$sth->execute(@queryParams);

	my %voteTotals;

	my $tagTotal;
	while ($tagTotal = $sth->fetchrow_arrayref()) {
		$voteTotals{@$tagTotal[0]} = @$tagTotal[1];
	}

	$sth->finish();

	return %voteTotals;
} # DBGetItemVoteTotals()

1;








		if ($message) {
			# cache the processed message text
			my $messageCacheName = GetMessageCacheName($fileHash);
			if ($txt) {
				WriteLog("IndexTextFile: \n====\n" . $messageCacheName . "\n====\n" . $message . "\n====\n" . $txt . "\n====\n");
			} else {
				WriteLog('IndexTextFile: warning: $txt was false; $fileHash = ' . $fileHash . '; $messageCacheName = ' . $messageCacheName);
			}
			PutFile($messageCacheName, $message);
		} else {
			WriteLog('IndexTextFile: I was going to save $messageCacheName, but $message is blank!');
		}

		# below we call DBAddItem, which accepts an author key
		if ($isSigned) {
			# If message is signed, use the signer's key
			DBAddItem($file, $itemName, $gpgKey, $fileHash, 'txt', $verifyError);

			if ($gpgTimestamp) {
				my $gpgTimestampEpoch = `date -d "$gpgTimestamp" +%s`;
				DBAddItemAttribute($fileHash, 'gpg_timestamp', $gpgTimestampEpoch);
			}
		} else {
			if ($hasCookie) {
				# Otherwise, if there is a cookie, use the cookie
				DBAddItem($file, $itemName, $hasCookie, $fileHash, 'txt', $verifyError);
			} else {
				# Otherwise add with an empty author key
				DBAddItem($file, $itemName, '', $fileHash, 'txt', $verifyError);
			}
		}

		DBAddPageTouch('read');
		DBAddPageTouch('item', $fileHash);
		if ($isSigned && $gpgKey && IsAdmin($gpgKey)) {
			$isAdmin = 1;
			DBAddVoteRecord($fileHash, 0, 'admin');
			DBAddPageTouch('tag', 'admin');
		}
		if ($isSigned) {
			DBAddPageTouch('author', $gpgKey);
			DBAddPageTouch('authors');
		} elsif ($hasCookie) {
			DBAddPageTouch('author', $hasCookie);
			DBAddPageTouch('authors');
		}
		DBAddPageTouch('stats');
		DBAddPageTouch('rss');
		DBAddPageTouch('index');
		DBAddPageTouch('compost');
		DBAddPageTouch('chain');
		DBAddPageTouch('flush'); #todo shouldn't be here
	}
	return $fileHash;
} # IndexTextFile()


















		if ($gpgKey) { #hack
			my $gpgWelcomeFilename = 'html/txt/welcome_' . $gpgKey . '.txt';
			my $gpgWelcomeCommand = 'echo "Welcome" | gpg --trust-model always --armor --encrypt -r ' . $gpgKey . ' > ' . $gpgWelcomeFilename;
			WriteLog('IndexTextFile: $gpgWelcomeCommand = ' . $gpgWelcomeCommand);
			$gpgWelcomeCommand = 'echo "Welcome" | gpg --trusted-key ' . $gpgKey . ' --armor --encrypt -r ' . $gpgKey . ' > ' . $gpgWelcomeFilename;
			WriteLog('IndexTextFile: $gpgWelcomeCommand = ' . $gpgWelcomeCommand);
		}



	while (@hashTags) {
		my $hashTagToken = shift @hashTags;
		$hashTagToken = trim($hashTagToken);
		my $hashTag = shift @hashTags;
		$hashTag = trim($hashTag);

		if ($hashTag && (IsAdmin($gpgKey) || $authorHasTag{'admin'} || $authorHasTag{$hashTag})) {
			#if ($hashTag) {
			WriteLog('IndexTextFile: $hashTag = ' . $hashTag);

			$hasToken{$hashTag} = 1;

			if ($hasParent) {
				WriteLog('$hasParent');

			} # if ($hasParent)
			else { # no parent, !($hasParent)
				WriteLog('$hasParent is FALSE');

				if ($isSigned) {
					# include author's key if message is signed
					DBAddVoteRecord($fileHash, $addedTime, $hashTag, $gpgKey, $fileHash);
				}
				else {
					if ($hasCookie) {
						DBAddVoteRecord($fileHash, $addedTime, $hashTag, $hasCookie, $fileHash);
					} else {
						DBAddVoteRecord($fileHash, $addedTime, $hashTag, '', $fileHash);
					}
				}
			}

			DBAddPageTouch('tag', $hashTag);

			$detokenedMessage =~ s/#$hashTag//g;
		} # if ($hashTag)
	} # while (@hashTags)
} # if (GetConfig('admin/token/hashtag') && $message)









{
	# look up author's tags

	my @tagsAppliedToAuthor = DBGetAllAppliedTags(DBGetAuthorPublicKeyHash($gpgKey));
	foreach my $tagAppliedToAuthor (@tagsAppliedToAuthor) {
		$authorHasTag{$tagAppliedToAuthor} = 1;
		my $tagsInTagSet = GetTemplate('tagset/' . $tagAppliedToAuthor);
		# if ($tagsInTagSet) {
		# 	foreach my $tagInTagSet (split("\n", $tagsInTagSet)) {
		# 		if ($tagInTagSet) {
		# 			$authorHasTag{$tagInTagSet} = 1;
		# 		}
		# 	}
		# }
	}
}
#DBAddItemAttribute($fileHash, 'x_author_tags', join(',', keys %authorHasTag));





















		#my $lineCount = @setTitleToLines / 3;
		while (@lines) {
			# loop through all found title: token lines
			my $token = shift @lines;
			my $space = shift @lines;
			my $value = shift @lines;

			chomp $token;
			chomp $space;
			chomp $value;
			$value = trim($value);

			my $reconLine; # reconciliation
			$reconLine = $token . $space . $value;

			WriteLog('IndexTextFile: #verify $reconLine = ' . $reconLine);
			WriteLog('IndexTextFile: #verify $value = ' . $value);

			if ($value =~ m|https://www.reddit.com/user/([0-9a-zA-Z\-_]+)/?|) {
				# reddit verify
				$hasToken{'verify'} = 1;
				my $redditUsername = $1;
				my $valueHash = sha1_hex($value);
				my $profileHtml = '';

				if (-e "once/$valueHash") {
					WriteLog('IndexTextFile: once exists');
					$profileHtml = GetFile("once/$valueHash");
				} else {
					my $curlCommand = 'curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" "' . EscapeShellChars($value) .'.json"';
					WriteLog('IndexTextFile: #verify once needed, doing curl');
					WriteLog('IndexTextFile: #verify "' . $curlCommand . '"');

					my $curlResult = `$curlCommand`; #note the backticks
					# this could be dangerous, but the url is sanitized above

					PutFile("once/$valueHash", $curlResult);
					$profileHtml = GetFile("once/$valueHash");
				}

				WriteLog('IndexTextFile: #verify $value = ' . $value);

				if ($hasParent) {
					# has parent(s), so add title to each parent
					foreach my $itemParent (@itemParents) {
						if (index($profileHtml, $itemParent) != -1) {
							DBAddItemAttribute($itemParent, 'reddit_url', $value, $addedTime, $fileHash);
							DBAddItemAttribute($itemParent, 'reddit_username', $redditUsername, $addedTime, $fileHash);
							DBAddPageTouch('item', $itemParent);
						}
					} # @itemParents
				} else {
					# no parents, ignore
					WriteLog('IndexTextFile: AccessLogHash: Item has no parent, ignoring');

					# DBAddVoteRecord($fileHash, $addedTime, 'hasAccessLogHash');
					# DBAddItemAttribute($fileHash, 'AccessLogHash', $titleGiven, $addedTime);
				}
			} #reddit


			if ($value =~ m|https://www.twitter.com/([0-9a-zA-Z_]+)/?|) { # supposed to be 15 chars or less
				# twitter verify
				$hasToken{'verify'} = 1;
				my $twitterUsername = $1;
				my $valueHash = sha1_hex($value);
				my $profileHtml = '';

				if (-e "once/$valueHash") {
					WriteLog('IndexTextFile: once exists');
					$profileHtml = GetFile("once/$valueHash");
				} else {
					my $curlCommand = 'curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" "' . EscapeShellChars($value);

					WriteLog('IndexTextFile: #verify once needed, doing curl');
					WriteLog('IndexTextFile: #verify "' . $curlCommand . '"');

					my $curlResult = `$curlCommand`; #note the backticks
					# should be safe because url is sanitized above

					PutFile("once/$valueHash", $curlResult);
					$profileHtml = GetFile("once/$valueHash");
				}

				WriteLog('IndexTextFile: #verify $value = ' . $value);

				if ($hasParent) {
					# has parent(s), so add title to each parent
					foreach my $itemParent (@itemParents) {
						if (index($profileHtml, $itemParent) != -1) {
							DBAddItemAttribute($itemParent, 'twitter_url', $value, $addedTime, $fileHash);
							DBAddItemAttribute($itemParent, 'twitter_username', $twitterUsername, $addedTime, $fileHash);
							DBAddPageTouch('item', $itemParent);
						}
					} # @itemParents
				} else {
					# no parents, ignore
					WriteLog('IndexTextFile: AccessLogHash: Item has no parent, ignoring');

					# DBAddVoteRecord($fileHash, $addedTime, 'hasAccessLogHash');
					# DBAddItemAttribute($fileHash, 'AccessLogHash', $titleGiven, $addedTime);
				}
			} # twitter

			if ($value =~ m|https://www.instagram.com/([0-9a-zA-Z._]+)/?|) {
				# instagram verification (not working yet)
				$hasToken{'verify'} = 1;
				my $instaUsername = $1;
				my $valueHash = sha1_hex($value);
				my $profileHtml = '';

				if (-e "once/$valueHash") {
					WriteLog('IndexTextFile: once exists');
					$profileHtml = GetFile("once/$valueHash");
				} else {
					my $curlCommand = 'curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" "' . EscapeShellChars($value) . '"';

					WriteLog('IndexTextFile: #verify once needed, doing curl');
					WriteLog('IndexTextFile: #verify "'.$curlCommand.'"');

					my $curlResult = `$curlCommand`; #note backticks
					# should be safe because url is sanitized above

					PutFile("once/$valueHash", $curlResult); # runs the curl command, note the backticks
					$profileHtml = GetFile("once/$valueHash");
				}

				WriteLog('IndexTextFile: #verify $value = ' . $value);

				if ($hasParent) {
					# has parent(s), so add title to each parent
					foreach my $itemParent (@itemParents) {
						if (index($profileHtml, $itemParent) != -1) {
							DBAddItemAttribute($itemParent, 'insta_url', $value, $addedTime, $fileHash);
							DBAddItemAttribute($itemParent, 'insta_username', $instaUsername, $addedTime, $fileHash);
							DBAddPageTouch('item', $itemParent);
						}
					} # @itemParents
				} else {
					# no parents, ignore
					WriteLog('IndexTextFile: AccessLogHash: Item has no parent, ignoring');

					# DBAddVoteRecord($fileHash, $addedTime, 'hasAccessLogHash');
					# DBAddItemAttribute($fileHash, 'AccessLogHash', $titleGiven, $addedTime);
				}
			} #instagram

			$message = str_replace($reconLine, '[Verified]', $message);
			$detokenedMessage = str_replace($reconLine, '[Verified]', $detokenedMessage);
			# $message = str_replace($reconLine, '[AccessLogHash: ' . $value . ']', $message);
		} # @lines
	}







		#look for #config and #resetconfig #setconfig
		if (GetConfig('admin/token/config') && $message) {
			if (
				IsAdmin($gpgKey) # admin can always config
					||
				GetConfig('admin/anyone_can_config') # anyone can config
					||
				(
					# signed can config
					GetConfig('admin/signed_can_config')
						&&
					$isSigned
				)
					||
				(
					# cookied can config
					GetConfig('admin/cookied_can_config')
						&&
					$hasCookie
				)
			) {
				# preliminary conditions met
				my @configLines = ($message =~ m/(config)(\W)([a-z0-9\/_]+)(\W+?[=]?\W+?)(.+?)$/mg);
				#                                 1       2   3             4             5
				WriteLog('@configLines = ' . scalar(@configLines));

				if (@configLines) {
					#my $lineCount = @configLines / 5;

					while (@configLines) {
						my $configAction = shift @configLines; # 1
						my $space1 = shift @configLines; # 2
						my $configKey = shift @configLines; # 3
						my $space2 = ''; # 4
						my $configValue; # 5

						# allow theme aliasing, currently only one alias: theme to setting/theme
						my $configKeyActual = $configKey;

						$space2 = shift @configLines;
						$configValue = shift @configLines;
						$configValue = trim($configValue);

						if ($configAction && $configKey && $configKeyActual) {
							my $reconLine;
							$reconLine = $configAction . $space1 . $configKey . $space2 . $configValue;
							WriteLog('IndexTextFile: #config: $reconLine = ' . $reconLine);

							if (ConfigKeyValid($configKey) && $reconLine) {
								WriteLog('IndexTextFile: ConfigKeyValid() passed!');
								WriteLog('$reconLine = ' . $reconLine);
								WriteLog('$gpgKey = ' . ($gpgKey ? $gpgKey : '(no)'));
								WriteLog('$isSigned = ' . ($isSigned ? $isSigned : '(no)'));
								WriteLog('$configKey = ' . $configKey);
								WriteLog('signed_can_config = ' . GetConfig('admin/signed_can_config'));
								WriteLog('anyone_can_config = ' . GetConfig('admin/anyone_can_config'));

								my $canConfig = 0;
								if (IsAdmin($gpgKey)) {
									$canConfig = 1;
								}

								if (!$canConfig && substr(lc($configKeyActual), 0, 5) ne 'admin') {
									if (GetConfig('admin/signed_can_config')) {
										if ($isSigned) {
											$canConfig = 1;
										}
									}
									if (GetConfig('admin/cookied_can_config')) {
										if ($hasCookie) {
											$canConfig = 1;
										}
									}
									if (GetConfig('admin/anyone_can_config')) {
										$canConfig = 1;
									}
								}

								if ($canConfig)	{
									# checks passed, we're going to update/reset a config entry
									DBAddVoteRecord($fileHash, $addedTime, 'config');

									$reconLine = quotemeta($reconLine);

									if ($configValue eq 'default') {
										DBAddConfigValue($configKeyActual, $configValue, $addedTime, 1, $fileHash);
										$message =~ s/$reconLine/[Successful config reset: $configKeyActual will be reset to default.]/g;
									}
									else {
										DBAddConfigValue($configKeyActual, $configValue, $addedTime, 0, $fileHash);
										$message =~ s/$reconLine/[Successful config change: $configKeyActual = $configValue]/g;
									}

									$detokenedMessage =~ s/$reconLine//g;

								} # if ($canConfig)
								else {
									$message =~ s/$reconLine/[Attempted change to $configKeyActual ignored. Reason: Not operator.]/g;
									$detokenedMessage =~ s/$reconLine//g;
								}
							} # if (ConfigKeyValid($configKey))
							else {
								#$message =~ s/$reconLine/[Attempted change to $configKey ignored. Reason: Config key has no default.]/g;
								#$detokenedMessage =~ s/$reconLine//g;
							}
						}
					} # while
				}
	}
	} # if (GetConfig('admin/token/config') && $message)







		if (0) {
			my %authorHasTag;
			{
				# look up author's tags

				my @tagsAppliedToAuthor = DBGetAllAppliedTags(DBGetAuthorPublicKeyHash($gpgKey));
				foreach my $tagAppliedToAuthor (@tagsAppliedToAuthor) {
					$authorHasTag{$tagAppliedToAuthor} = 1;
					my $tagsInTagSet = GetTemplate('tagset/' . $tagAppliedToAuthor);
					# if ($tagsInTagSet) {
					# 	foreach my $tagInTagSet (split("\n", $tagsInTagSet)) {
					# 		if ($tagInTagSet) {
					# 			$authorHasTag{$tagInTagSet} = 1;
					# 		}
					# 	}
					# }
				}
			}
			#DBAddItemAttribute($fileHash, 'x_author_tags', join(',', keys %authorHasTag));
		}



sub RemoveOldItems {
	my $query = "
		SELECT * FROM item_flat WHERE file_hash NOT IN (
			SELECT file_hash FROM item_flat
			WHERE
				',' || tags_list || ',' like '%approve%'
					OR
				file_hash IN (
					SELECT item_hash
					FROM item_parent
					WHERE parent_hash IN (
						SELECT file_hash FROM item_flat WHERE ',' || tags_list || ',' LIKE '%approve%'
					)
				)
		)
		ORDER BY add_timestamp
	";
}




===


#sub GetItemTemplate-1 {
#	my %file = %{shift @_}; #todo should be better formatted
#
#	if (
#		defined($file{'file_hash'}) &&
#		defined($file{'item_type'})
#	) {
#		WriteLog('GetItemTemplate: sanity check passed, defined($file{file_path}');
#
#		if ($file{'item_type'} eq 'txt') {
#			my $message = GetItemDetokenedMessage($file{'file_hash'});
#			$message = FormatMessage($message, \%file);
#		}
#
#		my $itemTemplate = '';
#		{
#			my %windowParams;
#			$windowParams{'body'} = GetTemplate('html/item/item.template'); # GetItemTemplate()
#			$windowParams{'title'} = HtmlEscape($file{'item_title'});
#			$windowParams{'guid'} = substr(sha1_hex($file{'file_hash'}), 0, 8);
#
#			$windowParams{'body'} =~ s/\$itemText/$message/;
#
#			{
#				my $statusBar = '';
#
#				$statusBar .= GetItemHtmlLink($file{'file_hash'}, GetTimestampWidget($file{'add_timestamp'}));
#				$statusBar .= '; ';
#
#				$statusBar .= '<span class=advanced>';
#				$statusBar .= substr($file{'file_hash'}, 0, 8);
#				$statusBar .= '; ';
#				$statusBar .= '</span>';
#
#				if ($file{'author_key'}) {
#					$statusBar .= trim(GetAuthorLink($file{'author_key'}));
#					$statusBar .= '; ';
#				}
#
#				WriteLog('GetItemTemplate: ' . $file{'file_hash'} . ': $file{child_count} = ' . $file{'child_count'});
#
#				if ($file{'child_count'}) {
#					$statusBar .= '<a href="' . GetHtmlFilename($file{'file_hash'}) . '#reply">';
#					if ($file{'child_count'}) {
#						$statusBar .= 'reply(' . $file{'child_count'} . ')';
#					} else {
#						$statusBar .= 'reply';
#					}
#					$statusBar .= '</a>; ';
#				}
#
#				$statusBar .= GetItemTagButtons($file{'file_hash'}, 'all');
#				$windowParams{'status'} = $statusBar;
#			}
#
#			$windowParams{'content'} = $message;
#
#			$itemTemplate = GetWindowTemplate2(\%windowParams);
#		}
#		return $itemTemplate;
#
#	} else {
#		WriteLog('GetItemTemplate: sanity check FAILED, defined($file{file_path}');
#		return '';
#	}
#} # GetItemTemplate()
