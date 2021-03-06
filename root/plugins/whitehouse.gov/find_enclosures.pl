# http://www.whitehouse.gov/feed/video/
use Web::Scraper::LibXML;
sub init {
    my $self = shift;
    $self->{handle} = '/video/';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my $res = scraper {
        process 'input[name="EMBED_URL"]', code => '@value';
    }->scrape($args->{content});

    if ($res->{code}) {
        $self->parent->find_enclosures(\$res->{code}, $args->{entry});
    }
}
