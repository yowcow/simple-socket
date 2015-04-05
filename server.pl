use common::sense;
use feature qw(say);
use IO::Socket::INET;
use Parallel::Prefork;

our $EOL = "\015\012";

my $server = IO::Socket::INET->new(
    Listen    => 5,
    Proto     => 'tcp',
    Reuse     => 1,
    LocalAddr => 'localhost',
    LocalPort => 8888,
) or die "Could not create a socket: $!";

$server->autoflush(1);
$server->listen;

my $pm = Parallel::Prefork->new(
    {   max_workers  => 3,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
    }
);

while ($pm->signal_received ne 'TERM') {
    $pm->start and next;

    say "[PID $$] Started";

    while (my $sock = $server->accept) {
        syswrite $sock, "[PID $$] Ready.\n";
        handle_connection($sock);
        $sock->close;
        last;
    }

    say "[PID $$] Finished";

    $pm->finish;
}

$pm->wait_all_children;

sub handle_connection {
    my $sock = shift;
    while (my $input = $sock->getline) {
        $input =~ s/\R//sg;
        my $res = handle_input($input);
        syswrite $sock, "[PID $$] Response: ${res}${EOL}";
        last if $input =~ /^bye/i;
    }
}

sub handle_input {
    my $input = shift;
    say "[PID $$] Got input '$input'";
    $input;
}
