
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

    my $cache = MT->model('actions_ua_cache')->load($uri)
        or return;

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

    my $uri = $resp->request->uri;
    my $cache = MT->model('actions_ua_cache')->load($uri);

    my $failed = !$resp->is_success();
    my $no_cache_headers = !$resp->header('Etag') && !$resp->header('Last-Modified');
    if ($failed || $no_cache_headers) {
        $cache->remove() if $cache;
        return;
    }

    $cache ||= MT->model('actions_ua_cache')->new();
    $cache->set_values({
        url           => $uri,
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
