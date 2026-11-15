&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Ardoise : mode « grand fichier » (consultation de fichiers de plusieurs dizaines de Go).
&&
&& Seul un bloc du fichier (4 Mo par défaut) est chargé dans un onglet en lecture seule ; le bloc
&& commence et finit sur des débuts de ligne (fichier.lirebloc). Quand on cherche à dépasser le
&& bas ou le haut du bloc (flèches, Page suivante, molette), l'éditeur envoie « cmd:edge:next » ou
&& « cmd:edge:prev » : Ardoise fait glisser la fenêtre d'un demi-bloc et garde la vue en place,
&& si bien que l'on parcourt le fichier sans couture.
&&
&& En arrière-plan (minuterie, budget de temps par tour) :
&& * l'index des lignes compte les fins de ligne par tranches de 64 Mo (fichier.compterlignes) :
&&   la marge affiche les vrais numéros de ligne et « Aller à la ligne » part de la tranche voisine ;
&& * la recherche dans tout le fichier progresse par 256 Mo (fichier.rechercher, limite) ;
&& * le suivi de la fin relit le dernier bloc quand le fichier grandit (journaux).

procedure GF_OUVRIR(chemin, raison)
  chemin = fichier.absolu(chemin)
  locale existant = GF_PAR_CHEMIN(chemin)
  si existant <> nul
    ed:activer(existant.uid)
    retourner
  finsi
  locale uid = ed:nouveau(fichier.nom(chemin))
  locale lang = ui.langagede(chemin)
  locale ext = minuscule(fichier.extension(chemin))
  si raison = "binaire"
    lang = "texte"
  sinonsi lang = nul
    lang = sisinon(ext = ".prg" ou ext = "prg", "lexis", sisinon(ext = ".sql" ou ext = "sql", "sql", ;
           sisinon(ext = ".md" ou ext = "md", "markdown", "texte")))
  finsi
  ed:langage(lang, uid)
  ed:lecture(vrai, uid, vrai)
  ed:pastille(sisinon(raison = "binaire", "BINAIRE", "GRAND"), uid, sisinon(raison = "binaire", "#7C3AED", "#D97706"))
  locale debut_ = fichier.lirebloc(chemin, 0, 65536, {lignes = faux})
  DOCS[chaine(uid)] = {chemin = chemin, genre = "grand", fin_ligne = sisinon(contient(debut_.texte, car(13) + car(10)), "CRLF", "LF"), tabs = faux}
  GF[chaine(uid)] = {uid = uid, chemin = chemin, taille = fichier.taille(chemin), debut = 0, fin = 0, lignes = 0, ;
                     ligne0 = 1, repere = {pos = 0, ligne = 1}, raison = raison, coupees = 0, suivre = faux, ;
                     index = {pas = 64 * 1024 * 1024, cumul = {0}, pos = 0, actif = vrai, fini = faux}, ;
                     rech = nul, curseur_demande = nul, derniere_valeur = -1, maj = 0}
  GF_CHARGER(uid, 0, nul)
  ed:aller(1, 1)
  STATUT(sisinon(raison = "binaire", "Fichier binaire : lecture seule, octets non UTF-8 remplacés par �.", ;
         "Grand fichier : lecture par blocs de " + TAILLE_LISIBLE(REG.bloc) + " — descendez au-delà du bloc pour enchaîner."))
  MAJ_ETAT()
retourner

fonction GF_PAR_CHEMIN(chemin)
  pour chaque k, g dans GF
    si g.chemin = chemin
      retourner g
    finsi
  suivant
retourner nul

fonction GF_ACTIF()
  locale uid = ed:actif()
  si uid = nul ou uid < 0
    retourner nul
  finsi
retourner GF[chaine(uid)]

&& charge le bloc qui commence à pos (aligné sur un début de ligne, sauf brut = vrai)
procedure GF_CHARGER(uid, pos, brut)
  locale g = GF[chaine(uid)]
  si g = nul
    retourner
  finsi
  locale b = fichier.lirebloc(g.chemin, max(0, pos), REG.bloc, {coupe = REG.coupe, lignes = non brut})
  ed:fixertexte(b.texte, uid, vrai)
  g.debut = b.debut
  g.fin = b.fin
  g.lignes = b.lignes
  g.taille = b.taille
  g.coupees = b.coupees
  g.ligne0 = GF_LIGNE_DE(g, b.debut)
  si g.ligne0 <> nul
    g.repere = {pos = b.debut, ligne = g.ligne0}
  finsi
  ed:premiereligne(sisinon(g.ligne0 = nul, 1, g.ligne0), uid)
  si uid = ed:actif()
    GF_MAJ_BARRE(uid)
  finsi
retourner

&& numéro de la ligne qui commence à l'octet pos (nul si inconnu) : index ou repère proche
fonction GF_LIGNE_DE(g, pos)
  si pos <= 0
    retourner 1
  finsi
  locale tranche = g.index.pas
  locale k = entier(pos / tranche) + 1
  si k <= #g.index.cumul
    retourner g.index.cumul[k] + fichier.compterlignes(g.chemin, (k - 1) * tranche, pos - (k - 1) * tranche) + 1
  finsi
  si g.repere <> nul et abs(pos - g.repere.pos) <= 512 * 1024 * 1024
    si pos >= g.repere.pos
      retourner g.repere.ligne + fichier.compterlignes(g.chemin, g.repere.pos, pos - g.repere.pos)
    finsi
    retourner g.repere.ligne - fichier.compterlignes(g.chemin, pos, g.repere.pos - pos)
  finsi
retourner nul

&& fenêtre glissante : sens = 1 (suite) ou -1 (début) ; la vue reste sur les mêmes lignes
procedure GF_GLISSER(uid, sens)
  locale g = GF[chaine(uid)]
  si g = nul
    retourner
  finsi
  locale cur = ed:curseur().ligne
  locale haut = ed:defilement().premiere
  locale ancien = g.debut
  si sens > 0
    si g.fin >= g.taille
      STATUT("Fin du fichier.")
      ed:lecture(vrai, uid, vrai)
      retourner
    finsi
    GF_CHARGER(uid, g.debut + entier((g.fin - g.debut) / 2), faux)
    si g.debut <= ancien
      GF_CHARGER(uid, g.fin, vrai)
    finsi
    locale retires = fichier.compterlignes(g.chemin, ancien, g.debut - ancien)
    ed:aller(max(1, cur - retires), 1)
    ed:defilement(max(1, haut - retires), uid)
  sinon
    si g.debut <= 0
      STATUT("Début du fichier.")
      ed:lecture(vrai, uid, vrai)
      retourner
    finsi
    GF_CHARGER(uid, max(0, g.debut - entier(REG.bloc / 2)), faux)
    si g.debut >= ancien
      GF_CHARGER(uid, max(0, ancien - entier(REG.bloc / 2)), vrai)
    finsi
    locale ajoutes = fichier.compterlignes(g.chemin, g.debut, ancien - g.debut)
    ed:aller(max(1, cur + ajoutes), 1)
    ed:defilement(max(1, haut + ajoutes), uid)
  finsi
retourner

procedure GF_SUIVANT(ev)
  locale g = GF_ACTIF()
  si g <> nul
    si g.fin >= g.taille
      STATUT("Fin du fichier.")
      retourner
    finsi
    GF_CHARGER(g.uid, g.fin, faux)
    ed:aller(1, 1)
  finsi
retourner

procedure GF_PRECEDENT(ev)
  locale g = GF_ACTIF()
  si g <> nul
    si g.debut <= 0
      STATUT("Début du fichier.")
      retourner
    finsi
    locale ancien = g.debut
    GF_CHARGER(g.uid, max(0, g.debut - REG.bloc), faux)
    ed:aller(max(1, fichier.compterlignes(g.chemin, g.debut, ancien - g.debut)), 1)
  finsi
retourner

procedure GF_DEBUT(ev)
  locale g = GF_ACTIF()
  si g <> nul
    GF_CHARGER(g.uid, 0, faux)
    ed:aller(1, 1)
  finsi
retourner

procedure GF_FIN(ev)
  locale g = GF_ACTIF()
  si g <> nul
    g.taille = fichier.taille(g.chemin)
    GF_CHARGER(g.uid, max(0, g.taille - REG.bloc), faux)
    ed:aller(ed:defilement().total, 1)
  finsi
retourner

procedure GF_RECHARGER(uid)
  locale g = GF[chaine(uid)]
  g.taille = fichier.taille(g.chemin)
  GF_CHARGER(uid, g.debut, faux)
  STATUT("Bloc relu (" + TAILLE_LISIBLE(g.taille) + ").")
retourner

&& curseur de position : appliqué quand il ne bouge plus (minuterie)
procedure GF_CURSEUR(ev)
  locale g = GF_ACTIF()
  si g = nul
    retourner
  finsi
  locale v = nombre(gf_curseur.valeur)
  si v = nul ou v = g.derniere_valeur
    retourner
  finsi
  g.curseur_demande = {valeur = v, t = horodatage()}
  gf_pos.libelle = "→ " + remplacertexte(chaine(v / 10, 1, 1), ".", ",") + " %"
retourner

procedure GF_ALLER(ev)
  locale g = GF_ACTIF()
  si g = nul
    CMD_ALLER(nul)
    retourner
  finsi
  locale r = ui.demander("Aller à une ligne (1234567), une position (37,5%) ou un octet (#1048576) :", "")
  si r <> nul et rogner(r) <> ""
    GF_ALLER_A(g.uid, rogner(r))
  finsi
retourner

procedure GF_ALLER_A(uid, r)
  locale g = GF[chaine(uid)]
  r = remplacertexte(remplacertexte(r, " ", ""), ",", ".")
  si finitpar(r, "%")
    locale p = nombre(gauche(r, #r - 1))
    si p = nul
      retourner
    finsi
    locale pos = entier(g.taille * max(0, min(100, p)) / 100)
    GF_CHARGER(uid, pos, faux)
    ed:aller(1, 1)
    STATUT("Position " + r + " : octet " + FORMAT_NOMBRE(g.debut) + ".")
    retourner
  finsi
  si commencepar(r, "#")
    locale o = nombre(souschaine(r, 2))
    si o = nul
      retourner
    finsi
    GF_ALLER_OCTET(uid, max(0, min(g.taille, o)))
    retourner
  finsi
  locale n = nombre(r)
  si n = nul ou n < 1
    retourner
  finsi
  && point de départ : tranche indexée ou repère, le plus proche avant la ligne voulue
  locale p0 = 0
  locale l0 = 1
  pour k = 1 a #g.index.cumul
    si g.index.cumul[k] + 1 < n
      p0 = (k - 1) * g.index.pas
      l0 = g.index.cumul[k] + 1
    finsi
  suivant
  si g.repere <> nul et g.repere.ligne <= n et g.repere.pos > p0
    p0 = g.repere.pos
    l0 = g.repere.ligne
  finsi
  si non g.index.fini et g.index.pos > 0 et p0 + 4 * 1024 * 1024 * 1024 < g.taille et n > l0 + 50000000 et p0 < g.index.pos - g.index.pas
    STATUT("Ligne au-delà de la partie indexée (" + INDEX_POURCENT(g) + ") : patientez pendant l'indexation, ou utilisez une position (%).")
    retourner
  finsi
  STATUT("Recherche de la ligne " + FORMAT_NOMBRE(n) + "…")
  locale off = fichier.positionligne(g.chemin, n, p0, l0)
  si off = nul
    STATUT("Le fichier a moins de " + FORMAT_NOMBRE(n) + " lignes.")
    retourner
  finsi
  g.repere = {pos = off, ligne = n}
  GF_CHARGER(uid, max(0, off - entier(REG.bloc / 3)), faux)
  locale dans = fichier.compterlignes(g.chemin, g.debut, off - g.debut) + 1
  ed:aller(dans, 1)
  ed:defilement(max(1, dans - 5), uid)
  STATUT("Ligne " + FORMAT_NOMBRE(n) + " (octet " + FORMAT_NOMBRE(off) + ").")
retourner

procedure GF_ALLER_OCTET(uid, o)
  locale g = GF[chaine(uid)]
  GF_CHARGER(uid, max(0, o - entier(REG.bloc / 3)), faux)
  locale dans = fichier.compterlignes(g.chemin, g.debut, max(0, o - g.debut)) + 1
  ed:aller(dans, 1)
  ed:defilement(max(1, dans - 5), uid)
  STATUT("Octet " + FORMAT_NOMBRE(o) + ".")
retourner

&&
&& Recherche dans tout le fichier
&&

procedure GF_RECHERCHER(ev)
  locale g = GF_ACTIF()
  si g = nul
    CMD_RECHERCHER(nul)
    retourner
  finsi
  locale r = ui.rechercher{texte = sisinon(ed:selection() = "", sisinon(RECH = nul, "", RECH.texte), ed:selection())}
  si r = nul ou r.texte = nul ou r.texte = ""
    retourner
  finsi
  RECH = r
  GF_CHERCHER_DEPUIS_CURSEUR(g.uid, r.texte, r.casse, r.arriere)
retourner

procedure GF_OCC_SUIVANTE(ev)
  CHERCHER(faux)
retourner

procedure GF_OCC_PRECEDENTE(ev)
  CHERCHER(vrai)
retourner

&& d'abord dans le bloc (après le curseur), puis dans le reste du fichier, en arrière-plan
procedure GF_CHERCHER_DEPUIS_CURSEUR(uid, motif, casse, arriere)
  locale g = GF[chaine(uid)]
  locale c0 = ed:curseur()
  si ed:chercher(motif, {casse = casse, arriere = arriere})
    locale c1 = ed:curseur()
    locale apres = c1.ligne > c0.ligne ou (c1.ligne = c0.ligne et c1.colonne > c0.colonne)
    si (non arriere et apres) ou (arriere et non apres et (c1.ligne <> c0.ligne ou c1.colonne <> c0.colonne))
      STATUT("« " + motif + " » : ligne " + FORMAT_NOMBRE(c1.ligne + ed:premiereligne() - 1) + ".")
      retourner
    finsi
  finsi
  locale depart = sisinon(arriere, g.debut + #motif, max(0, g.fin - #motif))
  si (arriere et g.debut <= 0) ou (non arriere et g.fin >= g.taille)
    STATUT("« " + motif + " » : plus d'occurrence " + sisinon(arriere, "avant", "après") + " dans le fichier.")
    retourner
  finsi
  g.rech = {motif = motif, casse = casse = vrai, arriere = arriere = vrai, suite = depart, depart = depart, t0 = horodatage()}
  STATUT("Recherche de « " + motif + " » dans tout le fichier… (Échap : arrêter)")
retourner

procedure GF_PAS_RECHERCHE(g)
  locale r = g.rech
  locale res = fichier.rechercher(g.chemin, r.motif, r.suite, {casse = r.casse, arriere = r.arriere, limite = 256 * 1024 * 1024})
  si res.position <> nul
    g.rech = nul
    GF_TROUVE(g, res.position, r.motif, r.casse)
    retourner
  finsi
  si res.suite = nul
    g.rech = nul
    STATUT("« " + r.motif + " » : aucune occurrence " + sisinon(r.arriere, "avant", "après") + " (" + chaine(horodatage() - r.t0, 1, 1) + " s).")
    retourner
  finsi
  r.suite = res.suite
  locale fait = sisinon(r.arriere, r.depart - r.suite, r.suite - r.depart)
  locale total = sisinon(r.arriere, r.depart, g.taille - r.depart)
  STATUT("Recherche de « " + r.motif + " »… " + TAILLE_LISIBLE(fait) + " / " + TAILLE_LISIBLE(total) + ;
         " (" + entier(100 * fait / max(1, total)) + " %) — Échap : arrêter")
retourner

procedure GF_TROUVE(g, pos, motif, casse)
  si ed:actif() <> g.uid
    ed:activer(g.uid)
  finsi
  GF_CHARGER(g.uid, max(0, pos - entier(REG.bloc / 3)), faux)
  locale dans = fichier.compterlignes(g.chemin, g.debut, pos - g.debut) + 1
  ed:aller(dans, 1)
  ed:defilement(max(1, dans - 8), g.uid)
  ed:chercher(motif, {casse = casse})
  STATUT("« " + motif + " » trouvé à l'octet " + FORMAT_NOMBRE(pos) + sisinon(g.ligne0 <> nul, ", ligne " + FORMAT_NOMBRE(g.ligne0 + dans - 1), "") + ".")
retourner

procedure GF_ARRETER_RECHERCHE(ev)
  locale n = 0
  pour chaque k, g dans GF
    si g.rech <> nul
      g.rech = nul
      n += 1
    finsi
  suivant
  si n > 0
    STATUT("Recherche arrêtée.")
  finsi
retourner

&&
&& Divers
&&

procedure GF_EXTRAIRE(ev)
  locale g = GF_ACTIF()
  si g = nul
    STATUT("L'onglet actif n'est pas un grand fichier.")
    retourner
  finsi
  locale lang = ed:langage()
  locale t = ed:texte(g.uid)
  locale uid = ed:nouveau(fichier.nom(g.chemin) + " [" + FORMAT_NOMBRE(g.debut) + "…]")
  ed:fixertexte(t, uid)
  ed:langage(lang, uid)
  DOCS[chaine(uid)] = {chemin = "", genre = "texte", fin_ligne = "LF", tabs = faux}
  ed:activer(uid)
  STATUT("Bloc copié dans un document modifiable (" + TAILLE_LISIBLE(#t) + ").")
retourner

procedure GF_BASCULER_SUIVI(ev)
  locale g = GF_ACTIF()
  si g = nul
    retourner
  finsi
  g.suivre = non g.suivre
  g.suivi_t = 0
  si g.suivre
    GF_FIN(nul)
  finsi
  gf_suivre.libelle = sisinon(g.suivre, "● Suivi", "Suivre")
  STATUT(sisinon(g.suivre, "Suivi de la fin du fichier activé.", "Suivi de la fin arrêté."))
retourner

procedure GF_BASCULER_INDEX(ev)
  locale g = GF_ACTIF()
  si g <> nul
    g.index.actif = non g.index.actif
    STATUT("Indexation des lignes " + sisinon(g.index.actif, "reprise", "suspendue") + " (" + INDEX_POURCENT(g) + ").")
  finsi
retourner

procedure GF_TAILLE_BLOC(ev)
  locale r = ui.demander("Taille des blocs en Mo (1 à 64) :", chaine(REG.bloc / 1048576))
  locale n = nombre(r)
  si n <> nul
    REG.bloc = entier(max(1, min(64, n)) * 1048576)
    STATUT("Blocs de " + TAILLE_LISIBLE(REG.bloc) + ".")
    locale g = GF_ACTIF()
    si g <> nul
      GF_CHARGER(g.uid, g.debut, faux)
    finsi
  finsi
retourner

procedure GF_SEUIL(ev)
  locale r = ui.demander("Ouvrir en mode grand fichier au-delà de (Mo) :", chaine(REG.seuil_grand / 1048576))
  locale n = nombre(r)
  si n <> nul
    REG.seuil_grand = entier(max(1, n) * 1048576)
    STATUT("Seuil du mode grand fichier : " + TAILLE_LISIBLE(REG.seuil_grand) + ".")
  finsi
retourner

fonction INDEX_POURCENT(g)
  si g.index.fini
    retourner "indexé"
  finsi
retourner "index " + entier(100 * g.index.pos / max(1, g.taille)) + " %"

procedure GF_INFOS(ev)
  locale g = GF_ACTIF()
  si g = nul
    retourner
  finsi
  locale n = car(10)
  ui.alerte(g.chemin + n + n + "Taille : " + TAILLE_LISIBLE(g.taille) + " (" + FORMAT_NOMBRE(g.taille) + " octets)" + n + ;
            "Bloc : octets " + FORMAT_NOMBRE(g.debut) + " à " + FORMAT_NOMBRE(g.fin) + " (" + FORMAT_NOMBRE(g.lignes) + " lignes)" + n + ;
            "Lignes : " + sisinon(g.index.fini, FORMAT_NOMBRE(g.index.cumul[#g.index.cumul]) + " au total", ;
                                  "au moins " + FORMAT_NOMBRE(g.index.cumul[#g.index.cumul]) + " (" + INDEX_POURCENT(g) + ")") + n + ;
            sisinon(g.coupees > 0, "Lignes de plus de " + REG.coupe + " octets coupées dans ce bloc : " + g.coupees + n, "") + ;
            "Fins de ligne : " + DOCS[chaine(g.uid)].fin_ligne, "information", "Grand fichier")
retourner

procedure GF_MAJ_BARRE(uid)
  locale g = GF[chaine(uid)]
  si g = nul
    retourner
  finsi
  locale pc = 100 * g.debut / max(1, g.taille)
  gf_titre.libelle = "⧉ " + fichier.nom(g.chemin) + " — " + TAILLE_LISIBLE(g.taille)
  locale lignes_ = sisinon(g.ligne0 = nul, "lignes ? (relatives au bloc)", ;
                           "lignes " + FORMAT_NOMBRE(g.ligne0) + "–" + FORMAT_NOMBRE(g.ligne0 + g.lignes))
  gf_pos.libelle = remplacertexte(chaine(pc, 1, 1), ".", ",") + " %  ·  " + lignes_
  locale v = entier(1000 * g.debut / max(1, g.taille))
  si g.curseur_demande = nul
    g.derniere_valeur = v
    gf_curseur.valeur = v
  finsi
  locale total = sisinon(g.index.fini, FORMAT_NOMBRE(g.index.cumul[#g.index.cumul]) + " lignes", INDEX_POURCENT(g))
  lblgf.libelle = "bloc " + TAILLE_LISIBLE(g.fin - g.debut) + " · " + total + sisinon(g.coupees > 0, " · " + g.coupees + " coupure(s)", "")
  gf_suivre.libelle = sisinon(g.suivre, "● Suivi", "Suivre")
retourner

&& tour de minuterie : curseur de position, recherche, suivi, index (budget ≈ 90 ms)
procedure GF_TICK
  locale t0 = horodatage()
  locale actif = ed:actif()
  pour chaque k, g dans GF
    si g.curseur_demande <> nul et horodatage() - g.curseur_demande.t > 0.3
      locale v = g.curseur_demande.valeur
      g.curseur_demande = nul
      g.derniere_valeur = v
      GF_CHARGER(g.uid, entier(g.taille * v / 1000), faux)
      ed:aller(1, 1)
    finsi
    si g.rech <> nul
      GF_PAS_RECHERCHE(g)
    finsi
    si g.suivre et horodatage() - sisinon(g.suivi_t = nul, 0, g.suivi_t) > 1
      g.suivi_t = horodatage()
      locale tn = fichier.taille(g.chemin)
      si tn <> g.taille
        locale a_la_fin = g.fin >= g.taille
        g.taille = tn
        si a_la_fin
          GF_CHARGER(g.uid, max(0, tn - REG.bloc), faux)
          si g.uid = actif
            ed:aller(ed:defilement().total, 1)
          finsi
        finsi
        && l'index rouvre sa dernière tranche, incomplète, pour compter la suite
        si g.index.total <> nul
          retirer(g.index.cumul)
          g.index.total = nul
          g.index.pos = (#g.index.cumul - 1) * g.index.pas
        finsi
        g.index.fini = faux
      finsi
    finsi
  suivant
  && index des lignes : tranches de 64 Mo tant que le budget le permet
  pour chaque k, g dans GF
    tantque g.index.actif et non g.index.fini et horodatage() - t0 < 0.09
      locale ix = g.index
      locale n = min(ix.pas, g.taille - ix.pos)
      si n <= 0
        ix.fini = vrai
        sortir
      finsi
      locale c = fichier.compterlignes(g.chemin, ix.pos, n)
      ix.pos = ix.pos + n
      si n = ix.pas
        inserer(ix.cumul, ix.cumul[#ix.cumul] + c)
      sinon
        && dernière tranche, incomplète : total des lignes (fin de ligne finale exclue)
        ix.total = ix.cumul[#ix.cumul] + c
        inserer(ix.cumul, ix.total)
        ix.fini = vrai
      finsi
      si ix.pos >= g.taille
        ix.fini = vrai
      finsi
      && numéros de ligne du bloc affiché désormais connus
      si g.ligne0 = nul et g.debut < ix.pos
        g.ligne0 = GF_LIGNE_DE(g, g.debut)
        si g.ligne0 <> nul
          ed:premiereligne(g.ligne0, g.uid)
        finsi
      finsi
    fintantque
    si g.uid = actif et horodatage() - g.maj > 0.5
      g.maj = horodatage()
      GF_MAJ_BARRE(g.uid)
    finsi
  suivant
retourner
