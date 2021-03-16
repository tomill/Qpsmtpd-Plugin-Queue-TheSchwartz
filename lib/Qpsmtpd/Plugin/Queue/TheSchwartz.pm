package Qpsmtpd::Plugin::Queue::TheSchwartz;
use strict;
use warnings;
our $VERSION = '0.01';

use Email::Address;
use Email::Abstract;
use YAML;
use TheSchwartz;
use Qpsmtpd::Constants;

use base qw/ Qpsmtpd::Plugin Class::Accessor::Fast /;
__PACKAGE__->mk_accessors(qw( client config ));

my $CONFIG_FILE = 'queue_theschwartz.yaml';

sub init {
    my ($self, $qp, @args) = @_;
    
    my $file = $qp->config_dir($CONFIG_FILE) . "/$CONFIG_FILE";
    my $conf = YAML::LoadFile($file);
    
    for my $handler (@{ $conf->{handlers} ||= [] }) {
        $handler->{rcpt} = qr/$handler->{rcpt}/;
    }
    
    $self->config($conf);
    $self->log(LOGINFO, "config =>\n". YAML::Dump $conf);
    
    my $schwa = TheSchwartz->new(%{ $conf->{config} });
    $self->client($schwa);
}

sub hook_queue {
    my ($self, $tx) = @_;
    
    my @rcpts = map { $_->address } $tx->recipients;
    my @task;
    for my $handler (@{ $self->config->{handlers} }) {
        if (grep { $_ =~ $handler->{rcpt} } @rcpts) {
            push @task, $handler->{worker};
        }
    }
    
    return DECLINED unless @task;
    
    my $arg = $self->_make_arg($tx);
        
    $self->log(LOGDEBUG, "arg =>\n". YAML::Dump $arg);
     
    for my $worker (@task) {
        my $handle = $self->client->insert($worker => $arg);
        
        $self->log(LOGINFO,
            sprintf 'sender:%s, worker:%s, jobid:%s',
                $tx->sender->address, $worker, $handle->jobid
        );
    }
     
    return OK;
}

sub _make_arg {
    my ($self, $tx) = @_;
    my $email = Email::Abstract->new($tx)->cast('Email::MIME');
    
    my $arg = {
        sender => $tx->sender->address,
        rcpt   => [ map { $_->address } $tx->recipients ],
        source => $email->as_string,
    };
    
    for my $header (qw( from to cc )) {
        my @email = Email::Address->parse($email->header($header));
        if ($header eq 'from') {
            $arg->{$header} = eval { $email[0]->address } || '';
        } else {
            $arg->{$header} = [ map { $_->address } @email ];
        }
    }
    
    return $arg;
}

1;
__END__

=encoding utf-8

=head1 NAME

Qpsmtpd::Plugin::Queue::TheSchwartz - Email to TheSchwartz job

=head1 SYNOPSIS

  # in /etc/qpsmtpd/plugins
  Qpsmtpd::Plugin::Queue::TheSchwartz
  
  # /etc/qpsmptd/que_theschwartz.yaml
  config:
    databases:
      - dsn: 'dbi:mysql:theschwartz'
        user: theschwartz
        pass: p4ssw0rd
  
  handlers:
    - rcpt: '^test@example\.com'
      warker: Foo::Bar

=head1 DESCRIPTION

Qpsmtpd::Plugin::Queue::TheSchwartz is a Qpsmtpd plugin that queues
a mail post as a TheSchwartz job.

=head2 EXAMPLE

=over 4

=item /etc/qpsmtpd/plugins

  plugin_you_like_foo
  plugin_you_like_bar
  plugin_you_like_baz

  Qpsmtpd::Plugin::Queue::TheSchwartz
  
  queue/you_like

=item /etc/qpsmtpd/queue_theschwartz.yaml

  config:
    databases:
      - dsn: 'dbi:mysql:theschwartz'
        user: theschwartz
        pass: p4ssw0rd
  
  handlers:
      - rcpt: 'signup-.+?@example.com'
        worker: Foo::Bar
      - rcpt: 'test@example\.com'
        worker: Foo::Test

=item Email

  From: =?ISO-2022-JP?B?GyRCSVpFRBsoQg==?= <tomita@cpan.org>
  To: test api <signup-xxxyyyzzz123@example.com>
  Subject: Hello =?ISO-2022-JP?B?GyRCQCQzJhsoQg==?=
  Cc: bar@example.com, Baz <baz@example.net>
  MIME-Version: 1.0
  Content-Type: text/plain; charset="ISO-2022-JP"
  Content-Transfer-Encoding: 7bit
  
  Can you see me?
  こんにちは

(Note: body is encoding ISO-2022-JP in practice.)

=item TheSchwartz job

  $client->insert('Foo::Bar' => [
      sender => 'tomita@cpan.org',
      from   => 'tomita@cpan.org',
      rcpt   => [ 'signup-xxxyyyzzz123@example.com' ],
      to     => [ 'signup-xxxyyyzzz123@example.com' ],
      cc     => [ 'bar@example.com', 'baz@example.net' ],
      source => <<'__EOF__'
  From: =?ISO-2022-JP?B?GyRCSVpFRBsoQg==?= <tomita@cpan.org>
  To: test api <signup-xxxyyyzzz123@example.com>
  Subject: Hello =?ISO-2022-JP?B?GyRCQCQzJhsoQg==?=
  Cc: bar@example.com, Baz <baz@example.net>
  MIME-Version: 1.0
  Content-Type: text/plain; charset="ISO-2022-JP"
  Content-Transfer-Encoding: 7bit
  
  Can you see me?
  こんにちは
  __EOF__
      ,
  );

(Note: source is bytes.)

=back

=head1 TODO

testing.. we need Qpsmtpd testing framework?

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://smtpd.develooper.com/>, L<TheSchwartz>

L<Qpsmtpd::Plugin::EmailAddressLoose>

=cut
