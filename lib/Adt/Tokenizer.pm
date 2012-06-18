# author: joe.zheng

package Adt::Tokenizer;
use Joez::Base -base;

has rules => sub {
  [
    qr|^(?<time>\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) (?<level>\w)/(?<tag>[^(]+)\(\s*(?<pid>\d+)\): (?<text>.*?)$|,

    qr|^(?<text>.*?)$|,    # last one is the default pattern
  ];
};

has _last_match_rule => undef;

sub prepare {
  my $self = shift;

  my @rules = ();
  for my $r (@{$self->rules}) {
    push @rules, ref $r ? $r : qr/$r/i;
  }
  return $self->rules(\@rules)->_last_match_rule(undef);
}

sub process {
  my $self = shift;
  my $line = shift;

  my $token = {};

  return $token unless $line;

  my $r = $self->_last_match_rule;
  if ($r && $line =~ $r) {
    $token = {%+};
  }
  else {
    for my $r (@{$self->rules}) {
      if ($line =~ $r) {
        $token = {%+};

        # do not cache the last pattern, because it is the last
        # choice, and will always match
        $self->_last_match_rule($r) if $r != ${$self->rules}[-1];
        last;
      }
    }
  }

  return $token;
}

1;
__END__
