#!/usr/bin/perl -T

use strict;
use warnings;

sub GetReadPage { # generates page with item listing based on parameters
	# GetReadPage
	#   $pageType, $parameter
	#		author, key/hash
	#		tag, tag name/value
	#		date, date in YYYY-MM-DD format
	#		random, (none)

	# sub MakeAuthorPage {
	# sub GetAuthorPage {
	# sub MakeReadPage {
	# sub PrintReadPage {
	# sub GetTagPage {

	my $title; # plain-text title for <title>
	my $titleHtml; # title which can have html formatting

	my $pageType = shift; # page type parameter
	my $pageParam; # parameter for page type, optionally looked up later

	my @files; # will contain array of hash-refs, one for each file

	my $authorKey; # stores author's key, if page type is author
	# #todo figure out why this is needed here

	my $zipName = '';

	if (defined($pageType)) {
		#$pageType can be 'author', 'tag', 'date'

		if ($pageType eq 'author') {
			# AUTHOR PAGE ##############################################################

			$pageParam = shift;
			$authorKey = $pageParam;

			if (!IsFingerprint($authorKey)) {
				WriteLog('GetReadPage(author) called with invalid parameter');
				return;
			}

			my $whereClause = "WHERE author_key = '$authorKey' AND item_score > 0";

			my $authorAliasHtml = GetAlias($authorKey);
			my $authorAvatarHtml = GetAvatar($authorKey);

			if (IsAdmin($authorKey)) {
				$title = "Admin's Blog (Posts by or for $authorAliasHtml)";
				$titleHtml = "Admin's Blog ($authorAvatarHtml)";
			} else {
				$title = "Posts by or for $authorAliasHtml";
				$titleHtml = "$authorAvatarHtml";
			}

			my %queryParams;
			$queryParams{'where_clause'} = $whereClause;
			$queryParams{'order_clause'} = 'ORDER BY add_timestamp DESC';
			$queryParams{'limit_clause'} = "LIMIT 25"; #todo fix hardcoded limit #todo pagination

			@files = DBGetItemList(\%queryParams); #used below in listing

			if (GetConfig('setting/zip/author')) {
				$zipName = "author/$authorKey.zip";
				#todo move this somewhere else
				if ($zipName) {
					require_once('make_zip.pl');
					my %zipOptions;
					$zipOptions{'where_clause'} = "WHERE author_key = '$authorKey'";
					my @zipFiles = DBGetItemList(\%zipOptions);
					MakeZipFromItemList($zipName, \@zipFiles);
				}
			}
		} # $pageType eq 'author'

		if ($pageType eq 'date') {
			$pageParam = shift;
			my $pageDate = $pageParam;
			chomp($pageDate);

			$title = 'hi';
			$titleHtml = 'hi';

			my %queryParams;

			$queryParams{'where_clause'} = "WHERE file_hash IN (SELECT file_hash FROM item_attribute WHERE attribute = 'date' AND value = '$pageDate')";
			@files = DBGetItemList(\%queryParams);

			$zipName = "$pageDate.zip";
		} # $pageType eq 'date'

		if ($pageType eq 'tag') { #'/top/tag.html' #'/tag/tag.html' '/top/'
			# TAG PAGE ##############################################################
			#todo tell user how many items we found

			$pageParam = shift;
			my $tagName = $pageParam;
			chomp($tagName);

			if ($tagName =~ m/[^a-zA-Z0-9_]/) { #tagName
				WriteLog('GetReadPage: warning: sanity check failed on $tagName');
				return '';
			}

			$title = "$tagName, posts with tag";
			$titleHtml = $title;

			my %queryParams;
			#$queryParams{'join_clause'} = "JOIN vote ON (item_flat.file_hash = vote.file_hash)";
			#$queryParams{'group_by_clause'} = "GROUP BY vote.file_hash";
			#$queryParams{'where_clause'} = "WHERE vote.vote_value = '$tagName'";

			# if (GetConfig('admin/expo_site_mode') && !GetConfig('admin/expo_site_edit')) {
			# 	$queryParams{'where_clause'} = "WHERE ','||tags_list||',' LIKE '%,$tagName,%'";
			# } else {
			# 	my $scoreThreshold = -100;
			# 	if ($tagName eq 'flag' || $tagName eq 'scunthorpe') {
			# 		# the flag page should show almost everything
			# 		# all other pages should have a filter
			# 		$scoreThreshold = -100;
			# 	}
			# 	#$queryParams{'where_clause'} = "WHERE ','||tags_list||',' LIKE '%,$tagName,%' AND item_score > 0";
			# 	#$queryParams{'where_clause'} = "WHERE ','||tags_list||',' LIKE '%,$tagName,%' AND item_score >= 0";
			# 	$queryParams{'where_clause'} = "WHERE ','||tags_list||',' LIKE '%,$tagName,%' AND item_score >= $scoreThreshold";
			# }
			$queryParams{'where_clause'} = "WHERE file_hash IN ( SELECT file_hash FROM vote WHERE vote_value = '$tagName' OR vote_value IN (SELECT tag FROM tag_parent WHERE tag_parent = '$tagName' ))";
			$queryParams{'order_clause'} = "ORDER BY item_score DESC, item_flat.add_timestamp DESC";
			$queryParams{'limit_clause'} = "LIMIT 1000"; #todo fix hardcoded limit #todo pagination

			@files = DBGetItemList(\%queryParams);

			$zipName = "$tagName.zip";
		} # $pageType eq 'tag'
		if ($pageType eq 'random') { #'/random.html'
			# RANDOM  PAGE ##############################################################

			$pageParam = shift;
			my $tagName = $pageParam;

			if (!$tagName) {
				WriteLog('GetReadPage: warning: $tagName is FALSE; caller = ' . join(',', caller));
				return '';
			}

			chomp($tagName);

			$title = 'Random';
			$titleHtml = $title;

			my %queryParams;

			$queryParams{'where_clause'} = "WHERE item_score >= 0";
			$queryParams{'order_clause'} = "ORDER BY RANDOM() DESC";
			$queryParams{'limit_clause'} = "LIMIT 100";

			@files = DBGetItemList(\%queryParams);
		} # $pageType eq 'random'
	} else {
		return; #this code is deprecated
		#		$title = GetConfig('html/home_title') . ' - ' . GetConfig('logo_text');
		#		$titleHtml = GetConfig('html/home_title');
		#
		#		my %queryParams;
		#
		#		@files = DBGetItemList(\%queryParams);
	}

	# GENERATE PAGE ######

	my $txtIndex = ""; # contains html output

	# this will hold the title of the page
	if (!$title) {
		$title = GetConfig('html/home_title');
	}

	chomp $title;
	$title = HtmlEscape($title);

	my $htmlStart = '';

	#$htmlStart .= GetPageHeader('read_' . $pageType);
	$htmlStart = GetPageHeader($title);

	if ($pageType eq 'tag') {
		# fill in tag placeholder at top of page
		# this is where it says, "this page shows all items with tag $tagSelected

		$htmlStart =~ s/\$tagSelected/$pageParam/;
		# $pageParam is the chosen tag for this page
	}

	$txtIndex .= $htmlStart;

	#todo
	#<span class="replies">last reply at [unixtime]</span>
	#javascript foreach span class=replies { get time after "last reply at" and compare to "last visited" cookie

	my $needUploadJs = 0;
	if ($pageType eq 'tag') {
		# add tag buttons with selected tag emphasized
		$txtIndex .= GetTagPageHeaderLinks($pageParam);

		my $tagInfo = GetString('tag_info/' . $pageParam);
		if ($tagInfo && ($tagInfo ne $pageParam)) {
			# don't show tag info if it matches page param
			# as that provides no additional useful information
			$txtIndex .= GetWindowTemplate($tagInfo, 'Tag Information');
		}
		if ($pageParam eq 'image') { # GetReadPage()
			#$txtIndex .= GetUploadDialog();

			if (GetConfig('admin/js/enable')) {
				$txtIndex .= GetWindowTemplate('<a href=# onclick="if (window.UnmaskBlurredImages) { UnmaskBlurredImages() }">Show Masked Images</a>', 'One Lonesome Link');
			}

			$needUploadJs = 1;
		}
	}

	$txtIndex .= GetTemplate('html/maincontent.template');
	if ($pageType eq 'author') {
		# author info box
		$txtIndex .= GetAuthorInfoBox($authorKey);

		my $queryAuthorThreads = SqliteGetQueryTemplate('author_threads');
		$queryAuthorThreads =~ s/\?/'$authorKey'/;
		my %queryFlags;
		$queryFlags{'no_no_results'} = 1;
		$txtIndex .= GetQueryAsDialog(
			$queryAuthorThreads,
			'Topics by Author',
			'',
			\%queryFlags
		);

		$txtIndex .= GetQueryAsDialog(
			"
				select
					item_title, add_timestamp, file_hash, item_score, author_score
					from item_flat
					LEFT JOIN author_score ON (item_flat.author_key = author_score.author_key)
					where item_flat.author_key = '$authorKey'
			",
			'Items by Author'
		);

		{
			#todo templatize and improve
			#liked by author and flagged by author

			my %queryFlags;
			$queryFlags{'no_no_results'} = 1;

			if (!IsFingerprint($authorKey)) {
				#something is wrong
				WriteLog('GetReadPage: warning: ...'); #todo
			} else {
				#todo templatize this
				my $query = "
					SELECT
						item_flat.file_hash AS file_hash,
						item_flat.item_title AS item_title
					FROM
						item_flat,
						(
							SELECT
								file_hash,
								ballot_time
							FROM
								vote
							WHERE
								vote.author_key = '$authorKey'
								AND vote_value = 'like'
						) AS like
					WHERE
						item_flat.file_hash = like.file_hash
						AND item_flat.author_key != '$authorKey'
					;
				";
				$txtIndex .= GetQueryAsDialog($query
					,
					'Posts Liked By Author',
					'',
					\%queryFlags
				);
			}

			if (!IsFingerprint($authorKey)) {
				#something is wrong
				WriteLog('GetReadPage: warning: ...'); #todo
			} else {
				my $query = "select file_hash, item_title from
						item_flat where file_hash in (select file_hash from vote where vote.author_key = '$authorKey' AND vote = 'flag');";
				$txtIndex .= GetQueryAsDialog($query
					,
					'Posts Flagged By Author',
					'',
					\%queryFlags
				);
			}
		}


		if (GetConfig('setting/zip/author')) {
			my $zipLink = '<a href="/author/' . $authorKey . '.zip">' . $authorKey . '.zip</a>';
			$txtIndex .= GetWindowTemplate($zipLink, 'Archive');
		}

		$txtIndex .= '<hr 5>';
	}

	my $itemComma = '';

	if (scalar(@files) > 0) {
		$txtIndex .= GetWindowTemplate('Items on page: ' . scalar(@files), 'Count');
	}
	WriteLog('GetReadPage: scalar(@files) = ' . scalar(@files));

	# LISTING ITEMS BEGINS HERE

	foreach my $row (@files) {
		my $file = $row->{'file_path'};

		if ($pageType eq 'tag' && $pageParam) {
			$row->{'vote_return_to'} = '/top/' . $pageParam . '.html'; #todo unhardcode
		}

		WriteLog('GetReadPage: calling DBAddItemPage (1)'); #GetReadPage()
		DBAddItemPage($row->{'file_hash'}, $pageType, $pageParam);

		if ($file && -e $file) {
			my $itemHash = $row->{'file_hash'};
			my $gpgKey = $row->{'author_key'};
			my $isSigned;
			if ($gpgKey) {
				$isSigned = 1;
			} else {
				$isSigned = 0;
			}

			my $alias;
			my $isAdmin = 0;
			my $message;
			my $messageCacheName = GetMessageCacheName($itemHash);

			WriteLog('GetReadPage: $row->{file_hash} = ' . $row->{'file_hash'});
			if ($gpgKey) {
				WriteLog('GetReadPage: $message = GetFile('.$messageCacheName.')');
				$message = GetFile($messageCacheName);
			} else {
				WriteLog('GetReadPage: $message = GetFile('.$file.')');
				$message = GetFile($file);
			}
			if (!$message) {
				WriteLog('GetReadPage: warning: $message is false!');
			} else {
				WriteLog('GetReadPage: $message is true!');
			}

			#$message = FormatForWeb($message);
			my $signedCss = "";
			if ($isSigned) {
				if (IsAdmin($gpgKey)) {
					$isAdmin = 1;
				}
				if ($isAdmin) {
					$signedCss = "signed admin";
				} else {
					$signedCss = "signed";
				}
			} # $isSigned

			#todo $alias = GetAlias($gpgKey);

			$alias = HtmlEscape($alias);

			my $itemTemplate = '';
			if ($message) {
#				$row->{'show_quick_vote'} = 1;
				$row->{'trim_long_text'} = 1;

				WriteLog('GetReadPage: GetItemTemplate($row)');

				$itemTemplate = GetItemTemplate($row); # GetReadPage() $message
			}
			else {
				$itemTemplate = GetItemTemplate($row); # GetReadPage() missing $message
				WriteLog('GetReadPage: warning: missing $message');
			}

			if ($itemComma eq '') {
				#$itemComma = '<br><hr size=7>';
				$itemComma = ' ';
			} else {
				$itemTemplate = $itemComma . $itemTemplate;
			}

			$txtIndex .= $itemTemplate;
		} # $file
		else {
			WriteLog('GetReadPage: warning: file not found, $file = ' . $file);
		}
	}

	# LISTING ITEMS ENDS HERE

	if ($pageType eq 'tag' && $pageParam eq 'image') { # GetReadPage()
		require_once('page/upload.pl');
		$txtIndex .= GetUploadDialog();
	}

	# Close html
	$txtIndex .= GetPageFooter('read_' . $pageType);

	my @jsToInject = qw(settings timestamp voting utils profile);
	if ($pageType eq 'author') {
		push @jsToInject, 'itsyou';
	}
	if (GetConfig('setting/admin/js/fresh')) {
		push @jsToInject, 'fresh';
	}
	if (GetConfig('setting/html/reply_cart')) {
		push @jsToInject, 'reply_cart';
	}
	if ($needUploadJs) {
		push @jsToInject, 'upload';
	}
	$txtIndex = InjectJs($txtIndex, @jsToInject);

	$txtIndex .= '<!-- GetReadPage() -->';

	return $txtIndex;
} # GetReadPage()

1;