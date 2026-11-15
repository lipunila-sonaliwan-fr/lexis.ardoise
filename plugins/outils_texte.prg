&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Extension Ardoise : outils de texte (lignes et casse), ajoutés à la palette de commandes.
&& Ils agissent sur la sélection, ou sur tout le document s'il n'y a pas de sélection.

procedure EXTENSION_OUTILS_TEXTE
  ARDOISE_ENREGISTRER{genre = "commande", nom = "trier", libelle = "Texte : trier les lignes (A → Z)", categorie = "Texte", procedure = @OT_TRIER}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "trierinverse", libelle = "Texte : trier les lignes (Z → A)", categorie = "Texte", procedure = @OT_TRIER_INVERSE}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "doublons", libelle = "Texte : supprimer les lignes en double", categorie = "Texte", procedure = @OT_DOUBLONS}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "vides", libelle = "Texte : supprimer les lignes vides", categorie = "Texte", procedure = @OT_VIDES}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "espaces", libelle = "Texte : supprimer les espaces en fin de ligne", categorie = "Texte", procedure = @OT_ESPACES}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "majuscules", libelle = "Texte : MAJUSCULES", categorie = "Texte", procedure = @OT_MAJ}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "minuscules", libelle = "Texte : minuscules", categorie = "Texte", procedure = @OT_MIN}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "numeroter", libelle = "Texte : numéroter les lignes", categorie = "Texte", procedure = @OT_NUMEROTER}
  ARDOISE_ENREGISTRER{genre = "commande", nom = "statistiques", libelle = "Texte : statistiques (lignes, mots, caractères)", categorie = "Texte", procedure = @OT_STATS}
retourner

&& applique f(liste de lignes) -> liste de lignes à la sélection ou au document
procedure OT_APPLIQUER(f)
  locale sel = DOC_SELECTION()
  locale src = sisinon(sel = "", DOC_TEXTE(), sel)
  locale r = joindre(appeler(f, decouper(src, car(10))), car(10))
  si sel = ""
    DOC_FIXER_TEXTE(r)
  sinon
    DOC_REMPLACER_SELECTION(r)
  finsi
retourner

fonction OT_F_TRIER(l)
retourner trier(l)

fonction OT_F_TRIER_INVERSE(l)
retourner trier(l, @OT_PLUS_GRAND)

fonction OT_PLUS_GRAND(a, b)
retourner a > b

fonction OT_F_DOUBLONS(l)
  locale vus = {}
  locale r = {}
  pour chaque x dans l
    si vus[x] = nul
      vus[x] = vrai
      inserer(r, x)
    finsi
  suivant
retourner r

fonction OT_F_VIDES(l)
  locale r = {}
  pour chaque x dans l
    si rogner(x) <> ""
      inserer(r, x)
    finsi
  suivant
retourner r

fonction OT_F_ESPACES(l)
  pour i = 1 a #l
    l[i] = rognerd(l[i])
  suivant
retourner l

fonction OT_F_NUMEROTER(l)
  locale w = #chaine(#l)
  pour i = 1 a #l
    l[i] = chaine(i, w) + "  " + l[i]
  suivant
retourner l

procedure OT_TRIER(ev)
  OT_APPLIQUER(@OT_F_TRIER)
retourner

procedure OT_TRIER_INVERSE(ev)
  OT_APPLIQUER(@OT_F_TRIER_INVERSE)
retourner

procedure OT_DOUBLONS(ev)
  OT_APPLIQUER(@OT_F_DOUBLONS)
retourner

procedure OT_VIDES(ev)
  OT_APPLIQUER(@OT_F_VIDES)
retourner

procedure OT_ESPACES(ev)
  OT_APPLIQUER(@OT_F_ESPACES)
retourner

procedure OT_NUMEROTER(ev)
  OT_APPLIQUER(@OT_F_NUMEROTER)
retourner

procedure OT_MAJ(ev)
  locale s = DOC_SELECTION()
  si s = ""
    DOC_FIXER_TEXTE(majuscule(DOC_TEXTE()))
  sinon
    DOC_REMPLACER_SELECTION(majuscule(s))
  finsi
retourner

procedure OT_MIN(ev)
  locale s = DOC_SELECTION()
  si s = ""
    DOC_FIXER_TEXTE(minuscule(DOC_TEXTE()))
  sinon
    DOC_REMPLACER_SELECTION(minuscule(s))
  finsi
retourner

procedure OT_STATS(ev)
  locale s = DOC_SELECTION()
  locale portee = sisinon(s = "", "document", "sélection")
  si s = ""
    s = DOC_TEXTE()
  finsi
  locale mots = 0
  pour chaque l dans decouper(s, car(10))
    pour chaque m dans decouper(rogner(l), " ")
      si m <> ""
        mots += 1
      finsi
    suivant
  suivant
  STATUT("Statistiques (" + portee + ") : " + #decouper(s, car(10)) + " lignes · " + mots + " mots · " + #s + " caractères")
retourner
