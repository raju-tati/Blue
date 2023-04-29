use strict;
use warnings;
use utf8;
use experimentals;
use Time::HiRes;
use threads;

sub fileContent($fileName) {
    my $contents;
    open( my $fh, '<', $fileName ) or die "Cannot open torrent $fileName";
    {
        local $/;
        $contents = <$fh>;
    }
    close($fh);
    return $contents;
}

sub main() {
    say "Blue >>";
}

my $signalThread = async {
    use sigtrap 'handler' => \&signalHandler, qw(INT);
};
# functionName: signalHandler().
# handles the INT signal form keyboard.
sub signalHandler($signalName) { 
    say "got an intterupt, print some info";
    my @threads = threads->list(threads::all);
    say "remaining threads: ", scalar @threads;
}
my $monitorThread = async {
    while(1) {
        foreach my $thread (threads->list(threads::joinable)) {
            $thread->detach();
        }
        Time::HiRes::sleep(0.005);
    }
};
main();
while(1) {
    my @threads = threads->list(threads::all);
    if(scalar @threads == 1) {
        $monitorThread->detach();
        last;
    } else {
        Time::HiRes::sleep(0.001);
    }
}
exit();

__END__
=encoding utf8
=pod
=head1 FUNCTIONS

    edit the functions not starting with _.
    functions starting with _ are private.
    function staring with __ are for export.

=cut
