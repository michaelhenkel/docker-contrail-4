FROM  10.87.64.33:5043/contrail-analytics-base:4.0.0.0-20
COPY entrypoint.sh /
RUN echo hallo
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/python","/usr/bin/contrail-analytics-api","-c","/etc/contrail/contrail-analytics-api.conf","-c","/etc/contrail/contrail-keystone-auth.conf"]
LABEL net.juniper.contrail=config
LABEL net.juniper.node=controller
