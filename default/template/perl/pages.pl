#!/usr/bin/perl -T
#freebsd: #!/usr/local/bin/perl -T

# pages.pl
# to do with html page generation

use strict;
use warnings;
use utf8;
use URI::Escape qw(uri_escape);
use 5.010;

my @foundArgs;
while (my $argFound = shift) {
	push @foundArgs, $argFound;
}

use lib qw(lib);
use Digest::MD5 qw(md5_hex);
use POSIX qw(strftime ceil);
use Data::Dumper;
use File::Copy;
use Cwd qw(cwd);

require './utils.pl';
require_once('sqlite.pl');
require_once('makepage.pl');
#require_once('compare_page.pl');

sub GetDialogPage { # $pageName, $pageTitle, $windowContents ; returns html page with dialog
# this is for getting one page with one dialog, not a /dialog/... page
	my $pageName = shift; # page name: 404
	my $pageTitle = shift; # page title (
	my $windowContents = shift;

	my @allowedPages = qw(401 404);
	if (!in_array($pageName, @allowedPages)) {
		WriteLog('GetDialogPage: warning: $pageName not in @allowedPages; caller = ' . join(',', caller));
		return '';
	}

	if ($pageName) {
		if ($pageName eq '404') { #/404.html
			$windowContents = GetTemplate('html/404.template');

			if (GetConfig('admin/expo_site_mode')) {
				$windowContents = str_replace(
					'<span id=mittens></span>',
					'',
					$windowContents
				)
			} else {
				$windowContents = str_replace(
					'<span id=mittens></span>',
					'<span id=mittens>' . GetTemplate('html/form/mittens.template') . '</span>',
					$windowContents
				)
			}

			my $lookingFor = 'test';
			my @lookingForList = split("\n", GetTemplate('list/looking_for')); #todo make safer
			if (@lookingForList) {
				$lookingFor = $lookingForList[rand scalar(@lookingForList)];
			}

			$windowContents =~ s/looking for mittens/looking for $lookingFor/;

			my $pageTemplate;
			$pageTemplate = '';

			$pageTemplate .= GetPageHeader('404'); #GetTemplate('html/htmlstart.template');
			$pageTemplate .= GetTemplate('html/maincontent.template');
			$pageTemplate .= GetWindowTemplate($windowContents, $pageTitle);
			#: $windowTitle, $windowMenubar, $columnHeadings, $windowBody, $windowStatus
			$pageTemplate .= GetPageFooter('404');

			# settings.js provides ui consistency with other pages
			$pageTemplate = InjectJs($pageTemplate, qw(settings profile));

			return $pageTemplate;
		}
		if ($pageName eq '401') { #/401.html
			my $message = GetConfig('admin/http_auth/message_401');
			$message =~ s/\n/<br>/g;

			$windowContents = GetTemplate('html/401.template');
			$windowContents = str_replace('<p id=message></p>', '<p id=message>' . $message . '</p>', $windowContents);

			my $pageTemplate;
			$pageTemplate = '';

			$pageTemplate .= GetPageHeader('401'); #GetTemplate('html/htmlstart.template');
			$pageTemplate .= GetTemplate('html/maincontent.template');
			$pageTemplate .= GetWindowTemplate($windowContents, $pageTitle);
			$pageTemplate .= GetPageFooter('401');

			return $pageTemplate;
		}
		if ($pageName eq 'ok') {
		}
	}
} # GetDialogPage()

sub RenderLink {
	my $url = shift;
	my $title = shift;

	WriteLog('RenderLink: $url = ' . $url . '; $title = ' . $title);

	my $link = '<a></a>';
	$link = str_replace('<a></a>', '<a>' . $title . '</a>', $link);
	$link = AddAttributeToTag($link, 'a', 'href', $url);

	if (GetConfig('admin/js/enable') && GetConfig('admin/js/dragging')) {
		if ($url =~ m/\/top\//) {
			$link = AddAttributeToTag($link, 'a ', 'onclick', "if (window.GetPrefs && GetPrefs('draggable_spawn') && window.FetchDialogFromUrl) { return FetchDialogFromUrl('/dialog" . $url . "'); }");
		}
	}

	return $link;
} # RenderLink()

require_once('render_field.pl');

sub GetQueryAsDialog { # $query, $title, $columns, \%param
# runs specified query and returns it as a dialog using GetResultSetAsDialog()
# this has some special conditions for GetAttributesDialog()
#todo this should report query error

# sub GetQueryDialog {
	my $query = shift;
	my $title = shift;
	my $columns = shift; # optional, default is to use all the columns from the query

	my $paramHashRef = shift;
	my %flags;
	if ($paramHashRef) {
		%flags = %{$paramHashRef};
	}

	if (!$query) {
		WriteLog('GetQueryAsDialog: warning: $query is FALSE; caller = ' . join(',', caller));
		return '';
	}
	if (!$title) {
		WriteLog('GetQueryAsDialog: warning: $title is FALSE; caller = ' . join(',', caller));
		$title = 'Untitled';
	}

	# 	$query = SqliteGetQueryTemplate("$query");

	$flags{'query'} = $query;

	my @result  = SqliteQueryHashRef($query);

	#WriteLog('GetQueryAsDialog: $query = ' . $query . '; calling GetResultSetAsDialog()');
	#commented because it prints a lot

	if (scalar(@result) < 2 && $flags{'no_empty'}) {
		return '';
	} else {
		return GetResultSetAsDialog(\@result, $title, $columns, \%flags);
	}
} # GetQueryAsDialog()

sub LightenColor { # $color ; returns a lightened version of a color
	my $color = shift;
	my @rgb;

	WriteLog('LightenColor: before: $color = ' . $color);

	my $hashPrefix = '';
	if (substr($color, 0, 1) eq '#') {
		$hashPrefix = '#';
		$color = substr($color, 1);
	}

	if ($color =~ m/^([a-fA-F0-9]{6})$/) {
		$color = $1;
		WriteLog('LightenColor: sanity check passed: $color = ' . $color);
	} else {
		WriteLog('LightenColor: warning: sanity check FAILED');
		return '';
	}

	$rgb[0] = hex(substr($color, 0, 2));
	$rgb[1] = hex(substr($color, 2, 2));
	$rgb[2] = hex(substr($color, 4, 2));

	while ($rgb[0] < 128 || $rgb[1] < 228 || $rgb[2] < 228) {
		$rgb[0] = $rgb[0] + 1;
		$rgb[1] = $rgb[1] + 1;
		$rgb[2] = $rgb[2] + 1;

		$color = sprintf("%X", $rgb[0]) . sprintf("%X", $rgb[1]) . sprintf("%X", $rgb[2]);
		WriteLog('LightenColor: after: $color = ' . $color);

	}

	if ($rgb[0] > 255) {
		$rgb[0] = 255;
	}

	if ($rgb[1] > 255) {
		$rgb[1] = 255;
	}

	if ($rgb[2] > 255) {
		$rgb[2] = 255;
	}

	$color = sprintf("%X", $rgb[0]) . sprintf("%X", $rgb[1]) . sprintf("%X", $rgb[2]);
	$color = $hashPrefix . $color;
	WriteLog('LightenColor: after: $color = ' . $color);

	return $color;
} # LightenColor()

require_once('resultset_as_dialog.pl');

sub GetStylesheet { # $styleSheet ; returns stylesheet template based on config
# sub GetCss {
	state $styleSheet;
	if ($styleSheet) {
		return $styleSheet;
	}

	my $style = GetTemplate('css/default.css');
	# baseline style

	if (GetConfig('html/avatar_icons')) {
		$style .= "\n" . GetTemplate('css/avatar.css');
		# add style for color avatars if that's the setting
	}

	if (GetConfig('admin/js/dragging') || GetConfig('html/css_inline_block')) {
		$style .= "\n" . GetTemplate('css/dragging.css');
	}

	if (GetConfig('html/css_shimmer')) {
		$style .= "\n" . GetTemplate('css/shimmer.css');
	}

	if (GetThemeAttribute('additional.css')) {
		$style .= "\n" . GetThemeAttribute('additional.css');
	}

	$styleSheet = $style;

	return $styleSheet;
} # GetStylesheet()

require_once('widget/author_link.pl');

sub GetPageLink { # returns one pagination link as html, used by GetPageLinks
	my $pageNumber = shift;
	my $itemCount = shift;

	my $pageLimit = GetConfig('html/page_limit');
	if (!$pageLimit) {
		#fallback
		WriteLog('GetPageLink: warning: $pageLimit was FALSE, setting to sane 25');
		$pageLimit = 25;
	}

	my $pageStart = $pageNumber * $pageLimit;
	my $pageEnd = $pageNumber * $pageLimit + $pageLimit;
	if ($pageEnd > $itemCount) {
		$pageEnd = $itemCount - 1;
	}
	my $pageCaption = $pageStart . '-' . $pageEnd;

	state $pageLinkTemplate;
	if (!defined($pageLinkTemplate)) {
		$pageLinkTemplate = GetTemplate('html/widget/pagelink.template');
	}

	my $pageLink = $pageLinkTemplate;
	$pageLink =~ s/\$pageName/$pageCaption/;

	$pageLink =~ s/\$pageNumber/$pageNumber/;

	return $pageLink;
} # GetPageLink()

require_once('get_window_template.pl');

sub GetPageLinks { # $currentPageNumber ; returns html for pagination links with frame/window
	my $currentPageNumber = shift; #

	state $pageLinks; # stores generated links html in case we need them again

	my $pageLimit = GetConfig('html/page_limit'); # number of items per page

	if (!$pageLimit) {
		WriteLog('GetPageLink: warning: $pageLimit was FALSE, setting to sane 25');
		$pageLimit = 25;
	}

	my $itemCount = DBGetItemCount(); # item count

	if (!$itemCount) {
		WriteLog('GetPageLink: warning: $itemCount was FALSE, sanity check failed');
		return '';
	}

	WriteLog("GetPageLinks($currentPageNumber)");

	# check if we've generated the html already, if so, use it
	if (defined($pageLinks)) {
		WriteLog("GetPageLinks: \$pageLinks already exists, doing search and replace");

		my $currentPageTemplate = GetPageLink($currentPageNumber, $itemCount);

		my $currentPageStart = $currentPageNumber * $pageLimit;
		my $currentPageEnd = $currentPageNumber * $pageLimit + $pageLimit;
		if ($currentPageEnd > $itemCount) {
			$currentPageEnd = $itemCount - 1;
		}

		my $currentPageCaption = $currentPageStart . '-' . $currentPageEnd;

		my $pageLinksReturn = $pageLinks; # make a copy of $pageLinks which we'll modify

		$pageLinksReturn =~ s/$currentPageTemplate/<b>$currentPageCaption<\/b> /g;
		# replace current page link with highlighted one

		return $pageLinksReturn;
	} else {

		# we've ended up here because we haven't generated $pageLinks yet

		WriteLog("GetPageLinks: \$itemCount = $itemCount");

		$pageLinks = "";

		my $lastPageNum = ceil($itemCount / $pageLimit);

		#	my $beginExpando;
		#	my $endExpando;
		#
		#	if ($lastPageNum > 15) {
		#		if ($currentPageNumber < 5) {
		#			$beginExpando = 0;
		#		} elsif ($currentPageNumber < $lastPageNum - 5) {
		#			$beginExpando = $currentPageNumber - 2;
		#		} else {
		#			$beginExpando = $lastPageNum - 5;
		#		}
		#
		#		if ($currentPageNumber < $lastPageNum - 5) {
		#			$endExpando = $lastPageNum - 2;
		#		} else {
		#			$endExpando = $currentPageNumber;
		#		}
		#	}

		if ($itemCount > $pageLimit) {
			#		for (my $i = $lastPageNum - 1; $i >= 0; $i--) {
			for (my $i = 0; $i < $lastPageNum; $i++) {
				my $pageLinkTemplate;
				#			if ($i == $currentPageNumber) {
				#				$pageLinkTemplate = "<b>" . $i . "</b>";
				#			} else {
				$pageLinkTemplate = GetPageLink($i, $itemCount);
				#			}

				$pageLinks .= $pageLinkTemplate;
			}
		}

		my $frame = GetTemplate('html/pagination.template');

		$frame =~ s/\$paginationLinks/$pageLinks/;

		$pageLinks = $frame;

		# up to this point, we are building the in-memory template for the pagination links
		# once it is stored in $pageLinks, which is a static ("state") variable,
		# GetPageLinks() returns at the top, and does not reach here.
		return GetPageLinks($currentPageNumber);
	}
} # GetPageLinks()

sub GetTagPageHeaderLinks { # $tagSelected ; returns html-formatted links to existing tags in system
# used for the header at the top of tag listings pages
# 'tag_wrapper.template', 'tag.template'

	my $tagSelected = shift;

	if (!$tagSelected) {
		$tagSelected = '';
	} else {
		chomp $tagSelected;
	}

	my $minimumTagCount = 5; # don't display if fewer than this, unless it is selected

	WriteLog("GetTagPageHeaderLinks($tagSelected)");

	my @voteCountsArray = DBGetVoteCounts();

	my $voteItemsWrapper = GetTemplate('html/tag_wrapper.template');

	my $voteItems = '';

	my $voteItemTemplateTemplate = GetTemplate('html/tag.template');

	shift @voteCountsArray;

	while (@voteCountsArray) {
		my $voteItemTemplate = $voteItemTemplateTemplate;

		my $tagHashRef = shift @voteCountsArray;
		my %tagHash = %{$tagHashRef};

		my $tagName = $tagHash{'vote_value'};
		my $tagCount = $tagHash{'vote_count'};

		if ($tagCount > $minimumTagCount || $tagName eq $tagSelected) {
			my $voteItemLink = "/top/" . $tagName . ".html";

			if ($tagName eq $tagSelected) {
				#todo template this
				$voteItems .= "<b>#$tagName</b>\n";
			}
			else {
				$voteItemTemplate =~ s/\$link/$voteItemLink/g;
				$voteItemTemplate =~ s/\$tagName/$tagName/g;
				$voteItemTemplate =~ s/\$tagCount/$tagCount/g;

				if (0 && GetConfig('admin/js/enable') && GetConfig('admin/js/dragging')) {
					#todo improve this (e.g. don't hard-code the url)
					$voteItemTemplate = AddAttributeToTag(
						$voteItemTemplate,
						'a ',
						'onclick',
						"if (window.GetPrefs && GetPrefs('draggable_spawn') && window.FetchDialogFromUrl) { return FetchDialogFromUrl('/dialog" . $voteItemLink . "'); }"
					);
				}

				$voteItems .= $voteItemTemplate;
			}
		}
	}

	if (!$voteItems) {
		# $voteItems = GetTemplate('html/tag_listing_empty.template');
	}

	$voteItemsWrapper =~ s/\$tagLinks/$voteItems/g;

	return $voteItemsWrapper;
} # GetTagPageHeaderLinks()

sub GetQueryPage { # $pageName, $title, $columns ;
# sub GetQueryAsPage {
	my $pageName = shift;
	my $title = shift;
	my $columns = shift;

	if (!$columns) {
		$columns = '';
	}

	WriteLog('GetQueryPage: $pageName = ' . $pageName . '; $title = ' . ($title ? $title : 'FALSE') . '; $columns = ' . $columns);

	if (!$title) {
		$title = ucfirst($pageName);
	}
	if (!$columns) {
		$columns = '';
	}

	#todo sanity

	my $html = '';
	my $query = SqliteGetQueryTemplate($pageName);

	my @result = SqliteQueryHashRef($query);

	if (@result) {
		$html .= GetPageHeader($pageName);
		$html .= GetTemplate('html/maincontent.template');

		###
		$html .= GetResultSetAsDialog(\@result, $title, $columns);
		###
#
#        my @queryChoices;
#        push @queryChoices, 'read';
#        push @queryChoices, 'compost';
#        push @queryChoices, 'chain';

#
#		$html .= '<span class=advanced><form action=/post.html>'; #todo templatify
#		$html .= GetWindowTemplate($queryWindowContents, 'View Selector');
#		$html .= '</form></span>';

		my $queryWindowContents;

		$queryWindowContents .= '<pre>'.HtmlEscape($query).'<br></pre>'; #todo templatify

		if (0) {
			#todo
			my @queryChoices = split("\n", `ls config/template/query`); #todo sanity
			my $querySelectorWidget = GetWidgetSelect('query', $pageName, @queryChoices);
			my $button = '<input type=submit value=Go>';
			$queryWindowContents .= '<label for=query>' . $querySelectorWidget . '</label> ' . $button; #todo templatify
		}

		#$html .= GetReplyCartDialog(); # GetQueryPage()

		$html .= '<span class=advanced><form action=/post.html>'; #todo templatify
		$html .= GetWindowTemplate($queryWindowContents, $pageName . '.sql', '', scalar(split("\n", $query)) . ' lines; ' . length($query) . ' bytes');
		$html .= '</form></span>';

		$html .= GetPageFooter($pageName);
		if (GetConfig('admin/js/enable')) {
			$html = InjectJs($html, qw(settings utils timestamp voting avatar));
			#todo only add timestamp if necessary?
		}
		return $html;
	} else {
#		$html .= GetPageHeader($pageName);
#		$html .= GetWindow('No results, please check index');
#		$html .= GetPageFooter($pageName);
		#todo
	}
} # GetQueryPage()

require_once('item_page.pl');

sub GetItemHtmlLink { # $hash, [link caption], [#anchor] ; returns <a href=...
# sub GetItemLink {
# sub GetLink {
	my $hash = shift;

	if ($hash = IsItem($hash)) {
		#ok
	} else {
		WriteLog('GetItemHtmlLink: warning: sanity check failed on $hash');
		return '';
	}

	if ($hash) {
		#todo templatize this
		my $linkCaption = shift;
		if (!$linkCaption) {
			$linkCaption = substr($hash, 0, 8) . '..';
		}

		my $shortHash = substr($hash, 0, 8);

		my $hashAnchor = shift;
		if ($hashAnchor) {
			if (substr($hashAnchor, 0, 1) ne '#') {
				$hashAnchor = '#' . $hashAnchor;
			}
		} else {
			$hashAnchor = '';
		}

		$linkCaption = HtmlEscape($linkCaption);

		my $htmlFilename = GetHtmlFilename($hash);
		my $linkPath = $htmlFilename;
		if (GetConfig('admin/php/enable') && GetConfig('admin/php/url_alias_friendly')) {
			$linkPath = substr($hash, 0, 8);
		}

		my $itemLink = '';

		if (
			GetConfig('html/overline_links_with_missing_html_files') &&
			! -e GetDir('html') . '/' . $htmlFilename
		) {
			# html file does't exist, annotate link to indicate this
			# the html file may be generated as needed
			$itemLink = '<a href="/' . $linkPath . $hashAnchor . '" style="text-decoration: overline">' . $linkCaption . '</a>';
		} else {
			# html file exists, nice
			$itemLink = '<a href="/' . $linkPath . $hashAnchor . '">' . $linkCaption . '</a>';
		}

		if (GetConfig('admin/js/enable') && GetConfig('admin/js/dragging')) {
			#$itemLink = AddAttributeToTag($itemLink, 'a ', 'onclick', '');
			$itemLink = AddAttributeToTag(
				$itemLink,
				'a ',
				'onclick',
				"
					if (
						(!window.GetPrefs || GetPrefs('draggable_spawn')) &&
						window.FetchDialogFromUrl &&
						document.getElementById
					) {
						if (document.getElementById('$shortHash')) {
							SetActiveDialog(document.getElementById('$shortHash'));
							return false;
						} else {
							return FetchDialogFromUrl('/dialog/$htmlFilename');
						}
					}
				"
			);
		}

		return $itemLink;
	} else {
		WriteLog('GetItemHtmlLink: warning: no $hash after first sanity check!');
		return '';
	}
} # GetItemHtmlLink()

sub GetItemTagsSummary { # returns html with list of tags applied to item, and their counts
	my $fileHash = shift;

	if (!IsItem($fileHash)) {
		WriteLog('GetItemTagsSummary: warning: sanity check failed');
		return '';
	}

	WriteLog("GetItemTagsSummary($fileHash)");
	my $voteTotalsRef = DBGetItemVoteTotals2($fileHash);
	my %voteTotals = %{$voteTotalsRef};

	my $votesSummary = '';

	foreach my $voteTag (keys %voteTotals) {
		$votesSummary .= "$voteTag (" . $voteTotals{$voteTag} . ")\n";
	}
	if ($votesSummary) {
		$votesSummary = $votesSummary;
	}

	return $votesSummary;
} # GetItemTagsSummary()

sub GetQuickVoteButtonGroup {
	my $fileHash = shift;
	my $returnTo = shift;

	my $quickVotesButtons = '';
	if ($returnTo) {
		WriteLog('GetQuickVoteButtonGroup: $returnTo = ' . $returnTo);
		$quickVotesButtons = GetItemTagButtons($fileHash, $returnTo); #todo refactor to take vote totals directly
	} else {
		$quickVotesButtons = GetItemTagButtons($fileHash); #todo refactor to take vote totals directly
	}

	my $quickVoteButtonGroup = GetTemplate('vote/votequick2.template');
	$quickVoteButtonGroup =~ s/\$quickVotesButtons/$quickVotesButtons/g;

	return $quickVoteButtonGroup;
} # GetQuickVoteButtonGroup()

require_once('format_message.pl');

sub GetImageContainer { # $fileHash, $imageAlt, $boolLinkToItemPage = 1
	my $fileHash = shift;
	my $imageAlt = shift;
	my $boolLinkToItemPage = shift;

	if (!defined($boolLinkToItemPage)) {
		$boolLinkToItemPage = 1;
	}

	#todo sanity

	#$fileHash = SqliteGetValue("SELECT file_hash FROM item_flat WHERE file_hash LIKE '$fileHash%'");
	#todo this is a hack

	WriteLog('GetImageContainer: $fileHash = ' . $fileHash);

	my $permalinkHtml = '';
	if (!$permalinkHtml) {
		$permalinkHtml = '/' . GetHtmlFilename($fileHash);
	}

	my $imageContainer = '';
	if ($boolLinkToItemPage) {
		$imageContainer = GetTemplate('html/item/container/image_with_link.template');
	} else {
		$imageContainer = GetTemplate('html/item/container/image_with_link.template');
		#$imageContainer = GetTemplate('html/item/container/image.template');
	}

	my $imageUrl = "/thumb/thumb_800_$fileHash.gif"; #todo hardcoding no
	# my $imageUrl = "/thumb/thumb_420_$fileHash.gif"; #todo hardcoding no
	my $imageSmallUrl = "/thumb/thumb_42_$fileHash.gif"; #todo hardcoding no
	#my $imageAlt = $itemTitle;

	WriteLog('GetImageContainer: $fileHash = ' . $fileHash . '; $imageAlt = ' . $imageAlt . '; $permalinkHtml = ' . $permalinkHtml);

	$imageContainer =~ s/\$imageUrl/$imageUrl/g;
	$imageContainer =~ s/\$imageSmallUrl/$imageSmallUrl/g;
	$imageContainer =~ s/\$imageAlt/$imageAlt/g;
	if ($boolLinkToItemPage) {
		$imageContainer =~ s/\$permalinkHtml/$permalinkHtml/g;
	}

	WriteLog('GetImageContainer: returning, length($imageContainer) = ' . length($imageContainer));

	return $imageContainer;
} # GetImageContainer()

sub GetTagsListAsHtmlWithLinks { # $tagsListParam ; prints up to 7 tags
	my $tagsListParam = shift;

	if (!$tagsListParam) {
		WriteLog('GetItemTemplate: warning: $tagsListParam is missing. caller: ' . join(',', caller));
		return '';
	}
	my @tagsList = split(',', $tagsListParam);

	my $headings;
	my $comma = '';

	my $safeLimit = 15; # don't print more than this many tags #hardcoded #todo

	foreach my $tag (@tagsList) {
		if (!$tag) {
			# sometimes $tagsListParam begins with a comma
			next;
		}

		if (!--$safeLimit) {
			# check if we've printed more than $safeLimit tags
			$headings .= '[...]';
			last;
		}

		$headings .= $comma;
		$comma = '; ';

		my $tagLink = GetTagLink($tag);

		#$headings .= 'tag='.$tag;
		$headings .= $tagLink;
	}

	return $headings;
} # GetTagsListAsHtmlWithLinks()

require_once('widget/tag_link.pl');

require_once('item_template.pl');

sub GetPageFooter { # $pageType ; returns html for page footer
# sub GetFooter {
	WriteLog('GetPageFooter()');

	my $pageType = shift;
	if (!$pageType) {
		$pageType = '';
	}

	if (
		!$pageType ||
		(index($pageType, ' ') != -1)
	) {
		WriteLog('GetPageFooter: warning: $pageType failed sanity check; caller = ' . join(',', caller));
	}

	my $txtFooter = GetTemplate('html/htmlend.template');

	#my $disclaimer = GetString('disclaimer');
	#$txtFooter =~ s/\$disclaimer/$disclaimer/g;

	$txtFooter = FillThemeColors($txtFooter);

	if (GetConfig('admin/js/enable') && GetConfig('admin/js/loading')) { #finished loading
		$txtFooter = InjectJs2($txtFooter, 'after', '</html>', qw(loading_end));

		# # #templatize #loading
		#this would hide all dialogs until they are ready to be shown
		#it is a major impediment for many browsers, and should not be enabled willy-nilly
		#it's challenging to show the dialogs reliably, especially with the !important bit
		#todo how to override this style and remove it? remove node?
		#the reason for trying this is trying to avoid windows changing position after page load
		# # #
		#$txtFooter .= "<style><!-- .dialog { display: table !important; } --></style>";
		# # #
	}

	if (GetConfig('html/back_to_top_button')) {
		# add back to top button to the bottom of the page, right before </body>
		my $backToTopTemplate = GetTemplate('html/widget/back_to_top_button.template');
		$backToTopTemplate = FillThemeColors($backToTopTemplate);
		$txtFooter =~ s/\<\/body>/$backToTopTemplate<\/body>/i;

		$txtFooter = InjectJs2($txtFooter, 'after', '</html>', qw(back_to_top_button));
	}

	if (GetConfig('setting/html/reset_button')) {
		my $resetButton = GetTemplate('html/widget/reset_button.template');
		$resetButton = FillThemeColors($resetButton);
		$txtFooter =~ s/\<\/body>/$resetButton<\/body>/i;
	}

	if (GetConfig('admin/ssi/enable') && GetConfig('admin/ssi/footer_stats')) {
		#footer stats inserted by ssi
		WriteLog('GetPageFooter: ssi footer conditions met!');
		# footer stats
		$txtFooter = str_replace(
			'</body>',
			GetTemplate('stats_footer_ssi.template') . '</body>',
			$txtFooter
		);
	} # ssi footer stats
	else {
		WriteLog('GetPageFooter: ssi footer conditions NOT met!');
	}

	if (
		GetConfig('html/menu_bottom') ||
		(
			GetConfig('html/menu_top') &&
			($pageType eq 'item')
			# for item pages, we still put the menu at the bottom, because the item's content
			# is the most important part of the page.
			# #todo this is confusing the way it's written right now, improve on it somehow
		)
	) {
		require_once('widget/menu.pl');
		my $menuBottom = GetMenuTemplate($pageType); # GetPageFooter()

		# if (GetConfig('admin/js/enable') && GetConfig('admin/js/dragging') && GetConfig('admin/js/controls_footer')) {
		# 	my $dialogControls = GetTemplate('html/widget/dialog_controls.template'); # GetPageFooter()
		# 	$dialogControls = GetWindowTemplate($dialogControls, 'Controls'); # GetPageFooter()
		# 	#$dialogControls = '<span class=advanced>' . $dialogControls . '</span>';
		# 	$menuBottom .= $dialogControls;
		# }

		require_once('widget/menu.pl');
		$txtFooter = str_replace(
			'</body>',
			'<br>' . $menuBottom . '</body>',
			$txtFooter
		);
	}

	if (GetConfig('setting/admin/js/enable')) {
		my $noJsInfo = GetWindowTemplate('<noscript>* Some features may require JavaScript</noscript>', 'Notice'); # GetDialog()
		$noJsInfo = '<noscript class=beginner>' . $noJsInfo . '</noscript>';
		$txtFooter = str_replace(
			'</body>',
			'<br>' . $noJsInfo . '</body>',
			$txtFooter
		);
	}

	if (GetConfig('html/recent_items_footer')) {
		require_once('widget/recent_items.pl');
		$txtFooter = GetRecentItemsDialog() . $txtFooter;
	}

	# if (GetConfig('admin/js/enable') && GetConfig('admin/js/dragging') && GetConfig('admin/js/controls_footer')) {
	# 	my $dialogControls = GetTemplate('html/widget/dialog_controls.template'); # GetPageFooter()
	# 	$dialogControls = GetWindowTemplate($dialogControls, 'Controls');
	# 	#$dialogControls = '<span class=advanced>' . $dialogControls . '</span>';
	# 	$txtFooter = str_replace(
	# 		'</body>',
	# 		'<br>' . $dialogControls . '</body>',
	# 		$txtFooter
	# 	);
	# }

	return $txtFooter;
} # GetPageFooter()

sub GetThemeColor { # returns theme color based on setting/theme
	my $colorName = shift;
	chomp $colorName;

	if ($colorName eq 'link' || $colorName eq 'vlink') {
		$colorName .= '_text';
	}

	if (GetConfig('html/mourn')) { # GetThemeColor()
		if (index(lc($colorName), 'text') != -1 || index(lc($colorName), 'link') != -1) {
			if (index(lc($colorName), 'back') != -1) {
				return '#000000';
			} else {
				return '#a0a0a0';
			}
		} else {
			return '#000000';
		}
	}

	$colorName = 'color/' . $colorName;
	my $color = GetThemeAttribute($colorName);

	if (!defined($color) || $color eq '') {
		if (GetConfig('html/mourn')) { # GetThemeColor()
			$color = '#000000';
		} else {
			$color = '#00ff00';
		}
		WriteLog('GetThemeColor: warning: value not found, $colorName = ' . $colorName . '; caller = ' . join(',', caller));
	}

	if ($color =~ m/^[0-9a-fA-F]{6}$/) {
		$color = '#' . $color;
	}

	return $color;
} # GetThemeColor()

sub FillThemeColors { # $html ; fills in templated theme colors in provided html
	my $html = shift;
	chomp($html);

	my $colorTagNegativeText = GetThemeColor('tag_negative_text');
	$html =~ s/\$colorTagNegativeText/$colorTagNegativeText/g;

	my $colorTagPositiveText = GetThemeColor('tag_positive_text');
	$html =~ s/\$colorTagPositiveText/$colorTagPositiveText/g;

	my $colorInputBackground = GetThemeColor('input_background');
	$html =~ s/\$colorInputBackground/$colorInputBackground/g;

	my $colorInputText = GetThemeColor('input_text');
	$html =~ s/\$colorInputText/$colorInputText/g;

	my $colorRow0Bg = GetThemeColor('row_0');
	$html =~ s/\$colorRow0Bg/$colorRow0Bg/g;

	my $colorRow1Bg = GetThemeColor('row_1');
	$html =~ s/\$colorRow1Bg/$colorRow1Bg/g;

	my $colorHighlightAlert = GetThemeColor('highlight_alert');
	$html =~ s/\$colorHighlightAlert/$colorHighlightAlert/g;

	my $colorHighlightBeginner = GetThemeColor('highlight_beginner');
	$html =~ s/\$colorHighlightBeginner/$colorHighlightBeginner/g;

	my $colorHighlightAdvanced = GetThemeColor('highlight_advanced');
	$html =~ s/\$colorHighlightAdvanced/$colorHighlightAdvanced/g;

	my $colorHighlightReady = GetThemeColor('highlight_ready');
	$html =~ s/\$colorHighlightReady/$colorHighlightReady/g;
	#
	# my $colorWindow = GetThemeColor('window');
	# $html =~ s/\$colorWindow/$colorWindow/g;

	my $colorDialogHeading = GetThemeColor('dialog_heading');
	$html =~ s/\$colorDialogHeading/$colorDialogHeading/g;

	my @colors = qw(primary secondary background text link vlink window);
	for my $color (@colors) {
		#todo my @array1 = map ucfirst, @array;
		my $templateToken = '$color' . ucfirst($color);
		$html = str_replace($templateToken, GetThemeColor($color), $html);
	}
	# there are two issues with replacing below with above
	# a) searching for template token in code wouldn't find this section
	# b)
	# my $colorPrimary = GetThemeColor('primary');
	# $html =~ s/\$colorPrimary/$colorPrimary/g;
	#
	# my $colorSecondary = GetThemeColor('secondary');
	# $html =~ s/\$colorSecondary/$colorSecondary/g;
	#
	# my $colorBackground = GetThemeColor('background');
	# $html =~ s/\$colorBackground/$colorBackground/g;
	#
	# my $colorText = GetThemeColor('text');
	# $html =~ s/\$colorText/$colorText/g;
	#
	# my $colorLink = GetThemeColor('link');
	# $html =~ s/\$colorLink/$colorLink/g;
	#
	# my $colorVlink = GetThemeColor('vlink');
	# $html =~ s/\$colorVlink/$colorVlink/g;

	return $html;
} # FillThemeColors()

sub GetSystemMenuList { # writes config/list/menu based on site configuration
	#todo this function is not obvious, overrides obvious list/menu
	my @menu;

	WriteLog('GetSystemMenuList()');

	my $menuList = '';

	if (GetConfig('admin/expo_site_mode')) {
		WriteLog('GetSystemMenuList: expo_site_mode');
		if (!GetConfig('admin/expo_site_edit')) {
			WriteLog('WriteMenuList: returning empty');
		}
	}

	push @menu, 'read';
	push @menu, 'write';

	if (GetConfig('admin/php/quickchat')) {
		push @menu, 'chat';
	}

	#upload
	if (GetConfig('admin/php/enable') && GetConfig('admin/upload/enable')) {
		# push @menu, 'art';
		push @menu, 'upload';
	}

	#profile
	if (GetConfig('admin/js/enable') || GetConfig('admin/php/enable')) {
		# one of these is required for profile to work
		push @menu, 'profile';
	} else {
		#todo hide it or something?
		#perhaps link to informational page on using offline profiles?
		push @menu, 'profile';
	}
	push @menu, 'help';

	return @menu;
} # GetSystemMenuList()

require_once('get_page_header.pl');

sub GetItemListing { # returns listing of items based on topic
	my $htmlOutput = '';

	my @topItems; #todo rename this

	my $fileHash = shift;
	my $title = 'Welcome, Guest!';

	if (!$fileHash) {
		$fileHash = 'top'; #what
	}

	#refactor
	if ($fileHash eq 'top') {
		@topItems = DBGetTopItems(); # get top items from db
	} else {
		@topItems = DBGetItemReplies($fileHash);
		$title = 'Replies';
	}

	if (!@topItems) {
		WriteLog('GetItemListing: warning @topItems missing, sanity check failed');
		return '';
	}

	my $itemCount = scalar(@topItems);

	if ($itemCount) {
	# at least one item returned

		my $itemListingWrapper = GetTemplate('html/item_listing_wrapper2.template');

		my $itemListings = '';

		my $rowBgColor = ''; # stores current value of alternating row color
		my $colorRow0Bg = GetThemeColor('row_0'); # color 0
		my $colorRow1Bg = GetThemeColor('row_1'); # color 1

		while (@topItems) {
			my $itemTemplate = GetTemplate('html/item_listing.template');
			# it's ok to do this every time because GetTemplate() already stores it in a static
			# alternative is to store it in another variable above

			#alternate row color
			if ($rowBgColor eq $colorRow0Bg) {
				$rowBgColor = $colorRow1Bg;
			} else {
				$rowBgColor = $colorRow0Bg;
			}

			my $itemRef = shift @topItems; # reference to hash containing item
			my %item = %{$itemRef}; # hash containing item data

			my $itemKey = $item{'file_hash'};
			my $itemScore = $item{'item_score'};
			my $authorKey = $item{'author_key'};

			my $itemLastTouch = DBGetItemLatestAction($itemKey); #todo add to itemfields

			my $itemTitle = $item{'item_title'};
			if (trim($itemTitle) eq '') {
				# if title is empty, use the item's hash
				# $itemTitle = '(' . $itemKey . ')';
				$itemTitle = 'Untitled';
			}
			$itemTitle = HtmlEscape($itemTitle);

			my $itemLink = '/'.GetHtmlFilename($itemKey); #todo this is a bandaid

			my $authorAvatar;
			if ($authorKey) {
#				$authorAvatar = GetPlainAvatar($authorKey);
				my $authorLink = GetAuthorLink($authorKey, 1);
				if ($authorLink) {
					$authorAvatar = GetAuthorLink($authorKey, 1);
#					$authorAvatar = 'by ' . GetAuthorLink($authorKey, 1);
				} else {
					$authorAvatar = 'Unsigned';
				}
			} else {
				$authorAvatar = 'Unsigned';
			}

			$itemLastTouch = GetTimestampWidget($itemLastTouch);

			# populate item template
			$itemTemplate =~ s/\$link/$itemLink/g;
			$itemTemplate =~ s/\$itemTitle/$itemTitle/g;
			$itemTemplate =~ s/\$itemScore/$itemScore/g;
			$itemTemplate =~ s/\$authorAvatar/$authorAvatar/g;
			$itemTemplate =~ s/\$itemLastTouch/$itemLastTouch/g;
			$itemTemplate =~ s/\$rowBgColor/$rowBgColor/g;

			# add to main html
			$itemListings .= $itemTemplate;
		}

		$itemListingWrapper =~ s/\$itemListings/$itemListings/;

		my $statusText = '';
		if ($itemCount == 0) {
			$statusText = 'No threads found.';
		} elsif ($itemCount == 1) {
			$statusText = '1 thread';
		} elsif ($itemCount > 1) {
			$statusText = $itemCount . ' threads';
		}

		my $columnHeadings = 'title,author,activity';

		$itemListingWrapper = GetWindowTemplate(
			$itemListings,
			$title,
			$columnHeadings,
			$statusText
		);

		$htmlOutput .= $itemListingWrapper;

		#$htmlOutput .= GetWindowTemplate('<tt>... and that is ' . $itemCount . ' item(s) total! beep boop</tt>', 'robot voice');

	} else {
	# no items returned, use 'no items' template
		$htmlOutput .= GetWindowTemplate(GetTemplate('html/item/no_items.template'), 'Welcome, Guest!');
		#todo add menu?
	}

	return $htmlOutput;
} # GetItemListing()

sub GetTopItemsPage { # returns page with top items listing
	WriteLog("GetTopItemsPage()");

	my $htmlOutput = ''; # stores the html

	my $title = 'Topics';
	my $titleHtml = 'Topics';

	$htmlOutput = GetPageHeader('read'); # <html><head>...</head><body>
	$htmlOutput .= GetTemplate('html/maincontent.template'); # where "skip to main content" goes

	$htmlOutput .= GetItemListing('top');

	$htmlOutput .= GetPageFooter('read'); # </body></html>

	if (GetConfig('admin/js/enable')) {
		# add necessary js
		$htmlOutput = InjectJs($htmlOutput, qw(settings voting timestamp profile avatar utils));
	}

	return $htmlOutput;
} # GetTopItemsPage()

sub GetItemPrefixPage { # $prefix ; returns page with items matching specified prefix
	WriteLog("GetItemPrefixPage()");

	my $prefix = shift;
	if (!IsItemPrefix($prefix)) {
		WriteLog('GetItemPrefixPage: warning: $prefix sanity check failed');
		return '';
	}

	WriteLog('GetItemPrefixPage: $prefix = ' . $prefix);

	my $htmlOutput = ''; # stores the html

	my $title = 'Items matching ' . $prefix;
	my $titleHtml = 'Items matching ' . $prefix;

	$htmlOutput = GetPageHeader('prefix'); # <html><head>...</head><body>
	$htmlOutput .= GetTemplate('html/maincontent.template'); # where "skip to main content" goes

	my @topItems = DBGetItemsByPrefix($prefix); # get top items from db

	my $itemCount = scalar(@topItems);

	WriteLog('GetItemPrefixPage: $itemCount = ' . $itemCount);

	if ($itemCount) {
	# at least one item returned
		my $itemListingWrapper = GetTemplate('html/item_listing_wrapper2.template'); # GetItemPrefixPage()
		my $itemListings = '';

		my $rowBgColor = ''; # stores current value of alternating row color
		my $colorRow0Bg = GetThemeColor('row_0'); # color 0
		my $colorRow1Bg = GetThemeColor('row_1'); # color 1

		if (scalar(@topItems)) {
			WriteLog('GetItemPrefixPage: scalar(@topItems) was true');
		} else {
			WriteLog('GetItemPrefixPage: warning: scalar(@topItems) was false');
		}

		while (@topItems) {
			my $itemTemplate = GetTemplate('html/item_listing.template'); # GetItemPrefixPage()
			# it's ok to do this every time because GetTemplate() already stores it in a static
			# alternative is to store it in another variable above

			#alternate row color
			if ($rowBgColor eq $colorRow0Bg) {
				$rowBgColor = $colorRow1Bg;
			} else {
				$rowBgColor = $colorRow0Bg;
			}

			my $itemRef = shift @topItems; # reference to hash containing item
			my %item = %{$itemRef}; # hash containing item data

			my $itemKey = $item{'file_hash'};
			my $itemScore = $item{'item_score'};
			my $authorKey = $item{'author_key'};

			my $itemLastTouch = DBGetItemLatestAction($itemKey); #todo add to itemfields

			my $itemTitle = $item{'item_title'};
			if (trim($itemTitle) eq '') {
				# if title is empty, use the item's hash
				# $itemTitle = '(' . $itemKey . ')';
				$itemTitle = 'Untitled';
			}
			$itemTitle = HtmlEscape($itemTitle);

			my $itemLink = GetHtmlFilename($itemKey);

			my $authorAvatar;
			if ($authorKey) {
#				$authorAvatar = GetPlainAvatar($authorKey);
				my $authorLink = GetAuthorLink($authorKey, 1);
				if ($authorLink) {
					$authorAvatar = GetAuthorLink($authorKey, 1);
#					$authorAvatar = 'by ' . GetAuthorLink($authorKey, 1);
				} else {
					$authorAvatar = 'Unsigned';
				}
			} else {
				$authorAvatar = 'Unsigned';
			}

			$itemLastTouch = GetTimestampWidget($itemLastTouch);

			# populate item template
			$itemTemplate =~ s/\$link/$itemLink/g;
			$itemTemplate =~ s/\$itemTitle/$itemTitle/g;
			$itemTemplate =~ s/\$itemScore/$itemScore/g;
			$itemTemplate =~ s/\$authorAvatar/$authorAvatar/g;
			$itemTemplate =~ s/\$itemLastTouch/$itemLastTouch/g;
			$itemTemplate =~ s/\$rowBgColor/$rowBgColor/g;

			# add to main html
			$itemListings .= $itemTemplate;
		}

		$itemListingWrapper =~ s/\$itemListings/$itemListings/;

		my $statusText = '';
		if ($itemCount == 0) {
			$statusText = 'No threads found.';
		} elsif ($itemCount == 1) {
			$statusText = '1 thread';
		} elsif ($itemCount > 1) {
			$statusText = $itemCount . ' threads';
		}

#		my $columnHeadings = 'Title,Score,Replied,Author';
		my $columnHeadings = 'title,author,activity';

		$itemListingWrapper = GetWindowTemplate(
			$itemListings,
			'Items prefixed ' . $prefix,
			$columnHeadings,
			$statusText,
			''
		);

		$htmlOutput .= $itemListingWrapper;
	} else {
	# no items returned, use 'no items' template
		$htmlOutput .= GetTemplate('html/item/no_items.template');
	}

	$htmlOutput .= GetPageFooter('prefix'); # </body></html>

	if (GetConfig('admin/js/enable')) {
		# add necessary js
		$htmlOutput = InjectJs($htmlOutput, qw(settings voting timestamp profile avatar utils));
	}

	return $htmlOutput;
} # GetItemPrefixPage()

require_once('dialog/stats_table.pl');
require_once('inject_js.pl');
require_once('dialog/author_info.pl');
require_once('widget/author_friends.pl');

require_once('get_read_page.pl');

sub GetItemListHtml { # @files(array of hashes) ; takes @files, returns html list
	my $filesArrayReference = shift; # array of hash refs which contains items
	if (!$filesArrayReference) {
		WriteLog('GetItemListHtml: warning: sanity check failed, missing $filesArrayReference');
		return 'problem getting item list, my apologies. (1)';
	}
	my @files = @$filesArrayReference; # de-reference
	if (!scalar(@files)) {
		WriteLog('GetItemListHtml: warning: sanity check failed, missing @files');
		return 'problem getting item list, my apologies. (2)';
	}

	WriteLog('GetItemListHtml: scalar(@files) = ' . scalar(@files));

	my $itemList = '';
	my $itemComma = '';

	my $itemListTemplate = '<span class=itemList></span>'; #todo templatize

	#shift @files;

	foreach my $rowHashRef (@files) { # loop through each file
		my %row = %{$rowHashRef};

		#print Dumper(%row);

		my $file = $row{'file_path'};

		if ($file && -e $file) { # file exists
		} else {
			WriteLog('GetItemListHtml: warning: $file does not exist; $file = ' . ($file ? $file : 'FALSE'));
			$file = 0;
		}

		my $itemHash = $row{'file_hash'};

		my $gpgKey = $row{'author_key'};
		my $isSigned;
		if ($gpgKey) {
			$isSigned = 1;
		} else {
			$isSigned = 0;
		}
		my $alias = '';
		my $isAdmin = 0;

		my $message;
		if (CacheExists("message/$itemHash")) {
			$message = GetCache("message/$itemHash");
		} else {
			if ($file) {
				$message = GetFile($file);
			} else {
				$message = '';
			}
		}

		$row{'vote_buttons'} = 1;
		$row{'show_vote_summary'} = 1;
		$row{'display_full_hash'} = 0;
		$row{'trim_long_text'} = 0;

		my $itemTemplate;
		$itemTemplate = GetItemTemplate(\%row); # GetIndexPage()

		if (!$itemTemplate) {
			WriteLog('GetItemListHtml: warning: $itemTemplate is FALSE');
		}

		$itemList = $itemList . $itemComma . $itemTemplate;

		if ($itemComma eq '') {
			$itemComma = '';
			#$itemComma = '<hr><br>';
			##$itemComma = '<p>';
		}
	}

	$itemListTemplate = str_replace('<span class=itemList></span>', '<span class=itemList>' . $itemList . '</span>', $itemListTemplate);

	WriteLog('GetItemListHtml: length($itemListTemplate) = ' . length($itemListTemplate));

	return $itemListTemplate;
} # GetItemListHtml()

sub GetAccessKey { # $caption ; returns access key to use for menu item
	# tries to find non-conflicting one
	WriteLog('GetAccessKey()');

	if (!GetConfig('html/accesskey')) {
		WriteLog('GetAccessKey: warning: sanity check failed');
		return '';
	}

	my $caption = shift;
	#todo sanity checks

	state %captionKey;
	state %keyCaption;
	if ($captionKey{$caption}) {
		return $captionKey{$caption};
	}

	my $newKey = '';
	for (my $i = 0; $i < length($caption) - 1; $i++) {
		my $newKeyPotential = lc(substr($caption, $i, 1));
		if ($newKeyPotential =~ m/^[a-z]$/) {
			if (!$keyCaption{$newKeyPotential}) {
				$newKey = $newKeyPotential;
				last;
			}
		}
	}

	if ($newKey) {
		$captionKey{$caption} = $newKey;
		$keyCaption{$newKey} = $caption;
		return $captionKey{$caption};
	} else {
		#todo pick another letter, add in parentheses like this: File (<u>N</u>)
	}
} # GetAccessKey()

sub MakeJsTestPages {
	my $jsTestPage = GetTemplate('js/test.js');
	PutHtmlFile("jstest.html", $jsTestPage);

	my $jsTest2Page = GetTemplate('js/test2.js');
	#	$jsTest2Page = InjectJs($jsTest2Page, qw(sha512.js));
	PutHtmlFile("jstest2.html", $jsTest2Page);

	my $jsTest3Page = GetTemplate('js/test3.js');
	PutHtmlFile("jstest3.html", $jsTest3Page);

	my $jsTest4Page = GetTemplate('js/test4.js');
	PutHtmlFile("jstest4.html", $jsTest4Page);

	my $jsTest2 = GetTemplate('test/jstest1/jstest2.template');
	$jsTest2 = InjectJs($jsTest2, qw(jstest2));
	PutHtmlFile("jstest2.html", $jsTest2);
} # MakeJsTestPages()

require_once('make_simple_page.pl');

sub MakePhpPages {
	WriteLog('MakePhpPages() begin');

	if (GetConfig('admin/php/enable')) {
		# 'post.php'
		# 'test2.php'
		# 'config.php'
		# 'test.php'
		# 'write.php'
		# 'upload.php'
		# 'search.php'
		# 'cookie.php'
		# 'cookietest.php'
		# 'route.php'
		# 'quick.php'
		my @templatePhpSimple = qw(post test2 config test write upload search cookie cookietest utils route handle_not_found process_new_comment);
		if (GetConfig('admin/php/quickchat')) {
			push @templatePhpSimple, 'quick';
		}
		for my $template (@templatePhpSimple) {
			my $fileContent = GetTemplate("php/$template.php");
			state $PHPDIR = GetDir('php');
			PutFile($PHPDIR . "/$template.php", $fileContent);
		}

		my $utilsPhpTemplate = GetTemplate('php/utils.php');
		state $SCRIPTDIR = GetDir('script');
		state $PHPDIR = GetDir('php');
		$utilsPhpTemplate =~ s/\$scriptDirPlaceholderForTemplating/$SCRIPTDIR/g;
		PutFile($PHPDIR . '/utils.php', $utilsPhpTemplate);

		MakeSimplePage('post'); #post.html, needed by post.php
		GetTemplate('html/item_processing.template'); #to cache it in config/

		if (GetConfig('admin/htaccess/enable')) { #.htaccess
			MakeHtAccessPages();
		} #.htaccess
	} else {
		WriteLog('MakePhpPages: warning: called when admin/php/enable is FALSE');
		return '';
	}
} # MakePhpPages()

sub MakeJsPages {
	state $HTMLDIR = GetDir('html');

	# Zalgo javascript
	PutHtmlFile("zalgo.js", GetTemplate('js/lib/zalgo.js'));

	if (
		GetConfig('admin/js/openpgp')
		&&
			(!-e "$HTMLDIR/openpgp.js")
			 ||
			(!-e "$HTMLDIR/openpgp.worker.js")
	)
	{
		# OpenPGP javascript
		PutHtmlFile("openpgp.js", GetTemplate('js/lib/openpgp.js'));
		PutHtmlFile("openpgp.worker.js", GetTemplate('js/lib/openpgp.worker.js'));
	}

	if (GetConfig('setting/admin/js/dragging')) {
		PutHtmlFile("dragging.js", GetScriptTemplate('dragging'));
		#PutHtmlFile("dragging.js", GetTemplate('js/dragging.js'));
	}

	PutHtmlFile("sha512.js", GetTemplate('js/sha512.js'));

	if (GetConfig('admin/php/enable')) {
	#if php/enabled, then use post.php instead of post.html
	#todo add rewrites for this
	#rewrites have been added for this, so it's commented out for now, but could still be an option in the future
#		$cryptoJsTemplate =~ s/\/post\.html/\/post.php/;
	}
	#PutHtmlFile("crypto.js", $cryptoJsTemplate);

	my $crypto2JsTemplate = GetTemplate('js/crypto2.js');
	if (GetConfig('admin/js/debug')) {
		#$crypto2JsTemplate =~ s/\/\/alert\('DEBUG:/if(!window.dbgoff)dbgoff=!confirm('DEBUG:/g;
		$crypto2JsTemplate = EnableJsDebug($crypto2JsTemplate);
	}
	my $algoSelectMode = GetConfig('admin/js/openpgp_algo_select_mode');
	if ($algoSelectMode) {
		if ($algoSelectMode eq '512' || $algoSelectMode eq 'random' || $algoSelectMode eq 'max') {
			my $oldValue = $crypto2JsTemplate;
			$crypto2JsTemplate = str_replace('var algoSelectMode = 0;', "var algoSelectMode = '$algoSelectMode'", $crypto2JsTemplate);
			if ($oldValue eq $crypto2JsTemplate) {
				WriteLog('MakeJsPages: warning: crypto2.js algoSelectMode templating failed, value of $crypto2JsTemplate did not change as expected');
			}
		}
	}
	my $promptForUsername = GetConfig('admin/js/openpgp_keygen_prompt_for_username');
	if ($promptForUsername) {
		$crypto2JsTemplate = str_replace('//username = prompt', 'username = prompt', $crypto2JsTemplate);
	}
	PutHtmlFile("crypto2.js", $crypto2JsTemplate);

	# Write avatar javascript
	my $avatarJsTemplate = GetTemplate('js/avatar.js');
	if (GetConfig('admin/js/debug')) {
		# $avatarJsTemplate =~ s/\/\/alert\('DEBUG:/if(!window.dbgoff)dbgoff=!confirm('DEBUG:/g;
		$avatarJsTemplate = EnableJsDebug($avatarJsTemplate);

	}
	PutHtmlFile("avatar.js", $avatarJsTemplate);

	# Write settings javascript
	#PutHtmlFile("settings.js", GetTemplate('js/settings.js'));
	PutHtmlFile("prefstest.html", GetTemplate('js/prefstest.template'));
} # MakeJsPages()

sub MakeSummaryPages { # generates and writes all "summary" and "static" pages StaticPages
# write, add event, stats, profile management, preferences, post ok, action/vote, action/event
# js files,
	WriteLog('MakeSummaryPages() BEGIN');

	state $HTMLDIR = GetDir('html');

	MakeSystemPages();

	# Add Authors page
	MakePage('authors', 0);

	MakePage('read', 0);

	MakePage('image', 0);

	MakePage('picture', 0);

	MakePage('tags', 0);

	MakePage('compost', 0);

	MakePage('deleted', 0);
	#
	# { # clock test page
	# 	my $clockTest = '<form name=frmTopMenu>' . GetTemplate('html/widget/clock.template') . '</form>';
	# 	my $clockTestPage = '<html><body>';
	# 	$clockTestPage .= $clockTest;
	# 	$clockTestPage .= '</body></html>';
	# 	$clockTestPage = InjectJs($clockTestPage, qw(clock));
	# 	PutHtmlFile("clock.html", $clockTestPage);
	# }


	WriteLog('MakeSummaryPages() END');
} # MakeSummaryPages()

sub MakeHtAccessPages {
	my $HTMLDIR = GetDir('html');

	if (GetConfig('admin/htaccess/enable')) { #.htaccess
		# .htaccess file for Apache
		my $HtaccessTemplate = GetTemplate('htaccess/htaccess.template');

		# here, we inject the contents of 401.template into .htaccess
		# this is a kludge until i figure out how to do it properly
		# 401.template should not contain any " characters (will be removed)
		#
		my $message = GetConfig('admin/http_auth/message_401');
		$message =~ s/\n/<br>/g;
		my $text401 = GetTemplate('html/401.template');
		$text401 = str_replace('<p id=message></p>', '<p id=message>' . $message . '</p>', $text401);

		$text401 = str_replace("\n", '', $text401);
		$text401 = str_replace('"', '\\"', $text401);
		$text401 = '"' . $text401 . '"';
		$HtaccessTemplate =~ s/\/error\/error-401\.html/$text401/g;

		if (GetConfig('admin/php/enable')) {
			$HtaccessTemplate .= "\n" . GetTemplate('htaccess/htaccess_php.template');

			my $rewriteSetting = GetConfig('admin/php/rewrite');
			if ($rewriteSetting) {
				if ($rewriteSetting eq 'all') {
					$HtaccessTemplate .= "\n" . GetTemplate('htaccess/htaccess_php_rewrite_all.template');
				}
				if ($rewriteSetting eq 'query') {
					$HtaccessTemplate .= "\n" . GetTemplate('htaccess/htaccess_php_rewrite_query.template');
				}
			}
		}

		if (GetConfig('admin/http_auth/enable')) {
			my $HtpasswdTemplate .= GetConfig('admin/http_auth/htpasswd');
			my $HtaccessHttpAuthTemplate = GetTemplate('htaccess/htaccess_htpasswd.template');

			if ($HtpasswdTemplate & $HtaccessHttpAuthTemplate) {
				PutFile("$HTMLDIR/.htpasswd", $HtpasswdTemplate);
				if ($HTMLDIR =~ m/^([^\s]+)$/) { #todo security less permissive and untaint at top of file #security #taint
					$HTMLDIR = $1;
					chmod 0644, "$HTMLDIR/.htpasswd";
				}

				$HtaccessHttpAuthTemplate =~ s/\.htpasswd/$HTMLDIR\/\.htpasswd/;

				my $errorDocumentRoot = "$HTMLDIR/error/";
				$HtaccessHttpAuthTemplate =~ s/\$errorDocumentRoot/$errorDocumentRoot/g;
				#todo this currently has a one-account template

				$HtaccessTemplate .= "\n" . $HtaccessHttpAuthTemplate;
			}
		}

		if (GetConfig('admin/ssi/enable')) {
			my $ssiConf = GetTemplate('htaccess/htaccess_ssi.template');
			$HtaccessTemplate .= "\n" . $ssiConf;
		}

		PutFile("$HTMLDIR/.htaccess", $HtaccessTemplate);

		# WriteDataPage();
	} #.htaccess
} # MakeHtAccessPages()

sub MakeSystemPages {
	state $HTMLDIR = GetDir('html');

	#MakeSimplePage('calculator'); # calculator.html calculator.template
	MakeSimplePage('welcome'); # welcome.html welcome.template index.html

	MakeSimplePage('cookie'); # welcome.html welcome.template index.html

	if (GetConfig('admin/php/enable')) {
		MakePhpPages();
	}

	{
		my $fourOhFourPage = GetDialogPage('404'); #GetTemplate('html/404.template');
		if (GetConfig('html/clock')) {
			$fourOhFourPage = InjectJs($fourOhFourPage, qw(clock fresh utils)); #todo this causes duplicate clock script
		}
		PutHtmlFile("404.html", $fourOhFourPage);
		PutHtmlFile("error/error-404.html", $fourOhFourPage);
	}
	# Submit page
	require_once('page/write.pl');
	my $submitPage = GetWritePage();
	PutHtmlFile("write.html", $submitPage);
	#MakeSimplePage('write');

	{
		my $accessDeniedPage = GetDialogPage('401'); #GetTemplate('html/401.template');
		PutHtmlFile("error/error-401.html", $accessDeniedPage);
	}

	if (GetConfig('admin/offline/enable')) {
		PutHtmlFile("cache.manifest", GetTemplate('js/cache.manifest.template') . "#" . time()); # config/admin/offline/enable
	}

	if (GetConfig('admin/dev/make_js_test_pages')) {
		MakeJsTestPages();
	}

	my $jsTest1 = GetTemplate('test/jstest1/jstest1.template'); # Browser Test
	$jsTest1 = InjectJs($jsTest1, qw(jstest1));
	PutHtmlFile("jstest1.html", $jsTest1);

	if (GetConfig('admin/php/enable')) {
		# create write_post.html for longer messages if admin/php/enable
		$submitPage =~ s/method=get/method=post/g;
		if (index(lc($submitPage), 'method=post') == -1) {
			$submitPage =~ s/\<form /<form method=post /g;
		}
		if (index(lc($submitPage), 'method=post') == -1) {
			$submitPage =~ s/\<form/<form method=post /g;
		}
		$submitPage =~ s/cols=32/cols=50/g;
		$submitPage =~ s/rows=9/rows=15/g;
		$submitPage =~ s/please click here/you're in the right place/g;
		PutHtmlFile("write_post.html", $submitPage);
	}

	MakePage('upload');

	# Upload page
	my $uploadMultiPage = GetUploadPage('html/form/upload_multi.template');
	PutHtmlFile("upload_multi.html", $uploadMultiPage);

	MakeSimplePage('post');

	# Blank page
	PutHtmlFile("blank.html", "");

	if (GetConfig('admin/js/enable')) {
		MakeJsPages();
	}

	if (GetConfig('admin/htaccess/enable')) { #.htaccess
		MakeHtAccessPages();
	} #.htaccess

	PutHtmlFile("favicon.ico", '');

	{
		# p.gif
		WriteLog('making p.gif');

		if (!-e './config/template/html/p.gif.template') {
			if (-e 'default/template/html/p.gif.template') {
				copy('default/template/html/p.gif.template', 'config/template/html/p.gif.template');
			}
		}

		if (-e 'config/template/html/p.gif.template') {
			copy('config/template/html/p.gif.template', $HTMLDIR . '/p.gif');
		}
	}

	MakePage('read');

} # MakeSystemPages()

sub MakeListingPages {

	if (GetConfig('admin/js/enable') && GetConfig('admin/js/dragging')) {
		my $dialog;

		$dialog = GetQueryAsDialog('read', 'Top Threads');
		PutHtmlFile('dialog/read.html', $dialog);

		$dialog = GetWriteForm();
		#PutHtmlFile('dialog/write.html', $dialog);
		PutHtmlFile('dialog/write.html', '<form action="/post.html" method=GET id=compose name=compose target=_top>' . $dialog . '</form>');

		$dialog = GetSettingsDialog();
		PutHtmlFile('dialog/settings.html', $dialog);

		$dialog = GetAnnoyancesDialog();
		PutHtmlFile('dialog/annoyances.html', $dialog);

		$dialog = GetStatsTable();
		PutHtmlFile('dialog/stats.html', $dialog);

		$dialog = GetProfileDialog();
		PutHtmlFile('dialog/profile.html', $dialog);

		$dialog = GetSimpleDialog('help');
		PutHtmlFile('dialog/help.html', $dialog);
	}
	MakePage('profile');

	MakePage('chain');

	MakePage('deleted');

	MakePage('compost');

	MakePage('authors');

	MakePage('data');

	#PutHtmlFile('desktop.html', GetDesktopPage());
	MakeSimplePage('desktop');

	if (1) {
		# Ok page
		my $okPage;
		$okPage .= GetPageHeader('default', 'OK');
		my $windowContents = GetTemplate('html/action_ok.template');
		$okPage .= GetWindowTemplate($windowContents, 'Data Received', '', 'Ready');
		$okPage .= GetPageFooter('default');
		$okPage =~ s/<\/head>/<meta http-equiv="refresh" content="10; url=\/"><\/head>/;
		$okPage = InjectJs($okPage, qw(settings));
		PutHtmlFile("action/event.html", $okPage);
	}

	# Search page
	MakeSimplePage('search');

	MakeSimplePage('access');

	MakeSimplePage('etc');

	# Add Event page
	my $eventAddPage = GetEventAddPage();
	PutHtmlFile("event.html", $eventAddPage);


	PutHtmlFile("test.html", GetTemplate('html/test.template'));
	PutHtmlFile("keyboard.html", GetTemplate('html/keyboard/keyboard.template'));
	PutHtmlFile("keyboard_netscape.html", GetTemplate('html/keyboard/keyboard_netscape.template'));
	PutHtmlFile("keyboard_android.html", GetTemplate('html/keyboard/keyboard_a.template'));

	PutHtmlFile("frame.html", GetTemplate('html/keyboard/keyboard_frame.template'));
	PutHtmlFile("frame2.html", GetTemplate('html/keyboard/keyboard_frame2.template'));
	PutHtmlFile("frame3.html", GetTemplate('html/keyboard/keyboard_frame3.template'));


	MakeSimplePage('manual'); # manual.html manual.template
	MakeSimplePage('help'); # 'help.html' 'help.template' GetHelpPage {
	MakeSimplePage('bookmark'); # welcome.html welcome.template
	# MakeSimplePage('desktop'); # desktop.html desktop.template
	MakeSimplePage('manual_advanced'); # manual_advanced.html manual_advanced.template
	MakeSimplePage('manual_tokens'); # manual_tokens.html manual_tokens.template


	MakeSimplePage('settings');
	MakeSimplePage('post');
	PutStatsPages();
	# Settings page
	#my $settingsPage = GetSettingsPage();
	#PutHtmlFile("settings.html", $settingsPage);

} # MakeListingPages()

sub GetEventAddPage { # get html for /event.html
	# $txtIndex stores html page output
	my $txtIndex = "";

	my $title = "Add Event";
	my $titleHtml = "Add Event";

	$txtIndex = GetPageHeader('event_add');

	$txtIndex .= GetTemplate('html/maincontent.template');


	my $eventAddForm = GetTemplate('html/form/event_add.template');

	#	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
#		localtime(time);
#
#	my $amPm = 0;
#	if ($hour > 12) {
#		$hour -= 12;
#		$amPm = 1;
#	}
#
	$txtIndex .= $eventAddForm;

	$txtIndex .= GetPageFooter('event_add');

	$txtIndex = InjectJs($txtIndex, qw(settings avatar event_add profile));

	my $colorRow0Bg = GetThemeColor('row_0');
	my $colorRow1Bg = GetThemeColor('row_1');

	$txtIndex =~ s/\$colorRow0Bg/$colorRow0Bg/g;
	$txtIndex =~ s/\$colorRow1Bg/$colorRow1Bg/g;

	return $txtIndex;
}

sub PutStatsPages { # stores template for footer stats dialog
	MakeSimplePage('stats');

	if (GetConfig('debug')) {
		#my $statsPage = GetStatsPage();
		if (-e 'log/log.log') {
			my $warningsLog = `grep -i warning log/log.log > html/warning.txt`;
			my $warningsSummary = `cat html/warning.txt | cut -d ' ' -f 3 | cut -d ':' -f 1 | cut -d '(' -f 1 | sort | uniq -c | sort -bnr > html/warnsumm.txt`;
			$warningsSummary = "\n" . GetFile('html/warnsumm.txt') . "\n";

			my $warningsSummaryHtml = '';
			my @warningsSummaryArray = split("\n", $warningsSummary);
			for my $warningSub ( @warningsSummaryArray ) {
				if ($warningSub =~ m/^([a-zA-Z0-9_\-])$/) {
					$warningSub = $1;
					$warningsSummaryHtml .= '<a href="/warning_' . $warningSub . '.txt">' . $warningSub . '</a>';
					$warningsSummaryHtml .= "\n";
				} else {
					$warningsSummaryHtml .= $warningSub;
					$warningsSummaryHtml .= "\n";
				}
			}

			my $warningsSummaryCommandResult = `find html | cut -d '/' -f 2-`;
			if ($warningsSummaryCommandResult =~ m/^([\x00-\x7F]+)$/) {
				$warningsSummaryCommandResult = $1;
			} else {
				WriteLog('PutStatsPage: warning: sanity check failed on $warningsSummaryCommandResult');
				$warningsSummaryCommandResult = '';
			}

			# THIS IS HARD-CODED BECAUSE it is a system-debugging feature,
			# and should have as few dependencies as possible
			# and maybe a little bit to save time
			my $warningsHtml =
				'<html><head><title>engine</title></head><body>' .
				'<center><table height=95% width=98%>' .
				'<tr><td align=center valign=middle>' .
				'<p>technical users:<br><a href="/warning.txt">warning list</a> can help fix bugs<br>or just <a href="/help.html">confuse more</a></p>' .
				'<p><tt>' .
				"cat html/warning.txt | cut -d ' ' -f 3 | cut -d ':' -f 1 | cut -d '(' -f 1 | sort | uniq -c | sort -bnr > html/warnsumm.txt" .
				'</tt></p>' .
				'</td>' .
				'<td><pre>' .
				$warningsSummaryHtml .
				'</pre></td>' .
				'</tr></table></center>' .
				'<hr>' .
				'<pre>' .
				$warningsSummaryCommandResult .
				'</pre>' .
				'</body></html>'
			;
			#$warningsHtml = InjectJs($warningsHtml, qw(utils fresh)); #shouldn't be any javascript on this page
			#todo warning if there is javascript in the html
			PutHtmlFile("engine.html", $warningsHtml); # engine.html
		} # if (-e 'log/log.log')
	} # if (GetConfig('debug'))

	my $statsFooter = GetWindowTemplate(
		GetStatsTable('stats-horizontal.template'),
		'Site Statistics*'
	);
	$statsFooter = '<span class=advanced>' . $statsFooter . '</span>';
	PutHtmlFile("stats-footer.html", $statsFooter);
} # PutStatsPages()

sub GetPagePath { # $pageType, $pageParam ; returns path to item's html path
# $pageType, $pageParam match parameters for MakePage()
	my $pageType = shift;
	my $pageParam = shift;

	chomp $pageType;
	chomp $pageParam;

	if (!$pageType) {
		WriteLog('GetPagePath: warning: called without $pageType; caller = ' . join(',', caller));
		return '';
	}

	my $htmlPath = '';

	if ($pageType eq 'author') {
		# /author/ABCDEF1234567890/index.html
		$htmlPath = $pageType . '/' . $pageParam . '/index.html';
	}
	elsif ($pageType eq 'tag') {
		# /top/approve.html
		$htmlPath = 'top/' . $pageParam . '.html';
	}
	elsif ($pageType eq 'rss') {
		# /rss.xml
		$htmlPath = 'rss.xml';
	}
	elsif ($pageType eq 'authors') {
		# /authors.html
		$htmlPath = 'authors.html';
	} else {
		if ($pageParam) {
			# e.g. /tag/approve.html
			$htmlPath = $pageType . '/' . $pageParam . '.html';
		} else {
			# e.g. /profile.html
			$htmlPath = $pageType . '.html';
		}
	}

	return $htmlPath;
} # GetPagePath()

sub BuildTouchedPages { # $timeLimit, $startTime ; builds pages returned by DBGetTouchedPages();
	WriteLog("BuildTouchedPages: warning: is broken, exiting");

	# DBGetTouchedPages() means select * from task where priority > 0

#	my $timeLimit = shift;
#	if (!$timeLimit) {
#		$timeLimit = 0;
#	}
#	my $startTime = shift;
#	if (!$startTime) {
#		$startTime = 0;
#	}

#	WriteLog("BuildTouchedPages($timeLimit, $startTime)");

#	my $pagesLimit = GetConfig('admin/update/limit_page');
#	if (!$pagesLimit) {
#		WriteLog("WARNING: config/admin/update/limit_page missing!");
#		$pagesLimit = 1000;
#	}

	my $pagesProcessed = 0;

	# get a list of pages that have been touched since touch git_flow
	# this is from the task table
	my @pages = SqliteQueryHashRef("SELECT task_name, task_param FROM task WHERE priority > 0 AND task_type = 'page' ORDER BY priority DESC;");
	#todo templatize

	shift @pages; #remove header row

	if (@pages) {
		# write number of touched pages to log
		WriteLog('BuildTouchedPages: scalar(@pages) = ' . scalar(@pages));

		# this part will refresh any pages that have been "touched"
		# in this case, 'touch' means when an item that affects the page
		# is updated or added

		my $isLazy = 0;
#		if (GetConfig('admin/pages/lazy_page_generation')) {
#			if (GetConfig('admin/php/enable')) {
#				# at this time, php is the only module which can support regrowing
#				# 404 pages and thsu lazy page gen
#				if (GetConfig('admin/php/rewrite')) {
#					# rewrite is also required for this to work
#					if (GetConfig('admin/php/regrow_404_pages')) {
#						WriteLog('BuildTouchedPages: $isLazy conditions met, setting $isLazy = 1');
#						$isLazy = 1;
#					}
#				}
#			}
#		}
		WriteLog('BuildTouchedPages: $isLazy = ' . $isLazy);

		foreach my $pageHashRef (@pages) {
			my %page = %{$pageHashRef};
#			if ($timeLimit && $startTime && ((time() - $startTime) > $timeLimit)) {
#				WriteMessage("BuildTouchedPages: Time limit reached, exiting loop");
#				WriteMessage("BuildTouchedPages: " . time() . " - $startTime > $timeLimit");
#				last;
#			}

#			$pagesProcessed++;
			#	if ($pagesProcessed > $pagesLimit) {
			#		WriteLog("Will not finish processing pages, as limit of $pagesLimit has been reached");
			#		last;
			#	}
			#	if ((GetTime2() - $startTime) > $timeLimit) {
			#		WriteLog("Time limit reached, exiting loop");
			#		last;
			#	}

			# dereference @pageArray and get the 3 items in it

			my $pageType = $page{'task_name'};
			my $pageParam = $page{'task_param'};
#			my $touchTime = shift @pageArray;

			# output to log
#			WriteLog('BuildTouchedPages: $pageType = ' . $pageType . '; $pageParam = ' . $pageParam . ';');
#			WriteLog('BuildTouchedPages: $pageType = ' . $pageType . '; $pageParam = ' . $pageParam . '; $touchTime = ' . $touchTime);

			if ($isLazy) {
				my $pagePath = GetPagePath($pageType, $pageParam);
				RemoveHtmlFile($pagePath);
			} else {
				MakePage($pageType, $pageParam);
			}
			DBDeletePageTouch($pageType, $pageParam);
		}
	} # $touchedPages
	else {
		WriteLog('BuildTouchedPages: warning: $touchedPages was false, and thus not an array reference.');
		return 0;
	}

	return $pagesProcessed;
} # BuildTouchedPages()

sub BuildStaticExportPages { #
	my $pagesProcessed = 0;
	my $allPages = DBGetAllPages();

	if ($allPages) { #todo actually check it's an array reference or something?
		# de-reference array of touched pages
		my @pagesArray = @$allPages;

		# write number of touched pages to log
		WriteLog('BuildTouchedPages: scalar(@pagesArray) = ' . scalar(@pagesArray));

		# this part will refresh any pages that have been "touched"
		# in this case, 'touch' means when an item that affects the page
		# is updated or added

		foreach my $page (@pagesArray) {
			$pagesProcessed++;

			# dereference @pageArray and get the 3 items in it
			my @pageArray = @$page;
			my $pageType = shift @pageArray;
			my $pageParam = shift @pageArray;
			my $touchTime = shift @pageArray;

			# output to log
			WriteLog('BuildStaticExportPages: $pageType = ' . $pageType . '; $pageParam = ' . $pageParam . '; $touchTime = ' . $touchTime);

			MakePage($pageType, $pageParam, './export');
		}
	} # $allPages
	else {
		WriteLog('BuildStaticExportPages: warning: $allPages was false, and thus not an array reference.');
		return 0;
	}

	return $pagesProcessed;
} # BuildStaticExportPages()

require_once('widget/avatar.pl');
require_once('format_message.pl');
require_once('widget.pl');
require_once('dialog.pl');
require_once('dialog/reply.pl');

sub PrintBanner {
	my $string = shift; #todo sanity checks
	my $width = length($string);

	my $edge = "=" x $width;

	print $edge;
	print $string;
	print $edge;
} # PrintBanner()

while (my $arg1 = shift @foundArgs) {
	# evaluate each argument, fuzzy-matching it, and generate requested pages

	# go through all the arguments one at a time
	if ($arg1) {
		if (-e $arg1 && -f $arg1) {
			# if filename was supplied, use its filehash
			$arg1 = GetFileHash($arg1);
		}

		#this cool feature also had undesired effects, which should be corrected
		#		if ($arg1 =! m/\/([0-9A-F]{16})\//) {
		#			# if it looks like a profile url, use the profile identifier
		#			$arg1 = $1;
		#		}
		#
		if ($arg1 eq '--theme') {
			# override the theme for remaining pages
			print ("recognized token --theme");
			my $themeArg = shift @foundArgs;
			chomp $themeArg;
			GetConfig('theme', 'override', $themeArg);
		}
		elsif (IsItem($arg1)) {
			print ("recognized item identifier\n");
			MakePage('item', $arg1, 1);
		}
		elsif (IsItemPrefix($arg1)) {
			print ("recognized item prefix\n");
			MakePage('prefix', $arg1, 1);
		}
		elsif (IsFingerprint($arg1)) {
			print ("recognized author fingerprint\n");
			MakePage('author', $arg1, 1);
		}
		elsif (IsDate($arg1)) {
			print ("recognized date\n");
			MakePage('date', $arg1, 1);
		}
		elsif (substr($arg1, 0, 1) eq '#') {
			#todo sanity checks here
			print ("recognized hash tag $arg1\n");
			MakePage('tag', substr($arg1, 1), 1);
		}
		elsif ($arg1 eq '--summary' || $arg1 eq '-s') {
			print ("recognized --summary\n");
			MakeSummaryPages();
		}
		elsif ($arg1 eq '--system' || $arg1 eq '-S') { #--system #system pages
			print ("recognized --system\n");
			MakeSystemPages();
		}
		elsif ($arg1 eq '--listing' || $arg1 eq '-L') { #--listing #listing pages
			print ("recognized --listing\n");
			MakeListingPages();
		}
		elsif ($arg1 eq '--php') {
			print ("recognized --php\n");
			if (!GetConfig('admin/php/enable')) {
				print("warning: --php was used, but admin/php/enable is false\n");
			}
			MakePhpPages();
		}
		elsif ($arg1 eq '--js') {
			print ("recognized --js\n");
			MakeJsPages();
		}
		elsif ($arg1 eq '--settings') {
			print ("recognized --settings\n");
			#my $settingsPage = GetSettingsPage();
			#PutHtmlFile('settings.html', $settingsPage);
			MakeSimplePage('settings');
			PutStatsPages();
		}
		elsif ($arg1 eq '--tags') {
			print ("recognized --tags\n");
			MakePage('tags');
		}
		elsif ($arg1 eq '--write') {
			print ("recognized --write\n");

			#MakeSimplePage('write');
			require_once('page/write.pl');
			my $submitPage = GetWritePage();
			PutHtmlFile("write.html", $submitPage);

			if (GetConfig('admin/php/enable')) {
				# create write_post.html for longer messages if admin/php/enable
				$submitPage =~ s/method=get/method=post/g;
				if (index(lc($submitPage), 'method=post') == -1) {
					$submitPage =~ s/\<form /<form method=post /g;
				}
				if (index(lc($submitPage), 'method=post') == -1) {
					$submitPage =~ s/\<form/<form method=post /g;
				}
				$submitPage =~ s/cols=32/cols=50/g;
				$submitPage =~ s/rows=9/rows=15/g;
				$submitPage =~ s/please click here/you're in the right place/g;
				PutHtmlFile("write_post.html", $submitPage);
			}

		}
		elsif ($arg1 eq '--data' || $arg1 eq '-i') {
			print ("recognized --data\n");
			MakePage('data');
		}
		elsif ($arg1 eq '--desktop' || $arg1 eq '-i') {
			print ("recognized --desktop\n");
			#PutHtmlFile('desktop.html', GetDesktopPage());
			MakeSimplePage('desktop');
		}
		elsif ($arg1 eq '--queue' || $arg1 eq '-Q') {
			print ("recognized --queue\n");
			BuildTouchedPages(); # -queue or -Q
		}
		elsif ($arg1 eq '--all' || $arg1 eq '-a') {
			print ("recognized --all\n");
			SqliteQuery("UPDATE task SET priority = priority + 1 WHERE task_type = 'page'");
			MakeSystemPages();
			MakeListingPages();
			MakeSummaryPages();
			BuildTouchedPages(); # --all
		}
		elsif ($arg1 eq '--export') {
			GetConfig('admin/php/enable', 'override', 0);
			GetConfig('admin/js/enable', 'override', 0);
			GetConfig('admin/pages/lazy_page_generation', 'override', 0);
			GetConfig('admin/expo_mode_edit', 'override', 0);
			print ("recognized --export\n");
			BuildStaticExportPages();
		}
		elsif ($arg1 eq '-M' || $arg1 eq '-m') { # makepage
			print ("recognized -M or -m\n");
			my $makePageArg = shift @foundArgs;
			#todo sanity check of $makePageArg
			if ($makePageArg) {
				if ($makePageArg eq 'compare') {
					require_once('page/compare.pl');

					my $itemA = shift @foundArgs;
					my $itemB = shift @foundArgs;

					if ($itemA && $itemB && IsItem($itemA) && IsItem($itemB)) {
						my $comparePage = GetComparePage($itemA, $itemB);
						print ("calling GetComparePage($itemA, $itemB)\n");
						PutHtmlFile('compare1.html', $comparePage);
					} else {
						print ("compare needs 2 items\n");
						#todo ...
					}
				} else {
					print ("calling MakePage($makePageArg)\n");
					MakePage($makePageArg);
				}
			} else {
				print("missing argument for -M\n");
			}
		}
		elsif ($arg1 eq '-D') { # dialog
			##### DIALOGS ######################
			##### DIALOGS ######################
			##### DIALOGS ######################
			##### DIALOGS ######################
			print ("recognized -D\n");
			my $makeDialogArg = shift @foundArgs;
			#todo sanity check of $makeDialogArg
			if ($makeDialogArg) {
				if ($makeDialogArg eq 'settings') {
					my $dialog = GetSettingsDialog();
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/settings.html', $dialog);
				}
				if ($makeDialogArg eq 'stats') {
					my $dialog = GetStatsTable();
					PutHtmlFile('dialog/stats.html', $dialog);
					print ("-D $makeDialogArg\n");
				}
				if ($makeDialogArg eq 'access') {
					my $dialog = GetAccessDialog();
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/access.html', $dialog);
				}
				if ($makeDialogArg eq 'write') {
					my $dialog = GetWriteForm();
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/write.html', '<form action="/post.html" method=GET id=compose name=compose target=_top>' . $dialog . '</form>');
				}
				if ($makeDialogArg eq 'read') {
					my $dialog = GetQueryAsDialog('read', 'Top Threads');
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/read.html', $dialog);
				}
				if ($makeDialogArg eq 'profile') {
					my $dialog = GetProfileDialog();
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/profile.html', $dialog);
				}
				if ($makeDialogArg eq 'help') {
					my $dialog = GetSimpleDialog('help');
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/help.html', $dialog);
				}
				if ($makeDialogArg eq 'threads') {
					my $dialog = GetQueryAsDialog('threads');
					print ("-D $makeDialogArg\n");
					$dialog = AddAttributeToTag($dialog, 'table', 'id', 'threads');
					PutHtmlFile('dialog/threads.html', $dialog);
				}
				if ($makeDialogArg eq 'welcome') {
					my $dialog = GetSimpleDialog('welcome');
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/welcome.html', $dialog);
				}
				if ($makeDialogArg eq 'authors') {
					my $dialog = GetQueryAsDialog('authors', 'Authors');
					print ("-D $makeDialogArg\n");
					PutHtmlFile('dialog/authors.html', $dialog);
				}

				#				elsif (IsItem($arg1)) {
#					print ("recognized item identifier\n");
#					MakePage('item', $arg1, 1);
#				}

				if (0) {
					# placeholder
				}
				elsif ($makeDialogArg =~ m/([0-9a-f]{8})/) {
					print ("-D (item_prefix)\n");
					my $dialog = GetItemTemplateFromHash($makeDialogArg);
					my $dialogPath = GetHtmlFilename($makeDialogArg);

					if ($dialog && $dialogPath) {
						PutHtmlFile('dialog/' . $dialogPath, $dialog);
					} else {
						WriteLog('warning');
					}
				}
				#				elsif (IsFingerprint($arg1)) {
				#					print ("recognized author fingerprint\n");
				#					MakePage('author', $arg1, 1);
				#				}
				elsif (substr($makeDialogArg, 0, 1) eq '#') { #hashtag top/like.html
					#todo sanity checks here
					print ("-D hash tag $makeDialogArg\n");

					my $hashTag = substr($makeDialogArg, 1);

					#todo sanity checks here

					my $query = GetTemplate('query/tag_dozen');
					my $queryLikeString = "'%,$hashTag,%'";
					$query =~ s/\?/$queryLikeString/;

					WriteLog('MakePage: $query = ' . $query); #todo removeme


					my $dialog = GetQueryAsDialog(
						$query,
						'#' . $hashTag
					); #todo sanity
					my $dialogPath = 'top/' . $hashTag . '.html';

					$dialog = AddAttributeToTag($dialog, 'table', 'id', 'top_' . $hashTag);

					if ($dialog && $dialogPath) {
						PutHtmlFile('dialog/' . $dialogPath, $dialog);
					} else {
						WriteLog('MakePage: warning: dialog: nothing returned for #' . $makeDialogArg);
					}
				}
				else {
					print 'huh... what kind of dialog is ' . $makeDialogArg . '?';
					print "\n";
				}

				#print ("calling MakePage($makePageArg)\n");
				#MakePage($makePageArg);
			} else {
				print("missing argument for -D\n");
			}
			##### DIALOGS ######################
			##### DIALOGS ######################
			##### DIALOGS ######################
			##### DIALOGS ######################
			##### DIALOGS ######################

		}
		else {
			print ("Available arguments:\n");
			print ("--summary or -s for all summary or system pages\n");
			print ("--system or -S for basic system pages\n");
			print ("--php for all php pages\n");
			print ("--queue or -Q for all pages in queue\n");
			print ("-M [page] to call MakePage\n");
			print ("-D [dialog] to make dialog page\n");
			print ("item id for one item's page\n");
			print ("author fingerprint for one item's page\n");
			print ("#tag for one tag's page\n");
			print ("YYYY-MM-DD for a date page\n");
		}
	}

	print "-------";
	print "\n";
	my @filesWrittenHtml = PutHtmlFile('report_files_written');
	for my $fileWritten (@filesWrittenHtml) {
		print $fileWritten;
		print "\n";
	}
	my @filesWritten = PutFile('report_files_written');
	for my $fileWritten (@filesWritten) {
		print $fileWritten;
		print "\n";
	}
	print "-------";
	print "\n";
	print "Total files written: ";
	print scalar(@filesWritten) + scalar(@filesWrittenHtml);
	print "\n";
}

##buggy
#my %configLookupList = GetConfig('get_memo'); #this gets a memo of all the lookups done with GetConfig() so far
##i know it is confusing to have a "method call" in the function's argument
#if (%configLookupList) {
#	print Dumper(keys(%configLookupList));
#}
print "\n";

1;
