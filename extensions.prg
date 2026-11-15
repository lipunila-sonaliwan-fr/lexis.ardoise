&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Ardoise : extensions (plugins) écrites en Lexis+.
&&
&& Une extension est un fichier .prg du dossier plugins/ d'Ardoise ou de ~/.ardoise/plugins/.
&& Elle ne contient que des procédures ; son point d'entrée EXTENSION_<NOM>() (NOM = nom du
&& fichier en majuscules) appelle ARDOISE_ENREGISTRER pour chaque apport :
&&
&&   {genre = "commande",  nom =, libelle =, categorie =, raccourci =, procedure = @P}   P(ev)
&&   {genre = "langage",   nom =, definition = {...}}         voir langages.prg / ui.definirlangage
&&   {genre = "structure", langage =, procedure = @S}         S(lignes, langage) -> {{nom, genre, ligne, fin, niveau, routine}}
&&   {genre = "formateur", nom =, langage = "json" | {...}, procedure = @F}   F(texte) -> texte formaté
&&   {genre = "surouverture" | "avantenregistrement" | "surenregistrement" | "surfermeture", nom =, procedure = @E}   E(uid, chemin)
&&
&& API offerte aux extensions : ed (l'éditeur), DOC_TEXTE(), DOC_FIXER_TEXTE(t), DOC_SELECTION(),
&& DOC_REMPLACER_SELECTION(t), DOC_INSERER(t), DOC_LIGNES(), DOC_CHEMIN(), DOC_LANGAGE(),
&& STATUT(message), QUICKPICK(titre, items, @P), DOC_INFO(titre, markdown), OUVRIR_FICHIER(chemin).

procedure CHARGER_EXTENSIONS
  EXTENSIONS = {}
  pour chaque dossier_ dans {fichier.joindre(systeme.dossierprogramme(), "plugins"), fichier.joindre(DOSSIER_ARDOISE(), "plugins")}
    si fichier.existe(dossier_)
      pour chaque nom dans fichier.liste(dossier_)
        si finitpar(nom, ".prg")
          locale base_ = gauche(nom, #nom - 4)
          essayer
            locale entree = lexis.procedure("EXTENSION_" + majuscule(base_))
            si entree = nul
              lexis.charger(fichier.joindre(dossier_, nom))
              entree = lexis.procedure("EXTENSION_" + majuscule(base_))
            finsi
            si entree <> nul
              appeler(entree)
              si non LISTE_CONTIENT(EXTENSIONS, base_)
                inserer(EXTENSIONS, base_)
              finsi
            finsi
          capturer e
            STATUT("Extension « " + nom + " » ignorée : " + e)
          finessayer
        finsi
      suivant
    finsi
  suivant
retourner

procedure ARDOISE_ENREGISTRER(x)
  si x = nul ou x.genre = nul
    erreur "ARDOISE_ENREGISTRER : {genre=, nom=, procedure=} attendu"
  finsi
  && un même apport (genre + nom) n'est gardé qu'une fois : recharger les extensions le remplace
  locale cle = x.genre + ":" + sisinon(x.nom = nul, sisinon(x.langage = nul, "", texte(x.langage)), x.nom)
  pour i = 1 a #EXT_REG
    si EXT_REG[i].cle = cle
      retirer(EXT_REG, i)
      sortir
    finsi
  suivant
  x.cle = cle
  inserer(EXT_REG, x)
  faire cas
  cas x.genre = "commande"
    COMMANDE("ext." + x.nom, sisinon(x.libelle = nul, x.nom, x.libelle), sisinon(x.categorie = nul, "Extensions", x.categorie), ;
             x.raccourci, x.procedure)
  cas x.genre = "langage"
    LANGAGE(x.nom, x.definition)
  fincas
retourner

&& événements de document transmis aux extensions
procedure EXT_EVENEMENT(genre, uid, chemin)
  pour chaque x dans EXT_REG
    si x.genre = genre
      essayer
        appeler(x.procedure, uid, chemin)
      capturer e
        STATUT("Extension « " + sisinon(x.nom = nul, genre, x.nom) + " » : " + e)
      finessayer
    finsi
  suivant
retourner

procedure CMD_EXTENSIONS(ev)
  CHARGER_EXTENSIONS()
  ed:analyser()
  STATUT("Extensions : " + sisinon(#EXTENSIONS = 0, "aucune", joindre(EXTENSIONS, ", ")) + ".")
retourner

procedure CMD_LISTE_EXTENSIONS(ev)
  locale n = car(10)
  locale t = "# Extensions" + n + n + "Dossiers : `" + fichier.joindre(systeme.dossierprogramme(), "plugins") + "` et `" + ;
             fichier.joindre(DOSSIER_ARDOISE(), "plugins") + "`" + n + n + "| Genre | Nom | Détail |" + n + "|:--|:--|:--|" + n
  pour chaque x dans EXT_REG
    t = t + "| " + x.genre + " | " + sisinon(x.nom = nul, "", x.nom) + " | " + ;
        sisinon(x.libelle <> nul, x.libelle, sisinon(x.langage <> nul, "langage " + texte(x.langage), "")) + " |" + n
  suivant
  t = t + n + "Fichiers chargés : " + sisinon(#EXTENSIONS = 0, "aucun", joindre(EXTENSIONS, ", ")) + "." + n
  DOC_INFO("Extensions.md", t)
retourner

&&
&& API des extensions
&&

fonction DOC_TEXTE()
retourner ed:texte()

procedure DOC_FIXER_TEXTE(t)
  si GF[chaine(ed:actif())] <> nul ou ed:lecture(ed:actif())
    erreur "document en lecture seule"
  finsi
  ed:fixertexte(t)
retourner

fonction DOC_SELECTION()
retourner ed:selection()

procedure DOC_REMPLACER_SELECTION(t)
  ed:inserer(t)
retourner

procedure DOC_INSERER(t)
  ed:inserer(t)
retourner

fonction DOC_LIGNES()
retourner decouper(ed:texte(), car(10))

fonction DOC_CHEMIN()
  locale g = GF[chaine(ed:actif())]
retourner sisinon(g <> nul, g.chemin, ed:chemin())

fonction DOC_LANGAGE()
retourner ed:langage()
