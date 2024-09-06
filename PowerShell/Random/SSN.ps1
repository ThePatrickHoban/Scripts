# Generate every possible combination of Social Security Numbers (SSN)
0..999999999 | % {"{0:000-00-0000}" -f $_}
