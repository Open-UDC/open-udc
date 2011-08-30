// This method is called as a validation before any document upload
function(newDoc, oldDoc, userCtx) {
  log('XXXXXXXXXXXx');
  if (newDoc && newDoc._attachments) {
    //var gpg = require(__dirname + '/../lib/gpg');
    //var gpg = require('/home/manu/.node_libraries/gpg/index.js');
    //var gpg = require('vendor/gpg/index.js');
    //var gpg = require('vendor/gpg/lib/gpg.js');
    // code vendor/gpg/lib/gpg.js

    /*
    gpg.decryptFile('../extras/firstbill.gpg', function(err, contents) {
      log(contents);
    });
    */
  }

  function required(field, message /* optional */) {
    message = message || "Document must have a " + field;
    if (!newDoc[field]) throw({forbidden : message});
  }

  function unchanged(field) {
    if (oldDoc && toJSON(oldDoc[field]) != toJSON(newDoc[field]))
      throw({forbidden : "Field can't be changed: " + field});
  }

  required("_id");
  /*
  required("created_on");
  required("content");
  required("_attachments");
  */

  if (oldDoc && (oldDoc._rev && !oldDoc._attachments)) {
    throw({forbidden : 'You can not modify this grain'});
  }
}
