# author: joe.zheng

package Adt::Parser;
use Joez::Base -base;

use Adt::Reporter;
use Adt::Tokenizer;

has rules             => sub { [] };
has _rules_match_file => sub { [] };
has reporter          => sub { Adt::Reporter->new };
has tokenizer         => sub { Adt::Tokenizer->new };

has file      => '';
has file_time => 0;
has lines     => sub { {} };
has topno     => 0;
has curno     => 0;
has endno     => 0;

has offset_top => 300;
has offset_end => 400;

my $re_skip
  = qr/\.(:?3gp|mp4|avi|wmv|mp3|ogg|aac|wma|wav|jpg|png|gif|bmp|dmp|dbg|rar|zip|tar|gz|tgz|7z|lzma)$/i;

sub context {
  my $self         = shift;
  my $lines_before = shift || 0;
  my $lines_after  = shift || 0;
  my $current      = shift || $self->curno;

  my $start = $current - $lines_before;
  $start = $self->topno if $start < $self->topno;
  my $end = $current + $lines_after;
  $end = $self->endno if $end > $self->endno;

  return [@{$self->lines}{$start .. $current - 1}],
    [@{$self->lines}{$current + 1 .. $end}];
}

sub current_line {
  my $self = shift;

  return $self->lines->{$self->curno};
}

sub current_info {
  my $self = shift;

  my $info = $self->stash('info');
  return $info if exists $info->{'text'};

  $info = $self->tokenizer->process($self->current_line || '');
  $self->stash('info', $info);
  return $info;
}

sub prepare {
  my $self = shift;

  $self->lines({})->curno(0)->topno(0)->endno(0);

  my $matched_rules = [];
  foreach my $r (@{$self->rules}) {
    push @{$matched_rules}, $r if $r->match_file($self);
  }
  $self->_rules_match_file($matched_rules);

  $self->file_time((stat $self->file)[9])->reset_stash;
}

sub capable {
  my $self = shift;
  my $file = $self->file;

  return 0 unless @{$self->_rules_match_file};    # no rules
  return 0 if $file =~ $re_skip;                  # skip these files
  return 0 if $file eq $self->reporter->path;     # skip report path
  return -f $self->file && -T _;                  # plain text only
}

sub feed {
  my $self = shift;

  foreach my $line (@_) {

    # normalize the 'end of line'
    $line =~ s/\r\n/\n/;

    my $endno = $self->endno + 1;

    $self->endno($endno)->lines->{$endno} = $line;

    if ($self->endno - $self->curno > $self->offset_end) {
      $self->parse;
    }
  }

  return $self;
}

sub done {
  my $self = shift;

  while ($self->endno > $self->curno) {
    $self->parse;
  }

  return $self;
}

sub parse {
  my $self = shift;

  if ($self->endno > $self->curno) {
    $self->{curno}++;
    $self->stash('info', {});

    foreach my $rule (@{$self->_rules_match_file}) {
      if ($rule->match_line($self) && $rule->match_filter($self)) {
        if ($self->reporter) {
          $self->reporter->feed($self, $rule);
        }
        last;
      }
    }

    if ($self->curno - $self->topno > $self->offset_top) {
      delete $self->lines->{$self->topno};
      $self->{topno}++;
    }
  }

  return $self;
}

1;
__END__
