#!/bin/sed -f
#
# Copyright © 2012 by Jean-Jacques Brucker <open-udc@googlegroups.com>
#
# Convert unicode (UTF-8) to it's closer US-ascii representation.
# version 0.3
# Feel free to add missing unicode characters.
# (It miss for example special combinations for greek...)

s/[áàâäãªαа]/a/g
s/[ÁÀÂÄÃΑА]/A/g
s/[б]/b/g
s/[Б]/B/g
s/[ç]/c/g
s/[Ç]/C/g
s/[δд]/d/g
s/[ΔД]/D/g
s/[éèêëεєеёэ]/e/g
s/[ÉÈÊËΕЄЕЁЭ]/E/g
s/[φф]/f/g
s/[ΦФ]/F/g
s/[γг]/g/g
s/[ΓГ]/G/g
s/[íìîïηιий]/i/g
s/[ÍÌÎÏΗΙИЙ]/I/g
s/[κк]/k/g
s/[ΚК]/K/g
s/[λл]/l/g
s/[ΛЛ]/L/g
s/[µμм]/m/g
s/[ΜМ]/M/g
s/[ñνн]/n/g
s/[ÑΝН]/N/g
s/[óòôöõºοωо]/o/g
s/[ÓÒÔÖÕΟΩО]/O/g
s/[πп]/p/g
s/[ΠП]/P/g
s/[ρр]/r/g
s/[ΡР]/R/g
s/[σςс]/s/g
s/[ΣС]/S/g
s/[τт]/t/g
s/[ΤТ]/T/g
s/[úùûüу]/u/g
s/[ÚÙÛÜУ]/U/g
s/[βв]/v/g
s/[ΒВ]/V/g
s/[ξ]/x/g
s/[Ξ]/X/g
s/[ŷÿυы]/y/g
s/[ŶŸΥЫ]/Y/g
s/[ζз]/z/g
s/[ΖЗ]/Z/g

s/[æ]/ae/g
s/[Æ]/AE/g
s/[œ]/oe/g
s/[Œ]/OE/g
s/[ß]/ss/g

s/[θ]/th/g
s/[Θ]/TH/g
s/[χ]/ch/g
s/[Χ]/CH/g
s/[ψ]/ps/g
s/[Ψ]/PS/g

s/[ж]/zh/g
s/[Ж]/ZH/g
s/[х]/kh/g
s/[Х]/KH/g
s/[ц]/tc/g
s/[Ц]/TC/g
s/[ч]/ch/g
s/[Ч]/CH/g
s/[ш]/sh/g
s/[Ш]/SH/g
s/[щ]/shch/g
s/[Щ]/SHCH/g
s/[ю]/iu/g
s/[Ю]/IU/g
s/[я]/ia/g
s/[Я]/IA/g

s/[€]/euros/g
s/[$]/dollars/g

