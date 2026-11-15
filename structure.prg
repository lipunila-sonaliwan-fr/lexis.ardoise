&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Ardoise : structure du document, en plan (arbre) et en graphe (panneau latéral).
&&
&& Les blocs viennent de l'éditeur natif (ed:blocs : routines, sections, conditions…, calculés
&& d'après la définition du langage) ; Ardoise nomme les blocs « routine » et « section » d'après
&& leur ligne d'en-tête et les règles « symboles » du langage, puis ajoute les symboles qui ne
&& forment pas de bloc (titres Markdown, sections INI, cibles de Makefile, erreurs d'un journal…).
&& Le graphe montre les sections (avec leurs membres) et les routines, reliées par leurs appels.
&& Une extension peut fournir sa propre analyse : ARDOISE_ENREGISTRER{genre = "structure", langage =, procedure =}.

procedure STRUCT_DEMANDER(immediat)
  si immediat
    STRUCT.demande = horodatage() - 1
  sinon
    STRUCT.demande = horodatage()
  finsi
retourner

procedure STRUCT_VIDER
  STRUCT.uid = nul
  STRUCT.symboles = {}
  STRUCT.cle = ""
  graphe:vider()
  plan:vider()
  lblstruct.libelle = "STRUCTURE"
retourner

procedure STRUCT_RAFRAICHIR
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    STRUCT_VIDER()
    retourner
  finsi
  locale t0 = horodatage()
  locale syms = {}
  STRUCT.note = ""
  essayer
    syms = SYMBOLES(uid)
  capturer e
    STATUT("Structure : " + e)
  finessayer
  STRUCT.uid = uid
  STRUCT.symboles = syms
  && rien de changé (noms, lignes) : le graphe et le plan gardent leur état
  locale parts = {chaine(uid) + "|" + filtre.valeur + "|" + ed:premiereligne()}
  pour chaque s dans syms
    inserer(parts, s.nom + "@" + s.ligne)
  suivant
  locale cle = joindre(parts, ";")
  si cle == STRUCT.cle
    retourner
  finsi
  STRUCT.cle = cle
  si panneau.visible
    STRUCT_PLAN(syms)
    STRUCT_GRAPHE(syms)
  finsi
  lblstruct.libelle = "STRUCTURE · " + #syms + sisinon(STRUCT.note = "", "", "+")
  lblstruct.infobulle = #syms + " symbole(s)" + STRUCT.note
retourner

procedure STRUCT_FILTRER(ev)
  STRUCT.cle = ""
  STRUCT_DEMANDER(vrai)
retourner

fonction STRUCT_FILTRE_OK(s)
  locale f = NORMALISER(rogner(filtre.valeur))
retourner f = "" ou contient(NORMALISER(s.nom), f)

&&
&& Symboles : liste de {nom, genre, ligne, fin, niveau, parent (indice ou nul), routine (logique)}
&&

fonction SYMBOLES(uid)
  locale lang = ed:langage()
  locale lignes = decouper(ed:texte(uid), car(10))
  pour chaque x dans EXT_REG
    si x.genre = "structure" et x.langage = lang
      retourner NORMALISER_SYMBOLES(appeler(x.procedure, lignes, lang))
    finsi
  suivant
  faire cas
  cas lang = "markdown"
    retourner SYMBOLES_MARKDOWN(lignes)
  cas lang = "sql"
    retourner SYMBOLES_SQL(lignes)
  cas lang = "texte"
    retourner {}
  cas lang = "lexis"
    retourner SYMBOLES_BLOCS(uid, lignes, {{mot = "procedure", genre = "procédure"}, {mot = "fonction", genre = "fonction"}}, faux)
  fincas
  locale def = LANGAGES[lang]
  si def = nul
    retourner {}
  finsi
retourner SYMBOLES_BLOCS(uid, lignes, def.symboles, def.casse = faux)

&& complète une liste fournie par une extension (niveaux, parents, fins)
fonction NORMALISER_SYMBOLES(syms)
  si syms = nul
    retourner {}
  finsi
  locale pile = {}
  pour i = 1 a #syms
    locale s = syms[i]
    s.niveau = sisinon(s.niveau = nul, 0, s.niveau)
    s.fin = sisinon(s.fin = nul, s.ligne, s.fin)
    s.genre = sisinon(s.genre = nul, "symbole", s.genre)
    s.routine = sisinon(s.routine = nul, faux, s.routine)
    tantque #pile > 0 et syms[pile[#pile]].niveau >= s.niveau
      retirer(pile)
    fintantque
    s.parent = sisinon(#pile > 0, pile[#pile], nul)
    inserer(pile, i)
  suivant
retourner syms

&& blocs natifs (routines, sections) + règles du langage
fonction SYMBOLES_BLOCS(uid, lignes, regles, sanscasse)
  locale r = {}
  locale donnees = faux
  locale par_ligne = {}
  pour chaque rg dans regles
    si rg.clef ou rg.balise ou rg.selecteur
      donnees = vrai
    finsi
  suivant
  && 1. blocs du diagramme de structure
  pour chaque b dans ed:blocs(uid)
    locale garder = b.genre = "routine" ou b.genre = "section" ou (donnees et b.niveau <= 3)
    si garder et b.debut <= #lignes
      locale l = lignes[b.debut]
      locale x = NOM_SYMBOLE(l, regles, sanscasse, b.genre)
      && « typedef struct { … } Nom; » : le nom suit l'accolade fermante
      si x <> nul et b.genre = "section" et b.fin <= #lignes et LISTE_CONTIENT({"struct", "union", "enum", "class", "typedef", "{"}, x.nom)
        locale apres = MOTS(remplacertexte(lignes[b.fin], "}", " "))
        si #apres > 0
          x.nom = apres[1]
        finsi
      finsi
      si x <> nul
        inserer(r, {nom = x.nom, genre = x.genre, ligne = b.debut, fin = b.fin, niveau = b.niveau, ;
                    routine = b.genre = "routine" ou x.routine = vrai})
        par_ligne[chaine(b.debut)] = vrai
      finsi
    finsi
  suivant
  && 2. règles sans bloc : préfixes, mots, sections INI, cibles Makefile, mots-clés (journaux)
  locale lignealigne = faux
  pour chaque rg dans regles
    si rg.prefixe <> nul ou rg.motcle <> nul ou rg.section ou rg.cible ou (rg.mot <> nul et commencepar(rg.mot, "#")) ou rg.fleche ou rg.suffixe <> nul
      lignealigne = vrai
    finsi
  suivant
  si lignealigne
    locale nblocs = #r
    locale plafond = sisinon(GF[chaine(uid)] <> nul, 500, 3000)
    locale n = min(#lignes, 60000)
    pour i = 1 a n
      si par_ligne[chaine(i)] = nul
        locale l = lignes[i]
        locale x = SYMBOLE_LIGNE(l, regles)
        si x <> nul
          inserer(r, {nom = x.nom, genre = x.genre, ligne = i, fin = i, niveau = 0, routine = x.routine = vrai})
          si #r - nblocs >= plafond
            STRUCT.note = " (liste limitée à " + plafond + ")"
            sortir
          finsi
        finsi
      finsi
    suivant
    si nblocs > 0 et #r > nblocs
      trier(r, @PAR_LIGNE)
    finsi
  finsi
retourner NIVEAUX(r)

fonction PAR_LIGNE(a, b)
retourner a.ligne < b.ligne

&& parents d'après l'imbrication des lignes (un symbole contient ceux qui commencent dans son bloc)
fonction NIVEAUX(r)
  locale pile = {}
  pour i = 1 a #r
    locale s = r[i]
    tantque #pile > 0 et r[pile[#pile]].fin < s.ligne
      retirer(pile)
    fintantque
    s.parent = sisinon(#pile > 0, pile[#pile], nul)
    s.niveau = #pile
    si s.fin > s.ligne
      inserer(pile, i)
    finsi
  suivant
retourner r

&& mots d'une ligne (identificateurs) : la ponctuation devient des espaces
fonction MOTS(l)
  locale t = l
  pour chaque c dans {"(", ")", "{", "}", "[", "]", ":", ";", ",", "=", "<", ">", "*", "&", "\"", "'", "|", "!"}
    t = remplacertexte(t, c, " ")
  suivant
  locale r = {}
  pour chaque m dans decouper(rogner(t), " ")
    si m <> ""
      inserer(r, m)
    finsi
  suivant
retourner r

&& nom d'un bloc d'après sa ligne d'en-tête
fonction NOM_SYMBOLE(l, regles, sanscasse, genre_bloc)
  locale t = rogner(l)
  && règles « données » : clef JSON / YAML, balise, sélecteur CSS
  pour chaque rg dans regles
    faire cas
    cas rg.clef
      locale k = t
      si commencepar(k, "\"")
        locale p = position("\"", souschaine(k, 2))
        k = sisinon(p > 0, souschaine(k, 2, p - 1), k)
      sinonsi position(":", k) > 0
        k = rogner(gauche(k, position(":", k) - 1))
      sinon
        k = gauche(remplacertexte(remplacertexte(k, "{", ""), "[", ""), 30)
        si rogner(k) = ""
          k = "{…}"
        finsi
      finsi
      retourner {nom = k, genre = "clef"}
    cas rg.balise
      si commencepar(t, "<") et non commencepar(t, "</")
        locale ms = MOTS(souschaine(t, 2))
        locale nom_ = sisinon(#ms > 0, ms[1], "?")
        locale idp = position("id=\"", t)
        si idp > 0
          locale reste = souschaine(t, idp + 4)
          nom_ = nom_ + "#" + gauche(reste, position("\"", reste) - 1)
        finsi
        retourner {nom = "<" + nom_ + ">", genre = "balise"}
      finsi
      retourner nul
    cas rg.selecteur
      locale p = position("{", t)
      retourner {nom = rogner(sisinon(p > 0, gauche(t, p - 1), t)), genre = "sélecteur"}
    fincas
  suivant
  locale ms = MOTS(t)
  locale cles = ms
  si sanscasse
    cles = MOTS(minuscule(t))
  finsi
  pour chaque rg dans regles
    si rg.mot <> nul
      pour i = 1 a #cles - 1
        si cles[i] = rg.mot
          retourner {nom = NETTOYER_NOM(ms[i + 1]), genre = rg.genre, routine = non (rg.genre $ "classe structure interface module espace énumération trait implémentation type")}
        finsi
      suivant
    finsi
  suivant
  && sans mot-clé : identificateur qui précède « ( » (fonctions C, Java…)
  locale p = position("(", t)
  si p > 1
    locale av = MOTS(gauche(t, p - 1))
    si #av > 0
      locale nm = NETTOYER_NOM(av[#av])
      si non LISTE_CONTIENT({"if", "for", "while", "switch", "catch", "return", "sizeof", "foreach", "elif", "with"}, minuscule(nm))
        retourner {nom = nm, genre = sisinon(genre_bloc = "section", "section", "fonction")}
      finsi
    finsi
  finsi
  si genre_bloc = "section" et #ms > 1
    retourner {nom = NETTOYER_NOM(ms[2]), genre = "section"}
  finsi
retourner nul

fonction NETTOYER_NOM(n)
  locale r = n
  pour chaque c dans {".", "@", "$"}
    tantque commencepar(r, c)
      r = souschaine(r, 2)
    fintantque
  suivant
retourner r

&& symbole d'une ligne isolée (règles sans bloc)
fonction SYMBOLE_LIGNE(l, regles)
  pour chaque rg dans regles
    faire cas
    cas rg.prefixe <> nul
      si commencepar(l, rg.prefixe)
        retourner {nom = gauche(rogner(l), 70), genre = rg.genre}
      finsi
    cas rg.motcle <> nul
      si contient(l, rg.motcle)
        retourner {nom = gauche(rogner(l), 70), genre = rg.genre}
      finsi
    cas rg.section
      locale t = rogner(l)
      si commencepar(t, "[") et finitpar(t, "]")
        retourner {nom = t, genre = "section"}
      finsi
    cas rg.cible
      && « cible: dépendances » en début de ligne (Makefile), ou « FROM image » (Dockerfile)
      si l <> "" et non commencepar(l, " ") et non commencepar(l, car(9)) et non commencepar(l, "#") et non commencepar(l, ".")
        locale p = position(":", l)
        si p > 1 et non contient(gauche(l, p), "=") et souschaine(l, p + 1, 1) <> "="
          retourner {nom = gauche(l, p - 1), genre = "cible"}
        finsi
        si commencepar(majuscule(l), "FROM ")
          retourner {nom = l, genre = "étape"}
        finsi
      finsi
    cas rg.suffixe <> nul
      locale t = rogner(l)
      locale p = position(rg.suffixe, t)
      si p > 1 et non contient(gauche(t, p - 1), " ")
        retourner {nom = gauche(t, p - 1), genre = rg.genre, routine = vrai}
      finsi
    cas rg.fleche
      && « [export] const nom = (…) => » ou « … = async (…) => » ou « … = function », et R : « nom <- function(…) »
      locale t = rogner(l)
      si commencepar(t, "export ")
        t = rogner(souschaine(t, 8))
      finsi
      locale p = position("<- function", t)
      si p > 1
        retourner {nom = rogner(gauche(t, p - 1)), genre = "fonction", routine = vrai}
      finsi
      si commencepar(t, "const ") ou commencepar(t, "let ")
        p = position("=", t)
        si p > 0
          locale apres = rognerg(souschaine(t, p + 1))
          si (commencepar(apres, "(") et contient(apres, "=>")) ou commencepar(apres, "async ") ou commencepar(apres, "function")
            locale ms = MOTS(gauche(t, p - 1))
            si #ms >= 2
              retourner {nom = ms[2], genre = "fonction", routine = vrai}
            finsi
          finsi
        finsi
      finsi
    cas rg.mot <> nul et commencepar(rg.mot, "#")
      locale t = rogner(l)
      si commencepar(t, rg.mot + " ")
        locale ms = MOTS(souschaine(t, #rg.mot + 1))
        si #ms > 0
          retourner {nom = ms[1], genre = rg.genre}
        finsi
      finsi
    fincas
  suivant
retourner nul

fonction SYMBOLES_MARKDOWN(lignes)
  locale r = {}
  locale code = faux
  pour i = 1 a #lignes
    locale l = lignes[i]
    si commencepar(l, "```") ou commencepar(l, "~~~")
      code = non code
    sinonsi non code et commencepar(l, "#")
      locale n = 0
      tantque souschaine(l, n + 1, 1) = "#"
        n += 1
      fintantque
      si n <= 6 et souschaine(l, n + 1, 1) = " "
        inserer(r, {nom = rogner(souschaine(l, n + 1)), genre = "titre", ligne = i, fin = #lignes, niveau = n - 1, hn = n, routine = faux})
      finsi
    finsi
  suivant
  && fin d'une section : avant le titre suivant de même niveau ou de niveau supérieur
  pour i = 1 a #r
    pour j = i + 1 a #r
      si r[j].hn <= r[i].hn
        r[i].fin = r[j].ligne - 1
        sortir
      finsi
    suivant
  suivant
retourner NIVEAUX(r)

fonction SYMBOLES_SQL(lignes)
  locale r = {}
  pour i = 1 a #lignes
    locale t = minuscule(rogner(lignes[i]))
    si commencepar(t, "create ") ou commencepar(t, "alter ") ou commencepar(t, "with ")
      locale ms = MOTS(rogner(lignes[i]))
      locale msm = MOTS(t)
      locale genre_ = ""
      locale nom_ = ""
      pour j = 2 a #msm - 1
        si LISTE_CONTIENT({"table", "view", "function", "procedure", "proc", "trigger", "index", "macro", "schema", "sequence", "type"}, msm[j])
          genre_ = msm[j]
          nom_ = ms[j + 1]
          si minuscule(nom_) = "if" et j + 3 <= #ms
            nom_ = ms[j + 3]
          finsi
          sortir
        finsi
      suivant
      si genre_ <> ""
        inserer(r, {nom = nom_, genre = genre_, ligne = i, fin = i, niveau = 0, routine = genre_ $ "function procedure proc macro"})
      finsi
    finsi
  suivant
  && fin : jusqu'à l'instruction suivante
  pour i = 1 a #r
    r[i].fin = sisinon(i < #r, r[min(#r, i + 1)].ligne - 1, #lignes)
  suivant
retourner r

&&
&& Plan (arbre)
&&

procedure STRUCT_PLAN(syms)
  PLAN_LIGNES = {}
  plan:vider()
  locale chemins = {}
  locale nplan = 0
  pour i = 1 a #syms
    locale s = syms[i]
    && le séparateur des chemins de l'arbre ne doit pas apparaître dans un libellé
    locale etiquette = ICONE_SYMBOLE(s.genre) + " " + remplacertexte(remplacertexte(s.nom, ui.sep, "∕"), "/", "∕") + "   :" + s.ligne
    locale ch = etiquette
    si s.parent <> nul et chemins[s.parent] <> nul
      ch = chemins[s.parent] + ui.sep + etiquette
    finsi
    chemins[i] = ch
    si STRUCT_FILTRE_OK(s) et nplan < 800
      plan:ajouter(ch)
      PLAN_LIGNES[ch] = s.ligne
      nplan += 1
    finsi
  suivant
  si nplan >= 800
    plan:ajouter("… (filtrez pour voir les autres symboles)")
  finsi
  pour i = 1 a min(#syms, 400)
    si syms[i].niveau <= 1 et chemins[i] <> nul
      plan:deplier(chemins[i])
    finsi
  suivant
retourner

procedure PLAN_CHOIX(ev)
  si ev.texte = nul
    retourner
  finsi
  locale l = PLAN_LIGNES[ev.texte]
  si l <> nul
    ed:aller(l, 1)
    ed:focus()
  finsi
retourner

&&
&& Graphe : sections avec leurs membres, routines, appels entre routines
&&

fonction COULEUR_GENRE(g)
  faire cas
  cas g = "classe" ou g = "structure" ou g = "interface" ou g = "trait" ou g = "énumération" ou g = "type"
    retourner "#8B5CF6"
  cas g = "module" ou g = "espace" ou g = "implémentation" ou g = "section"
    retourner "#0EA5E9"
  cas g = "titre"
    retourner "#10B981"
  cas g = "erreur"
    retourner "#EF4444"
  cas g = "clef" ou g = "balise" ou g = "sélecteur" ou g = "cible" ou g = "étape"
    retourner "#F59E0B"
  fincas
retourner "#3B82F6"

procedure STRUCT_GRAPHE(syms)
  graphe:vider()
  NOEUDS = {}                 && id -> {ligne, lignes = {lignes des rangées}}
  locale place = {}           && indice du symbole -> {id, rangee}
  && racines : symboles sans parent ; si trop peu, on descend d'un niveau
  locale racines = {}
  locale enfants_de = {}
  pour i = 1 a #syms
    locale p = syms[i].parent
    si p = nul
      inserer(racines, i)
    sinon
      si enfants_de[p] = nul
        enfants_de[p] = {}
      finsi
      inserer(enfants_de[p], i)
    finsi
  suivant
  locale haut = nul
  si #racines <= 2
    locale enfants = {}
    pour chaque ri dans racines
      pour chaque j dans sisinon(enfants_de[ri] = nul, {}, enfants_de[ri])
        inserer(enfants, j)
      suivant
    suivant
    si #enfants > 0
      haut = racines
      racines = enfants
    finsi
  finsi
  locale maxn = 120
  locale nb = 0
  si haut <> nul
    pour chaque hi dans haut
      locale s = syms[hi]
      graphe:noeud{id = "N" + hi, titre = ICONE_SYMBOLE(s.genre) + " " + s.nom, soustitre = s.genre + " · ligne " + s.ligne, ;
                   lignes = {}, couleur = COULEUR_GENRE(s.genre)}
      NOEUDS["N" + hi] = {ligne = s.ligne, lignes = {}}
      place[hi] = {id = "N" + hi, rangee = 0}
    suivant
  finsi
  pour chaque ri dans racines
    locale s = syms[ri]
    si STRUCT_FILTRE_OK(s) ou haut <> nul
      nb += 1
      si nb > maxn
        sortir
      finsi
      locale lignes = {}
      locale nl = {}
      pour chaque j dans sisinon(enfants_de[ri] = nul, {}, enfants_de[ri])
        si vrai
          si #lignes < 24
            inserer(lignes, {texte = ICONE_SYMBOLE(syms[j].genre) + " " + syms[j].nom, detail = ":" + syms[j].ligne})
            inserer(nl, syms[j].ligne)
            place[j] = {id = "N" + ri, rangee = #lignes}
          sinon
            place[j] = {id = "N" + ri, rangee = 0}
          finsi
        finsi
      suivant
      locale id = "N" + ri
      graphe:noeud{id = id, titre = ICONE_SYMBOLE(s.genre) + " " + s.nom, ;
                   soustitre = s.genre + " · lignes " + (s.ligne + ed:premiereligne() - 1) + "–" + (s.fin + ed:premiereligne() - 1), ;
                   lignes = lignes, couleur = COULEUR_GENRE(s.genre)}
      NOEUDS[id] = {ligne = s.ligne, lignes = nl}
      place[ri] = {id = id, rangee = 0}
      si haut <> nul et s.parent <> nul et place[s.parent] <> nul
        graphe:lien{de = place[s.parent].id, a = id, couleur = "#64748B", pointille = vrai}
      finsi
    finsi
  suivant
  GRAPHE_APPELS(syms, place)
  graphe:disposer("bas")
  graphe:ajuster(70)
  si nb > maxn
    STRUCT.note = STRUCT.note + " · graphe : " + maxn + " premiers"
  finsi
retourner

&& appels : une routine qui contient « nom( » d'une autre routine
procedure GRAPHE_APPELS(syms, place)
  locale routines = {}
  pour i = 1 a #syms
    si syms[i].routine et place[i] <> nul et #syms[i].nom >= 2
      inserer(routines, i)
    finsi
  suivant
  si #routines < 2 ou #routines > 250
    retourner
  finsi
  locale lignes = decouper(ed:texte(STRUCT.uid), car(10))
  locale sanscasse = ed:langage() = "lexis" ou ed:langage() = "basic" ou ed:langage() = "pascal"
  locale vus = {}
  locale nliens = 0
  pour chaque i dans routines
    locale s = syms[i]
    locale corps = joindre(TRANCHE(lignes, s.ligne + 1, min(s.fin, s.ligne + 3000)), car(10))
    si sanscasse
      corps = minuscule(corps)
    finsi
    pour chaque j dans routines
      si j <> i
        locale n = sisinon(sanscasse, minuscule(syms[j].nom), syms[j].nom)
        si contient(corps, n + "(") ou contient(corps, n + " (") ou contient(corps, "@" + n)
          locale a = place[i]
          locale b = place[j]
          locale k = a.id + "/" + a.rangee + ">" + b.id + "/" + b.rangee
          si vus[k] = nul et (a.id <> b.id ou a.rangee <> b.rangee)
            vus[k] = vrai
            graphe:lien{de = a.id, a = b.id, deligne = a.rangee, aligne = b.rangee, fleche = vrai, couleur = "#94A3B8"}
            nliens += 1
            si nliens > 400
              retourner
            finsi
          finsi
        finsi
      finsi
    suivant
  suivant
retourner

fonction TRANCHE(l, a, b)
  locale r = {}
  pour i = a a b
    si i >= 1 et i <= #l
      inserer(r, l[i])
    finsi
  suivant
retourner r

procedure GRAPHE_CHOIX(ev)
  locale n = NOEUDS[ev.texte]
  si n = nul
    retourner
  finsi
  locale l = n.ligne
  si ev.index <> nul et ev.index >= 1 et ev.index <= #n.lignes
    l = n.lignes[ev.index]
  finsi
  ed:aller(l, 1)
  ed:focus()
retourner

&& curseur dans un symbole : on le montre dans le graphe
procedure STRUCT_SUIVRE_CURSEUR(ligne)
  si non panneau.visible ou STRUCT.uid <> ed:actif() ou NOEUDS = nul
    retourner
  finsi
  locale meilleur = nul
  pour i = 1 a #STRUCT.symboles
    locale s = STRUCT.symboles[i]
    si s.ligne <= ligne et s.fin >= ligne
      meilleur = i
    finsi
  suivant
  si meilleur = STRUCT.courant
    retourner
  finsi
  STRUCT.courant = meilleur
  si meilleur = nul
    retourner
  finsi
  && nœud du symbole ou de son ancêtre le plus proche
  locale i = meilleur
  tantque i <> nul
    si NOEUDS["N" + i] <> nul
      locale rangee = 0
      locale n = NOEUDS["N" + i]
      pour k = 1 a #n.lignes
        si n.lignes[k] = STRUCT.symboles[meilleur].ligne
          rangee = k
        finsi
      suivant
      essayer
        graphe:selectionner("N" + i, rangee)
      capturer e
      finessayer
      retourner
    finsi
    i = STRUCT.symboles[i].parent
  fintantque
retourner
