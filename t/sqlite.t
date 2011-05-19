# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use FindBin qw($Bin);

# test an actual use-case

foreach my $mod ( qw(DBI DBD::SQLite) ){
  eval "require $mod"
    or plan skip_all => "$mod required for these tests";
}

my $path = 't/example.csv';
-e $path
  or plan skip_all => "Cannot find $path.  Please execute with dist root as working directory.";

use DBIx::TableLoader::CSV;

foreach my $csv_class ( qw(Text::CSV Text::CSV_XS Text::CSV_PP) ){
subtest "csv_class $csv_class" => sub {
  plan skip_all => "$csv_class required for testing with it"
    unless eval "require $csv_class";

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');
my $records;

DBIx::TableLoader::CSV->new(
  dbh => $dbh,
  file => $path,
  csv_opts => {allow_whitespace => 1},
  csv_class => $csv_class,
)->load();

my $table_info = $dbh->table_info('main', '%', '%', 'TABLE')->fetchall_arrayref({})->[0];
is($table_info->{TABLE_NAME}, 'example', 'table name');

$records = $dbh->selectall_arrayref(
  q[SELECT * FROM "example" ORDER BY "num"],
  {Slice => {}}
);

is_deeply($records, [
  {num => 2, boo => 'rubber', 'Two Words' => "says\nquack\nnot moo", 'B@d CHars!' => 'duck'},
  {num => 3, boo => 'ghost',  'Two Words' => 'bear', 'B@d CHars!' => 'lemon'},
  {num => 4, boo => 'arr',    'Two Words' => 'hello there', 'B@d CHars!' => '~!@#$%^&*()_+'},
  ], 'got expected records'
);

$records = $dbh->selectall_hashref(
  q[SELECT * FROM "example" WHERE boo like '%r%'],
  'boo'
);

is_deeply($records, {
    arr => {num => 4, boo => 'arr',    'Two Words' => 'hello there', 'B@d CHars!' => '~!@#$%^&*()_+'},
    rubber => {num => 2, boo => 'rubber', 'Two Words' => "says\nquack\nnot moo", 'B@d CHars!' => 'duck'},
  }, 'got expected records'
);

$records = $dbh->selectall_arrayref(q[SELECT num, "Two Words" FROM "example" WHERE num > 2 ORDER BY num]);

is_deeply($records, [[qw(3 bear)], ['4', 'hello there']], 'got expected records');

}
}

done_testing;
