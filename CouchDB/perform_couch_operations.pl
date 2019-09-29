use strict;
use warnings;
use Cwd qw( abs_path );
use File::Basename qw( dirname );

BEGIN {
    $ENV{'SCRIPT_DIR'} = dirname(abs_path($0));
}
use lib $ENV{'SCRIPT_DIR'} . '/lib/';

sub initialize_couch {
    my ($config) = @_;
    print "Iitializing couchDB...";
    my $couch_db = CouchDB->new("config" => $config, "logger" => <your log4perl object>);
    return $couch_db;
}

# Get your couch config from json config file
my $couch_config  = <read_json_file("config.json")>;
my $couch_db      = initialize_couch($couch_config);
my $database_name = $couch_config->{db};

# This is needed in first attempt, redundent therafter
# $couch_db->create_db($database_name});

my $data_to_insert = {
                        foo => {
                            bar => 123
                        }
                    };

my $res_json = ($couch_db->post("$database_name", $data_to_insert))->json;

#If record already exist update it
if (defined $res_json->{error} && $res_json->{error} eq "conflict") {
    $couch_db->resolve_conflict($database_name, $data_to_insert);
}
