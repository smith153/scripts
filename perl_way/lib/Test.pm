package Test;
use Test::Result;

sub testing
{
	print "from test::testing @_\n";
	my $str = shift();
	print "$str\n";
	my $i = Test::Result::getter(9);
	print "got $i from getter\n";

}

sub run
{
	print "from test::run: @_\n";
	my $str = shift();
	testing($str);
}


1;