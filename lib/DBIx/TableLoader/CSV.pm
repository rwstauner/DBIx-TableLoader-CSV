package DBIx::TableLoader::CSV;
# ABSTRACT: Easily load a CSV into a database table

=head1 SYNOPSIS

	my $dbh = DBI->connect(@connection_args);

	DBIx::TableLoader::CSV->new(dbh => $dbh, file => $path_to_csv)->load();

	# interact with new database table full of data in $dbh

In most cases simply calling C<load()> is sufficient,
but all methods are documented below in case you are curious
or want to do something a little trickier.

There are many options available for configuration.
See L</OPTIONS> for those specific to this module
and also L<DBIx::TableLoader/OPTIONS> for options from the base module.

=cut

use strict;
use warnings;
use parent 'DBIx::TableLoader';
use Carp qw(croak carp);
use Module::Load ();
use Text::CSV 1.21 ();

=method new

Accepts all options described in L<DBIx::TableLoader/OPTIONS>
plus some CSV specific options.

See L</OPTIONS>.

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

=head1 get_raw_row

Returns C<< $csv->getline($io) >>.

=cut

sub get_raw_row {
	my ($self) = @_;
	return $self->{csv}->getline($self->{io});
}

=head1 default_name

If the C<name> option is not provided,
and the C<file> option is,
returns the file basename.

Falls back to C<'csv'>.

=cut

sub default_name {
	my ($self) = @_;
	# guess name if not provided
	return $self->{name} ||=
		$self->{file}
			? do {
				require File::Basename; # core
				File::Basename::fileparse($self->{file}, qr/\.[^.]*/);
			}
			: 'csv';
}

=head1 prepare_data

This is called automatically from the constructor
to make things as simple and automatic as possible.

=for :list
* Load C<csv_class> if it is not.
* Instantiate C<csv_class> with C<csv_defaults> and C<csv_opts>.
* Open the C<file> provided unless C<io> is passed instead.
* Discard the first row if C<columns> is provided and C<no_header> is not.

=cut

sub prepare_data {
	my ($self) = @_;

	Module::Load::load($self->{csv_class});

	# if an object is not passed in via 'csv', create one from 'csv_opts'
	$self->{csv} ||= $self->{csv_class}->new({
		%{ $self->{csv_defaults} },
		%{ $self->{csv_opts} }
	});

	# 'file' should be an IO object or the path to a file
	$self->{io} ||= do {
		croak("Cannot proceed without a 'file' or 'io' attribute")
			unless my $file = $self->{file};
		ref $file
			? $file
			: do {
				open(my $fh, '<', $file)
					or croak("Failed to open '$file': $!");
				binmode($fh);
				$fh;
			};
	};

	# discard first row if columns given (see POD for 'no_header' option in new)
	$self->{first_row} = $self->get_raw_row()
		if $self->{columns} && !$self->{no_header};
}

1;

=head1 DESCRIPTION

This is a subclass of L<DBIx::TableLoader> that handles
the common operations of reading a CSV file
(using the powerful L<Text::CSV> (which uses L<Text::CSV_XS> if available)).

This module simplifies the task of transforming a CSV file
into a database table.
This functionality was the impetus for the parent module (L<DBIx::TableLoader>).

=head1 OPTIONS

The most common usage might include these options:

=begin :list

* C<csv_opts> - Hashref of options to pass to the C<new> method of C<csv_class>
See L<Text::CSV> for its list of accepted options.

* C<file> - Path of a csv file to read if C<io> is not supplied
C<table_name> will be set to the basename of C<file>
so if you use C<io> instead of C<file> you will likely want to specify
C<table_name> (otherwise C<table_name> will default to C<'csv'>).

=end :list

If you need more customization or are using this inside of
a larger application you may find some of these useful:

=begin :list

* C<csv> - A L<Text::CSV> compatible object instance
If not supplied an instance will be created
using C<< $csv_class->new(\%csv_opts) >>.

* C<csv_class> - The class to instantiate if C<csv> is not supplied
Defaults to C<Text::CSV>
(which will attempt to load L<Text::CSV_XS> and fall back to L<Text::CSV_PP>).

* C<csv_defaults> - Hashref of default options for C<csv_class> constructor
Includes C<< { binary => 1 } >> (as encouraged by L<Text::CSV>);
To turn off the C<binary> option
you can pass C<< { binary => 0 } >> to C<csv_opts>.
If you are using a different C<csv_class> that does not accept
the C<binary> option you may need to overwrite this with an empty hash.

* C<io> - A filehandle or IO-like object from which to read CSV lines
This will be used as C<< $csv->getline($io) >>.

* C<name> - Table name
If not given it will be set to the file basename
or C<'csv'> if C<file> is not provided.

* C<no_header> - Boolean
Usually the first row [header] of a CSV is the column names.
If you specify C<columns> this module assumes you are overwriting
the usual header row so the first row of the CSV will be discarded.
If there is no header row on the CSV (the first row is data),
you must set C<no_header> to true in order to preserve the first row of the CSV.

=end :list

=head1 SEE ALSO

=for :list
* L<DBIx::TableLoader>
* L<Text::CSV>

=cut
