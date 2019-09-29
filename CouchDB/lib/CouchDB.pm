package CouchDB;
use strict;
use warnings;
use Mojo::UserAgent;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);

sub new {
    my ($class, @arguments) = @_;
    my $self = {@arguments};
    bless $self, $class;
    $self->_user_agent;
    $self->register($self->{'ua'}, $self->{'config'});
    return $self;
}

sub _user_agent {
    my ($self, $ua) = @_;
    return $ua if defined($ua);
    $ua = Mojo::UserAgent->new(keep_alive => 1);

    # Request will never end.
    $ua->request_timeout(0);

    # We'll get a heartbeat from couch every 10 seconds.
    $ua->inactivity_timeout(11);
    $self->{'ua'} = $ua;
    return $ua;
}

sub register {
    my ($self, $ua, $couch_cnf) = @_;
    my $url = "http://" . $couch_cnf->{host} . ":" . $couch_cnf->{port} . "/";

    my $couch_conn;
    eval { $couch_conn = $ua->get($url)->result; };
    if ($@) {
        $self->{'logger'}->logdie("Unable to get response from couch : $@");
    }
    $self->{'logger'}->info("Got response from couch...");
    if ($couch_conn->is_success) {
        $self->{'logger'}->info("Couch connection successfull.");
        $self->{'logger'}->debug($couch_conn->body);
    }
    elsif ($couch_conn->is_error) {
        $self->{'logger'}->error($couch_conn->message);
    }
    elsif ($couch_conn->code == 301) {
        $self->{'logger'}->info($couch_conn->headers->location);
    }
    $self->{'base_uri'} = $url;
    return $couch_conn;
}

sub ua {
    my ($self) = @_;
    return $self->{ua};

    # Above can be written also as
    # shift->{ua};
    # For better understanding purpose written it like that
}

sub base_uri {
    my ($self) = @_;
    return $self->{base_uri};
}

sub dumper {
    return Data::Dumper->new([@_])->Maxdepth(4)->Indent(1)->Terse(1)->Dump;
}

# Create a DB in couch
sub create_db {
    my ($self, $db_name) = @_;
    $self->{'logger'}->info("Creating database: $db_name");
    my $create = $self->ua()->put($self->base_uri() . "/$db_name")->result;
    if ($create->is_success) {
        $self->{'logger'}->info("Database created.\n" . $create->body);
        return 1;
    }
    elsif ($create->is_error) {
        $self->{'logger'}->warn(
            $create->{error}->{code} . " - " . $create->message . " : " . dumper($create->json));
        return 0;
    }
}

# Perfoem various request ('GET', 'POST', 'PUT' etc)
sub request {
    my ($self, $method, $uri, $content) = @_;

    my $full_uri = $self->base_uri() . $uri;
    $self->{'logger'}->info("Doing '$method': $full_uri");
    my $response;

    if (defined $content) {
        $response = $self->ua()
                    ->$method($full_uri => {'Content-Type' => 'application/json'} => encode_json($content))
                    ->result;
    }
    else {
        $response = $self->ua()->$method($full_uri)->result;
    }
    my $res_json = $response->json;
    if ($response->is_success) {
        $self->{'logger'}->info("'$method' is successful");
        $self->{'logger'}->debug(dumper($res_json));
    }
    else {
        $self->{'logger'}->warn("Error while $method => $full_uri : "
                . $response->{error}->{code} . " - "
                . $response->message . "\n"
                . dumper($res_json));
    }
    return $response;
}

sub resolve_conflict {
    my ($self, $dbname, $data) = @_;
    $self->{'logger'}->info("Conflict found and hence will be doing 'put'");
    my $get_res = ($self->get("$dbname/$data->{_id}"))->json;
    $data->{_rev} = $get_res->{_rev};
    $self->put("$dbname/$data->{_id}", $data);
    return 1;
}

sub delete {
    my ($self, $url) = @_;
    return $self->request(delete => $url);
}

sub get {
    my ($self, $url) = @_;
    return $self->request(get => $url);
}

sub put {
    my ($self, $url, $content) = @_;
    return $self->request(put => $url, $content);
}

sub post {
    my ($self, $url, $content) = @_;
    return $self->request(post => $url, $content);
}

sub post_bulk_doc {
    my ($self, $url, $content) = @_;

    $url = $url . '/_bulk_docs';
    my $docs = {docs => $content};
    return $self->request(post => $url, $docs);
}

1;
