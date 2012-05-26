# author: joe.zheng

package Adt::Output;
use Joez::Base -base;

use overload
  'bool'   => sub {1},
  '""'     => sub { shift->to_string },
  fallback => 1;

has [qw/line lines_before lines_after/];
has [qw/file lineno rule/];
has 'time' => 0;

my $prefix_top = '# [[ ';
my $prefix_end = '# ]] ';
my $prefix_cur = '===> ';
my $prefix_com = '# ';

sub compare {
  $_[0]->time <=> $_[1]->time
    || $_[0]->file cmp $_[1]->file
    || $_[0]->lineno <=> $_[1]->lineno;
}

sub to_string {
  my $self = shift;
  my $rule = $self->rule;

  my @content;

  my $before   = $self->lines_before;
  my $after    = $self->lines_after;
  my $mark_cur = @{$before} || @{$after} ? $prefix_cur : '';

  if ($rule->format eq 'raw') {
    push @content, @{$before}, $mark_cur . $self->line, @{$after}, "\n";
  }
  else {
    my $info = sprintf "file: %s, line: %d, rule: %s\n", $self->file,
      $self->lineno, $rule->name;
    push @content, $prefix_top . $info;

    push @content, $prefix_com . $rule->hint, "\n" if $rule->hint;

    push @content, @{$before}, $mark_cur . $self->line, @{$after}, $prefix_end,
      "\n\n";
  }

  return join '', @content;
}

1;
__END__
