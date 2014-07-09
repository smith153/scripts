
package Test::Result;


my $g = 10;

sub getter
{
	print "from test::result::getter @_\n";
	my $i = shift();
	return $i * $g;
}

1;