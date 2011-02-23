package DBIx::TableLoader::CSV;
# ABSTRACT: Easily load a CSV into a database table

=head1 SYNOPSIS

	my $dbh = DBI->connect($dsn);
	my $loader = DBIx::TableLoader::CSV->new(dbh => $dbh, file => $path);
	$loader->load();

=cut

use strict;
use warnings;
use parent 'DBIx::TableLoader';
use Text::CSV 1.21 ();

=method new

Accepts all options from L<DBIx::TableLoader/new>,
as well as these csv specific options:

=for :list
* C<csv> - A L<Text::CSV> compatible object instance; If not supplied
an instance will be created with C<< $csv_class->new(\%csv_opts) >>.
* C<csv_class> - An alternate class to instantiate if C<csv> is not supplied;
Defaults to C<Text::CSV>
(which will attempt to load L<Text::CSV_XS> and fall back to L<Text::CSV_PP>).
* C<csv_defaults> - Hashref of default options to pass to the C<csv_class>
constructor; Includes C<< { binary => 1 } >> (as encouraged by L<Text::CSV>);
To turn off the C<binary> option you can pass C<< { binary => 0 } >>
to C<csv_opts>.  If you are using a different C<csv_class> that does not accept
the C<binary> option you can overwrite this with an empty hash.
* C<csv_opts> - Hashref of options to pass to the C<new> method of C<csv_class>;
* C<file> - Path of a csv file to read if C<io> is not supplied.
C<table_name> will be set to the basename of C<file>
so if you use C<io> instead of C<file> you will likely want to specify
C<table_name> (otherwise C<table_name> will default to C<csv>).
* C<io> - An IO-like object to read CSV lines from
* C<no_header> - Boolean.
Usually the first row [header] of a CSV is the column names.
If you specify C<columns> this module assumes you are overwriting
the usual header row so the first row of the CSV will be discarded.
If there is no header row on the CSV (the first row is data),
you must set C<no_header> to true in order to preserve the first row of the CSV.

=cut

# 'new' inherited

sub defaults {
	my ($self) = @_;
	return {
		csv             => undef,
		csv_class       => 'Text::CSV',
		csv_defaults    => {
			# Text::CSV encourages setting { binary => 1 }
			binary => 1,
		},
		csv_opts        => {},
		file            => undef,
		io              => undef,
		no_header       => 0,
	};
}

sub get_raw_row {
	my ($self) = @_;
	return $self->{csv}->getline($self->{io});
}

sub default_name {
	my ($self) = @_;
	# guess name if not provided
	return $self->{name} ||=
		$self->{file}
			? do {
				require File::Basename; # core
				File::Basename::basename($self->{file}, qr/\..+$/);
			}
			: 'csv';
}

sub prepare_data {
	my ($self) = @_;

	# if an object is not passed in via 'csv', create one from 'csv_opts'
	$self->{csv} ||= $self->{csv_class}->new({
		%{ $self->{csv_defaults} },
		%{ $self->{csv_opts} }
	});

	# 'file' should be an IO object or the path to a file
	$self->{io} ||= ref $self->{file}
		? $self->{file}
		: do {
			open(my $fh, '<', $self->{file})
				or die("Failed to open '$self->{file}': $!");
			binmode($fh);
			$fh;
		};

	# discard first row if columns given (see POD for 'no_header' option in new)
	$self->{first_row} = $self->get_raw_row()
		if $self->{columns} && !$self->{no_header};
}

1;

=head1 DESCRIPTION

This is a subclass of L<DBIx::TableLoader> that handles
the common operations of reading a CSV file (using the powerful L<Text::CSV>).

This module simplifies the task of transforming a CSV file
into a database table.
This functionality was the impetus for the parent module (L<DBIx::TableLoader>).

=head1 SEE ALSO

=for :list
* L<DBIx::TableLoader>
* L<Text::CSV>

=cut
