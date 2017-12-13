# PantheonSiteSync Todo List
1) For Multisite additional parameters for Faculty websites:

    Add aliases into /etc/hosts
    Add aliases into:
        WEB_SERVER_ETC="/usr/local/etc/apache2/2.4"
            WEB_SERVER_VHOST="$WEB_SERVER_ETC/extra/httpd-vhosts.conf"
                ServerAlias blockchain.lab.local www.blockchain.lab-dev.local

            WEB_SERVER_SSL="$WEB_SERVER_ETC/extra/httpd-ssl.conf"
                ServerAlias blockchain.lab.local www.blockchain.lab-dev.local

            Generate certs for alias domains
                WEB_SERVER_ETC="/usr/local/etc/apache2/2.4"
                WEB_SERVER_CERTS="$WEB_SERVER_ETC/certs"

2) Change Drupal database variable: purl_base_domain
    E.g.:
        UPDATE variable
        SET    value='s:32:"https://blockchain.lab-dev.local";'
        WHERE  name = 'purl_base_domain'

    Remove the cached variables
        DELETE FROM cache_bootstrap WHERE cid = 'variables'"?

3) Other updates in the Database:
    UPDATE field_data_field_group_path
    SET field_group_path_url = REPLACE(field_group_path_url, 'dev-faculty-pages.ws.asu.edu', 'blockchain.lab-dev.local')
    WHERE field_group_path_url LIKE ('%/dev-faculty-pages.ws.asu.edu/%');

    UPDATE field_revision_field_group_path
    SET field_group_path_url = REPLACE(field_group_path_url, 'dev-faculty-pages.ws.asu.edu', 'blockchain.lab-dev.local')
    WHERE field_group_path_url LIKE ('%/dev-faculty-pages.ws.asu.edu/%');

4) The timing works in terms of lapsed time but it's about 7 hours off for the start and end time suggesting it's using UTC instead of local time, fix it.
