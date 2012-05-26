# author: joe.zheng

package Adt::Matcher;
use Joez::Base -base;

has tokenizer => sub { Adt::Tokenizer->new };
has [qw/pattern/];

sub prepare {
  my $self = shift;

  return $self->reset_stash;
}

sub match {
  my $self = shift;
  my $info = shift;

  return 1 unless $self->pattern;
  return 0 unless $info;

  my $type = ref $info;
  die if $type && $type ne 'HASH';

  # should be hash reference
  $info = $self->tokenizer->process($info) unless $type;

  my $pattern = $self->stash('pattern');

  unless ($pattern) {
    my $p = $self->pattern;
    unless (ref $p) {
      for (split /\s*,\s*/, $p) {
        next unless $_;

        my ($k, $v) = split /\s*:\s*/;
        unless (defined $v) {

          # if there is no 'key', assume its key is 'tag'
          $v = $k;
          $k = 'tag';
        }
        push @{$pattern->{$k}}, $v;
      }

      # compile the regex
      my %compiled;
      while (my ($k, $v) = each %$pattern) {
        my $r = join '|', @$v;
        $compiled{$k} = qr/$r/i;
      }
      $pattern = \%compiled;
    }
    else {

      # regex is for 'tag' filter
      $pattern->{'tag'} = $p;
    }

    $self->stash('pattern', $pattern);
  }

  for my $k (sort keys %$pattern) {
    my $s = $info->{$k};

    return 0 unless $s;
    return 0 unless $s =~ $pattern->{$k};
  }

  return 1;
}

1;
__END__
