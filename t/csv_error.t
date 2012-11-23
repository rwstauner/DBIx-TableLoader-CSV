# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use File::Spec::Functions qw( catfile ); # core
use Try::Tiny;
use Test::Fatal;

my $mod = 'DBIx::TableLoader::CSV';
eval "require $mod" or die $@;

use DBI ();
use DBD::Mock ();

sub new_csv_loader {
  my ($file, $opts) = @_;

  my $dbh = DBI->connect('dbi:Mock:', undef, undef, {
    RaiseError => 1,
    PrintError => 0,
  });

  return $mod->new(
    dbh      => $dbh,
    file     => catfile(qw( t data ), $file),
    %$opts,
  );
}

{
  # instantiation failure will return undef but not die (so we must)
  like exception {
    new_csv_loader('example.csv',
      { csv_opts => { un_known_attr_ibute => 1 } },
    );
  }, qr/unknown attribute/i, 'caught csv instantion error';

  isa_ok try {
    new_csv_loader('example.csv',
      { csv_opts => { auto_diag => 2 } },
    );
  }, $mod, 'csv object created successfully';

  isa_ok try {
    new_csv_loader('example.csv',
      { csv => Text::CSV->new, csv_opts => { un_known_attr_ibute => 1 } },
    );
  }, $mod, 'csv object passed in';
}


done_testing;
