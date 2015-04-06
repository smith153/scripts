#include <time.h>
#include <stdio.h>
#include <stdlib.h>


//2000-02-29T12:34:56

/*
 # prints 1984-01-01 05:00 UTC +0000 # as it should 
$ENV{TZ} = "UTC"; 
my $t = Time::Piece->strptime("1984-01-01 00:00 -0500", "%Y-%m-%d %H:%M %z"); 
print $t->strftime("%Y-%m-%d %H:%M %Z %z\n");




*/


int main() 
{

    extern char *tzname[2];
    extern long timezone;
    extern int daylight;

    char time_buf[100];
    char format_str[] = "%Y-%m-%d %H:%M %z";
    char time_str[] = "1984-01-01 00:00 -0500";
    struct tm time_struct;

    putenv("TZ=UTC");

    strptime(time_str,  format_str, &time_struct);

    int i = mktime(&time_struct);

    strftime(time_buf, 100, "%Y-%m-%d %H:%M %Z %z", &time_struct);

    printf("%s\n",time_buf);

    return 0;


}
