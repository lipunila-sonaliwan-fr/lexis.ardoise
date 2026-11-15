&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Ardoise : ouvrir, enregistrer et fermer des documents ; récents ; session.
&&
&& L'éditeur range le texte avec des fins de ligne LF et des espaces à la place des
&& tabulations : Ardoise note les fins de ligne CRLF et les tabulations d'indentation du fichier
&& d'origine et les rétablit à l'enregistrement. Les fichiers plus gros que le seuil (64 Mo par
&& défaut) et les fichiers binaires s'ouvrent en mode « grand fichier » (lecture par blocs).

procedure OUVRIR_FICHIER(chemin)
  si chemin = nul ou chemin = ""
    retourner
  finsi
  chemin = fichier.absolu(chemin)
  locale deja = ed:chercherdocument(chemin)
  si deja <> nul
    ed:activer(deja)
    retourner
  finsi
  pour chaque k, g dans GF
    si g.chemin = chemin
      ed:activer(nombre(k))
      retourner
    finsi
  suivant
  si non fichier.existe(chemin) ou non fichier.estfichier(chemin)
    STATUT("Fichier introuvable : " + chemin)
    retourner
  finsi
  locale taille_ = fichier.taille(chemin)
  && début du fichier : binaire ? fins de ligne ? tabulations ?
  locale debut_ = fichier.lirebloc(chemin, 0, 65536, {lignes = faux})
  locale binaire_ = debut_.nuls > 0
  si taille_ > REG.seuil_grand ou binaire_
    GF_OUVRIR(chemin, sisinon(binaire_, "binaire", "taille"))
    AJOUTER_RECENT(chemin)
    retourner
  finsi
  locale uid = nul
  essayer
    uid = ed:ouvrir(chemin)
  capturer e
    STATUT("Ouverture impossible : " + e)
    retourner
  finessayer
  DOCS[chaine(uid)] = {chemin = chemin, genre = "texte", ;
                       fin_ligne = sisinon(contient(debut_.texte, car(13) + car(10)), "CRLF", "LF"), ;
                       tabs = contient(debut_.texte, car(9))}
  AJOUTER_RECENT(chemin)
  EXT_EVENEMENT("surouverture", uid, chemin)
  STATUT("Ouvert : " + chemin + " (" + TAILLE_LISIBLE(taille_) + ")")
  MAJ_ETAT()
retourner

procedure AJOUTER_RECENT(chemin)
  locale r = {chemin}
  pour chaque x dans REG.recents
    si x <> chemin et #r < 30
      inserer(r, x)
    finsi
  suivant
  REG.recents = r
retourner

&& enregistre un document ; chemin = nul : son chemin actuel
procedure ENREGISTRER_DOC(uid, chemin)
  locale d = DOCS[chaine(uid)]
  si GF[chaine(uid)] <> nul
    erreur "un grand fichier se consulte en lecture seule (extrayez le bloc pour le modifier)"
  finsi
  si chemin = nul
    chemin = ed:chemin(uid)
  finsi
  si chemin = nul ou chemin = ""
    erreur "document sans chemin"
  finsi
  EXT_EVENEMENT("avantenregistrement", uid, chemin)
  locale crlf = d <> nul et d.fin_ligne = "CRLF"
  locale tabs = d <> nul et d.tabs
  si non crlf et non tabs
    ed:enregistrer(chemin, uid)
  sinon
    locale t = ed:texte(uid)
    si tabs
      t = RETABULER(t)
    finsi
    si crlf
      t = remplacertexte(t, car(10), car(13) + car(10))
    finsi
    si chemin <> ed:chemin(uid)
      ed:enregistrer(chemin, uid)        && nouveau chemin et titre de l'onglet
    finsi
    fichier.ecrire(chemin, t)
    ed:marquer(faux, uid)
  finsi
  si d = nul
    DOCS[chaine(uid)] = {chemin = chemin, genre = "texte", fin_ligne = "LF", tabs = faux}
  sinon
    d.chemin = chemin
  finsi
  AJOUTER_RECENT(chemin)
  EXT_EVENEMENT("surenregistrement", uid, chemin)
retourner

&& indentation : chaque paire d'espaces de tête redevient une tabulation (l'éditeur avait
&& remplacé chaque tabulation par deux espaces)
fonction RETABULER(t)
  locale lignes = decouper(t, car(10))
  locale tab = car(9)
  pour i = 1 a #lignes
    locale l = lignes[i]
    si commencepar(l, "  ")
      locale n = 0
      tantque souschaine(l, n * 2 + 1, 2) = "  "
        n += 1
      fintantque
      lignes[i] = repliquer(tab, n) + souschaine(l, n * 2 + 1)
    finsi
  suivant
retourner joindre(lignes, car(10))

procedure FERMER_DOC(uid)
  si uid = nul ou uid < 0
    retourner
  finsi
  si ed:modifie(uid)
    ed:activer(uid)
    si ui.confirmer("« " + ed:titre(nul, uid) + " » a des modifications non enregistrées." + car(10) + ;
                    "Les enregistrer avant de fermer ?", "question")
      essayer
        si ed:chemin(uid) = ""
          locale c = ui.enregistrerfichier{nom = ed:titre(nul, uid)}
          si c = nul
            retourner
          finsi
          ENREGISTRER_DOC(uid, c)
        sinon
          ENREGISTRER_DOC(uid, nul)
        finsi
      capturer e
        si non ui.confirmer("Enregistrement impossible (" + e + ")." + car(10) + "Fermer quand même ?", "attention")
          retourner
        finsi
      finessayer
    finsi
  finsi
  locale g = GF[chaine(uid)]
  locale chemin = sisinon(g <> nul, g.chemin, ed:chemin(uid))
  si chemin <> nul et chemin <> ""
    inserer(FERMES, {chemin = chemin, position = sisinon(g = nul, nul, g.debut)})
  finsi
  EXT_EVENEMENT("surfermeture", uid, chemin)
  ed:fermer(uid)
  DOCS[chaine(uid)] = nul
  GF[chaine(uid)] = nul
  si STRUCT.uid = uid
    STRUCT_VIDER()
  finsi
  MAJ_ETAT()
retourner

&& session : onglets ouverts et document actif
procedure MEMORISER_SESSION
  locale s = {}
  locale actif_ = ""
  pour chaque d dans ed:documents()
    locale g = GF[chaine(d.uid)]
    si g <> nul
      inserer(s, {chemin = g.chemin, grand = vrai, position = g.debut})
    sinonsi d.chemin <> ""
      inserer(s, {chemin = d.chemin, grand = faux, ligne = sisinon(d.uid = ed:actif(), ed:curseur().ligne, 1)})
    finsi
    si d.uid = ed:actif()
      actif_ = sisinon(g <> nul, g.chemin, d.chemin)
    finsi
  suivant
  REG.session = s
  REG.actif = actif_
retourner

procedure RESTAURER_SESSION
  si REG.session = nul
    retourner
  finsi
  pour chaque x dans REG.session
    si x.chemin <> nul et fichier.existe(x.chemin)
      essayer
        OUVRIR_FICHIER(x.chemin)
        locale g = GF_PAR_CHEMIN(x.chemin)
        si g <> nul et x.position <> nul et x.position > 0
          GF_CHARGER(g.uid, x.position, nul)
        finsi
      capturer e
      finessayer
    finsi
  suivant
  si REG.actif <> nul et REG.actif <> ""
    OUVRIR_FICHIER(REG.actif)
    pour chaque x dans REG.session
      si x.chemin = REG.actif et x.ligne <> nul et x.ligne > 1
        ed:aller(x.ligne, 1)
      finsi
    suivant
  finsi
retourner

&&
&& Commandes du registre (groupe Fichier)
&&

procedure CMD_NOUVEAU(ev)
  locale uid = ed:nouveau("sans titre " + (#ed:documents() + 1))
  ed:langage("texte", uid)
  DOCS[chaine(uid)] = {chemin = "", genre = "texte", fin_ligne = "LF", tabs = faux}
  ed:focus()
  MAJ_ETAT()
retourner

procedure CMD_OUVRIR(ev)
  locale c = ui.ouvrirfichier{titre = "Ouvrir un fichier", dossier = REG.dossier}
  si c <> nul
    OUVRIR_FICHIER(c)
    REG.dossier = fichier.dossier(c)
  finsi
  ed:focus()
retourner

procedure CMD_OUVRIR_CHEMIN(ev)
  locale c = ui.demander("Chemin du fichier à ouvrir :", REG.dossier)
  si c <> nul et rogner(c) <> ""
    OUVRIR_FICHIER(rogner(c))
  finsi
retourner

procedure CMD_OUVRIR_GRAND(ev)
  locale c = ui.ouvrirfichier{titre = "Ouvrir en mode grand fichier", dossier = REG.dossier}
  si c <> nul
    GF_OUVRIR(c, "demande")
    AJOUTER_RECENT(c)
  finsi
retourner

procedure CMD_DOSSIER(ev)
  locale d = ui.demander("Dossier de travail (ouverture rapide, Ctrl+P) :", REG.dossier)
  si d <> nul et rogner(d) <> "" et fichier.estdossier(rogner(d))
    REG.dossier = fichier.absolu(rogner(d))
    FICHIERS_DOSSIER = nul
    STATUT("Dossier de travail : " + REG.dossier)
  finsi
retourner

procedure CMD_ENREGISTRER(ev)
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    retourner
  finsi
  si ed:chemin(uid) = ""
    CMD_ENREGISTRER_SOUS(ev)
    retourner
  finsi
  essayer
    ENREGISTRER_DOC(uid, nul)
    STATUT("Enregistré : " + ed:chemin(uid) + " (" + heure() + ")")
  capturer e
    ui.alerte("Enregistrement impossible : " + e, "attention")
  finessayer
  MAJ_ETAT()
retourner

procedure CMD_ENREGISTRER_SOUS(ev)
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    retourner
  finsi
  locale c = ui.enregistrerfichier{nom = ed:titre(nul, uid)}
  si c = nul
    retourner
  finsi
  essayer
    ENREGISTRER_DOC(uid, c)
    ed:langage("", uid)              && langage d'après la nouvelle extension
    STATUT("Enregistré sous : " + c)
  capturer e
    ui.alerte("Enregistrement impossible : " + e, "attention")
  finessayer
  MAJ_ETAT()
  STRUCT_DEMANDER(vrai)
retourner

procedure CMD_ENREGISTRER_TOUT(ev)
  locale n = 0
  pour chaque d dans ed:documents()
    si d.modifie et d.chemin <> ""
      essayer
        ENREGISTRER_DOC(d.uid, nul)
        n += 1
      capturer e
        STATUT("Erreur : " + e)
      finessayer
    finsi
  suivant
  STATUT(n + " document(s) enregistré(s).")
retourner

procedure CMD_FERMER(ev)
  FERMER_DOC(ed:actif())
retourner

procedure CMD_FERMER_TOUT(ev)
  pour chaque d dans ed:documents()
    FERMER_DOC(d.uid)
  suivant
retourner

procedure CMD_FERMER_AUTRES(ev)
  locale a = ed:actif()
  pour chaque d dans ed:documents()
    si d.uid <> a
      FERMER_DOC(d.uid)
    finsi
  suivant
retourner

procedure CMD_ROUVRIR(ev)
  si #FERMES = 0
    STATUT("Aucun onglet fermé à rouvrir.")
    retourner
  finsi
  locale x = retirer(FERMES)
  OUVRIR_FICHIER(x.chemin)
  si x.position <> nul
    locale g = GF_PAR_CHEMIN(x.chemin)
    si g <> nul
      GF_CHARGER(g.uid, x.position, nul)
    finsi
  finsi
retourner

procedure CMD_RECHARGER(ev)
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    retourner
  finsi
  si GF[chaine(uid)] <> nul
    GF_RECHARGER(uid)
    retourner
  finsi
  locale c = ed:chemin(uid)
  si c = "" ou non fichier.existe(c)
    retourner
  finsi
  si ed:modifie(uid) et non ui.confirmer("Abandonner les modifications et relire le fichier ?", "question")
    retourner
  finsi
  ed:fixertexte(fichier.lire(c), uid, vrai)
  STATUT("Relu depuis le disque : " + c)
retourner

procedure CMD_COPIER_CHEMIN(ev)
  locale uid = ed:actif()
  locale g = GF[chaine(uid)]
  locale c = sisinon(g <> nul, g.chemin, ed:chemin(uid))
  ed:pressepapiers(c)
  STATUT("Chemin copié : " + c)
retourner

procedure CMD_RECENTS(ev)
  locale items = {}
  pour chaque c dans REG.recents
    inserer(items, {libelle = fichier.nom(c), detail = fichier.dossier(c), valeur = c})
  suivant
  QUICKPICK("Fichiers récents", items, @OUVRIR_FICHIER)
retourner

&& liste des fichiers du dossier de travail (ouverture rapide)
fonction LISTER_DOSSIER()
  si FICHIERS_DOSSIER <> nul
    retourner FICHIERS_DOSSIER
  finsi
  locale r = {}
  essayer
    pour chaque n dans fichier.liste(REG.dossier, vrai)
      si non finitpar(n, "/") et non ("/.git/" $ "/" + n) et non ("node_modules/" $ n) et ;
         non ("/nimcache/" $ "/" + n) et non ("/__pycache__/" $ "/" + n) et non commencepar(n, ".git/")
        inserer(r, n)
        si #r >= 5000
          sortir
        finsi
      finsi
    suivant
  capturer e
  finessayer
  FICHIERS_DOSSIER = r
retourner r
