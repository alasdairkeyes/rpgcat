package RPGCat::Controller::Character;

use Moose;
use namespace::autoclean;

use HTML::FormHandler;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

RPGCat::Controller::Character

=head1 DESCRIPTION

Character related pages - creation, edit character info?

=cut

sub character_chain :Chained("/") PathPart("character") CaptureArgs(0) Does('NeedsAccount') {
    my ($self, $c) = @_;

}

=head2 /character

FIXME: Not sure what this page should contain!

=cut

sub character_index :Chained("character_chain") PathPart("") Args(0) {
    my ($self, $c) = @_;

    $c->stash(
        template => "character/index.html",
    );
}

sub character_create :Chained("character_chain") PathPart("create") Args(0) {
    my ($self, $c) = @_;

    $c->stash( template => "character/create.html" );

    my $create_form = HTML::FormHandler->new(
        field_list => [
            character_name => {
                # do_wrapper => 0,
                type => "Text",
                required => 1,
                messages => {
                    required => 'You must enter a character name',
                    text_minlength => 'That name is too short',
                    text_maxlength => 'That name is too long',
                },
                # Hardcoded min length of 3
                minlength => 3,
                # Hardcoded max length of 30 (NB db field is 32 characters)
                maxlength => 30,
                not_nullable => 1,
            },
            submit => {
                # do_wrapper => 0,
                type => "Submit",
                value => "Submit"
            },
        ],
    );

    my $fp = $c->request->params;
    $c->stash(
        params => $fp,
        create_form => $create_form,
    );
    unless ($c->request->method =~ /^POST$/i) {
        $c->detach();
    }

    $create_form->process( params => $fp );

    # Character validation
    # 1. Check name meets the criteria (min length, max length, permitted characters)
    unless ($create_form->validated) {
        # Didn't validate. Fields will already have errors assigned.
        $c->detach();
    }

    # 2. Check if name exists in db already
    # 3. Create character and link to account

    # Potential race condition between 2 & 3 so character name is a unique
    # key and if an error occurs when inserting, we assume it's because
    # the name is already taken. This combines steps 2 and 3, eliminating
    # the race condition.

    $c->log->debug("adding new character " . $fp->{ character_name });
    my $new_character = eval {
        $c->user->create_related( 'characters' => {
            character_name => $fp->{ character_name }
        });
    };
    if ($@ || !$new_character) {
        $create_form->add_form_error(
            "Error creating character. Name probably in use already."
        );
        $c->detach();
    }

    $c->response->redirect($c->uri_for("/account", {
        mid => $c->set_success_msg(
            "Character " . $fp->{ character_name } . " created."
        )
    }));
}

=head1 AUTHOR

Simon Amor <simon@leaky.org>

=head1 LICENSE

This program is free software; but please see the LICENSING file for
more information.

=cut

1;
