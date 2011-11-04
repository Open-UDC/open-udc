## unik board

Welcome to unik board, a place where to verify and publish your grains.

To setup this board, you'll need `couchdb`, `nodejs`, `gpg`.

The gpg decryption mechanism is a node file managed by couchdb. To configure please copy and modify appropriately the `proxy/couchdb_unikboard.ini` file into the couchdb configuration directory (on debian, it is in `/etc/couchdb/local.ini`.

Also, please install soca (https://github.com/quirkey/soca), for example in debian:
    sudo gem install soca
And javascript library to access the underlying `gpg` software:
    npm install gpg

Then you can develop using:
    compass watch . --sass-dir "sass" --css-dir "css" --javascripts-dir "js" --images-dir "images"

Not stored in git, there is a `.couchapprc` describing what couchdb you can deploy to, here is a sample:
    {
      "env": {
        "default": {
          "db": "http://admin:password@localhost:5984/unikboard"
        },
        "production": {
          "db": "http://admin:password@unikboard.acoeuro.org/unikboard"
        }
      }
    }

Then to deploy:
    soca push
or
    soca push production

During development it's even easier, this will follow your changes and
automatically deploy them:
    soca autopush

To generate html files form haml:
    haml -f html5 haml/index.haml index.html

Then upload a grain file:
    curl -F _attachments=@../extras/firstbill.gpg http://localhost:5984/upload

### Note for grain validation

We need to modify and improve the couchdb validation process so that only correct files can be uploaded. The rules are managed as a javascript file:
    db/validate_doc_update.js
