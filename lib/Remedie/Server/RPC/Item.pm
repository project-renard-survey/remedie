package Remedie::Server::RPC::Item;
use Moose;
use Remedie::DB::Channel;
use Remedie::DB::Item;
use Remedie::Download;
use Path::Class::URIfy;
use URI::filename;

BEGIN { extends 'Remedie::Server::RPC' };

__PACKAGE__->meta->make_immutable;

no Moose;

sub download :POST {
    my($self, $req, $res) = @_;

    my $id = $req->param('id');
    my $item = Remedie::DB::Item->new(id => $id)->load;

    # TODO scrape etc. to get the downloadable URL
    my $downloader = Remedie::Download->new('Wget', conf => $self->conf); # TODO configurable
    my $track_id = $downloader->start_download($item, $item->ident);
    $item->props->{track_id} = $track_id;
    $item->props->{download_path} = $item->download_path($self->conf)->urify;
    $item->save;

    return { success => 1, item => $item };
}

sub cancel_download :POST {
    my($self, $req, $res) = @_;

    my $id = $req->param('id');
    my $item = Remedie::DB::Item->new(id => $id)->load;

    my $track = $item->props->{track_id};
    if ($track) {
        my($impl, @args) = split /:/, $track;
        my $downloader = Remedie::Download->new($impl, conf => $self->conf);
        $downloader->cancel(@args);
    }

    unlink URI->new($item->props->{download_path})->fullpath;

    delete $item->props->{track_id};
    delete $item->props->{download_path};
    $item->save;

    return { success => 1, item => $item };
}

sub track_status {
    my($self, $req, $res) = @_;

    my $id = $req->param('id');
    my $item = Remedie::DB::Item->new(id => $id)->load;

    my $track  = $item->props->{track_id}
        or return { success => 1, status => { percentage => 100 } };

    my($impl, @args) = split /:/, $track;
    my $downloader = Remedie::Download->new($impl, conf => $self->conf);
    my $status = $downloader->track_status(@args);

    if ($status->{percentage} && $status->{percentage} == 100) {
        delete $item->props->{track_id};
        $item->save;
        $downloader->cleanup(@args);
    }

    return { success => 1, item => $item, status => $status };
}

1;
