#!/usr/bin/perl -T

use strict;
use warnings;

#todo this is the first version, and is sub-optimal

sub GetThreadListing { # $topLevel, $selectedItem, $indentLevel, $itemsListReference
	my $topLevel = shift; #todo sanity
	my $selectedItem = shift || '';
	my $indentLevel = shift || 0;
	my $itemsListReference = shift; # reference to array of all items included in thread listing

	my @itemInfo = SqliteQueryHashRef("SELECT * FROM item_flat WHERE file_hash = '$topLevel' LIMIT 1");
	shift @itemInfo; # headers

	if (@itemInfo) {
		#most basic sanity check passed
	} else {
		# @itemInfo is false
			WriteLog('GetThreadListing: warning: @itemInfo is FALSE; $topLevel = ' . $topLevel . '; caller = ' . join(',', caller));
		return '';
	}

	my %topLevelItem = %{$itemInfo[0]}; # first row

	if ($itemsListReference) {
		push @{$itemsListReference}, $topLevel;
	}

	my $itemTitle = $topLevelItem{'item_title'};
	my $itemTime = $topLevelItem{'add_timestamp'};

	my $listing = '';

	my @itemChildren = SqliteQueryHashRef("SELECT item_hash FROM item_parent WHERE parent_hash = '$topLevel'");
	shift @itemChildren;

	# if (@itemChildren) {
	# 	$listing .= '<details open><summary>';
	# }
	#
	if ($topLevel eq $selectedItem) {
		$listing .= '<tr bgcolor="' . GetThemeColor('highlight_alert') . '">';
	} else {
		$listing .= '<tr>';
	}
	$listing .= '<td>';

	$listing .= '&nbsp; &nbsp; ' x $indentLevel;

	$listing .= GetItemHtmlLink($topLevel, $itemTitle);

	$listing .= '</td>';

	$listing .= '<td>';
	if ($itemTime) {
		#$listing .= '; ';
		$listing .= GetTimestampWidget($itemTime);
	}
	#$listing .= "<br>";
	$listing .= '</td>';
	$listing .= '</tr>';

	#
	# if (@itemChildren) {
	# 	$listing .= '</summary>';
	# }

	#my %queryParams;
	#$queryParams{'where_clause'} = "WHERE file_hash != '$topLevel' AND file_hash IN (SELECT file_hash FROM item_parent WHERE parent_hash = '$topLevel')"; #todo sanity
	#my @itemChildren = DBGetItemList(\%queryParams);
	if (@itemChildren) {
		for my $refChild (@itemChildren) {
			my %itemChild = %{$refChild};
			my $itemHash = $itemChild{'item_hash'};
			if ($itemsListReference) {
				push @{$itemsListReference}, $itemHash;
			}

			$listing .= GetThreadListing($itemHash, $selectedItem, $indentLevel + 1, $itemsListReference);
			#$listing .= $itemHash;
		}
		# $listing .= '</details>';
	} else {
		if ($indentLevel == 0) {
			$listing = '';
		}
	}

	return $listing;
} # GetThreadListing()

1;
