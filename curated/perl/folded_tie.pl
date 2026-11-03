#!/usr/bin/env perl
# Perl 5.16+: tied hash with ASCII case-folded keys and snapshot iteration.
# perl folded_tie.pl; core modules only. Values are opaque scalars, including
# undef. Keys are canonical lowercase ASCII. Like an ordinary Perl hash, there
# is one active iterator; keys restarts it and each advances it. New keys do not enter an active
# snapshot; deleted keys are skipped. Invalid accesses throw before mutation.
use strict;
use warnings FATAL => 'all';

{
    package FoldedHash;
    use Carp qw(croak);
    sub TIEHASH { bless { data => {}, scan => [], cursor => 0 }, shift }
    sub canonical {
        my ($key) = @_;
        croak 'invalid key' unless $key =~ /\A[A-Za-z][A-Za-z0-9_-]{0,31}\z/;
        $key =~ tr/A-Z/a-z/;
        return $key;
    }
    sub STORE {
        my ($self, $key, $value) = @_;
        $self->{data}{canonical($key)} = $value;
    }
    sub FETCH { my ($self, $key) = @_; return $self->{data}{canonical($key)}; }
    sub EXISTS { my ($self, $key) = @_; return exists $self->{data}{canonical($key)}; }
    sub DELETE { my ($self, $key) = @_; return delete $self->{data}{canonical($key)}; }
    sub CLEAR {
        my ($self) = @_;
        $self->{data} = {};
        $self->{scan} = [];
        $self->{cursor} = 0;
    }
    sub SCALAR { my ($self) = @_; return scalar keys %{$self->{data}}; }
    sub FIRSTKEY {
        my ($self) = @_;
        $self->{scan} = [sort keys %{$self->{data}}];
        $self->{cursor} = 0;
        return $self->NEXTKEY();
    }
    sub NEXTKEY {
        my ($self) = @_; # previous key is unnecessary: this tie owns its cursor
        while ($self->{cursor} < @{$self->{scan}}) {
            my $key = $self->{scan}[$self->{cursor}++];
            return $key if exists $self->{data}{$key};
        }
        return undef;
    }
}
sub check { my ($truth, $label) = @_; die "assertion failed: $label\n" unless $truth; }
tie my %table, 'FoldedHash';
check(scalar(%table) == 0, 'empty scalar count');
$table{Alpha} = 1;
$table{BETA} = undef;
check(exists($table{beta}) && !defined($table{beta}), 'undef differs from absence');
check(!exists($table{missing}) && !defined($table{missing}), 'missing lookup');
$table{ALPHA} = 2;
check(scalar(%table) == 2 && $table{alpha} == 2, 'aliases share one slot');
check(join(',', keys %table) eq 'alpha,beta', 'canonical sorted keys');
check(delete($table{aLpHa}) == 2 && !exists($table{ALPHA}), 'delete alias');
check(!defined(delete($table{alpha})), 'delete missing');

%table = (Alpha => 1, Beta => 2, Gamma => 3);
my ($first, $value) = each %table;
check($first eq 'alpha' && $value == 1, 'first sorted item');
$table{Delta} = 4; # new entry excluded from the already active snapshot
delete $table{BETA};
$table{GAMMA} = 30; # snapshot keys, but current values
my @rest;
while (my ($key, $item) = each %table) { push @rest, "$key=$item"; }
check(join(',', @rest) eq 'gamma=30', 'snapshot excludes additions, skips deletions and reads current values');
check(join(',', keys %table) eq 'alpha,delta,gamma', 'fresh iteration sees current keys');
for my $bad ('', '1name', 'bad key', '../escape', 'x' x 33, "\x{e9}") {
    my $ok = eval { $table{$bad} = 9; 1 };
    check(!$ok && $@ =~ /\Ainvalid key/, 'invalid store rejected');
    check(scalar(%table) == 3 && $table{alpha} == 1 && $table{delta} == 4,
          'failed store preserves state');
    $ok = eval { my $ignored = $table{$bad}; 1 };
    check(!$ok && $@ =~ /\Ainvalid key/, 'invalid fetch rejected');
}
my $boundary = 'A' x 32;
$table{$boundary} = 0;
check(exists($table{lc $boundary}) && $table{lc $boundary} == 0, '32-byte key and false value');
my $payload = { count => 1 };
$table{Object} = $payload;
check(ref($table{object}) eq 'HASH' && $table{object} eq $payload, 'reference identity');
$table{object}{count} = 9;
check($payload->{count} == 9, 'reference values retain ordinary Perl aliasing');
%table = (Only => undef);
check(scalar(%table) == 1 && exists($table{ONLY}), 'assignment invokes clear then store');
%table = ();
check(scalar(%table) == 0 && !defined(each %table), 'clear resets iteration');
untie %table;
print "Perl tie: canonical keys, undef/absence, scalar count, snapshot iteration, mutation and exact key limits passed\n";
