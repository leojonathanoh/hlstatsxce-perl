@"
FROM ubuntu:16.04

#
# Export these environment variables
#

# MCPAN non-interactive (silent). It makes perl automatically answer "yes" when CPAN asks "Would you like to configure as much as possible automatically? [yes]"
# Same as using:
#   export PERL_MM_USE_DEFAULT=1
ENV PERL_MM_USE_DEFAULT 1

# Perl module installation location
# Enable line(s) if entrypoint throws errors about missing modules in @INC
# Same as using:
#   export PERL_MM_OPT=/usr/share/perl5
#   export PERL_MB_OPT=/usr/share/perl5
#ENV PERL_MM_OPT /usr/share/perl5
#ENV PERL_MB_OPT /usr/share/perl5

# Perl @INC location
# Enable line(s) if entrypoint throws errors about missing modules in @INC
# Same as using:
#   export PERL5LIB=/usr/share/perl5
#ENV PERL5LIB /usr/share/perl5

# Install perl
RUN apt-get update \
    && apt-get install -y \
        perl \
    && rm -rf /var/lib/apt/lists/*

#
# Perl modules
#

# Install DB perl modules through packages
RUN apt-get update \
    && apt-get install -y \
        libdbi-perl \
        libdbd-mysql-perl \
    && rm -rf /var/lib/apt/lists/*
"@