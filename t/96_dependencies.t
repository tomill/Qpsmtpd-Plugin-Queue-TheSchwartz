use Test::Dependencies
    exclude => [qw( Test::Dependencies Qpsmtpd::Plugin::Queue::TheSchwartz )],
    style => 'light';

ok_dependencies();
