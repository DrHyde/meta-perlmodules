perl Makefile.PL
if( "${{ matrix.perl-version }}" -lt "5.26" ) { dmake test TEST_VERBOSE=1 } else { gmake test TEST_VERBOSE=1 }
