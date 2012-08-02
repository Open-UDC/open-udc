<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--
    Copyright (c) 2012 Michele Bini <michele.bini@gmail.com>
    Copyright (c) Chris Veness 2002-2010
  
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
  
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
  
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

 The SHA-1 implementation was obtained from 
 http://www.movable-type.co.uk/scripts/sha1.html
 and is licensed with Creative Commons Attribution License 3.0
-->

<html>
  <head>
    <title>UDID2 - Create your Open-UDC ID</title>
    <script type="text/javascript">
      <!--
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/*  SHA-1 implementation in JavaScript | (c) Chris Veness 2002-2010 | www.movable-type.co.uk      */
/*   - see http://csrc.nist.gov/groups/ST/toolkit/secure_hashing.html                             */
/*         http://csrc.nist.gov/groups/ST/toolkit/examples.html                                   */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

var Sha1 = {};  // Sha1 namespace

/**
 * Generates SHA-1 hash of string
 *
 * @param {String} msg                String to be hashed
 * @param {Boolean} [utf8encode=true] Encode msg as UTF-8 before generating hash
 * @returns {String}                  Hash of msg as hex character string
 */
Sha1.hash = function(msg, utf8encode) {
  utf8encode =  (typeof utf8encode == 'undefined') ? true : utf8encode;
  
  // convert string to UTF-8, as SHA only deals with byte-streams
  if (utf8encode) msg = Utf8.encode(msg);
  
  // constants [4.2.1]
  var K = [0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xca62c1d6];
  
  // PREPROCESSING 
  
  msg += String.fromCharCode(0x80);  // add trailing '1' bit (+ 0's padding) to string [5.1.1]
  
  // convert string msg into 512-bit/16-integer blocks arrays of ints [5.2.1]
  var l = msg.length/4 + 2;  // length (in 32-bit integers) of msg + '1' + appended length
  var N = Math.ceil(l/16);   // number of 16-integer-blocks required to hold 'l' ints
  var M = new Array(N);
  
  for (var i=0; i<N; i++) {
    M[i] = new Array(16);
    for (var j=0; j<16; j++) {  // encode 4 chars per integer, big-endian encoding
      M[i][j] = (msg.charCodeAt(i*64+j*4)<<24) | (msg.charCodeAt(i*64+j*4+1)<<16) | 
        (msg.charCodeAt(i*64+j*4+2)<<8) | (msg.charCodeAt(i*64+j*4+3));
    } // note running off the end of msg is ok 'cos bitwise ops on NaN return 0
  }
  // add length (in bits) into final pair of 32-bit integers (big-endian) [5.1.1]
  // note: most significant word would be (len-1)*8 >>> 32, but since JS converts
  // bitwise-op args to 32 bits, we need to simulate this by arithmetic operators
  M[N-1][14] = ((msg.length-1)*8) / Math.pow(2, 32); M[N-1][14] = Math.floor(M[N-1][14])
  M[N-1][15] = ((msg.length-1)*8) & 0xffffffff;
  
  // set initial hash value [5.3.1]
  var H0 = 0x67452301;
  var H1 = 0xefcdab89;
  var H2 = 0x98badcfe;
  var H3 = 0x10325476;
  var H4 = 0xc3d2e1f0;
  
  // HASH COMPUTATION [6.1.2]
  
  var W = new Array(80); var a, b, c, d, e;
  for (var i=0; i<N; i++) {
  
    // 1 - prepare message schedule 'W'
    for (var t=0;  t<16; t++) W[t] = M[i][t];
    for (var t=16; t<80; t++) W[t] = Sha1.ROTL(W[t-3] ^ W[t-8] ^ W[t-14] ^ W[t-16], 1);
    
    // 2 - initialise five working variables a, b, c, d, e with previous hash value
    a = H0; b = H1; c = H2; d = H3; e = H4;
    
    // 3 - main loop
    for (var t=0; t<80; t++) {
      var s = Math.floor(t/20); // seq for blocks of 'f' functions and 'K' constants
      var T = (Sha1.ROTL(a,5) + Sha1.f(s,b,c,d) + e + K[s] + W[t]) & 0xffffffff;
      e = d;
      d = c;
      c = Sha1.ROTL(b, 30);
      b = a;
      a = T;
    }
    
    // 4 - compute the new intermediate hash value
    H0 = (H0+a) & 0xffffffff;  // note 'addition modulo 2^32'
    H1 = (H1+b) & 0xffffffff; 
    H2 = (H2+c) & 0xffffffff; 
    H3 = (H3+d) & 0xffffffff; 
    H4 = (H4+e) & 0xffffffff;
  }

  return Sha1.toHexStr(H0) + Sha1.toHexStr(H1) + 
    Sha1.toHexStr(H2) + Sha1.toHexStr(H3) + Sha1.toHexStr(H4);
}

//
// function 'f' [4.1.1]
//
Sha1.f = function(s, x, y, z)  {
  switch (s) {
  case 0: return (x & y) ^ (~x & z);           // Ch()
  case 1: return x ^ y ^ z;                    // Parity()
  case 2: return (x & y) ^ (x & z) ^ (y & z);  // Maj()
  case 3: return x ^ y ^ z;                    // Parity()
  }
}

//
// rotate left (circular left shift) value x by n positions [3.2.5]
//
Sha1.ROTL = function(x, n) {
  return (x<<n) | (x>>>(32-n));
}

//
// hexadecimal representation of a number 
//   (note toString(16) is implementation-dependant, and  
//   in IE returns signed numbers when used on full words)
//
Sha1.toHexStr = function(n) {
  var s="", v;
  for (var i=7; i>=0; i--) { v = (n>>>(i*4)) & 0xf; s += v.toString(16); }
  return s;
}


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/*  Utf8 class: encode / decode between multi-byte Unicode characters and UTF-8 multiple          */
/*              single-byte character encoding (c) Chris Veness 2002-2010                         */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

var Utf8 = {};  // Utf8 namespace

/**
 * Encode multi-byte Unicode string into utf-8 multiple single-byte characters 
 * (BMP / basic multilingual plane only)
 *
 * Chars in range U+0080 - U+07FF are encoded in 2 chars, U+0800 - U+FFFF in 3 chars
 *
 * @param {String} strUni Unicode string to be encoded as UTF-8
 * @returns {String} encoded string
 */
Utf8.encode = function(strUni) {
  // use regular expressions & String.replace callback function for better efficiency 
  // than procedural approaches
  var strUtf = strUni.replace(
      /[\u0080-\u07ff]/g,  // U+0080 - U+07FF => 2 bytes 110yyyyy, 10zzzzzz
      function(c) { 
        var cc = c.charCodeAt(0);
        return String.fromCharCode(0xc0 | cc>>6, 0x80 | cc&0x3f); }
    );
  strUtf = strUtf.replace(
      /[\u0800-\uffff]/g,  // U+0800 - U+FFFF => 3 bytes 1110xxxx, 10yyyyyy, 10zzzzzz
      function(c) { 
        var cc = c.charCodeAt(0); 
        return String.fromCharCode(0xe0 | cc>>12, 0x80 | cc>>6&0x3F, 0x80 | cc&0x3f); }
    );
  return strUtf;
}

/**
 * Decode utf-8 encoded string back into multi-byte Unicode characters
 *
 * @param {String} strUtf UTF-8 string to be decoded back to Unicode
 * @returns {String} decoded string
 */
Utf8.decode = function(strUtf) {
  // note: decode 3-byte chars first as decoded 2-byte strings could appear to be 3-byte char!
  var strUni = strUtf.replace(
      /[\u00e0-\u00ef][\u0080-\u00bf][\u0080-\u00bf]/g,  // 3-byte chars
      function(c) {  // (note parentheses for precence)
        var cc = ((c.charCodeAt(0)&0x0f)<<12) | ((c.charCodeAt(1)&0x3f)<<6) | ( c.charCodeAt(2)&0x3f); 
        return String.fromCharCode(cc); }
    );
  strUni = strUni.replace(
      /[\u00c0-\u00df][\u0080-\u00bf]/g,                 // 2-byte chars
      function(c) {  // (note parentheses for precence)
        var cc = (c.charCodeAt(0)&0x1f)<<6 | c.charCodeAt(1)&0x3f;
        return String.fromCharCode(cc); }
    );
  return strUni;
}
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

// Copyright (c) 2012 Michele Bini

// This program is free software: you can redistribute it and/or modify
// it under the terms of the version 3 of the GNU General Public License
// as published by the Free Software Foundation.

// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


function emptyElement(e) {
    while (e.firstChild!==null)
        e.removeChild(e.firstChild);
}

function insertElementAfter(e, w) {
    w.parentNode.insertBefore(e, w.nextSibling);
}

function setTextContent(element, text) {
    emptyElement(element);
    if (text != null) {
	var node = document.createTextNode(text);
	element.appendChild(node);
    }
}

function documentElement(id) {
    return document.getElementById(id);
}

function setMessageAfterElement(elementName, message) {
    var msgid = elementName + ".msg";
    var msg = documentElement(msgid);
    if (msg == null) {
	msg = document.createElement("span");
	msg.className = "message";
	documentElement(elementName).parentNode.appendChild(msg);
	msg.id = msgid;
    }
    setTextContent(msg, message);
}

function resetform() {
    try {
	if (!confirm("Do you really want to reset the form?")) return false;
	documentElement("firstname").value  = "";
	documentElement("lastname").value   = "";
	documentElement("day").value  = "";
	documentElement("month").value   = "";
	documentElement("year").value  = "";
	documentElement("lastname").value   = "";
	documentElement("place").value   = "";
	documentElement("lat").value   = "";
	documentElement("lon").value   = "";
	documentElement("udid2hashed").value = "";
	documentElement("udid2clear").value = "";
	documentElement("coordmethod").value = "geonamesorg";
	setMessageAfterElement("firstname");
	setMessageAfterElement("lastname");
	setMessageAfterElement("day");
	setMessageAfterElement("geonameslist");
	setMessageAfterElement("location");
	setMessageAfterElement("place");
	documentElement("placecell").className = "";
	documentElement("coordmethodcell").className = "hidden";
	documentElement("geonameslistcell").className = "hidden";
	documentElement("locationcell").className = "hidden";
	documentElement("generated").className = "hidden";
	emptyElement(documentElement("geonameslist"));
	documentElement("lat").disabled    = false;
	documentElement("lon").disabled    = false;
	documentElement("place").disabled  = false;
	return false;
   } catch (err) {
       alert("An error occurred: " + err.message);
       return false;
   }
}

function normalizeSign(n) {
    if (!(/^[+-]/.test(n))) {
	n = "+" + n;
    }
    return n;
}

function normalizeSpaces(n) {
    n = n.replace(/^\s\s*/, "");
    n = n.replace(/\s\s*$/, "");
    n = n.replace(/\s\s*/g, " ");
    return n;
}

function selectlatlon() {
    documentElement("place").value = "";
    documentElement("coordmethod").value = "latlon";
    documentElement("coordmethodcell").className = "";
    documentElement("locationcell").className = "";
    documentElement("lat").disabled = false;
    documentElement("lon").disabled = false;
    documentElement("placecell").className = "hidden";
    documentElement("geonameslistcell").className = "hidden";
}

function addoption(x, o) {
    try {
	// for IE earlier than version 8
	x.add(o,x.options[null]);
    } catch (e) {
	x.add(o,null);
    }
}

function showlatlon() {
    var x = documentElement("coordmethod");
    if (x.length > 2) {
	x.remove(2);
    }
    var o = document.createElement("option");
    o.text = "Use coordinates found via geonames.org";
    o.value = "usefound";
    addoption(x, o);
    x.value = "usefound";
    documentElement("coordmethodcell").className = "";
    documentElement("locationcell").className = "";
    documentElement("place").disabled = true;
    documentElement("lat").disabled = true;
    documentElement("lon").disabled = true;
}

function fullgeoname(t) {
    var n = (t.toponymName === undefined) ? t.name : t.toponymName;
    var v = function (x) { return ((x !== undefined) && (x !== "")  && (x != n)); };
    if (v(t.adminName5))   n += " (" + t.adminName5 + ")";
    if (v(t.adminName4))   n += " (" + t.adminName4 + ")";
    if (v(t.adminName3))   n += " (" + t.adminName3 + ")";
    if (v(t.adminName2))   n += " (" + t.adminName2 + ")";
    if (v(t.adminName1))   n += " (" + t.adminName1 + ")";
    if (v(t.countryName))  n += ", " + t.countryName;
    return n;
}

function showgeonameslist() {
    setMessageAfterElement("geonameslist", "Select your birthplace");
    documentElement("geonameslistcell").className = "";
    documentElement("coordmethodcell").className = "";
    documentElement("placecell").className = "hidden";
    documentElement("locationcell").className = "hidden";
}

function addselectlistoption(s) {
    if (s == null) s = documentElement("coordmethod");
    var o = document.createElement("option");
    o.text = "Select location found via geonames.org";
    o.value = "selectlist";
    o.name = "selectlist";
    addoption(s, o);
}

function setgeonameslist(l) {
    var i;
    var s = l.length;
    var sel = documentElement("geonameslist");
    var first;
    emptyElement(sel);
    for (i = 0; i < s; i++) {
	var t = l[i];
	var o = document.createElement("option");
	o.text = fullgeoname(t);
	o.value = t.geonameId + " " + t.lat + " " + t.lng;
	if (first == null) first = o.value;
	addoption(sel, o);
    }
    sel.value = first;
    var x = documentElement("coordmethod");
    if (x.length > 2) {
	x.remove(2);
    }
    addselectlistoption(x);
    x.value = "selectlist";
    showgeonameslist();
}

function selectgeonamesorg() {
    documentElement("place").disabled = false;
    documentElement("lat").value = "";
    documentElement("lon").value = "";
    documentElement("placecell").className = "";
    documentElement("coordmethodcell").className = "";
    documentElement("locationcell").className = "hidden";
    documentElement("geonameslistcell").className = "hidden";
}

function removeusefoundoption() {
    var x = documentElement("coordmethod");
    if ((x.length > 2) && (x.options[2].value == "usefound")) {
	x.remove(2);
	if (documentElement("geonameslist").firstChild != null)
	    addselectlistoption();
    }
}

function coordmethodselect() {
    var x = documentElement("coordmethod");
    x = x.options[x.selectedIndex].value;
    if (x == "geonamesorg") {
	removeusefoundoption();
	selectgeonamesorg();
	return true;
    } else if (x == "latlon") {
	removeusefoundoption();
	selectlatlon();
	return true;
    } else if (x == "selectlist") {
	showgeonameslist();
	return true;
    }
    return false;
}

function showcoordmethod() {
    documentElement("coordmethodcell").className = "";
}

function geonamesclearmsg() {
    setMessageAfterElement("geonameslist");
    return true;
}

function useselectedgeoname() {
    geonamesclearmsg();
    setMessageAfterElement("location");
    var l = documentElement("geonameslist");
    var o = l.options[l.selectedIndex];
    var x = o.value.split(/ /g);
    var lat = x[1];
    var lon = x[2];
    documentElement("place").value = o.text;
    documentElement("lat").value = lat;
    documentElement("lon").value = lon;
    showlatlon();
}

function geonameselect() {
    try {
	useselectedgeoname();
	return true;
    } catch (err) {
	setMessageAfterElement("geonameslist", "An error occurred: " + err.message);
	return false;
    }
}

function jsonquery(u, f, p, e) {
    var r = new XMLHttpRequest;
    r.open("GET", u, true);
    r.send(null);
    r.onreadystatechange = function () {
	if (r.readyState == 4) {
	    if (r.status == 200) {
		f(JSON.parse(r.responseText));
	    } else {
		e(r);
	    }
	} else if (r.readyState == 3) {
	    p(r);
	}
    };
}

function birthplacechanged() {
    if (documentElement("coordmethod").value != "geonamesorg") {
        documentElement("coordmethodcell").className = "";
    }
    documentElement("lat").value   = "";
    documentElement("lon").value   = "";
    documentElement("coordmethod").value = "geonamesorg";    
    return true;
}

function generateudid2() {
    var no_focusing = false; // Set this in json callbacks, so we don't change focus asynchronously from user input
    var to_focus = null;

    var foc = function (id) {
	if (to_focus == null) to_focus = documentElement(id);
    };

    var checkfirstname = function (id) {
	var name =  documentElement(id).value;
	name = normalizeSpaces(name);
	name = name.toUpperCase();
	name = name.substring(0, 20);
	var matches = name.match(/[^-A-Z]/);
	if (/[, ][, ]*/.test(name)) {
	    setMessageAfterElement(id, "Specify only the first of the names");
	    foc(id);
	    return null;
	}
	if (matches != null) {
	    setMessageAfterElement(id, "Invalid character: " + matches.join(", "));
	    foc(id);
	    return null;
	}
	if (name.length == 0) {
	    setMessageAfterElement(id, "Insert first name");
	    foc(id);
	    return null;
	}
	setMessageAfterElement(id); // Clear any message
	return name;
    };
    var checklastname = function (id) {
	var name =  documentElement(id).value;
	name = normalizeSpaces(name);
	name = name.toUpperCase();
	name = name.substring(0, 20);
	var matches = name.match(/[^-A-Z]/);
	if (/[, ][, ]*/.test(name)) {
	    setMessageAfterElement(id, "Specify only the last of the names");
	    foc(id);
	    return null;
	}
	if (matches != null) {
	    setMessageAfterElement(id, "Invalid character: " + matches.join(", "));
	    foc(id);
	    return null;
	}
	if (name.length == 0) {
	    setMessageAfterElement(id, "Insert last name");
	    foc(id);
	    return null;
	}
	setMessageAfterElement(id); // Clear any message
	return name;
    };

    var firstname  = checkfirstname("firstname");
    var lastname    = checklastname("lastname");

    var year   = documentElement("year").value;
    var month  = documentElement("month").value;
    var day    = documentElement("day").value;
    var date   = null;
    // Possible error conditions:
    // Missing date
    // Invalid date.
    // Incomplete date.

    if ((year == "") && (month == "") && (day == "")) {
	setMessageAfterElement("day", "Specify date");
	foc("day");
    } else if (day == "") {
	setMessageAfterElement("day", "Specify day");
	foc("day");
    } else if (month == "") {
	setMessageAfterElement("day", "Specify month");
	foc("month");
    } else if (year == "") {
	setMessageAfterElement("day", "Specify year");
	foc("year");
    } else {
	var currentdatemax = new Date;
	currentdatemax.setDate((new Date).getDate() + 1);
	var maxyear = currentdatemax.getFullYear();
	if (!(/^[12][0-9][0-9][0-9]$/.test(year))
	    || (year < 1880)
	    || (year > (currentdatemax.getFullYear()))) {
	    setMessageAfterElement("day", "Year should be a number between 1880 and " + maxyear);
	} else {
	    var birthdate = new Date(year, month-1, day);
	    if ((birthdate == null)
		|| (birthdate > currentdatemax)) {
		setMessageAfterElement("day", "Invalid date");
	    } else {
		if ((birthdate.getDate() != day)
		    || (birthdate.getMonth() != (month-1))
		    || (birthdate.getFullYear() != (year))) {
		    setMessageAfterElement("day", "Invalid date");
		} else {
		    setMessageAfterElement("day");
		    date = year + "-" + month + "-" + day;
		}
	    }
	}
    }

    var continuewithlatlon = function (lat, lon) {
	var ll = null;

	// Possible error conditions:
	if ((lat == "") && (lon == "")) {
	    setMessageAfterElement("location", "Specify latitude and longitude");
	    foc("lat");
	} else if (lat == "") {
	    setMessageAfterElement("location", "Specify latitude");
	    foc("lat");
	} else if (!(/^[+-]?[0-9][0-9]*/.test(lat))) {
	    setMessageAfterElement("location", "Latitude should have the format (+/-)N.NN");	
	    foc("lat");
	} else if (!(/^[+-]?[0-9][0-9]*[.][0-9][0-9]/.test(lat))) {
	    setMessageAfterElement("location", "Latitude should have at least two decimal places");
	    foc("lat");
	} else if (!(/^[+-]?[0-9][0-9]*[.][0-9][0-9][0-9]*$/.test(lat))) {
	    setMessageAfterElement("location", "Latitude has invalid format");
	    foc("lat");
	} else if ((lat > 90) || (lat < -90)) {
	    setMessageAfterElement("location", "Latitude should be between +90 and -90");
	    foc("lat");
	} else if (lon == "") {
	    setMessageAfterElement("location", "Specify longitude");
	    foc("lon");
	} else if (!(/^[+-]?[0-9][0-9]*/.test(lon))) {
	    setMessageAfterElement("location", "Longitude should have the format (+/-)N.NN");	
	    foc("lon");
	} else if (!(/^[+-]?[0-9][0-9]*[.][0-9][0-9]/.test(lon))) {
	    setMessageAfterElement("location", "Longitude should have at least two decimal places: " + lon);
	    foc("lon");
	} else if (!(/^[+-]?[0-9][0-9]*[.][0-9][0-9][0-9]*$/.test(lon))) {
	    setMessageAfterElement("location", "Longitude has invalid format");
	    foc("lon");
	} else if ((lon > 180) || (lon <= -180)) {
	    setMessageAfterElement("location", "Longitude should be between +180.00 and -179.99");
	    foc("lon");
	} else {
	    // Add sign and extra zeroes, round latitude and longitude
	    lat = normalizeSign(parseFloat(lat).toFixed(2));
	    lon = normalizeSign(parseFloat(lon).toFixed(2));
	    
	    // Remove extra leading zeroes
	    lat = lat.replace(/^[+]0*/, "+");
	    lat = lat.replace(/^[-]0*/, "-");
	    
	    // Add back zeroes
	    if (/^[+-][.]/.test(lat)) {
		lat = lat.substring(0, 1) + "0" + lat.substring(1);
	    }
	    if (/^[+-][0-9][.]/.test(lat)) {
		lat = lat.substring(0, 1) + "0" + lat.substring(1);
	    }
	    if (/^[+-][.]/.test(lon)) {
		lon = lon.substring(0, 1) + "0" + lon.substring(1);
	    }
	    if (/^[+-][0-9][.]/.test(lon)) {
		lon = lon.substring(0, 1) + "0" + lon.substring(1);
	    }
	    if (/^[+-][0-9][0-9][.]/.test(lon)) {
		lon = lon.substring(0, 1) + "0" + lon.substring(1);
	    }

	    // Check correctness of the format
	    if (!(/^[+-][0-9][0-9][.][0-9][0-9]$/.test(lat))) {
		setMessageAfterElement("location", "Could not parse latitude: " + lat);
	    } else if (!(/^[+-][0-9][0-9][0-9][.][0-9][0-9]$/.test(lon))) {
		setMessageAfterElement("location", "Could not parse longitude: " + lon);
	    } else {
		documentElement("verifylocation").href = "http://www.openstreetmap.org/?lat=" + lat + "&lon=" + lon + "&zoom=15&layers=M";
		setTextContent(documentElement("verifylocation"), "Verify with openstreetmap");
		setMessageAfterElement("location");
		ll = lat + "" + lon;
	    }
	}    

	if ((firstname !== null) && (lastname !== null) && (ll !== null) && (date !== null)) {
	    documentElement("generated").className = "";
	    documentElement("udid2clear").value   = "udid2;c;" + lastname + ";" + firstname + ";" + date + ";e" + ll + ";0;";
	    documentElement("udid2hashed").value  = "udid2;h;" + Sha1.hash(lastname + ";" + firstname + ";" + date + ";e" + ll) + ";0;";
	    documentElement("udid2hashed").scrollIntoView(false);
	    documentElement("udid2clear").readOnly = true;
	    documentElement("udid2hashed").readOnly = true;
	    return true;
	} else {
	    documentElement("udid2clear").readOnly = false;
	    documentElement("udid2hashed").readOnly = false;
	    documentElement("udid2clear").value    = "";
	    documentElement("udid2hashed").value   = "";
	    if (!no_focusing) {
		if (to_focus !== null) {
		    to_focus.focus();
		}
	    }
	    return false;
	}
    };

    if (documentElement("coordmethod").value == "geonamesorg") {
	var place = normalizeSpaces(documentElement("place").value);
	if (place == "") {
	    setMessageAfterElement("place", "Specify your birthplace");
	    foc("place");
	} else if (
	    // Detect when the user is inputting numerical coordinates
	    (!(/[^-+0-9 .,;][^-+0-9 .,;]/.test(place))) &&
		(/[0-9][.]/.test(place))
	) {
	    // Try to different ways to split the string into latitude and longitude
	    var lat, lon, x;
	    if         ((x = place.split(/;\s*/g)).length == 2) {
		lat = x[0]; lon = x[1];
	    } else if  ((x = place.split(/;\s*/g)).length == 2) {
		lat = x[0]; lon = x[1];
	    } else if  ((x = place.split(/,\s\s*/g)).length == 2) {
		lat = x[0]; lon = x[1];
	    } else if  ((x = place.split(/\s/g)).length == 2) {
		lat = x[0]; lon = x[1];
	    } else if  ((x = place.split(/,/g)).length == 2) {
		lat = x[0]; lon = x[1];
	    } else if  ((x = place.match(/[+-]?[0-9][0-9]*[.][0-9][0-9][0-9]*/g)) && (x.length == 2)) {
		lat = x[0]; lon = x[1];
	    } else {
		lat = place; lon = "";
	    }
	    selectlatlon();
	    documentElement("lat").value = lat;
	    documentElement("lon").value = lon;
	} else {
	    var n = 0;
	    try {
		// For compatibility with Internet Explorer's default security settings, the json request to geonames.org should be proxied by a PHP script in the local domain
		jsonquery("http://api.geonames.org/search?q="+encodeURIComponent(place)+"&type=json&featureClass=P&username=rev22", function (j) {
		    try {
			var g = j.geonames;
			if (g.length == 0) {
			    setMessageAfterElement("place", "Location not found (in geonames.org)");
			} else if (g.length == 1) {
			    setMessageAfterElement("place", "Location found");
			    var t = g[0];
			    var lat = t.lat;
			    var lon = t.lng;
			    documentElement("place").value = fullgeoname(t);
			    documentElement("lat").value = lat;
			    documentElement("lon").value = lon;
			    showlatlon();
			    continuewithlatlon(lat, lon);
			} else {
			    setMessageAfterElement("place");
			    setgeonameslist(g);
			}
		    } catch (err) {
			setMessageAfterElement("place", "Error processing geonames response: " + err.message);
		    }
		}, function (r) {
		    setMessageAfterElement("place", "Looking up in geonames.org.." + (((n%1)==0)?"":"."));
		    n++;
		}, function (r) {
		    setMessageAfterElement("place", "Error contacting geonames.org: (" + r.status + ") " + r.responseText);
		});
		setMessageAfterElement("place", "Looking up in geonames.org...");
		foc("generate");
	    } catch (err) {
		setMessageAfterElement("place", "Could not access geonames.org: " + err.message);
		showcoordmethod();
		foc("coordmethod");
	    }
	}
    } else if (documentElement("coordmethod").value == "selectlist") {
	useselectedgeoname();
	foc("generate");
    }
    
    continuewithlatlon(normalizeSpaces(documentElement("lat").value),
		       normalizeSpaces(documentElement("lon").value));
}
	  -->
    </script>
    <style type="text/css">
      <!--
body {
    background: #eef;
}

h1,h2,h3 {
    margin-top: 0.4em;
    margin-bottom: 0.2em;
    font-weight: bold;
    font-family: helvetica,arial;
    color: #9999bb;
    border-bottom: 1px solid #99b;
}

.message {
    color: #0000dd;
    font-weight: bold;
}

.centered {
    text-align:center;
}

.hidden {
    display:none;
}

.info {
    color: #444455;
}

.inputcell {
    text-align:left;
}

.secondary {
    opacity: 0.8;
    font-size: 75%;
}

.primary {
    font-weight: bold;
}

input, select {
    font-weight: normal;
    font-size: 100%;
}
-->
    </style>
  </head>
  <body style="text-align:center">
    <div class=info><a href="http://www.openudc.org">Open-UDC</a>: currency based on Universal Dividend and Consensus</div>
    <h3>Your information:</h3>
    <form class=centered style="display:inline-table" action="nojavascript.html" method="get">
      <div class=info>This form allows you to create your Open-UDC ID (UDID2).</div>
      <table>
	<tr>
	  <td>Your first name:</td>
	  <td class=inputcell>
	    <input id=firstname size=30 type=text>
	  </td>
	</tr><tr>
	  <td>Your last name:</td>
	  <td class=inputcell>
	    <input id=lastname size=30 type=text>
	  </td>
	</tr><tr>
	  <td>Your birth date:</td>
	  <td class=inputcell>
	    <select title="The day of the month in which you were born (1-31)"
		    id="day" name="day">
	      <option value="">Day</option>
	      <option value="1">1</option>
	      <option value="2">2</option>
	      <option value="3">3</option>
	      <option value="4">4</option>
	      <option value="5">5</option>
	      <option value="6">6</option>
	      <option value="7">7</option>
	      <option value="8">8</option>
	      <option value="9">9</option>
	      <option value="10">10</option>
	      <option value="11">11</option>
	      <option value="12">12</option>
	      <option value="13">13</option>
	      <option value="14">14</option>
	      <option value="15">15</option>
	      <option value="16">16</option>
	      <option value="17">17</option>
	      <option value="18">18</option>
	      <option value="19">19</option>
	      <option value="20">20</option>
	      <option value="21">21</option>
	      <option value="22">22</option>
	      <option value="23">23</option>
	      <option value="24">24</option>
	      <option value="25">25</option>
	      <option value="26">26</option>
	      <option value="27">27</option>
	      <option value="28">28</option>
	      <option value="29">29</option>
	      <option value="30">30</option>
	      <option value="31">31</option>
	    </select>
	    <select title="The month in which you were born"
		    id=month name="month">
	      <option value="">Month</option>
	      <option value="01">January</option>
	      <option value="02">February</option>
	      <option value="03">March</option>
	      <option value="04">April</option>
	      <option value="05">May</option>
	      <option value="06">June</option>
	      <option value="07">July</option>
	      <option value="08">August</option>
	      <option value="09">September</option>
	      <option value="10">October</option>
	      <option value="11">November</option>
	      <option value="12">December</option>
	    </select>
	    <input title="The year in which you were born"
		   size=4 id=year name=year type=text>
	    <!-- <input style="text-align:center" size=2 type=text>/<input style="text-align:center" size=2 type=text>/<input style="text-align:center" size=4 type=text> -->
	  </td>
	</tr><tr>
	  <td>Your birthplace:</td>
	  <td class=inputcell>
	    <div class=hidden id="coordmethodcell">
              <select class=secondary id="coordmethod" name="coordmethod" onChange="coordmethodselect()">
		<option value="geonamesorg">Find earth coordinates via geonames.org</option>
		<option value="latlon">Specify latitude/longitude</option>
              </select>
	    </div>
	    <div id=placecell><input id=place name=place size=30 type=text onChange="birthplacechanged()"></div>
	    <div class=hidden id=geonameslistcell>
	      <select style="width:19em" id=geonameslist name=geonameslist onChange="geonameselect()" onMouseDown="geonamesclearmsg()">
		<option></option>
	      </select>
	    </div>
	    <div class=hidden id=locationcell>
	      <span id=location>
		<span title="Latitude of your birth location, in decimal form"><input id=lat style="text-align:center" size=6 type=text><sub>(lat)</sub></span>
		<span title="Longitude of your birth location, in decimal form"><input id=lon style="text-align:center" size=5 type=text><sub>(lon)</sub></span>
	      </span>
	      <a class=secondary id=verifylocation href="http://geonames.org/">Find on geonames.org</a>
	    </div>
	  </td>
	</tr>
      </table>
      <input class=secondary id=reset type=button value="Reset" onClick="resetform()">
      <input class=primary id=generate type=submit value="Generate your UDID2" onClick="try { generateudid2() } catch (err) { alert('An error occurred in this page: ' + err.message ); };return false">
    </form>
    <div class=hidden id=generated>
    <h3>Your OpenUDC ID (UDID2):</h3>
    <input id=udid2clear style="font-family:fixed,courier" size=70 title="Your clear UDID2" type=text><br>
    <input id=udid2hashed style="font-family:fixed,courier" size=70 title="Your hashed UDID2" type=text>
    </div>
    <div class=info>Your <a href="http://openudc.org/Specifications/OpenpgpIndividualCertification">UDID2</a> is the identification code that allows you to take part in the Open-UDC monetary community.</div>
    <div class=info>Your information on this form is processed by your web-browser; your birthplace is processed via geonames.org.</div>
    <div class=info>Internet Explorer users may need to enable accessing data sources across domains.</div>
    <div class=info>This application requires Javascript.</div>
  </body>
</html>
