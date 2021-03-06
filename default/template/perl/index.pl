#!/usr/bin/perl -T
#freebsd: #!/usr/local/bin/perl -T

# indexes one file or all files eligible for indexing
# --all .... all eligible files
# [path] ... index specified file
# --chain .. chain.log file (contains timestamps)

use strict;
use warnings;
use utf8;
use 5.010;
#use HTML::Entities qw(decode_entities);

my @argsFound;
while (my $argFound = shift) {
	push @argsFound, $argFound;
}

use Digest::SHA qw(sha512_hex);
use POSIX qw(floor);

#use threads ('yield',
#             'stack_size' => 64*4096,
#             'exit' => 'threads_only',
#             'stringify');

require('./utils.pl');
require_once('gpgpg.pl');
require_once('sqlite.pl');
require_once('index_text_file.pl');
require_once('chain.pl');

sub IndexHtmlFile { # $file | 'flush' ; indexes one text file into database
# DRAFT
# DRAFT
# DRAFT
# DRAFT
# DRAFT
	state $SCRIPTDIR = GetDir('script');
	state $HTMLDIR = GetDir('html');
	state $TXTDIR = GetDir('txt');

	my $file = shift;
	chomp($file);

	if ($file eq 'flush') {
		IndexTextFile('flush');
	}

	my $html = GetFile($file);
	my @matches;

	print length($html)."\n";

	$html =~ s/\<span[^>]+\>/<span>/g;

	print length($html)."\n";

	sleep 3;

	while ($html =~/(?<=<span>)(.*?)(?=<\/span>)/g) {
	  push @matches, $1;
	}

	foreach my $m (@matches) {
		print trim($m), "\n===\n";
		#todo htmldecode

		$m = str_replace('<p>', "\n\n", $m);
		#$m = decode_entities($m);
		my $mHash = sha1_hex($m);
		my $mFilename = GetPathFromHash($mHash);
		PutFile($mFilename, $m);
	}

	#if ($html =~ m/<span.+>(.+)<\/span>/g) {
		#print Dumper($1);
		#print ';-)';
#		print "Word is $1, ends at position ", pos $x, "\n";
		sleep 3;
	#}#

	sleep 3;
} # IndexHtmlFile()

sub uniq { # @array ; return array without duplicate elements
# copied from somewhere like perlmonks
	my %seen;
	grep !$seen{$_}++, @_;
}

sub IndexImageFile { # $file ; indexes one image file into database
	# Reads a given $file, gets its attributes, puts it into the index database
	# If ($file eq 'flush), flushes any queued queries
	# Also sets appropriate task entries

	if (!GetConfig('setting/admin/convert/enable')) {
		WriteLog('IndexImageFile: warning: called when convert/enable is false');
		#todo deal with it better
	}

	my $file = shift;
	chomp($file);

	if ($file =~ m/\s/) {
		WriteLog('IndexImageFile: warning: sanity check failed, $file contains space character, which is not allowed');
		return 0;
	}

	if ($file =~ m/^([0-9a-zA-Z.\/_\-:]+)$/) { #todo bug here?
		if ($1 eq $file) {
			$file = $1;
		} else {
			WriteLog('IndexImageFile: warning: sanity check 2 failed on $file: ' . $file);
			return 0;
		}
	} else {
		WriteLog('IndexImageFile: warning: sanity check 1 failed on $file: ' . $file);
		return 0;
	}

	WriteLog("IndexImageFile($file)");

	if ($file eq 'flush') {
		WriteLog("IndexImageFile(flush)");
		DBAddItemAttribute('flush');
		DBAddItem('flush');
		DBAddVoteRecord('flush');
		DBAddPageTouch('flush');

		return 1;
	}

	#my @tagFromFile;
	#my @tagsFromFile;
	my @tagFromPath;

	my $addedTime;          # time added, epoch format
	my $fileHash;            # git's hash of file blob, used as identifier

	if (IsImageFile($file)) {
		my $fileHash = GetFileHash($file);

		if (GetCache('indexed/'.$fileHash)) {
			WriteLog('IndexImageFile: skipping because of flag: indexed/'.$fileHash);
			return $fileHash;
		}

		WriteLog('IndexImageFile: $fileHash = ' . ($fileHash ? $fileHash : '--'));

		$addedTime = DBGetAddedTime($fileHash);
		# get the file's added time.

		# debug output
		WriteLog('IndexImageFile: $file = ' . ($file?$file:'false'));
		WriteLog('IndexImageFile: $fileHash = ' . ($fileHash?$fileHash:'false'));
		WriteLog('IndexImageFile: $addedTime = ' . ($addedTime?$addedTime:'false'));

		# if the file is present in deleted.log, get rid of it and its page, return
		if (IsFileDeleted($file, $fileHash)) {
			# write to log
			WriteLog('IndexImageFile: IsFileDeleted() returned true, returning');
			return 0;
		}

		if (!$addedTime) {
			WriteLog('IndexImageFile: file missing $addedTime');
			if (GetConfig('admin/logging/write_chain_log')) {
				$addedTime = AddToChainLog($fileHash);
			} else {
				$addedTime = GetTime();
			}
			if (!$addedTime) {
				# sanity check
				WriteLog('IndexImageFile: warning: sanity check failed for $addedTime');
				$addedTime = GetTime();
			}
		}

		my $itemName = TrimPath($file);

		require_once('image_thumbnail.pl');
		ImageMakeThumbnails($file);

		DBAddItem($file, $itemName, '', $fileHash, 'image', 0);
		DBAddItem('flush');
		#DBAddItemAttribute($fileHash, 'title', $itemName, $addedTime);
		#DBAddItemAttribute($fileHash, 'title', $itemName, time()); #todo time should come from actual file time #todo re-add this
		DBAddVoteRecord($fileHash, $addedTime, 'image'); # add image tag

		if (@tagFromPath) {
			foreach my $tag (@tagFromPath) {
				DBAddVoteRecord($fileHash, $addedTime, $tag);
			}
		}

		DBAddPageTouch('read');
		DBAddPageTouch('tag', 'image');
		DBAddPageTouch('item', $fileHash);
		DBAddPageTouch('stats');
		DBAddPageTouch('rss');
		DBAddPageTouch('index');
		DBAddPageTouch('flush');
		DBAddPageTouch('compost');
		DBAddPageTouch('chain');

		return $fileHash;
	}
} # IndexImageFile()

sub MakeIndex { # indexes all available text files, and outputs any config found
	WriteLog( "MakeIndex()...\n");

	state $TXTDIR = GetDir('txt');
	WriteLog('MakeIndex: $TXTDIR = ' . $TXTDIR);

	#my @filesToInclude = split("\n", `grep txt\$ ~/index/home.txt`); #homedir #~
	#my @filesToInclude = split("\n", `find $TXTDIR -name \\\*.txt -o -name \\\*.html`); #includes html files #indevelopment
	my @filesToInclude = split("\n", `find $TXTDIR -name \\\*.txt`);

	my $filesCount = scalar(@filesToInclude);
	my $currentFile = 0;
	foreach my $file (@filesToInclude) {
		#$file =~ s/^./../;

		$currentFile++;
		my $percent = floor(($currentFile / $filesCount) * 100);
		my $printedFilename = str_replace($TXTDIR . '/', '', $file);
		WriteMessage("[$percent%] $currentFile/$filesCount  $printedFilename");
		IndexFile($file); # aborts if cache/.../indexed/filehash exists
	}
	IndexFile('flush');

	#WriteIndexedConfig(); # MakeIndex

	if (GetConfig('admin/image/enable')) {
		state $HTMLDIR = GetDir('html');

		my @imageFiles = split("\n", `find $HTMLDIR/image`);
		my $imageFilesCount = scalar(@imageFiles);
		my $currentImageFile = 0;
		WriteLog('MakeIndex: $imageFilesCount = ' . $imageFilesCount);

		foreach my $imageFile (@imageFiles) {
			$currentImageFile++;
			my $percentImageFiles = floor($currentImageFile / $imageFilesCount * 100);
			WriteMessage("[$percentImageFiles%] $currentImageFile/$imageFilesCount  $imageFile");
			#WriteMessage("*** MakeIndex: $currentImageFile/$imageFilesCount ($percentImageFiles %) $imageFile");
			IndexImageFile($imageFile);
		}

		IndexImageFile('flush');
	} # admin/image/enable
} # MakeIndex()

sub DeindexMissingFiles { # remove from index data for files which have been removed
# takes no parameters
#
	# get all items in database
	my %queryParams = ();
	my @items = DBGetItemList(\%queryParams);
	my $itemsDeletedCount = 0;

	WriteLog('DeindexMissingFiles scalar(@items) is ' . scalar(@items));
	WriteMessage("Checking for deleted items... ");

	#print Dumper(@items);

	if (@items) {
		# for each of the items, check if the file still exists
		foreach my $item (@items) {

			if ($item->{'file_path'}) {
				if (!-e $item->{'file_path'}) {
					# if file does not exist, remove its references
					WriteLog('DeindexMissingFiles: Found a missing text file, removing references. ' . $item->{'file_path'});
					DBDeleteItemReferences($item->{'file_hash'});
					$itemsDeletedCount++;
				}
			}
		}

		if ($itemsDeletedCount) {
			# if any files were de-indexed, report this, and pause for 3 seconds to inform operator
			WriteMessage('DeindexMissingFiles: deleted items found and removed: ' . $itemsDeletedCount);
			#WriteIndexedConfig(); # DeindexMissingFiles()
			WriteMessage(`sleep 2`);
		}
	}

	return $itemsDeletedCount;
} # DeindexMissingFiles()

sub IndexFile { # $file ; calls IndexTextFile() or IndexImageFile() based on extension
	my $file = shift;

	my $flagsReference = shift;
	my %flags;
	if ($flagsReference) {
		%flags = %{$flagsReference};
	}

	if ($file eq 'flush') {
		WriteLog('IndexFile: flush was requested');
		IndexImageFile('flush');
		IndexTextFile('flush');
		return '';
	}

	if (!$file) {
		WriteLog('IndexFile: warning: $file is FALSE');
		return '';
	}

	chomp $file;

	WriteLog('IndexFile: $file = ' . $file);
	if (!-e $file) {
		WriteLog('IndexFile: warning: -e $file is false (file does not exist)');
		return '';
	}
	if (-d $file) {
		WriteLog('IndexFile: warning: -d $file was true (file is a directory)');
		return '';
	}

#this causes bug
#	if ($file =~ m/([0-9a-f]{40})/) {
#		#attempted optimization of next block
#		my $fileHash = $1;
#		if (-e "./cache/b/indexed/$fileHash" || GetCache("indexed/$fileHash")) {
#			WriteLog('IndexFile: aleady indexed, returning. $fileHash = ' . $fileHash);
#			return $fileHash;
#		}
#	}

	my $fileHashFromFilename = '';
	if ($file =~ m/([0-9a-f]{40})/) {
		my $simpleHash = $1;
		my $cachedFilename = GetCache('indexed/' . $1);

		if ($cachedFilename) {
			WriteLog('IndexFile: found hash in filename; $simpleHash = ' . $simpleHash);
			WriteLog('IndexFile: found hash in filename; $cachedFilename = ' . $cachedFilename);
			WriteLog('IndexFile: found hash in filename; $file = ' . $file);

			if ( index( $cachedFilename , $file ) != -1 ) {
				WriteLog('IndexFile: found hash in filename: already indexed, returning. $simpleHash = ' . $simpleHash);
				return $simpleHash;
			} else {
				WriteLog('IndexFile: found hash in filename: NOT indexed, continuing. $simpleHash = ' . $simpleHash);
			}
		}
	}

	my $fileHash = GetFileHash($file);
	
	if (GetCache('indexed/' . $fileHash)) {
		if (trim(GetCache('indexed/' . $fileHash)) eq $file) {
			WriteLog('IndexFile: already indexed, returning. $fileHash = ' . $fileHash);
			return $fileHash;
		} else {
			#return $fileHash; #who does that?#todo
			WriteLog('IndexFile: already indexed, but from different path. continuing. $fileHash = ' . $fileHash);
			if (GetConfig('admin/organize_files') && !$flags{'skip_organize'}) {
				WriteLog('IndexFile: calling OrganizeFile() with $fileHash = ' . $fileHash);
				$file = OrganizeFile($file);
			}
		}
	}

	my $indexSuccess = 0;

	my $ext = lc(GetFileExtension($file));

	# THREADS MODE IS NOT FINISHED
	# DO NOT CHANGE THIS UNLESS YKWYD
	my $useThreads = 0;
	# IF TURNING ON, UNCOMMENT 'use' STATEMENT
	# AT THE TOP OF THIS FILE AS WELL

	if ($ext eq 'txt') {
		WriteLog('IndexFile: calling IndexTextFile()');

		if ($useThreads) {
			my $thr = threads->create('IndexTextFile', $file);
			$indexSuccess = $thr->join();
			$indexSuccess = 1;
		} else {
			$indexSuccess = IndexTextFile($file); #IndexFile()
		}

		if (!$indexSuccess) {
			WriteLog('IndexFile: warning: IndexTextFile: $indexSuccess was FALSE');
			$indexSuccess = 0;
		}

		if (GetConfig('setting/admin/index/add_dir_as_hashtag')) {
			my $fileLocalPath = $file;
			$fileLocalPath = str_replace(GetDir('txt'), '', $file);
			$fileLocalPath = substr($fileLocalPath, 0, rindex($fileLocalPath, '/')); #just the path
			my @dirTags = split('/', $fileLocalPath);
			if (@dirTags) {
				foreach my $dirTag (@dirTags) {
					$dirTag = trim($dirTag);
					if ($dirTag =~ m/([0-9a-zA-Z_-]+)/ && length($dirTag) > 2) {
						$dirTag = $1;
						DBAddVoteRecord($fileHash, 0, $dirTag);
					} else {
						WriteLog('IndexFile: warning: $dirTag failed sanity check; $dirTag = ' . $dirTag);
					}
				}
			}

			WriteLog('IndexFile: add_dir_as_hashtag: $fileLocalPath = ' . $fileLocalPath);

		}

	}

	if (0 && $ext eq 'html') { #todo enable once IndexHtmlFile() is better
		WriteLog('IndexFile: calling IndexHtmlFile()');
		$indexSuccess = IndexHtmlFile($file);

		if (!$indexSuccess) {
			WriteLog('IndexFile: warning: IndexHtmlFile $indexSuccess was FALSE');
			$indexSuccess = 0;
		}
	}

	if (
		$ext eq 'png' ||
		$ext eq 'gif' ||
		$ext eq 'jpg' ||
		$ext eq 'jpeg' ||
		$ext eq 'bmp' ||
		$ext eq 'svg' ||
		$ext eq 'webp' ||
		$ext eq 'jfif' ||
		$ext eq 'tiff' ||
		$ext eq 'tff'
	) {
		WriteLog('IndexFile: calling IndexImageFile()');
		$indexSuccess = IndexImageFile($file);
	}

	if ($indexSuccess) {
		WriteLog('IndexFile: $indexSuccess = ' . $indexSuccess);
	} else {
		WriteLog('IndexFile: warning: $indexSuccess FALSE; $file = ' . $file . '; caller = ' . join(',', caller));
	}

	if ($indexSuccess) {
		if (-e $file) {
	 		if (GetConfig('admin/index/stat_file')) { #todo put all the other pieces of this here
				my @fileStat = stat($file);
				my $fileSize =    $fileStat[7]; #file size
				my $fileModTime = $fileStat[9];
				WriteLog('IndexFile: $fileModTime = ' . $fileModTime . '; $fileSize = ' . $fileSize);
				if ($fileModTime) {
					if (IsItem($indexSuccess)) {
						DBAddItemAttribute($indexSuccess, 'file_m_timestamp', $fileModTime);
						DBAddItemAttribute($indexSuccess, 'file_size', $fileSize);
					} else {
						WriteLog('IndexFile: warning: IsItem($indexSuccess) was FALSE');
					}
				}
			}

			if (GetConfig('admin/index/index_local_path_as_attribute')) {
				use Cwd 'abs_path';
				my $absPath = abs_path($file);

				if ($file) {
					DBAddItemAttribute($indexSuccess, 'local_path', $absPath);
				} else {
					WriteLog('IndexFile: warning: tried to get $absPath, got FALSE; $file = ' . $file . '; caller = ' . join(',', caller));
				}
			}

	 		if (GetConfig('admin/index/add_git_hash_file')) {
	 			#todo sanity check before running shell command #security
	 			if ($file =~ m/^([0-9a-z.\/_]+)/) {
	 				$file = $1;

					my $gitHash = `git hash-object $file`;
					if ($gitHash) {
						DBAddItemAttribute($indexSuccess, 'git_hash_object', $gitHash);
					} else {
						WriteLog('IndexFile: warning: $gitHash returned false');
					}
				} else {
					WriteLog('IndexFile: warning: add_git_hash_file, $file failed sanity check');
				}
	 		}
		}
	}

	if ($indexSuccess) {
		PutCache('indexed/' . $indexSuccess, $file);
	} else {
		WriteLog('IndexFile: warning: $indexSuccess is FALSE; $file = ' . $file);
	}

	return $indexSuccess;
} # IndexFile()

sub SweepDeleted {
	my %queryParams;
	my @files = DBGetItemList(\%queryParams);

	my $itemsDeletedCounter = 0;
	
	my @deletedHash;

	foreach my $file (@files) {
		my $fileName = $file->{'file_path'};
		my $fileHash = $file->{'file_hash'};

		WriteMessage($fileHash . ' = ' . $fileName);
		
		if (IsFileDeleted($fileName, $fileHash)) {
			WriteMessage('Found deleted item: $fileHash = ' . $fileHash);
			push @deletedHash, $fileHash;
			
			if (scalar(@deletedHash) > 100) {
				DBDeleteItemReferences(@deletedHash);
				@deletedHash = ();
			}
			
			$itemsDeletedCounter++;
		}
	}
	if (@deletedHash) {
		DBDeleteItemReferences(@deletedHash);
	}
	
	my @attribs = SqliteQueryHashRef(
		"select value, file_hash from item_attribute where attribute = 'file_path';"
	);
	shift @attribs; # first one is headers

	state $htmlDir1 = GetDir('html'); #todo is txt always under html? only for now
	
	foreach my $file (@attribs) {
		my $fileName = $file->{'value'};
		my $fileHash = $file->{'file_hash'};
		
		if ( ! -e $htmlDir1 . $fileName) {
			WriteMessage('Found missing file in attribute: $fileName = ' . $fileName);
			my $query1 = "Delete from item_attribute WHERE value = ? AND file_hash = ?";
			my @qParams1;
			push @qParams1, $fileName;
			push @qParams1, $fileHash;
			SqliteQuery($query1, @qParams1);
			$itemsDeletedCounter++;
		}
	}

	WriteMessage('Total deleted items found: ' . $itemsDeletedCounter);

	#if ($itemsDeletedCounter) {
		DeindexMissingFiles();
	#}

} # SweepDeleted()

my $flagNoCache = 0; # GetCache('indexed/' . $fileHash)

my $didSomething = 0;

sub PrintHelp {
	print "index.pl: --clear-cache\n";
	print "index.pl: --all\n";
	print "index.pl: --sweep\n";
	print "index.pl: --chain\n";
	#print "index.pl: --write-indexed-config (-C) calls WriteIndexedConfig\n";
}

while (my $arg1 = shift @argsFound) {
	WriteLog('index.pl: $arg1 = ' . $arg1);
	if ($arg1) {
		$arg1 = trim($arg1);

		$didSomething++;
		if ($arg1 eq '--help') {
			print "index.pl: --help\n";
			PrintHelp();
		}
		if ($arg1 eq '--no-cache') {
			print "index.pl: --no-cache\n";
			$flagNoCache = 1;
		}
		if ($arg1 eq '--clear-cache') {
			print "index.pl: --clear-cache\n";
			print `rm -vrf cache/b/indexed/*`;
		}
		if ($arg1 eq '--all') {
			print "index.pl: --all\n";
			MakeIndex();
			print "=========================\n";
			print "index.pl: --all finished!\n";
			print "=========================\n";
		}
		if ($arg1 eq '--sweep') {
			# sweep deleted files
			print "index.pl: --sweep\n";
			SweepDeleted();
		}
		if ($arg1 eq '--chain') {
			# html/chain.log
			print "index.pl: --chain\n";
			if (GetConfig('admin/read_chain_log')) {
				MakeChainIndex(); # index.pl --chain
			} else {
				print "index.pl: MakeChainIndex() SKIPPED because of config/admin/read_chain_log = FALSE\n";
				print "index.pl: MakeChainIndex() SKIPPED because of config/admin/read_chain_log = FALSE\n";
				print "index.pl: MakeChainIndex() SKIPPED because of config/admin/read_chain_log = FALSE\n";
			}
		}
		if ($arg1 eq '--squash-chain' || $arg1 eq '-S') {
			# html/chain.log
			print "index.pl: --squash-chain -S\n";
			if (GetConfig('admin/read_chain_log')) {
				SquashChain(); # index.pl --squash-chain
			} else {
				print "index.pl: SquashChain() SKIPPED because of config/admin/read_chain_log = FALSE\n";
				print "index.pl: SquashChain() SKIPPED because of config/admin/read_chain_log = FALSE\n";
				print "index.pl: SquashChain() SKIPPED because of config/admin/read_chain_log = FALSE\n";
			}
		}
#		if ($arg1 eq '--write-indexed-config' || $arg1 eq '-C') {
#			# sweep deleted files
#			print "index.pl: --write-indexed-config (-C) calls WriteIndexedConfig()\n";
#			WriteIndexedConfig(); # index.pl '--write-indexed-config'
#		}
		if (-e $arg1) {
			my $fileHash = GetFileHash($arg1);
			if ($fileHash && $flagNoCache) {
				if (GetCache('indexed/' . $fileHash)) {
					print "Removing indexed marker\n";
					#UnlinkCache("indexed/$fileHash");
				}
			}
			WriteMessage("IndexFile($arg1) " . '(' . scalar(@argsFound) . ' left)');

			my $indexFileResult = IndexFile($arg1);

			WriteMessage("IndexFile($arg1) result: $indexFileResult");

			my $htmlFilename = GetHtmlFilename($indexFileResult);

			#WriteMessage("IndexFile($arg1) returned: http://localhost:2784/" . $htmlFilename);
			IndexFile('flush');
		}
		else {
			WriteMessage("index.pl: what is $arg1");
			PrintHelp();
		}
	}
}

if (!$didSomething) {
	PrintHelp();
}

print "\n";

1;
