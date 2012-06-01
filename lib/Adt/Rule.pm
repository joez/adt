# author: joe.zheng

package Adt::Rule;
use Joez::Base -base;

use Adt::Matcher;

use File::Basename qw/basename/;

has [qw/name probe filter hint/];
has file     => '^';              # default to match all
has 'format' => 'verbose';
has context  => sub { [0, 0] };
has matcher => sub { Adt::Matcher->new->pattern(shift->filter)->prepare };

sub prepare {
  my $self = shift;

  no strict 'refs';

  my $p;
  foreach (qw/probe file/) {
    if ($p = $self->$_) {
      $self->$_(qr/$p/i) unless ref $p;    # scalar
    }
  }

  return $self->reset_stash;
}

sub match_file {
  my ($self, $parser) = @_;
  my $p = $self->file;

  return 0 unless $p;

  if (ref $p eq 'CODE') {
    return $p->($self, $parser);
  }
  else {
    my $file = basename($parser->file);

    return 0 unless $file;
    return $file =~ $p;
  }
}

sub match_filter {
  my ($self, $parser) = @_;
  my $p = $self->filter;

  return 1 unless $p;

  if (ref $p eq 'CODE') {
    return $p->($self, $parser);
  }
  else {
    return $self->matcher->match($parser->current_info);
  }
}

sub match_line {
  my ($self, $parser) = @_;
  my $p = $self->probe;

  return 0 unless $p;

  if (ref $p eq 'CODE') {
    return $p->($self, $parser);
  }
  else {
    my $text = $parser->current_line;

    return 0 unless $text;
    return $text =~ $p;
  }
}

sub get_context {
  my ($self, $parser) = @_;
  my $p = $self->context;

  return undef unless $p;

  if (ref $p eq 'CODE') {
    return $p->($self, $parser);
  }
  else {
    return $parser->context(@{$p});
  }
}

sub get_hint {
  my ($self, $parser) = @_;
  my $p = $self->hint;

  return undef unless $p;

  if (ref $p eq 'CODE') {
    return $p->($self, $parser);
  }
  else {
    return $p;
  }
}

1;
__END__
