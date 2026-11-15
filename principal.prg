&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Ardoise : éditeur de texte et de code multi-usage, écrit en Lexis+.
&&
&& Pas de menu : tout passe par la palette de commandes (F1 ou Ctrl+Maj+P), que les extensions
&& (plugins/*.prg) enrichissent. Onglets, coloration de nombreux langages, diagramme de structure
&& dans la marge, minicarte, plan et graphe latéral de structure, et un mode « grand fichier »
&& qui consulte des fichiers de plusieurs dizaines de gigaoctets bloc par bloc.
&&
&&   principal.prg     fenêtre, disposition, barre d'état, signaux de l'éditeur, session
&&   commandes.prg     registre des commandes, palette (> commandes, @ symboles, : ligne, fichiers)
&&   fichiers.prg      ouvrir, enregistrer, fermer, récents, fins de ligne et tabulations
&&   langages.prg      langages livrés (ui.definirlangage) et règles des symboles
&&   structure.prg     symboles du document : plan (arbre) et graphe (appels entre routines)
&&   grandfichier.prg  mode grand fichier : blocs, index des lignes, recherche dans tout le fichier
&&   extensions.prg    chargement des extensions et API offerte aux extensions
&&
&& Lancement : wdlexisrt exemples/ardoise/principal.prg [fichier ...]

ui = paquet("interface")
VERSION = "1.0.1"

REG = LIRE_REGLAGES()
COMMANDES = {}
DOCS = {}                 && par uid (texte) : {chemin, genre = "texte" | "grand", fin_ligne, tabs}
FERMES = {}               && onglets fermés (rouvrir)
LANGAGES = {}
EXTENSIONS = {}
EXT_REG = {}
STRUCT = {demande = nul, uid = nul, symboles = {}, cle = ""}
GF = {}                   && état des documents en mode grand fichier, par uid
FICHIERS_DOSSIER = nul    && cache de l'ouverture rapide

fen = ui.fenetre{titre = "Ardoise", largeur = 1440, hauteur = 900, disposition = "bordure", ;
                 sombre = REG.sombre, densite = "compacte", etat = sisinon(REG.agrandie, "agrandie", "normale")}
fen.marge = 0
fen.espacement = 0
fen.surtouchebas = @TOUCHE
fen.surfermeture = @FERMETURE

&& barre du mode grand fichier (visible quand l'onglet actif en est un)
barregf = fen:ajouter(ui.rangee())
barregf.ancrage = "haut"
barregf.marge = 4
barregf.espacement = 4
barregf.fond = "#3B2F0B"
barregf.visible = faux
gf_titre = barregf:ajouter(ui.etiquette(""))
gf_titre.couleur = "#FCD34D"
gf_titre.largeurfixe = 300
BOUTON_GF("⏮", "Début du fichier", @GF_DEBUT)
BOUTON_GF("◀", "Bloc précédent (ou flèche haut / molette en haut du bloc)", @GF_PRECEDENT)
BOUTON_GF("▶", "Bloc suivant (ou flèche bas / molette en bas du bloc)", @GF_SUIVANT)
BOUTON_GF("⏭", "Fin du fichier", @GF_FIN)
gf_curseur = barregf:ajouter(ui.curseur())
gf_curseur.min = 0
gf_curseur.max = 1000
gf_curseur.poids = 1
gf_curseur.infobulle = "Position dans le fichier : glissez pour y aller"
gf_curseur.surchangement = @GF_CURSEUR
gf_pos = barregf:ajouter(ui.etiquette(""))
gf_pos.couleur = "#FDE68A"
gf_pos.largeurfixe = 270
BOUTON_GF("Aller…", "Aller à une ligne, une position (%) ou un octet", @GF_ALLER)
BOUTON_GF("Chercher…", "Rechercher dans tout le fichier", @GF_RECHERCHER)
gf_suivre = BOUTON_GF("Suivre", "Suivre la fin du fichier pendant qu'il grandit (journaux)", @GF_BASCULER_SUIVI)

&& barre d'état
pied = fen:ajouter(ui.rangee())
pied.ancrage = "bas"
pied.marge = 2
pied.espacement = 14
pied.hauteurfixe = 22
lblmsg = pied:ajouter(ui.etiquette("Prêt — F1 ou Ctrl+Maj+P : palette de commandes"))
lblmsg.poids = 1
lblmsg.couleur = "#94A3B8"
lblgf = pied:ajouter(ui.etiquette(""))
lblgf.couleur = "#FBBF24"
lbllang = pied:ajouter(ui.etiquette(""))
lbllang.couleur = "#93C5FD"
lbllang.infobulle = "Langage du document (clic : changer)"
lbllang.surclic = @CMD_LANGAGE
lbleol = pied:ajouter(ui.etiquette(""))
lbleol.couleur = "#94A3B8"
lblpos = pied:ajouter(ui.etiquette(""))
lblpos.couleur = "#CBD5E1"
lblpos.largeurfixe = 150
lblaide = pied:ajouter(ui.etiquette("F1 ▸ commandes"))
lblaide.couleur = "#64748B"
lblaide.infobulle = "Palette de commandes (F1, Ctrl+Maj+P)"
lblaide.surclic = @PALETTE

&& structure (plan et graphe) | éditeur
sep = fen:ajouter(ui.separateur{vertical = vrai, position = REG.sep})
sep.ancrage = "centre"
panneau = sep:ajouter(ui.colonne())
panneau.marge = 0
panneau.espacement = 0
tetestruct = panneau:ajouter(ui.rangee())
tetestruct.marge = 4
tetestruct.espacement = 4
lblstruct = tetestruct:ajouter(ui.etiquette("STRUCTURE"))
lblstruct.couleur = "#94A3B8"
lblstruct.poids = 1
filtre = tetestruct:ajouter(ui.saisie{indication = "filtrer"})
filtre.largeurfixe = 120
filtre.surchangement = @STRUCT_FILTRER
vues = panneau:ajouter(ui.onglets())
vues.poids = 1
pgraphe = vues:ajouterpage("Graphe", "bordure")
pplan = vues:ajouterpage("Plan", "bordure")
graphe = pgraphe:ajouter(ui.diagramme{modifiable = faux, direction = "bas"})
graphe.ancrage = "centre"
graphe.surselection = @GRAPHE_CHOIX
plan = pplan:ajouter(ui.arbre())
plan.ancrage = "centre"
plan.surselection = @PLAN_CHOIX
si REG.vue = "plan"
  vues.valeur = 2
finsi
vues.surchangement = @VUE_CHANGEE
panneau.visible = REG.structure

ed = sep:ajouter(ui.editeur{minicarte = REG.minicarte, taille = REG.police, numeros = "simples", raccourcis = "palette"})
ed.surselection = @SIGNAL
ed.surchangement = @CHANGEMENT
ed:accueil({"Ardoise", "Aucun document ouvert", "", "F1  ou  Ctrl+Maj+P   palette de commandes", ;
            "Ctrl+P   ouvrir rapidement un fichier", "Ctrl+N   nouveau document", "Ctrl+O   ouvrir un fichier", "", ;
            "Les fichiers très volumineux s'ouvrent en mode « grand fichier »", "(consultation par blocs, sans limite de taille)"})

COULEURS_THEME()
DEFINIR_LANGAGES()
ENREGISTRER_COMMANDES()
CHARGER_EXTENSIONS()
ed:analyser()

&& fichiers passés en argument, sinon la session précédente
locale args = systeme.args
locale ouverts = 0
pour i = 1 a #args
  si args[i] <> nul et args[i] <> "" et fichier.existe(args[i]) et fichier.estfichier(args[i])
    OUVRIR_FICHIER(fichier.absolu(args[i]))
    ouverts += 1
  finsi
suivant
si ouverts = 0
  RESTAURER_SESSION()
finsi
ui.minuterie(200, @HORLOGE, vrai)
ed:focus()
ui.executer()

&&
&& Réglages
&&

fonction DOSSIER_ARDOISE()
  locale d = fichier.joindre(fichier.dossierperso(), ".ardoise")
  si non fichier.existe(d)
    essayer
      fichier.creerdossier(d)
    capturer e
    finessayer
  finsi
retourner d

fonction LIRE_REGLAGES()
  locale r = {sombre = vrai, police = 14, minicarte = vrai, structure = vrai, sep = 0.22, vue = "graphe", ;
              agrandie = faux, recents = {}, cmds_recentes = {}, session = {}, dossier = "", ;
              seuil_grand = 64 * 1024 * 1024, bloc = 4 * 1024 * 1024, coupe = 20000, actif = ""}
  locale p = fichier.joindre(DOSSIER_ARDOISE(), "reglages.json")
  si fichier.existe(p)
    essayer
      pour chaque k, v dans dejson(fichier.lire(p))
        r[majuscule(k)] = v
      suivant
    capturer e
    finessayer
  finsi
  si r.dossier = nul ou r.dossier = ""
    r.dossier = fichier.courant()
  finsi
retourner r

procedure ECRIRE_REGLAGES
  essayer
    fichier.ecrire(fichier.joindre(DOSSIER_ARDOISE(), "reglages.json"), json(REG))
  capturer e
  finessayer
retourner

&&
&& Barre d'état
&&

procedure STATUT(m)
  lblmsg.libelle = m
retourner

procedure MAJ_ETAT
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    lbllang.libelle = ""
    lbleol.libelle = ""
    lblpos.libelle = ""
    lblgf.libelle = ""
    barregf.visible = faux
    fen.titre = "Ardoise"
    retourner
  finsi
  locale d = DOCS[chaine(uid)]
  lbllang.libelle = TITRE_LANGAGE(ed:langage())
  locale info = {}
  si d <> nul
    inserer(info, sisinon(d.fin_ligne = nul, "LF", d.fin_ligne))
    si d.tabs
      inserer(info, "Tab")
    finsi
    si ed:lecture(uid)
      inserer(info, "lecture seule")
    finsi
  finsi
  lbleol.libelle = joindre(info, " · ")
  fen.titre = "Ardoise — " + ed:titre(nul, uid) + sisinon(ed:chemin(uid) = "", "", "  (" + fichier.dossier(ed:chemin(uid)) + ")")
  barregf.visible = GF[chaine(uid)] <> nul
  si GF[chaine(uid)] <> nul
    GF_MAJ_BARRE(uid)
  sinon
    lblgf.libelle = ""
  finsi
retourner

&&
&& Signaux de l'éditeur
&&

procedure SIGNAL(ev)
  locale s = ev.texte
  si s = nul
    retourner
  finsi
  faire cas
  cas commencepar(s, "pos:")
    locale p = decouper(souschaine(s, 5), ":")
    locale uid = ed:actif()
    locale n = nombre(p[1])
    si GF[chaine(uid)] <> nul
      lblpos.libelle = "Ln " + FORMAT_NOMBRE(n + ed:premiereligne() - 1) + ", Col " + p[2]
    sinon
      lblpos.libelle = "Ln " + p[1] + ", Col " + p[2]
    finsi
    STRUCT_SUIVRE_CURSEUR(n)
  cas commencepar(s, "doc:")
    MAJ_ETAT()
    STRUCT_DEMANDER(vrai)
  cas commencepar(s, "cmd:close:")
    FERMER_DOC(nombre(souschaine(s, 11)))
  cas s = "cmd:edge:next"
    GF_GLISSER(ed:actif(), 1)
  cas s = "cmd:edge:prev"
    GF_GLISSER(ed:actif(), -1)
  cas commencepar(s, "cmd:definition:")
    ALLER_DEFINITION(souschaine(s, 16))
  cas commencepar(s, "cmd:")
    RACCOURCI(souschaine(s, 5))
  fincas
retourner

&& raccourcis de l'éditeur -> commandes du registre
procedure RACCOURCI(nom)
  locale t = {save = "fichier.enregistrer", saveas = "fichier.enregistrersous", new = "fichier.nouveau", ;
              open = "fichier.ouvrir", find = "edition.rechercher", findnext = "edition.suivant", ;
              findprev = "edition.precedent", goto = "edition.aller", replace = "edition.remplacer", ;
              fontbigger = "affichage.plusgrand", fontsmaller = "affichage.pluspetit", fontreset = "affichage.policedefaut", ;
              palette = "palette.commandes", quickopen = "palette.fichiers", closetab = "fichier.fermer", ;
              symbols = "palette.symboles", run = "palette.commandes"}
  locale id = t[majuscule(nom)]
  si id <> nul
    EXECUTER(id)
  finsi
retourner

procedure CHANGEMENT(ev)
  STRUCT_DEMANDER(faux)
retourner

&& raccourcis quand le focus n'est pas dans l'éditeur (structure, barre…)
fonction MODS(ev)
  locale m = sisinon(ev.modificateurs = nul, 0, ev.modificateurs)
retourner {cmd = (m % 256) >= 64 ou (m % 2048) >= 1024, maj = (m % 4) >= 1, alt = (m % 1024) >= 256}

procedure TOUCHE(ev)
  && l'éditeur a déjà traduit ses raccourcis en signaux (SIGNAL) : rien à refaire ici
  si ev.id = ed
    retourner
  finsi
  locale m = MODS(ev)
  locale t = ev.touche
  si t = 1073741882
    PALETTE(nul)
    retourner
  finsi
  si t = 27
    GF_ARRETER_RECHERCHE(nul)
    retourner
  finsi
  si non m.cmd
    retourner
  finsi
  faire cas
  cas t = 112 et m.maj
    PALETTE(nul)
  cas t = 112
    PALETTE_FICHIERS(nul)
  cas t = 111
    CMD_OUVRIR(nul)
  cas t = 110
    CMD_NOUVEAU(nul)
  cas t = 115
    CMD_ENREGISTRER(nul)
  cas t = 119
    CMD_FERMER(nul)
  fincas
retourner

&&
&& Minuterie : structure différée, index des grands fichiers, recherche, suivi de la fin
&&

procedure HORLOGE(ev)
  si STRUCT.demande <> nul et horodatage() - STRUCT.demande > 0.45
    STRUCT.demande = nul
    STRUCT_RAFRAICHIR()
  finsi
  GF_TICK()
retourner

procedure FERMETURE(ev)
  locale modifies = {}
  pour chaque d dans ed:documents()
    si d.modifie
      inserer(modifies, d)
    finsi
  suivant
  si #modifies > 0
    locale noms = {}
    pour chaque d dans modifies
      inserer(noms, "  • " + d.titre)
    suivant
    si ui.confirmer(#modifies + " document(s) modifié(s) :" + car(10) + joindre(noms, car(10)) + car(10) + car(10) + ;
                    "Les enregistrer avant de quitter ?", "question")
      pour chaque d dans modifies
        essayer
          ENREGISTRER_DOC(d.uid, nul)
        capturer e
        finessayer
      suivant
    finsi
  finsi
  MEMORISER_SESSION()
  si sep.position <> nul
    REG.sep = sep.position
  finsi
  REG.agrandie = fen.etatfenetre = "agrandie"
  ECRIRE_REGLAGES()
retourner

&&
&& Outils
&&

fonction BOUTON_GF(libelle, aide, proc)
  locale b = barregf:ajouter(ui.bouton(libelle, {plat = vrai}))
  b.infobulle = aide
  b.surclic = proc
retourner b

fonction FORMAT_NOMBRE(n)
  si n = nul
    retourner "?"
  finsi
  locale s = chaine(entier(n))
  locale r = ""
  locale neg = commencepar(s, "-")
  si neg
    s = souschaine(s, 2)
  finsi
  tantque #s > 3
    r = " " + droite(s, 3) + r
    s = gauche(s, #s - 3)
  fintantque
retourner sisinon(neg, "-", "") + s + r

fonction TAILLE_LISIBLE(o)
  faire cas
  cas o < 1024
    retourner entier(o) + " o"
  cas o < 1024 * 1024
    retourner remplacertexte(chaine(o / 1024, 1, 1), ".", ",") + " Ko"
  cas o < 1024 * 1024 * 1024
    retourner remplacertexte(chaine(o / 1048576, 1, 1), ".", ",") + " Mo"
  fincas
retourner remplacertexte(chaine(o / 1073741824, 1, 2), ".", ",") + " Go"

fonction LISTE_CONTIENT(l, v)
  pour chaque x dans l
    si x == v
      retourner vrai
    finsi
  suivant
retourner faux

&& minuscules sans accents : la palette trouve « Thème » en tapant « theme »
fonction NORMALISER(s)
  locale r = minuscule(s)
  pour chaque p dans {{"é", "e"}, {"è", "e"}, {"ê", "e"}, {"ë", "e"}, {"à", "a"}, {"â", "a"}, {"ä", "a"}, ;
                     {"î", "i"}, {"ï", "i"}, {"ô", "o"}, {"ö", "o"}, {"ù", "u"}, {"û", "u"}, {"ü", "u"}, ;
                     {"ç", "c"}, {"œ", "oe"}, {"æ", "ae"}, {"’", "'"}}
    si p[1] $ r
      r = remplacertexte(r, p[1], p[2])
    finsi
  suivant
retourner r

&& couleurs des libellés selon le thème (clair ou sombre)
procedure COULEURS_THEME
  locale sombre = REG.sombre
  lblmsg.couleur = sisinon(sombre, "#94A3B8", "#475569")
  lblgf.couleur = sisinon(sombre, "#FBBF24", "#B45309")
  lbllang.couleur = sisinon(sombre, "#93C5FD", "#1D4ED8")
  lbleol.couleur = sisinon(sombre, "#94A3B8", "#475569")
  lblpos.couleur = sisinon(sombre, "#CBD5E1", "#1E293B")
  lblaide.couleur = sisinon(sombre, "#64748B", "#64748B")
  lblstruct.couleur = sisinon(sombre, "#94A3B8", "#475569")
retourner
