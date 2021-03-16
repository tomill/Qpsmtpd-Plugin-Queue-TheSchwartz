# NAME

Qpsmtpd::Plugin::Queue::TheSchwartz - Email to TheSchwartz job

# SYNOPSIS

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

# DESCRIPTION

Qpsmtpd::Plugin::Queue::TheSchwartz is a Qpsmtpd plugin that queues
a mail post as a TheSchwartz job.

## EXAMPLE

- /etc/qpsmtpd/plugins

        plugin_you_like_foo
        plugin_you_like_bar
        plugin_you_like_baz

        Qpsmtpd::Plugin::Queue::TheSchwartz
        
        queue/you_like

- /etc/qpsmtpd/queue\_theschwartz.yaml

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

- Email

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

- TheSchwartz job

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

# TODO

testing.. we need Qpsmtpd testing framework?

# AUTHOR

Naoki Tomita <tomita@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[http://smtpd.develooper.com/](http://smtpd.develooper.com/), [TheSchwartz](https://metacpan.org/pod/TheSchwartz)

[Qpsmtpd::Plugin::EmailAddressLoose](https://metacpan.org/pod/Qpsmtpd%3A%3APlugin%3A%3AEmailAddressLoose)
