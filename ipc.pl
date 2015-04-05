use common::sense;
use feature 'say';
use Data::Dumper;
use IO::Handle;
use Socket;

our $EOL = "\015\012";

my ($r, $w);
socketpair($r, $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair failed: $!";

$r->autoflush(1);
$w->autoflush(1);

my $pid = fork;
die "fork failed: $!" if not defined $pid;

if ($pid) {    # Parent process
    close $r or die "close reader handle failed: $!";

    say "[Parent $$] Started child $pid";

    print $w "Sending to child: hogehoge${EOL}";

    waitpid($pid, 0);
    say "[Parent $$] Child $pid has exited";
    close $w or die "close writer handle failed: $!";
}
else {         # Child process
    close $w or die "close writer handle failed: $!";

    say "[Child $$] Booted";

    my $line = $r->getline;
    chomp $line;
    say "[Child $$] Got: $line";

    close $r
        or die "close reader handle failed: $!";

    say "[Child $$] Finished";
    exit 0;
}
