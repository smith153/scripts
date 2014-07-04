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
	"HTTP::Tiny" => [
		{verify_SSL => 0},
		sub {my $ref = shift; die Dumper $ref unless $ref->{success};},
	],
	"LWP::UserAgent" => [
		{cookie_jar => undef, ssl_opts => { verify_hostname => 0 }},
		sub {my $ref = shift; die Dumper $ref unless $ref->is_success();},
	],
	"LWP::Curl" => [
		{},
		sub { my $ref = shift; die Dumper $ref unless $ref;},
	],
	"WWW::Mechanize" => [
		{stack_depth => 0, cookie_jar => undef, ssl_opts => { verify_hostname => 0 }},
		sub {my $ref = shift; die Dumper $ref unless $ref->is_success();},
	],
	
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
	eval "require $module";
	die "dying: $@" if $@;

	
	$ua = $module->new(%{$args_ref->[0]});

	print "Before $i iterations: ";
	print_sizes($ua);

	while($i--) {

		$response = $ua->get($URL);
		$args_ref->[1]->($response);

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




