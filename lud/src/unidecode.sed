#!/bin/sed -f
# Copyright © 2012 by Jean-Jacques Brucker <open-udc@googlegroups.com>
# convert unicode to it's closer ascii representation.
# Feel free to add missing unicode characters
s/[áàâäãªαа]/a/g
s/[ÁÀÂÄÃΑА]/A/g
s/[βб]/b/g
s/[ΒБ]/B/g
s/[ç]/c/g
s/[Ç]/C/g
s/[δд]/d/g
s/[ΔД]/D/g
s/[éèêëεєе]/e/g
s/[ÉÈÊËΕЄЕ]/E/g
s/[γ]/g/g
s/[Γ]/G/g
s/[íìîïι]/i/g
s/[ÍÌÎÏΙ]/I/g
s/[ñн]/n/g
s/[ÑН]/N/g
s/[óòôöõº]/o/g
s/[ÓÒÔÖÕ]/O/g
s/[úùûü]/u/g
s/[ÚÙÛÜ]/U/g
s/[в]/v/g
s/[В]/V/g
s/[ŷÿ]/y/g
s/[ŶŸ]/Y/g
s/[æ]/ae/g
s/[Æ]/AE/g
s/[œ]/oe/g
s/[Œ]/OE/g
s/[ß]/ss/g
s/[€]/euros/g
s/[$]/dollars/g
