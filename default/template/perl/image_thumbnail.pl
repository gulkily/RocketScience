#!/usr/bin/perl -T

use strict;
use warnings;
use 5.010;

sub ImageMakeThumbnails {

	my $file = shift;
	chomp $file; #todo sanity

	my $fileHash = GetFileHash($file);
	if (!$fileHash) {
		WriteLog('warning');
		return '';
	}

	# # make 1024x1024 thumbnail
	# if (!-e "$HTMLDIR/thumb/thumb_1024_$fileHash.gif") {
	# 	my $convertCommand = "convert \"$file\" -thumbnail 1024x1024 -strip $HTMLDIR/thumb/thumb_1024_$fileHash.gif";
	# 	WriteLog('IndexImageFile: ' . $convertCommand);
	#
	# 	my $convertCommandResult = `$convertCommand`;
	# 	WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
	# }

	my $fileShellEscaped = EscapeShellChars($file); #todo this is still a hack, should rename file if it has shell chars?

	if ($fileShellEscaped =~ m/(.+)/) { #todo #security
		$fileShellEscaped = $1;
	} else {
		WriteLog('IndexImageFile: warning: sanity check failed on $fileShellEscaped!');
		return '';
	}

	# make 800x800 thumbnail
	state $HTMLDIR = GetDir('html');

	if ($HTMLDIR =~ m/(.+)/) { #todo #security
		$HTMLDIR = $1;
	} else {
		WriteLog('IndexImageFile: warning: sanity check failed on $HTMLDIR!');
		return '';
	}


	if ($fileHash =~ m/(.+)/) { #todo #security
		$fileHash = $1;
	} else {
		WriteLog('IndexImageFile: warning: sanity check failed on $fileHash');
		return '';
	}


	#imagemagick

	#my @res = qw(800 512 42);
	if (!-e "$HTMLDIR/thumb/thumb_800_$fileHash.gif") {
		my $convertCommand = "convert \"$fileShellEscaped\" -thumbnail 800x800 -strip $HTMLDIR/thumb/thumb_800_$fileHash.gif";
		WriteLog('IndexImageFile: ' . $convertCommand);

		my $convertCommandResult = `$convertCommand`;
		WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);

		#sub DBAddTask { # $taskType, $taskName, $taskParam, $touchTime # make new task

	}
#			if (!-e "$HTMLDIR/thumb/squared_800_$fileHash.gif") {
#				my $convertCommand = "convert \"$fileShellEscaped\" -crop 800x800 -strip $HTMLDIR/thumb/squared_800_$fileHash.gif";
#				WriteLog('IndexImageFile: ' . $convertCommand);
#
#				my $convertCommandResult = `$convertCommand`;
#				WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
#			}
	if (!-e "$HTMLDIR/thumb/thumb_512_g_$fileHash.gif") {
		my $convertCommand = "convert \"$fileShellEscaped\" -thumbnail 512x512 -colorspace Gray -blur 0x16 -strip $HTMLDIR/thumb/thumb_512_g_$fileHash.gif";
		#my $convertCommand = "convert \"$fileShellEscaped\" -scale 5% -blur 0x25 -resize 5000% -colorspace Gray -blur 0x8 -thumbnail 512x512 -strip $HTMLDIR/thumb/thumb_512_$fileHash.gif";
		WriteLog('IndexImageFile: ' . $convertCommand);

		my $convertCommandResult = `$convertCommand`;
		WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
	}
	if (!-e "$HTMLDIR/thumb/thumb_512_$fileHash.gif") {
		my $convertCommand = "convert \"$fileShellEscaped\" -thumbnail 512x512 -strip $HTMLDIR/thumb/thumb_512_$fileHash.gif";
		#my $convertCommand = "convert \"$fileShellEscaped\" -scale 5% -blur 0x25 -resize 5000% -colorspace Gray -blur 0x8 -thumbnail 512x512 -strip $HTMLDIR/thumb/thumb_512_$fileHash.gif";
		WriteLog('IndexImageFile: ' . $convertCommand);

		my $convertCommandResult = `$convertCommand`;
		WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
	}
#			if (!-e "$HTMLDIR/thumb/squared_512_$fileHash.gif") {
#				my $convertCommand = "convert \"$fileShellEscaped\" -crop 512x512 -strip $HTMLDIR/thumb/squared_512_$fileHash.gif";
#				WriteLog('IndexImageFile: ' . $convertCommand);
#
#				my $convertCommandResult = `$convertCommand`;
#				WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
#			}
	if (!-e "$HTMLDIR/thumb/thumb_42_$fileHash.gif") {
		my $convertCommand = "convert \"$fileShellEscaped\" -thumbnail 42x42 -strip $HTMLDIR/thumb/thumb_42_$fileHash.gif";
		WriteLog('IndexImageFile: ' . $convertCommand);

		my $convertCommandResult = `$convertCommand`;
		WriteLog('IndexImageFile: convert result: ' . $convertCommandResult);
	}
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
}

1;