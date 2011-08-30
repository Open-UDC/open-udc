#! /usr/bin/env node

// See https://github.com/drudge/node-gpg

var sys = require('sys');
var http = require('http');
var gpg = require('/home/manu/.node_libraries/gpg');
var formidable = require('/home/manu/.node_libraries/formidable');
var readFile = require('fs').readFile;

// Send a log message to be included in CouchDB's
// log files.
var log = function(mesg) {
  console.log(JSON.stringify(["log", mesg]));
}

function send_content(req, resp, files, decrypted_content) {
  log("Host: "+req.headers['host']);
  log("Method: "+req.method);
  //log(sys.inspect(req.headers));

  var options = {
    method: 'PUT',
    host: 'localhost',
    port: 5984,
    path: '/unikboard/'+files._attachments.name.replace(/.gpg$/, '')
  };

  var request = http.request(options, function(ifsResponse) {
    ifsResponse.on('data', function(chunk) {
      //resp.writeHead(proxy_response.statusCode, {'Content-Type': 'text/plain'});
      resp.write(chunk, 'binary');
    });
    ifsResponse.on('end', function() {
      resp.end(files._attachments.name+" → " +decrypted_content+'\n');
    });
  });

  readFile(files._attachments.path, function(err, content){
    var data = {
      created_on: new Date(),
      content: decrypted_content,
      _attachments: {}
    };
    data._attachments[files._attachments.name] = {
      content_type: 'application/pgp-encrypted',
      data: content.toString('base64')
    };

    request.write(JSON.stringify(data));
    request.end();
  });
}

var server = http.createServer(function (req, resp) {
  //log(sys.inspect(req));
  log(req.method + " " + req.url);

  // curl -F _attachments=@../extras/firstbill.gpg http://localhost:5984/upload
  new formidable.IncomingForm().parse(req, function(err, fields, files) {
    gpg.decryptFile(files._attachments.path, function(err, contents) {
      log("Decrypted content: "+contents);
      send_content(req, resp, files, contents);
    });
  });
})

// We use stdin in a couple ways. First, we
// listen for data that will be the requested
// port information. We also listen for it
// to close which indicates that CouchDB has
// exited and that means its time for us to
// exit as well.
var stdin = process.openStdin();

stdin.on('data', function(d) {
  server.listen(parseInt(JSON.parse(d)));
});

stdin.on('end', function () {
  process.exit(0);
});

// Send the request for the port to listen on.
console.log(JSON.stringify(["get", "gpg_upload", "port"]));
