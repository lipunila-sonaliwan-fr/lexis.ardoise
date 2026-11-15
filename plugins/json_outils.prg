&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Extension Ardoise : JSON (formater, compacter, valider) et formateur du langage json.
&&
&& La mise en forme travaille sur le texte lui-même (chaînes conservées telles quelles) et non
&& sur une valeur décodée : rien n'est perdu (null, ordre des clefs, nombres, échappements).

procedure EXTENSION_JSON_OUTILS
  ARDOISE_ENREGISTRER{genre = "formateur", nom = "json", langage = "json", procedure = @JO_JOLI}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "jsonformater", libelle = "JSON : formater (indenter)", categorie = "JSON", procedure = @JO_FORMATER}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "jsoncompacter", libelle = "JSON : compacter sur une ligne", categorie = "JSON", procedure = @JO_COMPACTER}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "jsonvalider", libelle = "JSON : valider le document", categorie = "JSON", procedure = @JO_VALIDER}
retourner

&& morceaux alternés : hors chaîne (impairs) / chaîne entre guillemets (pairs)
fonction JO_MORCEAUX(t)
  locale bruts = decouper(t, "\"")
  locale r = {}
  locale i = 1
  tantque i <= #bruts
    locale m = bruts[i]
    si #r % 2 = 1
      && dans une chaîne : un guillemet précédé d'un nombre impair de « \ » est échappé
      tantque JO_ECHAPPE(m) et i < #bruts
        i += 1
        m = m + "\"" + bruts[i]
      fintantque
    finsi
    inserer(r, m)
    i += 1
  fintantque
retourner r

fonction JO_ECHAPPE(m)
  locale n = 0
  tantque n < #m et souschaine(m, #m - n, 1) = "\\"
    n += 1
  fintantque
retourner n % 2 = 1

fonction JO_SANS_BLANCS(s)
  pour chaque b dans {" ", car(9), car(10), car(13)}
    s = remplacertexte(s, b, "")
  suivant
retourner s

fonction JO_COMPACT(t)
  locale ms = JO_MORCEAUX(t)
  locale out = {}
  pour i = 1 a #ms
    si i % 2 = 1
      inserer(out, JO_SANS_BLANCS(ms[i]))
    sinon
      inserer(out, "\"" + ms[i] + "\"")
    finsi
  suivant
retourner joindre(out, "")

fonction JO_JOLI(t)
  locale ms = JO_MORCEAUX(t)
  locale out = {}
  locale nl = car(10)
  pour i = 1 a #ms
    si i % 2 = 1
      locale s = JO_SANS_BLANCS(ms[i])
      s = remplacertexte(s, "{", "{" + nl)
      s = remplacertexte(s, "[", "[" + nl)
      s = remplacertexte(s, "}", nl + "}")
      s = remplacertexte(s, "]", nl + "]")
      s = remplacertexte(s, ",", "," + nl)
      s = remplacertexte(s, ":", ": ")
      inserer(out, s)
    sinon
      inserer(out, "\"" + ms[i] + "\"")
    finsi
  suivant
  locale res = {}
  locale niveau = 0
  pour chaque l dans decouper(joindre(out, ""), nl)
    l = rogner(l)
    si l <> ""
      locale ferme = commencepar(l, "}") ou commencepar(l, "]")
      si ferme
        niveau = max(0, niveau - 1)
      finsi
      locale der = sisinon(#res > 0, res[#res], "")
      si ferme et (finitpar(der, "{") ou finitpar(der, "["))
        res[#res] = der + l                  && {} et [] vides sur une ligne
      sinon
        inserer(res, repliquer("  ", niveau) + l)
      finsi
      si finitpar(l, "{") ou finitpar(l, "[")
        niveau += 1
      finsi
    finsi
  suivant
retourner joindre(res, nl)

procedure JO_FORMATER(ev)
  essayer
    json.decoder(DOC_TEXTE(), vrai)
  capturer e
    STATUT("JSON invalide : " + e)
    retourner
  finessayer
  DOC_FIXER_TEXTE(JO_JOLI(DOC_TEXTE()))
  STATUT("JSON formaté.")
retourner

procedure JO_COMPACTER(ev)
  essayer
    json.decoder(DOC_TEXTE(), vrai)
  capturer e
    STATUT("JSON invalide : " + e)
    retourner
  finessayer
  DOC_FIXER_TEXTE(JO_COMPACT(DOC_TEXTE()))
  STATUT("JSON compacté.")
retourner

procedure JO_VALIDER(ev)
  essayer
    locale v = json.decoder(DOC_TEXTE(), vrai)
    STATUT("JSON valide (" + sisinon(type(v) = "table", nbelements(v) + " élément(s) à la racine", type(v)) + ").")
  capturer e
    STATUT("JSON invalide : " + e)
  finessayer
retourner
