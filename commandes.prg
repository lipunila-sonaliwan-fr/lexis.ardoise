&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Ardoise : registre des commandes et palette.
&&
&& Toute action est une commande {id, libelle, categorie, raccourci, proc} : la palette, les
&& raccourcis et les extensions s'appuient sur ce seul registre (il n'y a pas de menu).
&& La palette change de rôle selon le premier caractère tapé :
&&   >texte   commandes (les plus récemment utilisées d'abord)
&&   texte    fichiers : récents et dossier de travail (Ctrl+P)
&&   @texte   symboles du document (structure)
&&   :n       aller à la ligne n ; :n% à une position ; :#n à un octet (grand fichier)
&&   ?        aide

procedure COMMANDE(id, libelle, categorie, raccourci, proc)
  && une commande de même id est remplacée (extensions rechargées)
  pour i = 1 a #COMMANDES
    si COMMANDES[i].id = id
      COMMANDES[i] = {id = id, libelle = libelle, categorie = categorie, raccourci = sisinon(raccourci = nul, "", raccourci), proc = proc}
      retourner
    finsi
  suivant
  inserer(COMMANDES, {id = id, libelle = libelle, categorie = categorie, raccourci = sisinon(raccourci = nul, "", raccourci), proc = proc})
retourner

procedure EXECUTER(id)
  pour chaque c dans COMMANDES
    si c.id = id
      CMD_RECENTE(id)
      essayer
        appeler(c.proc, nul)
      capturer e
        STATUT("« " + c.libelle + " » : " + e)
      finessayer
      retourner
    finsi
  suivant
  STATUT("Commande inconnue : " + id)
retourner

procedure CMD_RECENTE(id)
  si commencepar(id, "palette.")
    retourner
  finsi
  locale r = {id}
  pour chaque x dans REG.cmds_recentes
    si x <> id et #r < 12
      inserer(r, x)
    finsi
  suivant
  REG.cmds_recentes = r
retourner

procedure ENREGISTRER_COMMANDES
  && Fichier
  COMMANDE("fichier.nouveau", "Nouveau document", "Fichier", "Ctrl+N", @CMD_NOUVEAU)
  COMMANDE("fichier.ouvrir", "Ouvrir un fichier…", "Fichier", "Ctrl+O", @CMD_OUVRIR)
  COMMANDE("fichier.ouvrirchemin", "Ouvrir un fichier par son chemin…", "Fichier", "", @CMD_OUVRIR_CHEMIN)
  COMMANDE("palette.fichiers", "Ouvrir rapidement (dossier de travail, récents)", "Fichier", "Ctrl+P", @PALETTE_FICHIERS)
  COMMANDE("fichier.recents", "Fichiers récents…", "Fichier", "", @CMD_RECENTS)
  COMMANDE("fichier.dossier", "Choisir le dossier de travail…", "Fichier", "", @CMD_DOSSIER)
  COMMANDE("fichier.enregistrer", "Enregistrer", "Fichier", "Ctrl+S", @CMD_ENREGISTRER)
  COMMANDE("fichier.enregistrersous", "Enregistrer sous…", "Fichier", "Ctrl+Maj+S", @CMD_ENREGISTRER_SOUS)
  COMMANDE("fichier.enregistrertout", "Enregistrer tout", "Fichier", "", @CMD_ENREGISTRER_TOUT)
  COMMANDE("fichier.fermer", "Fermer l'onglet", "Fichier", "Ctrl+W", @CMD_FERMER)
  COMMANDE("fichier.fermertout", "Fermer tous les onglets", "Fichier", "", @CMD_FERMER_TOUT)
  COMMANDE("fichier.fermerautres", "Fermer les autres onglets", "Fichier", "", @CMD_FERMER_AUTRES)
  COMMANDE("fichier.rouvrir", "Rouvrir l'onglet fermé", "Fichier", "", @CMD_ROUVRIR)
  COMMANDE("fichier.recharger", "Relire le fichier depuis le disque", "Fichier", "", @CMD_RECHARGER)
  COMMANDE("fichier.copierchemin", "Copier le chemin du fichier", "Fichier", "", @CMD_COPIER_CHEMIN)
  COMMANDE("fichier.grand", "Ouvrir en mode grand fichier…", "Fichier", "", @CMD_OUVRIR_GRAND)
  COMMANDE("app.quitter", "Quitter Ardoise", "Fichier", "", @CMD_QUITTER)
  && Édition
  COMMANDE("edition.annuler", "Annuler", "Édition", "Ctrl+Z", @CMD_ANNULER)
  COMMANDE("edition.retablir", "Rétablir", "Édition", "Ctrl+Y", @CMD_RETABLIR)
  COMMANDE("edition.toutselectionner", "Tout sélectionner", "Édition", "Ctrl+A", @CMD_TOUT)
  COMMANDE("edition.dupliquer", "Dupliquer la ligne", "Édition", "Ctrl+D", @CMD_DUPLIQUER)
  COMMANDE("edition.commenter", "Commenter / décommenter", "Édition", "Ctrl+B", @CMD_COMMENTER)
  COMMANDE("edition.indenter", "Indenter", "Édition", "Tab", @CMD_INDENTER)
  COMMANDE("edition.desindenter", "Désindenter", "Édition", "Maj+Tab", @CMD_DESINDENTER)
  COMMANDE("edition.rechercher", "Rechercher…", "Édition", "Ctrl+F", @CMD_RECHERCHER)
  COMMANDE("edition.suivant", "Rechercher l'occurrence suivante", "Édition", "F3", @CMD_SUIVANT)
  COMMANDE("edition.precedent", "Rechercher l'occurrence précédente", "Édition", "Maj+F3", @CMD_PRECEDENT)
  COMMANDE("edition.remplacer", "Remplacer…", "Édition", "Ctrl+K", @CMD_REMPLACER)
  COMMANDE("edition.aller", "Aller à la ligne…", "Édition", "Ctrl+L", @CMD_ALLER)
  COMMANDE("palette.symboles", "Aller à un symbole…", "Édition", "Ctrl+Maj+O", @PALETTE_SYMBOLES)
  COMMANDE("edition.definition", "Aller à la définition du mot courant", "Édition", "F12", @CMD_DEFINITION)
  COMMANDE("edition.date", "Insérer la date et l'heure", "Édition", "", @CMD_DATE)
  COMMANDE("edition.formater", "Formater le document", "Édition", "", @CMD_FORMATER)
  && Affichage
  COMMANDE("palette.commandes", "Palette de commandes", "Affichage", "F1 · Ctrl+Maj+P", @PALETTE)
  COMMANDE("affichage.structure", "Afficher / masquer la structure", "Affichage", "", @CMD_STRUCTURE)
  COMMANDE("affichage.graphe", "Structure : graphe", "Affichage", "", @CMD_VUE_GRAPHE)
  COMMANDE("affichage.plan", "Structure : plan", "Affichage", "", @CMD_VUE_PLAN)
  COMMANDE("affichage.minicarte", "Afficher / masquer la minicarte", "Affichage", "", @CMD_MINICARTE)
  COMMANDE("affichage.theme", "Thème clair / sombre", "Affichage", "", @CMD_THEME)
  COMMANDE("affichage.plusgrand", "Police plus grande", "Affichage", "Ctrl++", @CMD_PLUS_GRAND)
  COMMANDE("affichage.pluspetit", "Police plus petite", "Affichage", "Ctrl+-", @CMD_PLUS_PETIT)
  COMMANDE("affichage.policedefaut", "Taille de police par défaut", "Affichage", "Ctrl+0", @CMD_POLICE_DEFAUT)
  COMMANDE("affichage.pleinecran", "Plein écran", "Affichage", "", @CMD_PLEIN_ECRAN)
  COMMANDE("affichage.suivant", "Onglet suivant", "Affichage", "Ctrl+Tab", @CMD_ONGLET_SUIVANT)
  && Langage
  COMMANDE("langage.choisir", "Changer le langage du document…", "Langage", "", @CMD_LANGAGE)
  COMMANDE("langage.liste", "Langages disponibles", "Langage", "", @CMD_LANGAGES)
  && Grand fichier
  COMMANDE("gf.debut", "Grand fichier : début", "Grand fichier", "", @GF_DEBUT)
  COMMANDE("gf.fin", "Grand fichier : fin", "Grand fichier", "", @GF_FIN)
  COMMANDE("gf.suivant", "Grand fichier : bloc suivant", "Grand fichier", "↓ en bas du bloc", @GF_SUIVANT)
  COMMANDE("gf.precedent", "Grand fichier : bloc précédent", "Grand fichier", "↑ en haut du bloc", @GF_PRECEDENT)
  COMMANDE("gf.aller", "Grand fichier : aller à une ligne, une position (%) ou un octet…", "Grand fichier", ":", @GF_ALLER)
  COMMANDE("gf.rechercher", "Grand fichier : rechercher dans tout le fichier…", "Grand fichier", "", @GF_RECHERCHER)
  COMMANDE("gf.occsuivante", "Grand fichier : occurrence suivante", "Grand fichier", "F3", @GF_OCC_SUIVANTE)
  COMMANDE("gf.occprecedente", "Grand fichier : occurrence précédente", "Grand fichier", "Maj+F3", @GF_OCC_PRECEDENTE)
  COMMANDE("gf.arreter", "Grand fichier : arrêter la recherche", "Grand fichier", "Échap", @GF_ARRETER_RECHERCHE)
  COMMANDE("gf.extraire", "Grand fichier : copier le bloc dans un nouvel onglet modifiable", "Grand fichier", "", @GF_EXTRAIRE)
  COMMANDE("gf.suivre", "Grand fichier : suivre la fin (journal qui grandit)", "Grand fichier", "", @GF_BASCULER_SUIVI)
  COMMANDE("gf.index", "Grand fichier : indexer les lignes (marche / arrêt)", "Grand fichier", "", @GF_BASCULER_INDEX)
  COMMANDE("gf.bloc", "Grand fichier : taille des blocs…", "Grand fichier", "", @GF_TAILLE_BLOC)
  COMMANDE("gf.seuil", "Grand fichier : seuil d'ouverture automatique…", "Grand fichier", "", @GF_SEUIL)
  COMMANDE("gf.infos", "Grand fichier : informations", "Grand fichier", "", @GF_INFOS)
  && Extensions et aide
  COMMANDE("ext.recharger", "Recharger les extensions", "Extensions", "", @CMD_EXTENSIONS)
  COMMANDE("ext.liste", "Extensions chargées", "Extensions", "", @CMD_LISTE_EXTENSIONS)
  COMMANDE("aide.guide", "Aide d'Ardoise", "Aide", "", @CMD_AIDE)
  COMMANDE("aide.apropos", "À propos d'Ardoise", "Aide", "", @CMD_APROPOS)
retourner

&&
&& Choix rapide générique : une liste filtrée au clavier dans une fenêtre rattachée
&&

procedure QUICKPICK(titre, items, proc)
  PALETTE_FENETRE(titre, "", {items = items, proc = proc, dynamique = faux})
retourner

procedure PALETTE_FENETRE(titre, texte_, options_)
  globale fenpal, qp_saisie, qp_liste, qp_aide, QP
  si fenpal <> nul
    essayer
      fenpal:fermer()
    capturer e
    finessayer
  finsi
  QP = options_
  QP.visibles = {}
  QP.mode = "?"
  fenpal = ui.fenetre{titre = titre, largeur = 680, hauteur = 440, disposition = "bordure", sombre = REG.sombre, ;
                      densite = "compacte", parent = fen}
  fenpal.surtouchebas = @QP_TOUCHE
  fenpal.surfermeture = @QP_FERMEE
  qp_saisie = fenpal:ajouter(ui.saisie{indication = sisinon(QP.dynamique, ;
                "> commandes · @ symboles · : ligne · ? aide · sinon : fichiers", "Tapez pour filtrer")})
  qp_saisie.ancrage = "haut"
  qp_saisie.valeur = texte_
  qp_saisie.surchangement = @QP_FILTRER
  qp_saisie.surtouchebas = @QP_TOUCHE
  qp_aide = fenpal:ajouter(ui.etiquette(""))
  qp_aide.ancrage = "bas"
  qp_aide.couleur = "#94A3B8"
  qp_liste = fenpal:ajouter(ui.liste())
  qp_liste.ancrage = "centre"
  qp_liste.surdoubleclic = @QP_VALIDER
  qp_liste.surtouchebas = @QP_TOUCHE
  QP_FILTRER(nul)
  qp_saisie:focus()
retourner

procedure QP_FERMEE(ev)
  globale fenpal
  fenpal = nul
retourner

&& éléments de la palette selon le mode (premier caractère)
fonction QP_SOURCE(mode, reste)
  locale items = {}
  faire cas
  cas mode = ">"
    locale vus = {}
    pour chaque id dans REG.cmds_recentes
      pour chaque c dans COMMANDES
        si c.id = id
          inserer(items, {libelle = c.libelle, detail = "récent · " + c.categorie + sisinon(c.raccourci <> "", "  " + c.raccourci, ""), valeur = "cmd:" + c.id})
          vus[c.id] = vrai
        finsi
      suivant
    suivant
    pour chaque c dans COMMANDES
      si vus[c.id] = nul
        inserer(items, {libelle = c.libelle, detail = c.categorie + sisinon(c.raccourci <> "", "  " + c.raccourci, ""), valeur = "cmd:" + c.id})
      finsi
    suivant
  cas mode = "@"
    pour chaque s dans STRUCT.symboles
      inserer(items, {libelle = repliquer("  ", s.niveau) + ICONE_SYMBOLE(s.genre) + " " + s.nom, ;
                      detail = s.genre + " · ligne " + s.ligne, valeur = "ligne:" + s.ligne})
    suivant
  cas mode = ":"
    locale r = rogner(reste)
    si r <> ""
      inserer(items, {libelle = "Aller à " + sisinon(finitpar(r, "%"), "la position " + r, ;
                      sisinon(commencepar(r, "#"), "l'octet " + souschaine(r, 2), "la ligne " + r)), ;
                      detail = sisinon(GF[chaine(ed:actif())] <> nul, "grand fichier", "document"), valeur = "aller:" + r})
    finsi
  cas mode = "?"
    inserer(items, {libelle = ">  commandes", detail = "toutes les actions d'Ardoise et des extensions", valeur = "prefixe:>"})
    inserer(items, {libelle = "@  symboles du document", detail = "fonctions, classes, titres… (Ctrl+Maj+O)", valeur = "prefixe:@"})
    inserer(items, {libelle = ":  aller à la ligne", detail = ":120   :50%   :#1048576 (octet, grand fichier)", valeur = "prefixe::"})
    inserer(items, {libelle = "    fichiers", detail = "sans préfixe : récents et dossier de travail (Ctrl+P)", valeur = "prefixe:"})
  autrement
    pour chaque c dans REG.recents
      inserer(items, {libelle = fichier.nom(c), detail = "récent · " + fichier.dossier(c), valeur = "fichier:" + c})
    suivant
    pour chaque n dans LISTER_DOSSIER()
      inserer(items, {libelle = fichier.nom(n), detail = n, valeur = "fichier:" + fichier.joindre(REG.dossier, n)})
    suivant
  fincas
retourner items

procedure QP_FILTRER(ev)
  locale q = qp_saisie.valeur
  locale reste = q
  si QP.dynamique
    locale m = gauche(q, 1)
    si m <> ">" et m <> "@" et m <> ":" et m <> "?"
      m = ""
    sinon
      reste = souschaine(q, 2)
    finsi
    si m <> QP.mode ou m = ":"
      QP.mode = m
      QP.items = QP_SOURCE(m, reste)
    finsi
    qp_aide.libelle = sisinon(m = ">", "Commandes — Entrée pour exécuter", sisinon(m = "@", "Symboles du document", ;
                      sisinon(m = ":", "Aller à…", sisinon(m = "?", "Préfixes de la palette", ;
                      "Fichiers — dossier de travail : " + REG.dossier + "   (> commandes, @ symboles, : ligne)"))))
  finsi
  qp_liste:vider()
  QP.visibles = {}
  locale mots = decouper(NORMALISER(rogner(sisinon(QP.mode = ":", "", reste))), " ")
  pour chaque it dans QP.items
    si it.cle = nul
      it.cle = NORMALISER(it.libelle + " " + sisinon(it.detail = nul, "", it.detail))
    finsi
    locale h = it.cle
    locale ok = vrai
    pour chaque mm dans mots
      si mm <> "" et non contient(h, mm)
        ok = faux
        sortir
      finsi
    suivant
    si ok
      qp_liste:ajouter(it.libelle + sisinon(it.detail = nul ou it.detail = "", "", "      — " + it.detail))
      inserer(QP.visibles, it)
      si #QP.visibles >= 300
        sortir
      finsi
    finsi
  suivant
  si #QP.visibles > 0
    qp_liste:selectionner(1)
  finsi
retourner

procedure QP_TOUCHE(ev)
  faire cas
  cas ev.touche = 27
    ev:arreter()
    QP_FERMER()
  cas ev.touche = 13 ou ev.touche = 1073741912
    ev:arreter()
    QP_VALIDER(nul)
  cas ev.touche = 1073741905                && bas
    locale i = nombre(qp_liste:selection())
    si i <> nul et i < #QP.visibles
      qp_liste:selectionner(i + 1)
    finsi
    ev:arreter()
  cas ev.touche = 1073741906                && haut
    locale i = nombre(qp_liste:selection())
    si i <> nul et i > 1
      qp_liste:selectionner(i - 1)
    finsi
    ev:arreter()
  fincas
retourner

procedure QP_FERMER
  globale fenpal
  si fenpal <> nul
    locale f = fenpal
    fenpal = nul
    f:fermer()
  finsi
  ed:focus()
retourner

procedure QP_VALIDER(ev)
  si fenpal = nul
    retourner
  finsi
  locale i = nombre(qp_liste:selection())
  si i = nul ou i < 1 ou i > #QP.visibles
    retourner
  finsi
  locale it = QP.visibles[i]
  si QP.dynamique et commencepar(it.valeur, "prefixe:")
    qp_saisie.valeur = souschaine(it.valeur, 9)
    qp_saisie:focus()
    retourner
  finsi
  locale proc = QP.proc
  QP_FERMER()
  appeler(proc, it.valeur)
retourner

&&
&& Palette de commandes et ses variantes
&&

procedure PALETTE(ev)
  PALETTE_FENETRE("Palette de commandes", ">", {proc = @PALETTE_CHOIX, dynamique = vrai})
retourner

procedure PALETTE_FICHIERS(ev)
  PALETTE_FENETRE("Ouvrir rapidement", "", {proc = @PALETTE_CHOIX, dynamique = vrai})
retourner

procedure PALETTE_SYMBOLES(ev)
  STRUCT_RAFRAICHIR()
  PALETTE_FENETRE("Aller à un symbole", "@", {proc = @PALETTE_CHOIX, dynamique = vrai})
retourner

procedure CMD_ALLER(ev)
  PALETTE_FENETRE("Aller à…", ":", {proc = @PALETTE_CHOIX, dynamique = vrai})
retourner

procedure PALETTE_CHOIX(v)
  faire cas
  cas commencepar(v, "cmd:")
    EXECUTER(souschaine(v, 5))
  cas commencepar(v, "fichier:")
    OUVRIR_FICHIER(souschaine(v, 9))
  cas commencepar(v, "ligne:")
    ed:aller(nombre(souschaine(v, 7)), 1)
  cas commencepar(v, "aller:")
    ALLER_A(souschaine(v, 7))
  fincas
  ed:focus()
retourner

&& « 120 », « 50% » ou « #1048576 » (octet)
procedure ALLER_A(r)
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    retourner
  finsi
  si GF[chaine(uid)] <> nul
    GF_ALLER_A(uid, r)
    retourner
  finsi
  si finitpar(r, "%")
    locale p = nombre(remplacertexte(gauche(r, #r - 1), ",", "."))
    si p <> nul
      ed:aller(max(1, entier(ed:defilement().total * p / 100)), 1)
    finsi
    retourner
  finsi
  locale n = nombre(remplacertexte(r, " ", ""))
  si n <> nul
    ed:aller(n, 1)
  finsi
retourner

fonction ICONE_SYMBOLE(g)
  faire cas
  cas g = "classe" ou g = "structure" ou g = "interface" ou g = "trait" ou g = "type" ou g = "énumération"
    retourner "◆"
  cas g = "module" ou g = "espace" ou g = "implémentation" ou g = "section"
    retourner "▣"
  cas g = "titre"
    retourner "§"
  cas g = "erreur"
    retourner "✖"
  cas g = "macro" ou g = "variable"
    retourner "#"
  cas g = "clef" ou g = "balise" ou g = "sélecteur" ou g = "cible"
    retourner "•"
  fincas
retourner "ƒ"

&&
&& Commandes d'édition et d'affichage
&&

procedure CMD_ANNULER(ev)
  ed:commande("annuler")
retourner

procedure CMD_RETABLIR(ev)
  ed:commande("retablir")
retourner

procedure CMD_TOUT(ev)
  ed:commande("toutselectionner")
retourner

procedure CMD_DUPLIQUER(ev)
  ed:commande("dupliquer")
retourner

procedure CMD_COMMENTER(ev)
  ed:commande("commenter")
retourner

procedure CMD_INDENTER(ev)
  ed:commande("indenter")
retourner

procedure CMD_DESINDENTER(ev)
  ed:commande("desindenter")
retourner

procedure CMD_RECHERCHER(ev)
  locale r = ui.rechercher{texte = sisinon(ed:selection() = "", sisinon(RECH = nul, "", RECH.texte), ed:selection()), ;
                           casse = RECH <> nul et RECH.casse}
  si r = nul
    retourner
  finsi
  RECH = r
  CHERCHER(faux)
retourner

procedure CMD_REMPLACER(ev)
  locale r = ui.rechercher{texte = sisinon(ed:selection() = "", sisinon(RECH = nul, "", RECH.texte), ed:selection()), remplacer = vrai}
  si r = nul
    retourner
  finsi
  RECH = r
  si GF[chaine(ed:actif())] <> nul
    STATUT("Un grand fichier est en lecture seule : recherche seulement.")
    CHERCHER(faux)
    retourner
  finsi
  faire cas
  cas r.action = "toutremplacer"
    locale n = ed:remplacertout(r.texte, r.remplacement, {casse = r.casse, motentier = r.motentier})
    STATUT(n + " remplacement(s).")
  cas r.action = "remplacer"
    ed:remplacer(r.texte, r.remplacement, {casse = r.casse, motentier = r.motentier})
  autrement
    CHERCHER(faux)
  fincas
retourner

procedure CMD_SUIVANT(ev)
  CHERCHER(faux)
retourner

procedure CMD_PRECEDENT(ev)
  CHERCHER(vrai)
retourner

&& recherche dans le document ; en mode grand fichier, poursuit dans tout le fichier
procedure CHERCHER(arriere)
  si RECH = nul ou RECH.texte = nul ou RECH.texte = ""
    CMD_RECHERCHER(nul)
    retourner
  finsi
  locale uid = ed:actif()
  si GF[chaine(uid)] <> nul
    GF_CHERCHER_DEPUIS_CURSEUR(uid, RECH.texte, RECH.casse, arriere)
    retourner
  finsi
  si ed:chercher(RECH.texte, {casse = RECH.casse, motentier = RECH.motentier, arriere = arriere})
    STATUT("« " + RECH.texte + " » trouvé ligne " + ed:curseur().ligne + ".")
  sinon
    STATUT("« " + RECH.texte + " » introuvable.")
  finsi
retourner

procedure CMD_DEFINITION(ev)
  ALLER_DEFINITION(ed:motcourant())
retourner

procedure ALLER_DEFINITION(mot)
  si mot = nul ou mot = ""
    retourner
  finsi
  STRUCT_RAFRAICHIR()
  pour chaque s dans STRUCT.symboles
    si minuscule(s.nom) = minuscule(mot)
      ed:aller(s.ligne, 1)
      STATUT(s.genre + " « " + s.nom + " » ligne " + s.ligne)
      retourner
    finsi
  suivant
  STATUT("Pas de définition de « " + mot + " » dans ce document.")
retourner

procedure CMD_DATE(ev)
  ed:inserer(date() + " " + heure())
retourner

procedure CMD_FORMATER(ev)
  locale lang = ed:langage()
  pour chaque x dans EXT_REG
    si x.genre = "formateur" et (x.langage = lang ou LISTE_CONTIENT(sisinon(type(x.langage) = "table", x.langage, {}), lang))
      locale t = appeler(x.procedure, ed:texte())
      si t <> nul
        ed:fixertexte(t)
        STATUT("Document formaté (" + x.nom + ").")
      finsi
      retourner
    finsi
  suivant
  STATUT("Aucun formateur pour le langage « " + TITRE_LANGAGE(lang) + " » (ajoutez-en un par extension).")
retourner

procedure CMD_STRUCTURE(ev)
  REG.structure = non panneau.visible
  panneau.visible = REG.structure
  si REG.structure
    STRUCT_DEMANDER(vrai)
  finsi
retourner

procedure CMD_VUE_GRAPHE(ev)
  panneau.visible = vrai
  REG.structure = vrai
  vues.valeur = 1
  REG.vue = "graphe"
  STRUCT_DEMANDER(vrai)
retourner

procedure CMD_VUE_PLAN(ev)
  panneau.visible = vrai
  REG.structure = vrai
  vues.valeur = 2
  REG.vue = "plan"
  STRUCT_DEMANDER(vrai)
retourner

procedure VUE_CHANGEE(ev)
  REG.vue = sisinon(vues.valeur = 2, "plan", "graphe")
retourner

procedure CMD_MINICARTE(ev)
  REG.minicarte = non REG.minicarte
  ed:minicarte(REG.minicarte)
retourner

procedure CMD_THEME(ev)
  REG.sombre = non REG.sombre
  fen:fixertheme("natif", REG.sombre, "compacte")
  COULEURS_THEME()
retourner

procedure CMD_PLUS_GRAND(ev)
  REG.police = min(40, REG.police + 1)
  ed:taillepolice(REG.police)
retourner

procedure CMD_PLUS_PETIT(ev)
  REG.police = max(8, REG.police - 1)
  ed:taillepolice(REG.police)
retourner

procedure CMD_POLICE_DEFAUT(ev)
  REG.police = 14
  ed:taillepolice(REG.police)
retourner

procedure CMD_PLEIN_ECRAN(ev)
  fen:pleinecran(fen.etatfenetre <> "pleinecran")
retourner

procedure CMD_ONGLET_SUIVANT(ev)
  locale docs = ed:documents()
  locale a = ed:actif()
  pour i = 1 a #docs
    si docs[i].uid = a
      ed:activer(docs[(i % #docs) + 1].uid)
      retourner
    finsi
  suivant
retourner

procedure CMD_LANGAGE(ev)
  locale items = {}
  pour chaque l dans TOUS_LANGAGES()
    inserer(items, {libelle = l.titre, detail = l.nom, valeur = l.nom})
  suivant
  QUICKPICK("Langage du document", items, @LANGAGE_CHOISI)
retourner

procedure LANGAGE_CHOISI(nom)
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    retourner
  finsi
  ed:langage(nom, uid)
  MAJ_ETAT()
  STRUCT_DEMANDER(vrai)
  STATUT("Langage : " + TITRE_LANGAGE(nom))
retourner

procedure CMD_LANGAGES(ev)
  locale n = car(10)
  locale t = "# Langages d'Ardoise" + n + n + "| Langage | Nom | Extensions |" + n + "|:--|:--|:--|" + n + ;
             "| Lexis+ | lexis | .prg |" + n + "| SQL | sql | .sql |" + n + "| Markdown | markdown | .md .markdown |" + n
  pour chaque l dans ui.langages()
    t = t + "| " + l.titre + " | " + l.nom + " | " + joindre(l.extensions, " ") + " |" + n
  suivant
  t = t + n + "Ajoutez un langage avec une extension (plugins/) : `ARDOISE_ENREGISTRER{genre = \"langage\", nom =, definition = {...}}`." + n
  DOC_INFO("Langages.md", t)
retourner

&& document d'information en lecture seule (aide, listes)
procedure DOC_INFO(titre, texte_)
  locale uid = ed:chercherdocument(titre)
  si uid = nul
    uid = ed:nouveau(titre)
    DOCS[chaine(uid)] = {chemin = "", genre = "info", fin_ligne = "LF", tabs = faux}
  finsi
  ed:langage("markdown", uid)
  ed:fixertexte(texte_, uid, vrai)
  ed:lecture(vrai, uid)
  ed:activer(uid)
  ed:aller(1, 1)
retourner

procedure CMD_QUITTER(ev)
  FERMETURE(nul)
  ui.quitter()
retourner

procedure CMD_AIDE(ev)
  locale n = car(10)
  locale t = "# Ardoise — aide" + n + n + ;
    "Ardoise n'a pas de menu : **F1** ou **Ctrl+Maj+P** ouvre la palette de commandes. " + ;
    "Tapez quelques lettres, puis Entrée." + n + n + ;
    "## Préfixes de la palette" + n + n + "| Préfixe | Rôle |" + n + "|:--|:--|" + n + ;
    "| `>` | commandes (les plus récentes d'abord) |" + n + "| *(aucun)* | fichiers récents et du dossier de travail (Ctrl+P) |" + n + ;
    "| `@` | symboles du document (Ctrl+Maj+O) |" + n + "| `:` | aller à la ligne : `:120`, `:50%`, `:#1048576` (octet) |" + n + ;
    "| `?` | rappel des préfixes |" + n + n + ;
    "## Raccourcis" + n + n + "| Touche | Action |" + n + "|:--|:--|" + n + ;
    "| Ctrl+N / Ctrl+O / Ctrl+S | nouveau, ouvrir, enregistrer |" + n + "| Ctrl+W | fermer l'onglet |" + n + ;
    "| Ctrl+Tab | onglet suivant |" + n + "| Ctrl+F / F3 / Maj+F3 | rechercher, suivant, précédent |" + n + ;
    "| Ctrl+K | remplacer |" + n + "| Ctrl+L | aller à la ligne |" + n + "| F12 | aller à la définition |" + n + ;
    "| Ctrl+B | commenter |" + n + "| Ctrl+D | dupliquer la ligne |" + n + "| Ctrl+Espace | complétion |" + n + ;
    "| Ctrl + / - / 0 | taille de la police |" + n + n + ;
    "## Structure" + n + n + "À gauche, le **graphe** montre les classes (avec leurs membres) et les routines du document, " + ;
    "reliées par leurs appels ; le **plan** les présente en arbre. Un clic amène le curseur sur le symbole. " + ;
    "Dans la marge de l'éditeur, le diagramme de structure trace les blocs (routines, conditions, boucles, essais)." + n + n + ;
    "## Grand fichier" + n + n + "Un fichier de plus de " + TAILLE_LISIBLE(REG.seuil_grand) + " (ou binaire) s'ouvre en **lecture par blocs** de " + ;
    TAILLE_LISIBLE(REG.bloc) + " : seul le bloc affiché est en mémoire, quelle que soit la taille du fichier (plusieurs dizaines de Go). " + ;
    "Descendez au-delà du bas du bloc (flèche, Page suivante, molette) pour enchaîner sur la suite, sans couture ; " + ;
    "la barre jaune donne la position, un curseur pour s'y rendre, *Aller…* (ligne, %, octet) et *Chercher…* dans tout le fichier. " + ;
    "Les lignes sont indexées en arrière-plan : la marge affiche alors les vrais numéros de ligne." + n + n + ;
    "## Extensions" + n + n + "Un fichier `.prg` placé dans `plugins/` (à côté d'Ardoise ou dans `~/.ardoise/plugins`) définit " + ;
    "`EXTENSION_<NOM>()`, qui appelle `ARDOISE_ENREGISTRER{genre = …}` : `commande`, `langage`, `structure`, `formateur`, " + ;
    "ou un événement (`surouverture`, `avantenregistrement`, `surenregistrement`, `surfermeture`)." + n + n + ;
    "Extensions chargées : " + sisinon(#EXTENSIONS = 0, "aucune", joindre(EXTENSIONS, ", ")) + "." + n
  DOC_INFO("Aide d'Ardoise.md", t)
retourner

procedure CMD_APROPOS(ev)
  ui.alerte("Ardoise " + VERSION + car(10) + "Éditeur multi-usage écrit en Lexis+." + car(10) + car(10) + ;
            #COMMANDES + " commandes · " + (#ui.langages() + 3) + " langages · " + #EXTENSIONS + " extension(s)" + car(10) + car(10) + ;
            "CC BY-NC-SA 4.0 — jean-marc « jihem » quere 2026", "information", "À propos d'Ardoise")
retourner
