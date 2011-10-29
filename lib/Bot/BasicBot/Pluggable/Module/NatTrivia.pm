package Bot::BasicBot::Pluggable::Module::NatTrivia;

use strict;
use Bot::BasicBot::Pluggable::Module;
use LWP::Simple;
use LWP::UserAgent;
use Encode;

use vars qw( @ISA $VERSION );
@ISA     = qw(Bot::BasicBot::Pluggable::Module);
$VERSION = '0.01_2';

my $cmds  = qr/nattrivia/;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my ($topic, $question, $answer);
my $tries = 0;
my $channel;
my $running = 0;
my $counter = 0;
my %players;

sub told {
    my ( $self, $mess ) = @_;
    my $bot = $self->bot();

    # we must be directly addressed
    return
        if !( ( defined $mess->{address} && $mess->{address} eq $bot->nick() )
        || $mess->{channel} eq 'msg' );

    # ignore people we ignore
    return if $bot->ignore_nick( $mess->{who} );
	
	my $reply;
	my $msg = $mess->{body};

	if ($msg =~ m/\s*nattrivia\s+(\w+)/) {
		my $opt = $1;

		if ($opt =~ m/start/i) {
			if ($question or $running) {
				$reply = 'Pergunta ou jogo já a decorrer...';
				return $reply;
			}
			else {
				$running = 1;
				%players = ();
				$channel = $mess->{channel};
				$bot->say({channel=>$mess->{channel},body=>"[NatTrivia] Jogo a começar em ".$mess->{channel}.", uma pergunta por minuto"});
			}
		}

		if ($opt =~ m/stop/i) {
			if ($running) {
				my $res;
				foreach (keys %players) {
					$res .= "$_:".$players{$_}." ";
				}
				$bot->say({channel=>$mess->{channel},body=>"[NatTrivia] Jogo terminado em ".$mess->{channel}.", resultados: $res"});
				$running = 0;
				$question = '';
			}
			else {
				$running = 0;
				$reply = 'Jogo não está a decorrer!';
				return $reply;
			}
		}
	}

	if ($running and $question) {
   	my $request = HTTP::Request->new(POST => 'http://eremita.di.uminho.pt:3000/verify');
   	$request->content_type("text/xml; charset=utf-8");
   	$request->content("<question>$question</question><answer>$msg</answer>");
print STDERR "###\n<question>$question</question><answer>$msg</answer>\n###\n";
		my $response = $ua->request($request);

		if ($response =~ /correcto/i) {
			$question = '';
			$reply = 'certo!';
			$players{$mess->{who}}++;
			return $reply;
		}
		else {
			$reply = "resposta errada ($msg)";
			return $reply;
		}
	}

	return;
}

sub tick {
	my $self = shift;
	my $bot = $self->bot();

	return unless $running;
	$counter++;

	if ($question and $counter >= 12) {
		$bot->say({channel=>$channel,body=>"[NatTrivia] Acabou o tempo, resposta correcta era: $answer"});
		$question = '';
		$counter = 0;
		return;
	}

	if ($counter > 12) {
		$counter = 0;
	}

	return if $question;
	return unless $running;

	my $xml = get 'http://eremita.di.uminho.pt:3000/random';
	utf8::decode($xml) unless utf8::is_utf8($xml);

	$xml =~ m/<topic>(.*?)<\/topic>/i;
	$topic = $1;
	$xml =~ m/<question>(.*?)<\/question>/i;
	$question = $1;
print STDERR "Q $question\n";
	$xml =~ m/<answer>(.*?)<\/answer>/i;
	$answer = $1;
	my $x = $answer;
	$x =~ s/\S/_/g;
	$bot->say({channel=>$channel,body=>"[NatTrivia] ($topic) $question$x"});
}

sub help {'trivia [start|stop] to control the game'}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::NatTrivia - IRC frontend to NatTrivia

=head1 SYNOPSIS

    < you> bot: nattrivia on
    < you> bot: nattrivia off

=head1 DESCRIPTION

XXX

=head1 IRC USAGE

XXX

=head2 Commands

The robot understand the following subcommands:

=over 4

=item * nattrivia [on|off]

XXXX

=back

=head1 AUTHOR

Nuno Carvalho, C<< <smash@cpan.org> >>

José Joao Almeida, C<<jj@di.uminho.pt>>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bot-basicbot-pluggable-module-corelist@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/>. I will be notified, and
then you'll automatically be notified of progress on your bug as I
make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Nuno Carvalho.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
