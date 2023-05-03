use strict;
use warnings;
use utf8;
use experimentals;
use Time::HiRes;
use threads;
use threads::shared;
use Bencode qw(bencode bdecode);
use LWP::Simple qw(get);
use Encode;
use Digest::SHA::PurePerl qw(sha1);

my $startTime :shared = time();

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

sub printUsage() {
    say "Usage example:";
    say "blue.pl -t path/to/torrent.torrent";
    say "blue.pl -m magentLink";
}

sub properTorrent($torrentPath) {
    if(substr($torrentPath, -8) eq ".torrent") {
        if(-e $torrentPath) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

sub getInfoHash($infoKey) {
    my $bencodeInfoKey = bencode($infoKey);
    my $shaInfoKey = sha1($bencodeInfoKey);
    my $infoHash = Encode::encode("ISO-8859-1", $shaInfoKey);
    return $infoHash;
}

sub trackerRequest($torrentContent) {
    my $announce = $torrentContent->{"announce"};
    my $port = 6881;
    my $left = $torrentContent->{"info"}->{"length"};
    my $uploaded = 0;
    my $downloaded = 0;
    my $peerId = "-AZ2200-6wfG2wk8wWLd";

    my $infoHash = getInfoHash($torrentContent->{"info"});

    my $trackerRequest = 
            $announce
          . "?info_hash="
          . $infoHash
          . "&peer_id="
          . $peerId
          . "&port="
          . $port
          . "&uploaded="
          . $uploaded
          . "&downloaded="
          . $downloaded
          . "&left="
          . $left;
    
    return $trackerRequest;
}

sub getTrackerResponse($trackerRequest) {
    my $trackerResponseContent = get($trackerRequest)
                                    or say "Cannot Connect to tracker";
    my $trackerResponse = bdecode($trackerResponseContent);
    return $trackerResponse;
}

sub downloadTorrent($torrentPath) {
    my $torrentFileContent = fileContent($torrentPath);
    my $torrentContent = bdecode($torrentFileContent);
    my $trackerRequest = trackerRequest($torrentContent);
    my $trackerResponse = getTrackerResponse($trackerRequest);

    use Data::Printer;
    p($trackerResponse);
}

sub main() {
    if(scalar @ARGV != 2) {
        printUsage();
        return;
    }
    
    my $magentOrTorrent = $ARGV[0];
    my $linkOrTorrent = $ARGV[1];

    if($magentOrTorrent eq "-t") {
        if(properTorrent($linkOrTorrent)) {
            downloadTorrent($linkOrTorrent);
        } else {
            printUsage();
        }
    } elsif($magentOrTorrent eq "-m") {
        say "got a magnet link";
    } else {
        printUsage();
    }
}

my $keyBoardInput = async {
    my $input = <STDIN>;
    chomp $input;

    if($input eq "stats") {
        say "show stats";
    }
};

my $signalThread = async {
    use sigtrap 'handler' => \&signalHandler, qw(INT TSTP);
};
# functionName: signalHandler().
# handles the INT and TSTP signals form keyboard.
sub signalHandler($signalName) { 
    if($signalName eq "INT") {
        say "recieved an INT(CTRL-C) signal";
    } elsif($signalName eq "TSTP") {
        say "recieved TSTP(CTRL-Z) signal";
    } else {
        say "recieved ", $signalName, " signal";
    }
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
    if(scalar @threads == 2) {
        $monitorThread->detach();
        $keyBoardInput->detach();
        last;
    } else {
        Time::HiRes::sleep(0.001);
    }
}
exit();

__END__
=encoding utf8
=pod

=head1 USAGE

    blue.pl -t path/to/torrent.torrent
    blue.pl -m magentLink

=cut
