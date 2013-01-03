package # no_index
  CSVTester;

use Test::More 0.96;
use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT = qw(
  test_with_all_csv_classes
);

my @csv_classes = qw(
  Text::CSV
  Text::CSV_XS
  Text::CSV_PP
);

my %csv_classes;

sub test_with_all_csv_classes ($$) {
  my ($name, $subtest) = @_;
  subtest $name => sub {
    foreach my $class ( @csv_classes ){
      subtest "$name with $class" => sub {
        # load if not already attempted
        $csv_classes{$class} = eval "require $class"
          unless exists $csv_classes{$class};

        # skip if failed to load
        plan skip_all => "Failed to load $class"
          if ! $csv_classes{$class};

        # try it
        $subtest->($class);
      };
    }
  };
}

1;
