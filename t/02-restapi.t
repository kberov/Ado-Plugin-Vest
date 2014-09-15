#02-restapi.t
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::Util qw(decode);

my $OE  = $^O =~ /win/i ? 'cp866' : 'utf8';
my $t1  = Test::Mojo->new('Ado');
my $app = $t1->app;
my $dbh = $app->dbix->dbh;
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

# Remove generic routes (for this test only) so newly generated routes can match.
$app->routes->find('controller')->remove();
$app->routes->find('controlleraction')->remove();
$app->routes->find('controlleractionid')->remove();

isa_ok($app->plugin('vest'), 'Ado::Plugin::Vest');

#$t1 login first
subtest 't1_login' => sub {
    $t1->get_ok('/login/ado');

#get the csrf fields
    my $form       = $t1->tx->res->dom->at('#login_form');
    my $csrf_token = $form->at('[name="csrf_token"]')->{value};
    my $form_hash  = {
        _method        => 'login/ado',
        login_name     => 'test1',
        login_password => '',
        csrf_token     => $csrf_token,
        digest         => Mojo::Util::sha1_hex($csrf_token . Mojo::Util::sha1_hex('test1test1')),
    };
    $t1->post_ok('/login' => {} => form => $form_hash)->status_is(302);
};

# $t2 login
my $t2 = Test::Mojo->new('Ado');
subtest 't2_login' => sub {
    $t2->get_ok('/login/ado');

    #get the csrf fields
    my $form       = $t2->tx->res->dom->at('#login_form');
    my $csrf_token = $form->at('[name="csrf_token"]')->{value};
    my $form_hash  = {
        _method        => 'login/ado',
        login_name     => 'test2',
        login_password => '',
        csrf_token     => $csrf_token,
        digest         => Mojo::Util::sha1_hex($csrf_token . Mojo::Util::sha1_hex('test2test2')),
    };
    $t2->post_ok('/login' => {} => form => $form_hash)->status_is(302);
};

#reload
#{route => '/вест', via => ['GET'],  to => 'vest#list',}
#no format
$t1->get_ok('/вест')->status_is('415', '415 - Unsupported Media Type ')
  ->content_type_is('text/html;charset=UTF-8')->header_like('Content-Location' => qr|\.json$|x)
  ->content_like(qr|\.json</a>\!|x);
$t1->get_ok('/вест/list')->status_is('404', '404 Not Found');

#=pod

#with format
$t1->get_ok('/вест.json')->status_is('200', 'Status is 200')
  ->content_type_is('application/json')->json_has('/data')->json_has('/links')
  ->json_is('/links/0/rel' => 'self', '/links/0/rel is self')
  ->json_like('/links/0/href' => qr'\.json\?limit=20\&offset=0')
  ->json_is('/links/1' => undef, '/links/1 is not present')
  ->json_is('/data'    => [],    '/data is empty');


#Play with several messages.
#{route => '/вест', via => ['POST'], to => 'vest#add',},
$t1->post_ok(
    '/вест',
    form => {
        from_uid           => 3,
        subject_message_id => 0,

        #to_uid   => 4,
        subject => 'Какъв приятен разговор!',
        message => 'Здравей, Приятел!'
    }
  )->status_is('400', 'Status is 400')->json_is(
    {   'code'    => 400,
        'data'    => 'validate_input',
        'message' => {'to_uid' => ['required'],},
        'status'  => 'error'
    }
  );

# fixed bug - missing "required" validation on second POST
$t1->post_ok(
    '/вест',
    form => {
        from_uid           => 3,
        subject_message_id => 0,

        #to_uid   => 4,
        subject => 'Какъв приятен разговор!',
        message => 'Здравей, Приятел!'
    }
)->status_is('400', 'Status is 400');

$t1->post_ok(
    '/вест',
    form => {
        from_uid           => 3,
        subject_message_id => 0,
        to_uid             => 'не число',
        subject            => 'Какъв приятен разговор!',
        message            => 'Здравей, Приятел!'
    }
  )->status_is('400', 'Status is 400')->json_is('/message/to_uid/0/', 'like')
  ->content_like(qr/"message"\:\{"to_uid"\:\["like"/x, 'erros ok: to_uid is not alike ');
my $s_m_id = 0;
for my $id (1, 3, 5) {
    $t1->post_ok(
        '/вест',
        form => {
            from_uid => 3,
            to_uid   => 4,
            subject  => 'разговор' . time,

            # $s_m_id==0 =>new talk
            subject_message_id => $s_m_id,
            message            => "Здравей, Приятел! $id"
        }
      )->status_is('201', 'ok 201 - Created')->header_like(Location => qr/\/id\/\d+/)
      ->content_is('');
    ($s_m_id) = $t1->tx->res->headers->header('Location') =~ qr/\/id\/(\d+)/
      unless $s_m_id;

=pod
{   route  => '/вест/:id',
    params => {id => qr/\d+/},
    via    => ['GET'],
    to     => 'messshow',
},
=cut

    $t2->get_ok("/вест/$id.json")->status_is('200', 'Status is 200')
      ->json_is('/data/message', "Здравей, Приятел! $id", "ok created $id");
    my $next = $id + 1;

#=pod

    #reply from a friend
    $t2->post_ok(
        '/вест',
        form => {
            from_uid           => 4,
            to_uid             => 3,
            subject            => 'Какъв приятен разговор',
            subject_message_id => $s_m_id,
            message            => "Oh, salut mon ami! $next"
        }
      )->status_is('201', 'ok 201 - Created')->header_like(Location => qr"/id/$next")
      ->content_is('');

#=cut

}    # end for my $id

=pod
{   route  => '/вест/:id',
    params => {id => qr/\d+/},
    via    => ['PUT'],
    to     => 'messupdate',
},
=cut

$t1->put_ok(
    '/вест/5',
    form => {
        to_uid             => 4,
        from_uid           => 3,
        subject            => 'Какъв приятен разговор',
        subject_message_id => 1,
        message            => "Let's speak some English."
    }
)->status_is('204', 'Status is 204')->content_is('', 'ok updated id 5');

$t1->get_ok('/вест/5.json')->status_is('200', 'Status is 200')
  ->json_is('/data/message',  "Let's speak some English.", 'ok message 5 is updated')
  ->json_is('/data/to_uid',   4,                           'ok message 5 to_uid is unchanged')
  ->json_is('/data/from_uid', 3,                           'ok message 5 from_uid is unchanged')
  ->json_is(    #becuse it belongs to a talk with id 1
    '/data/subject', '', 'ok message 5 subject is empty'
  )->json_is('/data/subject_message_id', 1, 'ok message 5 subject_message_id is unchanged');

#=cut

#=pod
#{   route  => '/вест/:id',
#    params => {id => qr/\d+/},
#    via    => ['DELETE'],
#    to     => 'vest#disable',
#},
#=cut

$t1->delete_ok('/вест/1')->status_is('200', 'Status is 200')
  ->content_is('not implemented...', 'ok not implemented...yet');
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

done_testing();

