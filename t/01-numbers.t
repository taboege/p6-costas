#!/usr/bin/env perl6

use Test;

my %RESULTS =
    # sharpSAT fails an internal assertion with this trivial one
    #'costas1.cnf' => 1,
    'costas2.cnf'  => 2,
    'costas3.cnf'  => 4,
    'costas4.cnf'  => 12,
    'costas5.cnf'  => 40,
    'costas6.cnf'  => 116,
    'costas7.cnf'  => 200,
    # These usually take longer
    #'costas8.cnf'  => 444,
    #'costas9.cnf'  => 760,
    #'costas10.cnf' => 2160,
;

my @cnfs = %RESULTS.keys.sort;

plan +@cnfs;
# TODO: Make this more portable. Ideally, we would use a SAT solver module.
my $which = run 'which', 'sharpSAT', :out, :err;
bail-out 'sharpSAT needs to be available in $PATH' unless $which;
my $solver = $which.out.slurp.trim;

# sharpSAT likes to create a data.out file in the CWD. We remove that if
# it exists after the tests, but only if it didn't exist before, because
# it might be the user's file.
my $have-data-out = "data.out".IO.e;

for @cnfs -> $f {
    my $proc = shell "$solver 't/$f' | grep -A1 '# solutions' | tail -n1", :out;
    is $proc.out.slurp.Int, %RESULTS{$f}, "count of $f";
}

if "data.out".IO.e and not $have-data-out {
    diag "removing data.out created by sharpSAT";
    unlink "data.out";
}
