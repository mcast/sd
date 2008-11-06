#!/usr/bin/env perl
use warnings;
use strict;
use Prophet::Test;
use App::SD::Test;

BEGIN {
    if ( $ENV{'JIFTY_APP_ROOT'} ) {
        plan tests => 8;
        require File::Temp;
        $ENV{'PROPHET_REPO'} = $ENV{'SD_REPO'} = File::Temp::tempdir( CLEANUP => 0 ) . '/_svb';
        diag $ENV{'PROPHET_REPO'};
        eval "use Jifty";
        push @INC, File::Spec->catdir( Jifty::Util->app_root, "lib" );
    } else {
        plan skip_all => "You must define a JIFTY_APP_ROOT environment variable which points to your hiveminder source tree";
    }
}

eval 'use BTDT::Test; 1;' or die "$@";

my $server = BTDT::Test->make_server;
my $URL    = $server->started_ok;
$URL =~ s|http://|http://onlooker\@example.com:something@|;
my $sd_hm_url = "hm:$URL";

ok( 1, "Loaded the test script" );
my $root = BTDT::CurrentUser->superuser;
my $as_root = BTDT::Model::User->new( current_user => $root );
$as_root->load_by_cols( email => 'onlooker@example.com' );
my ( $val, $msg ) = $as_root->set_accepted_eula_version( Jifty->config->app('EULAVersion') );
ok( $val, $msg );
my $GOODUSER = BTDT::CurrentUser->new( email => 'onlooker@example.com' );
$GOODUSER->user_object->set_accepted_eula_version( Jifty->config->app('EULAVersion') );
my $task = BTDT::Model::Task->new( current_user => $GOODUSER );
$task->create(
    summary     => "YATTA",
    description => '',
);

my ($yatta_uuid, $yatta_id);
{
    my ($ret, $out, $err) = run_script( 'sd', [ 'clone', '--from', $sd_hm_url ] );
    run_output_matches( 'sd', [qw(ticket list --regex .)], [qr/(.*?)(?{ $yatta_uuid = $1 }) YATTA (.*)/] );
    ( $ret, $out, $err ) = run_script( 'sd', [ qw(ticket show --batch --id), $yatta_uuid ] );
    $yatta_id = $1 if $out =~ /^id: (\d+) /m;
}

my ($comment_id, $comment_uuid) = create_ticket_comment_ok(
    '--uuid', $yatta_uuid, '--content',
    "'This is a test'"
);
{
    my ( $ret, $out, $err ) = run_script( 'sd', [ 'push','--to', $sd_hm_url ] );

    my $task = BTDT::Model::Task->new( current_user => $GOODUSER );
    ok( $task->load_by_cols( summary => 'YATTA' ), "loaded a task" );
    my $comments = $task->comments;
    is( $comments->count, 2, "there are two comments" );
    my $comment = do { $comments->next; $comments->next->formatted_body };
    like( $comment, qr/This is a test/, "text matches comment" );
}
