use inc::Module::Install;

name 'Qpsmtpd-Plugin-Queue-TheSchwartz';
all_from 'lib/Qpsmtpd/Plugin/Queue/TheSchwartz.pm';

die "\nPlease install Qpsmtpd first. http://smtpd.develooper.com/\n"
    unless eval { require Qpsmtpd; 1 };

requires 'Class::Accessor::Fast';
requires 'Email::Address';
requires 'Email::Abstract';
requires 'Email::Abstract::QpsmtpdTransaction';
requires 'YAML';
requires 'TheSchwartz';

build_requires 'Test::More';

auto_include;

WriteAll;
