FROM alpine:3.8

# Get hlstatsxce perl daemon scripts and set permissions
RUN apk add --no-cache git \
    && git clone https://bitbucket.org/Maverick_of_UC/hlstatsx-community-edition.git /hlstatsx-community-edition \
    && cd /hlstatsx-community-edition \
    && git checkout 11cac08de8c01b7a07897562596e59b7f0f86230 \
    && mv /hlstatsx-community-edition/scripts /app \
    && find /app -type d -exec chmod 750 {} \; \
    && find /app -type f -exec chmod 640 {} \; \
    && find /app -type f -name '*.sh' -exec chmod 750 {} \; \
    && find /app -type f -name '*.pl' -exec chmod 750 {} \; \
    && find /app -type f -name 'run_*' -exec chmod 750 {} \; \
    && rm -rf /hlstatsx-community-edition \
    && apk del git

# Download the GeoIP binary. Maxmind discontinued distributing the GeoLite Legacy databases. See: https://support.maxmind.com/geolite-legacy-discontinuation-notice/
# So let's download it from our fork of GeoLiteCity.dat
RUN apk add --no-cache ca-certificates wget \
    && rm -rf /var/lib/apt/lists/* \
    && cd /app/GeoLiteCity \
    && wget -qO- https://github.com/startersclan/GeoLiteCity-data/raw/c14d99c42446f586e3ca9c89fe13714474921d65/GeoLiteCity.dat > GeoLiteCity.dat \
    && chmod 666 GeoLiteCity.dat \
    && ls -l

# Download the GeoIP2 binary. Maxmind discontinued distributing the GeoLite2 databases publicly, so a license key is needed. See: https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/
# In order to obtain the secret MAXMIND_LICENSE_KEY, we assume we have a sidecar secrets-server which will serve the secret MAXMIND_LICENSE_KEY at: http://localhost:8000/MAXMIND_LICENSE_KEY
RUN apk add --no-cache ca-certificates curl \
    && cd /app/GeoLiteCity \
    && ls -l; \
    \
    echo "Downloading a copy of GeoLite2City..."; \
    URL="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$( curl -s http://localhost:8000/MAXMIND_LICENSE_KEY )&suffix=tar.gz"; \
    FILE=$( curl -sI "$URL" | grep -i 'content-disposition' | sed 's/.*filename=//i' | tr -d '\r\n' ); \
    echo "FILE: $FILE"; \
    curl -so "$FILE" "$URL"; \
    if [ $? = 0 ]; then \
        tar -tvf "$FILE"; \
        echo "Uncompressing database"; \
        MMDB_PATH=$( tar -tvf "$FILE" | grep '.mmdb' | awk '{print $6}' ); \
        MMDB_FOLDER=$( dirname $MMDB_PATH ); \
        MMDB=$( basename "$MMDB_PATH" ); \
        echo "MMDB_PATH: $MMDB_PATH"; \
        echo "MMDB_FOLDER: $MMDB_FOLDER"; \
        echo "MMDB: $MMDB"; \
        tar -zxvf "$FILE" "$MMDB_PATH"; \
        mv "$MMDB_PATH" "$MMDB"; \
        chmod 666 *.mmdb; \
        echo "Cleaning up"; \
        rm -rf $( echo $MMDB_FOLDER | sed "s/.+$MMDB//" ); \
        rm -rf $FILE; \
        ls -l; \
    fi; \
    apk del curl; \
    if [ ! -f GeoLite2-City.mmdb ]; then \
        echo "Could not download GeoIP2 db"; \
        exit 1; \
    fi;

# Install perl
RUN apk add --no-cache \
    wget \
    perl \
    perl-dev \
    perl-doc

#
# Perl modules
#

# Install DB perl modules through packages
RUN apk add --no-cache \
        perl-dbi \
        perl-dbd-mysql

# Install modules for perl GeoIP
RUN apk add --no-cache --virtual build-dependencies \
        build-base \
        perl-app-cpanminus \
    && cpanm \
        Geo::IP::PurePerl \
    && apk del build-dependencies \
    && rm -rf /root/.cpan /root/.cpanminus

# Install modules for perl GeoIP2
# 11 dependencies missing for GeoIP2:
#   - 11 dependencies missing (Data::Validate::IP,LWP::Protocol::https,List::SomeUtils,MaxMind::DB::Metadata,MaxMind::DB::Reader,Moo,Moo::Role,Params::Validate,Path::Class,Throwable::Error,namespace::clean);
RUN apk add --no-cache --virtual build-dependencies \
        build-base \
        perl-app-cpanminus \
    #&& apk add --no-cache \
        #perl-datetime \
        #perl-path-class \
        perl-net-ssleay \
        #perl-libwww \
        #perl-lwp-protocol-https \
        #perl-netaddr-ip \
        #perl-list-someutils \
        #perl-params-validate \
        #perl-namespace-clean \
        #perl-list-allutils \
        #perl-moo \
        #perl-net-ip \
    # Workaround the fact that HTTP::Daemon@6.0.6 unit tests fail, probably due to ipv6 tests - let's use an older version
    && cpanm \
        HTTP::Daemon@6.01 \
    && cpanm \
        MaxMind::DB::Reader \
        GeoIP2 \
# Install maxmind DB::Reader::XS (faster than MaxMind::DB::Reader)
# See: https://github.com/maxmind/libmaxminddb
# NOTE: Not working atm, tests fail at MAXMIND's Net::Works::Network
#
    # && apk add --no-cache \
    #     libmaxminddb \
    #     libmaxminddb-dev \
    # && cpanm \
    #     MaxMind::DB::Reader::XS \
    && apk del build-dependencies \
    && rm -rf /root/.cpan /root/.cpanminus

COPY ./docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

EXPOSE 27500/udp

STOPSIGNAL SIGINT

WORKDIR /app

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["perl", "./hlstats.pl"]