
package ActionStreams::Scraper;

my $import_error = 'Cannot update stream without Web::Scraper; a prerequisite may not be installed';

sub scraper (&)   { die $import_error }
sub process       { die $import_error }
sub process_first { die $import_error }
sub result        { die $import_error }

sub import {
    if (eval { require Web::Scraper; 1 }) {
        # Override the die-ing methods above with Web::Scraper's.
        Web::Scraper->import();
    }
    elsif (my $err = $@) {
        $import_error .= ': ' . $err;
    }
    
    # Export these methods like Web::Scraper does.
    my $pkg = caller;
    no strict 'refs';
    *{"${pkg}::scraper"}       = \&scraper;
    *{"${pkg}::process"}       = sub { goto &process };
    *{"${pkg}::process_first"} = sub { goto &process_first };
    *{"${pkg}::result"}        = sub { goto &result };
    
    return 1;
}

1;
