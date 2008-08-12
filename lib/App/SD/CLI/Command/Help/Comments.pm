package App::SD::CLI::Command::Help::Comments;
use Moose;
extends 'App::SD::CLI::Command::Help';

sub run {
        my $self = shift;
            $self->print_header('Working with ticket comments');
                my $cmd = $self->_get_cmd_name;
                
print <<EOF
 $cmd ticket comment 456
     Add a comment to the ticket with id 456, popping up a text editor
 
 $cmd ticket comment 456 --file=myfile
     Add a comment to the ticket with id 456, using the content of 'myfile'
 
 $cmd ticket comment list
     List all ticket comments 
 
 $cmd ticket comment show 4
     Show ticket comment 4 and all metadata
EOF

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
