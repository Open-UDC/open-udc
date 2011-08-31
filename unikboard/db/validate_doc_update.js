// This method is called as a validation before any document upload
function(newDoc, oldDoc, userCtx) {
  log('A new file is being uploaded');

  function required(field, message /* optional */) {
    message = message || "Document must have a " + field;
    if (!newDoc[field]) throw({forbidden : message});
  }

  function unchanged(field) {
    if (oldDoc && toJSON(oldDoc[field]) != toJSON(newDoc[field]))
      throw({forbidden : "Field can't be changed: " + field});
  }

  /*
  required("_id");
  required("created_on");
  required("content");
  required("_attachments");

  if (newDoc._rev != undefined) {
    throw({forbidden : 'You can not modify this grain'});
  }
  */
}
