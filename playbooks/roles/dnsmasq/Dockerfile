FROM alpine:edge
# Source: https://hub.docker.com/r/andyshinn/dnsmasq/
RUN apk --no-cache add dnsmasq
# RUN echo '37.60.244.101 bla.net' >> /etc/hosts
EXPOSE 53 53/udp
ENTRYPOINT ["dnsmasq", "-k"]