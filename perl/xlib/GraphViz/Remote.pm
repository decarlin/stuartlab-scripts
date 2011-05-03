package GraphViz::Remote;

use strict;
use GraphViz;
use HTTP::Request::Common;
use LWP::UserAgent;
use vars qw($VERSION @ISA);

# This is incremented every time there is a change to the API
$VERSION = '0.01';

@ISA = qw(GraphViz);

=head1 NAME

GraphViz::Remote - use graphviz without installing it

=head1 SYNOPSIS

  use GraphViz::Remote;

  my $g = GraphViz::Remote->new();
  # methods as for GraphViz

=head1 DESCRIPTION

Installing the graphviz tools dot and neato is occasionally
tricky. This module allows you to send your GraphViz object across the
Internet to a GraphViz server which processes the graph with the
graphviz tools. That way, you do not need to install graphviz locally.

=head1 METHODS

As for GraphViz.

=cut


sub _as_generic {
  my($self, $type, $dot) = @_;

  my $ua = LWP::UserAgent->new;

  my $response = $ua->request(POST 'http://www.astray.com/GraphViz/graphviz.cgi',
			      [ type => $type, directed => $self->{DIRECTED}, dot => $dot]);

  my $out;
  if ($response->is_success) {
    $out = $response->content;
  } else {
    $out = $response->error_as_HTML;
  }

  return $out;
}


=head1 NOTES

This module functions by running dot and neato on my own personal
webserver, so please do not use this script too often or with large
graphs. If you intend to use GraphViz a lot, please install it
locally! Many thanks.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
