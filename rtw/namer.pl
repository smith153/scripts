#!/bin/perl -w
use strict;
use MP3::Tag;
use File::Copy;
use DateTime::Format::Strptime;

#Renames files to the proper yyyymmdd format from something like "tues, 04 jul 2012
#writes mp3 tags as well
#written on 20120710




my $i = 1;
my $date = "";
my $file = "";
my $title = "";
my $description = "";
my $album = "Running to Win";
my $artist = "Erwin Lutzer";
my $mp3;
my $id3v2;

open(MYINPUTFILE, "<mirror2.txt");

#date format 
my $strp = DateTime::Format::Strptime->new(
	pattern   => '%d %b %Y',
);


while(<MYINPUTFILE>){


	my($line) = $_;
	chomp($line);
	
	#date
	if ( $i == 1 ){
		#convert to date like: 20120701
		#rip out days
		$line =~ s/sun|mon|tue|wed|thu|fri|sat//i;
		$line =~ s/^\s+//;
		my $dt = $strp->parse_datetime($line);
		$date = $dt->strftime("%Y%m%d");
	}
	#file name
	if ( $i == 2 ){
		#copy file to new file with date as filename
		#return new filename
		$line = &createFile($line, $date);

		$title = $line;
		print "Writing to: $line\n";
		$mp3 = MP3::Tag->new("$line");
		$mp3->delete_tag("ID3v1");
		$mp3->delete_tag("ID3v2");
		$id3v2 = $mp3->new_tag("ID3v2");
	}
	#title
	if ( $i == 3 ){
		#rip out ".mp3" and use date as first part of title
		$title =~ s/\.\w+$//;
		$id3v2->add_frame("TIT2", "$title $line");
	}
	#desc
	if ( $i == 4 ){
		$id3v2->add_frame("COMM", "ENG", "Description", "$line");

	}

	$i++;

	if($i > 4){
		$i = 1;
		$date = "";
		$file = "";
		$title = "";
		$description = "";
		$id3v2->add_frame("TALB","$album");
		$id3v2->add_frame("TPE1","$artist");
		$id3v2->write_tag();

	}
}

sub createFile
{
  my ($oldName, $date) = @_;
  my $newName = "rtw" . $date . ".mp3";
  my $i = 1;
  #build a filename that isn't used already
  while(-e $newName){
	$newName =~ s/_\d+//;
	$newName =~ s/\.mp3//;
	$newName = $newName . "_$i" . ".mp3";
	$i = $i + 1;
  }
  copy($oldName,$newName);
  return $newName;  
}







