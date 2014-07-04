#!/usr/bin/env perl 
use warnings;
use strict;
use Getopt::Long;
use Devel::SizeMe qw(total_size);
use Data::Dumper;

my $URL;


GetOptions (
	"url=s" => \$URL,
) or die("Wrong args!\n" );



my $ref = {
	"HTTP::Tiny" => {},
	"LWP::UserAgent" => {cookie_jar => undef, ssl_opts => { verify_hostname => 0 }},
	#"WWW::Curl" => {},
	"LWP::Curl" => {},
	"WWW::Mechanize" => {stack_depth => 0, cookie_jar => undef, ssl_opts => { verify_hostname => 0 }},
	
};


sub print_sizes
{
	my $ref = shift();
	my $bytes = total_size($ref);
	print "Size in kbytes: " . $bytes/1024 . "\n";
	system("ps aux|grep $$|grep -v grep");
	return;
}

sub run
{
	my ($module, $args_ref )= @_;
	my $ua;
	my $response;
	my $i = 1000;
	my $sec = time();

	print "Loading $module\n";
	eval "use $module";
	die "dying: $@" if $@;

	
	$ua = $module->new(%{$args_ref});

	print "Before $i iterations: ";
	print_sizes($ua);

	while($i--) {

		$response = $ua->get($URL);

	}

	print "After iterations: ";
	print_sizes($ua);
	$sec = time() - $sec;
	print "Ended after $sec seconds\n";
	exit;
}

##############################  MAIN  ########################################


foreach my $key (keys %{$ref} ){

	my $i = fork();
	if($i == 0){
		run($key, $ref->{$key});
	}

	waitpid($i,0);

}




