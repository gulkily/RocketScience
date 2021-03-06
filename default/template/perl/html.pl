#!/usr/bin/perl -T

use strict;
use 5.010;
use utf8;

sub GetHtmlAvatar { # Returns HTML avatar from cache
	state %avatarMemo;

	# returns avatar suitable for comments
	my $key = shift;
	if (!$key) {
		return;
	}

	if (!IsFingerprint($key)) {
		return;
	}

	if ($avatarMemo{$key}) {
		WriteLog("GetHtmlAvatar: found in hash");
		return $avatarMemo{$key};
	}

	my $avatar = GetAvatar($key);
	if ($avatar) {
		if (-e 'html/author/' . $key) {
			my $avatarLink = GetAuthorLink($key);
			$avatarMemo{$key} = $avatar;
			return $avatarLink;
		}
	} else {
		return $key;
		#		return 'unregistered';
	}

	return $key;
	#	return 'unregistered';
}

sub GetHtmlFilename { # get the HTML filename for specified item hash
	# GetItemUrl GetItemHtmlLink { GetHtmlFilePath { #keywords
	# GetItemHtmlFilePath {
	# Returns 'ab/cd/abcdef01234567890[...].html'
	# -or- Slug-From-Item-Name.html
	#
	my $hash = shift;

	WriteLog("GetHtmlFilename()");

	if (!defined($hash) || !$hash) {
		if (WriteLog("GetHtmlFilename: warning: called without parameter")) {

			#my $trace = Devel::StackTrace->new;
			#print $trace->as_string; # like carp
		}

		return '';
	}

	WriteLog('GetHtmlFilename: $hash = ' . $hash);

	if (!IsItem($hash)) {
		WriteLog("GetHtmlFilename: warning: called with parameter that isn't a SHA-1. Returning.");
		#WriteLog("$hash");
		#
		# my $trace = Devel::StackTrace->new;
		# print $trace->as_string; # like carp

		return '';
	}

	#	my $htmlFilename =
	#		substr($hash, 0, 2) .
	#		'/' .
	#		substr($hash, 2, 8) .
	#		'.html';
	#


	# my $htmlFilename =
	# 	substr($hash, 0, 2) .
	# 	'/' .
	# 	substr($hash, 2, 2) .
	# 	'/' .
	# 	$hash .
	# 	'.html';
	#
	#
	my $htmlFilename = '';

	if (GetConfig('html/item_name_slug')) {
		my $itemName = DBGetItemAttribute($hash, 'name');

		WriteLog('GetHtmlFilename: item_name_slug: $itemName = ' . $itemName);

		if ($itemName) {
			my $slug = $itemName;
			$slug = str_replace(' ', '-', $slug);
			$slug =~ s/[^a-zA-Z0-9\-]//g;

			#todo sanity

			if ($slug) {
				$htmlFilename = $slug . '.html';
			}
		} # if ($itemName)
	} # if (GetConfig('html/item_name_slug'))

	if (!$htmlFilename) {
		# fallback and default in one
		$htmlFilename =
			substr($hash, 0, 2) .
				'/' .
				substr($hash, 2, 2) .
				'/' .
				substr($hash, 0, 8) .
				'.html';
	}

	WriteLog('GetHtmlFilename: returning: $htmlFilename = ' . $htmlFilename);

	return $htmlFilename;
} # GetHtmlFilename()

sub AddAttributeToTag { # $html, $tag, $attributeName, $attributeValue; adds attr=value to html tag;
# sub AddTagAttribute {
	my $html = shift; # chunk of html to work with
	my $tag = shift; # tag we'll be modifying
	my $attributeName = shift; # name of attribute
	my $attributeValue = shift; # value of attribute

	my $lengthBefore = length($html);

	WriteLog("AddAttributeToTag(\$html, $tag, $attributeName, $attributeValue)");
	WriteLog('AddAttributeToTag: length($html) $lengthBefore: ' . $lengthBefore);

	my $tagAttribute = '';
	if ($attributeValue eq '') {
		$tagAttribute = $attributeName;
	}
	elsif ($attributeValue =~ m/\s/ || index($attributeValue, "'") != -1 || index($attributeValue, '(') != -1 || index($attributeValue, ')') != -1) {
		# attribute value contains whitespace, must be enclosed in double quotes
		$tagAttribute = $attributeName . '="' . $attributeValue . '"';
	}
	else {
		$tagAttribute = $attributeName . '=' . $attributeValue . '';
	}

	my $htmlBefore = $html;
	$html = str_ireplace('<' . $tag . ' ', '<' . $tag . ' ' . $tagAttribute . ' ', $html);
	if ($html eq $htmlBefore) {
		$html = str_ireplace('<' . $tag . '', '<' . $tag . ' ' . $tagAttribute . ' ', $html);
	}
	if ($html eq $htmlBefore) {
		$html = str_ireplace('<' . $tag . '>', '<' . $tag . ' ' . $tagAttribute . '>', $html);
	}
	if ($html eq $htmlBefore) {
		WriteLog('AddAttributeToTag: warning: nothing was changed; $tag = ' . $tag . '; $attributeName = ' . $attributeName . '; caller = ' . join (',', caller));
	}

	my $lengthAfter = length($html);

	if ($lengthBefore == $lengthAfter) {
		WriteLog('AddAttributeToTag: warning: $lengthBefore == $lengthAfter = ' . $lengthAfter . '; caller = ' . join (',', caller));
	}

	return $html;
} # AddAttributeToTag()

sub RemoveHtmlFile { # $file ; removes existing html file
# returns 1 if file was removed
	my $file = shift;
	if (!$file) {
		return 0;
	}
	if ($file eq 'index.html') {
		# do not remove index.html
		# temporary measure until caching is fixed
		# also needs a fix for lazy html, because htaccess rewrite rule doesn't catch it
		return 0;
	}

	my $HTMLDIR = './html'; #todo

	my $fileProvided = $file;
	$file = "$HTMLDIR/$file";

	if (
		$file =~ m/^([0-9A-Za-z\/.]+)$/
			&&
		index($file, '..') == -1
	) {
		# sanity check passed
		WriteLog('RemoveHtmlFile: sanity check passed for $file = ' . $file);
	 	$file = $1;
		if (-e $file) {
			unlink($file);
		}
	} else {
		WriteLog('RemoveHtmlFile: warning: sanity check failed, $file = ' . $file);
		return '';
	}
} # RemoveHtmlFile()


1;
