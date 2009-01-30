
package ActionStreams::UserAgent::NotModified;

use overload q{""} => \&as_string;

sub new {
    my ($class, $string) = @_;
    return bless \$string, $class;
}

sub as_string {
    my $self = shift;
    return $$self;
}


package ActionStreams::UserAgent::Adapter;

sub new {
    my $class = shift;
    my %param = @_;

    return bless \%param, $class;
}

sub _add_cache_headers {
    my $self = shift;
    my %param = @_;
    my ($uri, $headers) = @param{qw( uri headers )};

    my $action_type = $self->{action_type}
        or return;
    my $cache = MT->model('as_ua_cache')->load({
        url         => $uri,
        action_type => $action_type,
    });
    return if !$cache;

    if (my $etag = $cache->etag) {
        $headers->{If_None_Match} = $etag;
    }
    if (my $last_mod = $cache->last_modified) {
        $headers->{If_Last_Modified} = $last_mod;
    }
}

sub _save_cache_headers {
    my $self = shift;
    my ($resp) = @_;

    # Don't do anything if our existing cache headers were effective.
    return if $resp->code == 304;

    my $action_type = $self->{action_type}
        or return;
    my $uri = $resp->request->uri;
    my $cache = MT->model('as_ua_cache')->load({
        url         => $uri,
        action_type => $action_type,
    });

    my $failed = !$resp->is_success();
    my $no_cache_headers = !$resp->header('Etag') && !$resp->header('Last-Modified');
    if ($failed || $no_cache_headers) {
        $cache->remove() if $cache;
        return;
    }

    $cache ||= MT->model('as_ua_cache')->new();
    $cache->set_values({
        url           => $uri,
        action_type   => $action_type,
        etag          => ($resp->header('Etag') || undef),
        last_modified => ($resp->header('Last-Modified') || undef),
    });
    $cache->save();
}

sub get {
    my $self = shift;
    my ($uri, %headers) = @_;
    $self->_add_cache_headers( uri => $uri, headers => \%headers );
    my $resp = $self->{ua}->get($uri, %headers);
    if ($self->{die_on_not_modified} && $resp->code == 304) {
        die ActionStreams::UserAgent::NotModified->new(
            join q{ }, "GET", $uri, "failed:", $resp->status_line,
        );
    }
    $self->_save_cache_headers($resp);
    return $resp;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $funcname = $AUTOLOAD;
    $funcname =~ s{ \A .* :: }{}xms;
    return if $funcname eq 'DESTROY';

    my $fn = sub {
        my $self = shift;
        return shift->{ua}->$funcname(@_) if ref $self;

        if (eval { require LWPx::ParanoidAgent; 1 }) {
            return LWPx::ParanoidAgent->$funcname(@_);
        }
        return LWP::UserAgent->$funcname(@_);
    };

    {
        no strict 'refs';
        *{$AUTOLOAD} = $fn;
    }
    goto &$AUTOLOAD;
}

1;
