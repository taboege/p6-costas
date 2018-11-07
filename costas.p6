#!/usr/bin/env perl6

# Our problem formulation for $N-dimensional Costas arrays uses $N**2
# Boolean variables (at least log2($N!) are needed anyway) which correspond
# to the entries of a permutation matrix. That is what we mean when we
# speak of rows and columns. True Boolean variable is a 1 in the permutation
# matrix.

class Literal {
    has $.negated is rw;
    has $.i;
    has $.j;

    method Str {
        ($!negated ?? "-" !! "") ~ (1 + $!i * $*N + $!j);
    }
}

multi sub prefix:<¬> (Literal $l --> Literal) {
    $l.negated .= not;
    $l
}

multi sub circumfix:<⸨ ⸩> (List $ij where .elems == 2 --> Literal) {
    new Literal: :!negated, :i($ij[0]), :j($ij[1]);
}

# TODO: I remember one of our SAT solvers has support for E-clauses
# (which are clauses with the implicit instruction to the solver
# that they must be satisfied with exactly one satisfied literal).
# Those would make some parts easier.

# Every row and column needs exactly one true variable.
sub permutation-axioms {
    gather {
        # At least one true variable ...
        #   • per row:    ∨_j (i,j) for all i
        for ^$*N -> $i {
            take [⸨$i,$_⸩ for ^$*N];
        }
        #   • per column: ∨_i (i,j) for all j
        for ^$*N -> $j {
            take [⸨$_,$j⸩ for ^$*N];
        }

        # At most one true variable ...
        #   • per row:         (i,j) => ∧_{k≠j} ¬(i,k)
        #     which is in CNF: ∧_{k≠j} (¬(i,j)∨¬(i,k)) for all (i,j)
        for [X] ^$*N xx 2 -> ($i, $j) {
            take [¬⸨$i,$j⸩, ¬⸨$i,$_⸩] for ^$*N .grep(* ≠ $j);
        }
        #   • per column:      (i,j) => ∧_{k≠i} ¬(k,j)
        #     which is in CNF: ∧_{k≠i} (¬(i,j)∨¬(k,j)) for all (i,j)
        for [X] ^$*N xx 2 -> ($i, $j) {
            take [¬⸨$i,$j⸩, ¬⸨$_,$j⸩] for ^$*N .grep(* ≠ $i);
        }
    }
}

# If the two variables (i,j) and (i+u,j+v) are true, then no other pair
# of variables (x,y) and (w,z) which are true are allowed to have the same
# distance and slope, i.e. w=x+u and z=y+v. This condition introduces
# $N**6 clauses (which is a LOT for the application N=32 we have in mind).
sub costas-axioms {
    # That is, (i,j) ∧ (i+u,j+v) => ∧_{x,y} ¬((x,y) ∧ (x+u,y+v)),
    # which in CNF reads:
    #   • ¬(i,j) ∨ ¬(i+u,j+v) ∨ ¬(x,y) ∨ ¬(x+u,y+v)
    # where i,j run through ^$N, u through 0..$N, v through -$N..$N
    # (but u and v are not both zero) and x,y run through ^$N.
    # Only those clauses where i+u, j+v, x+u and y+v are defined
    # must be emitted.
    gather for [X] ^$*N xx 2 -> ($i, $j) {
        for 0..$*N X -$*N..$*N -> ($u, $v) {
            next if $u == 0 and $v == 0;
            next if $i+$u >= $*N or $j+$v >= $*N or $j+$v < 0;
            for [X] ^$*N xx 2 -> ($x, $y) {
                next if $x+$u >= $*N or $y+$v >= $*N or $y+$v < 0;
                take [¬⸨$i,$j⸩, ¬⸨$i+$u,$j+$v⸩, ¬⸨$x,$y⸩, ¬⸨$x+$u,$y+$v⸩];
            }
        }
    }
}

sub MAIN (Int $N = fail "missing dimension") {
    my $*N = $N; # Literal.Str depends on this because I don't want to store $N in every literal

    my @axioms = [|permutation-axioms, |costas-axioms];
    say "c Description of Costas arrays in dimension $N";
    say "p cnf { $N**2 } { elems @axioms }";
    for @axioms -> @clause {
        say @clause».Str.join(' '), " 0";
    }
}
