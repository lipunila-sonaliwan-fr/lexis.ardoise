&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Extension Ardoise : exemple d'ajout d'un langage (Zig) avec ses règles de structure,
&& et d'une analyse de structure propre à un langage (fichiers .env : une entrée par variable).

procedure EXTENSION_LANGAGE_ZIG
  ARDOISE_ENREGISTRER{genre = "langage", nom = "zig", definition = { ;
    titre = "Zig", extensions = {".zig", ".zon"}, ;
    motscles = "addrspace align allowzero and anyframe anytype asm async await break callconv catch comptime const continue defer else " + ;
               "enum errdefer error export extern fn for if inline linksection noalias noinline nosuspend opaque or orelse packed pub " + ;
               "resume return struct suspend switch test threadlocal try union unreachable usingnamespace var volatile while", ;
    types = "i8 i16 i32 i64 i128 isize u8 u16 u32 u64 u128 usize f16 f32 f64 f128 bool void noreturn type anyerror comptime_int comptime_float", ;
    constantes = "true false null undefined", annotation = "@", ;
    commentaire = {"//"}, documentation = {"///", "//!"}, chaineslongues = {"\\\\"}, definitions = "fn test", ;
    blocs = "accolades", indenterapres = {"{", "(", "["}, ;
    structure = {routines = "fn test", conditions = "if else switch", boucles = "for while", sections = "struct enum union", ;
                 branches = "else", modificateurs = "pub export extern inline"}, ;
    symboles = {{mot = "fn", genre = "fonction"}, {mot = "test", genre = "test"}, {mot = "struct", genre = "structure"}}}}
  ARDOISE_ENREGISTRER{genre = "langage", nom = "env", definition = {titre = "Variables d'environnement (.env)", ;
    extensions = {".env", ".env.local", ".envrc"}, commentaire = {"#"}, appels = faux, variable = "$"}}
  ARDOISE_ENREGISTRER{genre = "structure", langage = "env", procedure = @ZIG_STRUCTURE_ENV}
retourner

&& .env : chaque « NOM=valeur » est un symbole
fonction ZIG_STRUCTURE_ENV(lignes, langage)
  locale r = {}
  pour i = 1 a #lignes
    locale l = rogner(lignes[i])
    locale p = position("=", l)
    si p > 1 et non commencepar(l, "#")
      locale nom_ = rogner(gauche(l, p - 1))
      si commencepar(nom_, "export ")
        nom_ = rogner(souschaine(nom_, 8))
      finsi
      inserer(r, {nom = nom_, genre = "variable", ligne = i})
    finsi
  suivant
retourner r
