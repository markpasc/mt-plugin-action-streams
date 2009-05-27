
package ActionStreams::Scraper;

my $import_error = 'Cannot update stream without Web::Scraper; a prerequisite may not be installed';

sub import {
    my %methods;
    
    if (eval { require Web::Scraper; 1 }) {
        Web::Scraper->import();
        %methods = (
            scraper       => \&scraper,
            result        => sub { goto &result },
            process       => sub { goto &process },
            process_first => sub { goto &process_first },
        );
    }
    elsif (my $err = $@) {
        $import_error .= ': ' . $err;
        %methods = (
            scraper       => sub (&) { die $import_error },
            result        => sub     { die $import_error },
            process       => sub     { die $import_error },
            process_first => sub { die $import_error },
        );
    }
    
    # Export these methods like Web::Scraper does.
    my $pkg = caller;
    no strict 'refs';
    while (my ($key, $val) = each %methods) {
        *{"${pkg}::${key}"} = $val;
    }
    return 1;
}

1;
