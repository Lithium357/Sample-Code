#!/usr/bin/env perl
# Perl 5.16+, core modules. Byte records from an owned, regular raw file.
# Fixed width 1..4096; allow/reject final short record. Paths may contain spaces.
# No concurrent file changes, pipes, devices or VMS record-file claim.
# Callbacks run synchronously with (bytes, zero-based index). Earlier callback
# effects survive a later short-tail/error; no transaction/rollback is promised.
# $/ is localized only while reading; callback sees its caller's separator.
# API reference: https://perldoc.perl.org/perlvar (input record separator).
use strict;
use warnings FATAL => 'all';
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(refaddr);

sub records_from_file {
    my ($path, $width, $tail, $callback) = @_;
    die "width: expected integer 1..4096\n"
        unless defined($width) && !ref($width) && $width =~ /\A[0-9]+\z/
            && $width >= 1 && $width <= 4096;
    die "tail: expected allow or reject\n"
        unless defined($tail) && ($tail eq 'allow' || $tail eq 'reject');
    die "callback: expected CODE\n" unless ref($callback) eq 'CODE';
    open my $input, '<:raw', $path or die "open: $!\n";
    my $count = 0;
    # Do not clobber the caller's eval error. Save an exception immediately:
    # close may itself alter ambient error state. A callback exception wins.
    local $@;
    my $ok = eval {
        my $pending = '';
        while (1) {
            my $part;
            {
                my $remaining = $width - length($pending);
                $/ = \$remaining;
                local $! = 0;
                $part = <$input>;
                die "read: $!\n" if !defined($part) && $!;
            }
            if (!defined $part) {
                if (length $pending) {
                    die "tail: short final record\n" if $tail eq 'reject';
                    $callback->($pending, $count++);
                }
                last;
            }
            # Coalesce short reads rather than assuming every read is full.
            $pending .= $part;
            if (length($pending) == $width) {
                $callback->($pending, $count++);
                $pending = '';
            }
        }
        1;
    };
    my $error = $@;
    my $closed = close $input;
    die $error unless $ok;
    die "close: $!\n" unless $closed;
    return $count;
}

unless (caller) {
    my $checks = 0;
    my $check = sub { die "failed: $_[1]\n" unless $_[0]; ++$checks };
    my $dir = tempdir('records with spaces XXXXX', TMPDIR => 1, CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'binary fixture.dat');
    my $write = sub {
        my ($target, $bytes) = @_;
        open my $out, '>:raw', $target or die "fixture open: $!";
        print {$out} $bytes or die "fixture write: $!";
        close $out or die "fixture close: $!";
    };
    my $failure = sub {
        my ($pattern, $operation) = @_;
        local $@;
        my $ok = eval { $operation->(); 1 };
        my $error = $@;
        $check->(!$ok && !ref($error) && $error =~ $pattern, 'expected error');
        return $error;
    };
    # Independent partition oracle uses substr on the original byte fixture;
    # it neither reads a handle nor uses the input record separator.
    for my $length (0..96, 255, 256, 257, 4095, 4096, 4097) {
        my $bytes = pack('C*', map { ($_ * 73 + 11) % 256 } 0..$length-1);
        $write->($path, $bytes);
        for my $width (1..24, 4095, 4096) {
            my @expected;
            for (my $at = 0; $at < $length; $at += $width) {
                push @expected, substr($bytes, $at, $width);
            }
            for my $separator (undef, '', "\n", 'not a delimiter') {
                local $/ = $separator;
                my (@actual, @indices);
                my $count = records_from_file($path, $width, 'allow', sub {
                    push @actual, $_[0]; push @indices, $_[1];
                    $check->(defined($separator) ? defined($/) && $/ eq $separator : !defined($/),
                             'callback separator scope');
                });
                $check->($count == @expected && @actual == @expected, 'record count');
                $check->(join('', @actual) eq $bytes, 'byte conservation');
                $check->(join(',', @indices) eq join(',', 0..$#expected), 'indices');
                for my $index (0..$#expected) {
                    $check->($actual[$index] eq $expected[$index], 'independent record oracle');
                }
                $check->(defined($separator) ? defined($/) && $/ eq $separator : !defined($/),
                         'separator restored on success');
            }
        }
    }
    $write->($path, "a\x00b\nc");
    my @seen;
    $failure->(qr/^tail: short final record/, sub {
        records_from_file($path, 2, 'reject', sub { push @seen, $_[0] });
    });
    $check->(@seen == 2 && $seen[0] eq "a\x00" && $seen[1] eq "b\n", 'tail does not undo callbacks');
    $write->($path, 'abcd');
    $check->(records_from_file($path, 2, 'reject', sub {}) == 2, 'exact rejected-tail boundary');
    $write->($path, '');
    $check->(records_from_file($path, 2, 'reject', sub { die 'empty callback' }) == 0, 'empty input');

    my $nested = File::Spec->catfile($dir, 'nested file.dat');
    $write->($path, 'abcdef'); $write->($nested, '12345');
    my $sentinel = 9;
    local $/ = \$sentinel;
    my $address = refaddr($/);
    my @outer;
    records_from_file($path, 2, 'allow', sub {
        push @outer, $_[0];
        my @inner;
        records_from_file($nested, 3, 'allow', sub { push @inner, $_[0] });
        $check->(join('|', @inner) eq '123|45', 'nested reader width');
        $check->(refaddr($/) == $address && ${$/} == 9, 'nested dynamic localization');
    });
    $check->(join('|', @outer) eq 'ab|cd|ef', 'outer continues after nested reads');
    my $boom = bless { reason => 'callback fixture' }, 'RecordFixtureError';
    {
        local $@ = 'outer eval sentinel';
        my $observed;
        { local $@; eval { records_from_file($path, 2, 'allow', sub { die $boom }); 1 }; $observed = $@; }
        $check->(ref($observed) && refaddr($observed) == refaddr($boom), 'callback exception identity');
        $check->($@ eq 'outer eval sentinel', 'caller eval state restored');
    }
    $check->(refaddr($/) == $address, 'separator restored after callback exception');
    $check->(records_from_file($path, 3, 'allow', sub {}) == 2, 'fresh file read after failure');
    for my $width (0, -1, 4097, 1.5, undef, []) {
        $failure->(qr/^width:/, sub { records_from_file($path, $width, 'allow', sub {}) });
    }
    $failure->(qr/^tail:/, sub { records_from_file($path, 2, 'ignore', sub {}) });
    $failure->(qr/^callback:/, sub { records_from_file($path, 2, 'allow', undef) });
    $failure->(qr/^open:/, sub { records_from_file(File::Spec->catfile($dir, 'absent'), 2, 'allow', sub {}) });
    print "scoped byte records: $checks checks passed\n";
}
