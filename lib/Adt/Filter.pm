# author: joe.zheng

package Adt::Filter;
use Joez::Base -base;

has [qw/begin want/] => '^';     # always match
has [qw/end skip/]   => ' ^';    # never match
has backward => 0;

sub prepare {
  my $self = shift;

  no strict 'refs';

  my $p;
  foreach (qw/begin want end skip/) {
    if ($p = $self->$_) {
      $self->$_(qr/$p/i) unless ref $p;    # scalar
    }
  }

  return $self->reset_stash;
}

sub process {
  my $self = shift;
  my $lines = shift or die;

  die if ref $lines ne 'ARRAY';

  my $output = [];
  my $cbs    = $self->stash('cbs');

  unless ($cbs) {

    # generate callbacks
    no strict 'refs';

    foreach my $n (qw/begin end want skip/) {
      my $cb = $self->$n;
      $cbs->{$n} = ref $cb eq 'CODE' ? $cb : sub { $_[1] =~ $cb };
    }

    $self->stash('cbs', $cbs);
  }

  my ($cb_begin, $cb_end, $cb_want, $cb_skip)
    = @{$cbs}{qw/begin end want skip/};

  my $started;
  foreach ($self->backward ? reverse @{$lines} : @{$lines}) {
    unless ($started) {
      $started++ if $cb_begin->($self, $_);
    }

    if ($started) {
      next if $cb_skip->($self, $_);

      push @{$output}, $_ if $cb_want->($self, $_);

      last if $cb_end->($self, $_);
    }
  }

  return $self->backward ? [reverse @{$output}] : $output;
}

1;
__END__
