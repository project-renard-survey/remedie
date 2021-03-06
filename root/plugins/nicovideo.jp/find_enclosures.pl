# author: Tatsuhiko Miyagawa
use HTML::TreeBuilder::LibXML;

sub init {
    my $self = shift;
    $self->{handle} = "/watch/";
}

sub find {
    my ($self, $args) = @_;
    my($id) = $args->{url} =~ qr!watch/(\w\w[^/?]+|\d+)!
        or return;

    my $thumbnail = $self->_thumbnail_for($id, $args->{entry});

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://ext.nicovideo.jp/thumb_watch/$id");
    $enclosure->type('application/javascript');
    $enclosure->thumbnail({ url => $thumbnail }) if $thumbnail;
    return $enclosure;
}

sub _thumbnail_for {
    my($self, $id, $entry) = @_;

    # Extract thumbnails if the source feed is on nicovideo.jp
    # otherwise, generate the thumbnail using the ad-hoc URL construction
    if ($entry->body =~ /nico-thumbnail/) {
        my $tree = HTML::TreeBuilder::LibXML->new;
        $tree->parse($entry->body);
        my $thumb = $tree->findvalue('//p[@class="nico-thumbnail"]/img/@src');
        $tree->delete;
        return $thumb;
    } elsif ($id =~ s/^\w\w//) {
        return "http://tn-skr1.smilevideo.jp/smile?i=$id";
    }

    return;
}
