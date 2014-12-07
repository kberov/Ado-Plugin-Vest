use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
my $t   = Test::Mojo->new('Ado');
my $app = $t->app;

# Remove generic routes (for this test only).
$app->routes->find('controlleraction')->remove();

$app->routes->post('/vest/uadd')->to(
    cb => sub {
        my $c = shift;
        $c->app->plugins->emit_hook(after_user_add => $c, $c->user, {});
        $c->render(text => $c->user->ingroup('vest') || '');
    }
);


isa_ok($app->plugin('vest'), 'Ado::Plugin::Vest');
my $dbh = $app->dbix->dbh;

#The table vest should be created by now.
is($dbh->table_info(undef, undef, 'vest', "'TABLE'")->fetchall_arrayref({})->[0]{TABLE_NAME},
    'vest', 'Table "vest" was created.');

$t->post_ok('/vest/uadd' => {})->status_is(200)->content_is('vest');

#Now user "Guest" should be in group "vest" and have a wellcome message.
my $guest = Ado::Model::Users->by_login_name('guest');
my $ugSQL = <<'SQL';
SELECT user_id FROM user_group 
  WHERE group_id=(SELECT id FROM groups WHERE name='vest') 
  AND user_id=(SELECT id FROM groups WHERE name='guest')
SQL

my $ug = $app->dbix->query($ugSQL)->hash;
is($ug->{user_id}, $guest->id, 'guest is in group vest');
my $wellcomeSQL = <<'SQL';
SELECT subject FROM vest WHERE to_uid=?
SQL

my $wellcome_msg = $app->dbix->query($wellcomeSQL, $guest->id)->hash->{subject};
is($wellcome_msg, 'Wellcome guest!', 'wellcome message');

done_testing();

