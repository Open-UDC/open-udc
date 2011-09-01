## unik board

Welcome to unik board, a place where to verify and publish your grains.

To setup this board, you'll need couchdb. But also to install soca:
    sudo gem install soca

Then:
    compass watch . --sass-dir "sass" --css-dir "css" --javascripts-dir "js" --images-dir "images"
    soca autopush

The gpg decryption mechanism is a node file managed by couchdb. In the /etc/couhdb/local.ini file needs to be declared:
    [httpd_global_handlers]
    upload = {couch_httpd_proxy, handle_proxy_req, <<"http://localhost:9000">>}

    [os_daemons]
    gpg_upload = /home/manu/develop/open-udc/unikboard/proxy/couch-gpg.js
