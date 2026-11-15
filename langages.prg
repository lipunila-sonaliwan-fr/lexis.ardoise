&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Ardoise : langages livrés (coloration, diagramme de structure dans la marge, plan).
&&
&& Chaque langage est décrit par LANGAGE(nom, def) : la définition est transmise telle quelle à
&& ui.definirlangage (coloration et blocs de la marge, calculés par l'éditeur natif), et Ardoise
&& garde pour le plan et le graphe de structure les règles « symboles » : mots qui annoncent un
&& symbole et sa nature. Lexis+, SQL et Markdown sont colorés par l'éditeur lui-même.
&& Une extension ajoute un langage de la même façon (voir plugins/langage_lua.prg).

procedure LANGAGE(nom, def)
  locale symboles = def.symboles
  def.symboles = nul
  ui.definirlangage(nom, def)
  LANGAGES[minuscule(nom)] = {nom = minuscule(nom), titre = sisinon(def.titre = nul, nom, def.titre), ;
                              symboles = sisinon(symboles = nul, {}, symboles), ;
                              commentaire = def.commentaire, casse = sisinon(def.casse = nul, vrai, def.casse)}
retourner

&& langage d'un document : nom défini, ou lexis / sql / markdown / texte
fonction LANGAGE_DOC(uid)
  locale l = nul
  essayer
    l = ed:langage()
    si uid <> nul et uid <> ed:actif()
      l = DOCS[chaine(uid)].langage
    finsi
  capturer e
  finessayer
retourner sisinon(l = nul, "texte", l)

fonction TITRE_LANGAGE(nom)
  faire cas
  cas nom = "lexis"
    retourner "Lexis+"
  cas nom = "sql"
    retourner "SQL"
  cas nom = "markdown"
    retourner "Markdown"
  cas nom = "texte" ou nom = nul ou nom = ""
    retourner "Texte brut"
  fincas
  locale d = LANGAGES[nom]
retourner sisinon(d = nul, nom, d.titre)

&& liste {nom, titre} de tous les langages, intégrés compris
fonction TOUS_LANGAGES()
  locale r = {{nom = "texte", titre = "Texte brut"}, {nom = "lexis", titre = "Lexis+"}, ;
              {nom = "sql", titre = "SQL"}, {nom = "markdown", titre = "Markdown"}}
  pour chaque l dans ui.langages()
    inserer(r, {nom = l.nom, titre = l.titre + "  (" + joindre(l.extensions, " ") + ")"})
  suivant
retourner r

procedure DEFINIR_LANGAGES
  LANGAGES = {}
  locale c_mots = "if else for while do switch case default break continue return goto sizeof typedef struct union enum " + ;
                  "static extern const volatile register inline restrict auto signed unsigned"
  locale cpp_mots = c_mots + " class namespace template typename public private protected virtual override final " + ;
                    "new delete this try catch throw using operator friend constexpr noexcept nullptr explicit mutable decltype co_await co_return"
  locale c_types = "void int char short long float double bool size_t ssize_t int8_t int16_t int32_t int64_t " + ;
                   "uint8_t uint16_t uint32_t uint64_t wchar_t FILE string vector map set unique_ptr shared_ptr auto"
  locale accol = {routines = "", conditions = "if else switch", boucles = "for while do", essais = "try catch", ;
                  sections = "class struct namespace union enum interface", branches = "else catch finally case default", ;
                  modificateurs = "static public private protected inline virtual export async const extern"}

  LANGAGE("c", {titre = "C / C++", extensions = {".c", ".h", ".cpp", ".hpp", ".cc", ".hh", ".cxx", ".ino"}, ;
    motscles = cpp_mots, types = c_types, constantes = "true false NULL nullptr EOF", ;
    fonctions = "printf fprintf sprintf snprintf scanf malloc calloc realloc free memcpy memset memcmp strlen strcpy strncpy strcmp strcat fopen fclose fread fwrite fgets fputs exit assert", ;
    commentaire = {"//"}, commentairebloc = {"/*", "*/"}, documentation = {"///", "/**", "//!"}, directive = "#", ;
    blocs = "accolades", structure = accol, indenterapres = {"{", "(", "["}, ;
    symboles = {{mot = "class", genre = "classe"}, {mot = "struct", genre = "structure"}, {mot = "namespace", genre = "espace"}, ;
                {mot = "enum", genre = "énumération"}, {mot = "#define", genre = "macro"}}})

  LANGAGE("java", {titre = "Java / Kotlin / C#", extensions = {".java", ".kt", ".kts", ".cs", ".scala", ".groovy", ".gradle"}, ;
    motscles = "abstract assert break case catch class continue default do else enum extends final finally for if implements import " + ;
               "instanceof interface native new package private protected public return static super switch synchronized this throw throws " + ;
               "transient try volatile while var val fun object companion data sealed when is in out override open internal lateinit " + ;
               "namespace using struct readonly async await yield record get set init where", ;
    types = "int long short byte char boolean float double void String Integer Long Object List Map Set ArrayList HashMap Any Unit Int string bool decimal", ;
    constantes = "true false null", commentaire = {"//"}, commentairebloc = {"/*", "*/"}, documentation = {"/**", "///"}, ;
    annotation = "@", chaineslongues = {"\"\"\""}, definitions = "class interface enum fun record object", ;
    blocs = "accolades", structure = {conditions = "if else switch when", boucles = "for while do", essais = "try catch", ;
      sections = "class interface enum object record namespace struct", branches = "else catch finally case default", ;
      modificateurs = "public private protected static final abstract override open internal sealed data async synchronized readonly"}, ;
    indenterapres = {"{", "(", "["}, ;
    symboles = {{mot = "class", genre = "classe"}, {mot = "interface", genre = "interface"}, {mot = "enum", genre = "énumération"}, ;
                {mot = "fun", genre = "fonction"}, {mot = "record", genre = "classe"}, {mot = "object", genre = "classe"}}})

  LANGAGE("javascript", {titre = "JavaScript / TypeScript", extensions = {".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx", ".mts", ".vue", ".svelte"}, ;
    motscles = "break case catch class const continue debugger default delete do else export extends finally for function if import in " + ;
               "instanceof let new return super switch this throw try typeof var void while with yield async await of from as " + ;
               "interface type enum implements namespace declare abstract readonly public private protected static get set", ;
    types = "string number boolean any unknown never object symbol bigint Array Promise Map Set Record Partial", ;
    constantes = "true false null undefined NaN Infinity", ;
    fonctions = "console require setTimeout setInterval clearTimeout fetch JSON Math Object parseInt parseFloat document window", ;
    commentaire = {"//"}, commentairebloc = {"/*", "*/"}, documentation = {"/**"}, chaineslongues = {"`"}, ;
    identificateurs = "$", definitions = "function class interface", annotation = "@", ;
    blocs = "accolades", structure = {routines = "function", conditions = "if else switch", boucles = "for while do", essais = "try catch", ;
      sections = "class interface namespace enum", branches = "else catch finally case default", ;
      modificateurs = "export default async static public private protected abstract declare"}, ;
    indenterapres = {"{", "(", "["}, ;
    symboles = {{mot = "function", genre = "fonction"}, {mot = "class", genre = "classe"}, {mot = "interface", genre = "interface"}, ;
                {mot = "type", genre = "type"}, {mot = "enum", genre = "énumération"}, {mot = "const", genre = "constante", fleche = vrai}}})

  LANGAGE("python", {titre = "Python", extensions = {".py", ".pyw", ".pyi", "sconstruct", "sconscript"}, ;
    motscles = "and as assert async await break class continue def del elif else except finally for from global if import in is " + ;
               "lambda nonlocal not or pass raise return try while with yield match case", ;
    types = "int float str bytes bool list dict set tuple object complex frozenset bytearray", ;
    constantes = "True False None self cls", ;
    fonctions = "print len range enumerate zip map filter sorted reversed open isinstance issubclass super min max sum abs any all " + ;
                "input repr hash id iter next getattr setattr hasattr type round divmod format vars dir", ;
    commentaire = {"#"}, chaineslongues = {"\"\"\"", "'''"}, annotation = "@", definitions = "def class", ;
    blocs = "indentation", structure = {routines = "def", conditions = "if elif else match", boucles = "for while", ;
      essais = "try except finally with", sections = "class", branches = "elif else except finally case", modificateurs = "async"}, ;
    indenterapres = {":"}, ;
    symboles = {{mot = "def", genre = "fonction"}, {mot = "class", genre = "classe"}}})

  LANGAGE("nim", {titre = "Nim", extensions = {".nim", ".nims", ".nimble"}, ;
    motscles = "addr and as asm bind block break case cast concept const continue converter defer discard distinct div do elif else end " + ;
               "enum except export finally for from func if import in include interface is isnot iterator let macro method mixin mod nil " + ;
               "not notin object of or out proc ptr raise ref return shl shr static template try tuple type using var when while xor yield", ;
    types = "int int8 int16 int32 int64 uint uint8 uint16 uint32 uint64 float float32 float64 bool char string cstring seq array set " + ;
            "openArray varargs pointer untyped typed auto Table HashSet", ;
    constantes = "true false nil", fonctions = "echo len add high low inc dec newSeq newString toSeq assert doAssert", ;
    commentaire = {"#"}, commentairebloc = {"#[", "]#"}, documentation = {"##"}, chaineslongues = {"\"\"\""}, ;
    definitions = "proc func method iterator template macro converter", ;
    blocs = "indentation", structure = {routines = "proc func method iterator template macro converter", ;
      conditions = "if elif else when case of", boucles = "for while", essais = "try except finally", sections = "type", ;
      branches = "elif else of except finally"}, indenterapres = {":", "=", "var", "let", "const", "type"}, ;
    symboles = {{mot = "proc", genre = "procédure"}, {mot = "func", genre = "fonction"}, {mot = "method", genre = "méthode"}, ;
                {mot = "iterator", genre = "itérateur"}, {mot = "template", genre = "gabarit"}, {mot = "macro", genre = "macro"}}})

  LANGAGE("go", {titre = "Go", extensions = {".go"}, ;
    motscles = "break case chan const continue default defer else fallthrough for func go goto if import interface map package range " + ;
               "return select struct switch type var", ;
    types = "bool byte complex64 complex128 error float32 float64 int int8 int16 int32 int64 rune string uint uint8 uint16 uint32 uint64 uintptr any", ;
    constantes = "true false nil iota", fonctions = "append cap close copy delete len make new panic print println recover", ;
    commentaire = {"//"}, commentairebloc = {"/*", "*/"}, chaineslongues = {"`"}, definitions = "func type", ;
    blocs = "accolades", structure = {routines = "func", conditions = "if else switch select", boucles = "for", ;
      sections = "struct interface", branches = "else case default"}, indenterapres = {"{", "("}, ;
    symboles = {{mot = "func", genre = "fonction"}, {mot = "type", genre = "type"}}})

  LANGAGE("rust", {titre = "Rust", extensions = {".rs"}, ;
    motscles = "as async await break const continue crate dyn else enum extern fn for if impl in let loop match mod move mut pub ref " + ;
               "return self Self static struct super trait type unsafe use where while macro_rules", ;
    types = "i8 i16 i32 i64 i128 isize u8 u16 u32 u64 u128 usize f32 f64 bool char str String Vec Option Result Box Rc Arc HashMap", ;
    constantes = "true false None Some Ok Err", commentaire = {"//"}, commentairebloc = {"/*", "*/"}, documentation = {"///", "//!"}, ;
    definitions = "fn struct enum trait mod impl", annotation = "#", ;
    blocs = "accolades", structure = {routines = "fn", conditions = "if else match", boucles = "for while loop", ;
      sections = "impl struct enum trait mod", branches = "else", modificateurs = "pub async unsafe const extern"}, indenterapres = {"{", "(", "["}, ;
    symboles = {{mot = "fn", genre = "fonction"}, {mot = "struct", genre = "structure"}, {mot = "enum", genre = "énumération"}, ;
                {mot = "trait", genre = "trait"}, {mot = "impl", genre = "implémentation"}, {mot = "mod", genre = "module"}}})

  LANGAGE("php", {titre = "PHP", extensions = {".php", ".phtml"}, ;
    motscles = "abstract and as break case catch class clone const continue declare default do echo else elseif empty enddeclare " + ;
               "endfor endforeach endif endswitch endwhile extends final finally fn for foreach function global goto if implements " + ;
               "include include_once instanceof insteadof interface isset list match namespace new or print private protected public " + ;
               "readonly require require_once return static switch throw trait try unset use var while xor yield", ;
    constantes = "true false null TRUE FALSE NULL", commentaire = {"//", "#"}, commentairebloc = {"/*", "*/"}, documentation = {"/**"}, ;
    variable = "$", definitions = "function class interface trait", ;
    blocs = "accolades", structure = {routines = "function", conditions = "if else elseif switch match", boucles = "for foreach while do", ;
      essais = "try catch", sections = "class interface trait namespace", branches = "else elseif catch finally case default", ;
      modificateurs = "public private protected static abstract final"}, indenterapres = {"{", "(", "["}, ;
    symboles = {{mot = "function", genre = "fonction"}, {mot = "class", genre = "classe"}, {mot = "interface", genre = "interface"}, {mot = "trait", genre = "trait"}}})

  LANGAGE("ruby", {titre = "Ruby", extensions = {".rb", ".rake", "rakefile", "gemfile"}, ;
    motscles = "alias and begin break case class def defined? do else elsif end ensure for if in module next not or redo rescue " + ;
               "retry return self super then undef unless until when while yield require attr_accessor attr_reader private protected public", ;
    constantes = "true false nil", commentaire = {"#"}, variable = "@$", definitions = "def class module", ;
    blocs = "motscles", structure = {routines = "def", conditions = "if unless case", boucles = "while until for", essais = "begin", ;
      sections = "class module", branches = "else elsif when rescue ensure", ouvrants = "def class module if unless case while until for begin do", ;
      fermants = "end"}, ;
    symboles = {{mot = "def", genre = "méthode"}, {mot = "class", genre = "classe"}, {mot = "module", genre = "module"}}})

  LANGAGE("shell", {titre = "Shell (bash, zsh)", extensions = {".sh", ".bash", ".zsh", ".ksh", ".bashrc", ".profile", ".zshrc"}, ;
    motscles = "if then else elif fi case esac for while until do done in function select time return exit break continue local " + ;
               "export readonly declare set unset shift source alias trap eval exec", ;
    fonctions = "echo printf cd ls cat grep sed awk find xargs test read mkdir rm cp mv chmod chown tar curl wget git sudo", ;
    constantes = "true false", commentaire = {"#"}, variable = "$", directive = "#!", definitions = "function", ;
    blocs = {"motscles", "accolades"}, structure = {routines = "function", conditions = "if case", boucles = "for while until select", ;
      branches = "else elif", ouvrants = "if case for while until select", fermants = "fi esac done"}, ;
    symboles = {{mot = "function", genre = "fonction"}, {suffixe = "()", genre = "fonction"}}})

  LANGAGE("powershell", {titre = "PowerShell", extensions = {".ps1", ".psm1", ".psd1"}, casse = faux, ;
    motscles = "begin break catch class continue data do dynamicparam else elseif end exit filter finally for foreach from function " + ;
               "if in param process return switch throw trap try until using var while", ;
    constantes = "$true $false $null", commentaire = {"#"}, commentairebloc = {"<#", "#>"}, variable = "$", definitions = "function filter class", ;
    identificateurs = "-", blocs = "accolades", structure = {routines = "function filter", conditions = "if else elseif switch", ;
      boucles = "for foreach while do", essais = "try catch", sections = "class", branches = "else elseif catch finally"}, ;
    symboles = {{mot = "function", genre = "fonction"}, {mot = "class", genre = "classe"}}})

  LANGAGE("lua", {titre = "Lua", extensions = {".lua"}, ;
    motscles = "and break do else elseif end for function goto if in local not or repeat return then until while", ;
    constantes = "true false nil", fonctions = "print pairs ipairs type tostring tonumber require setmetatable getmetatable error pcall assert select table string math io os", ;
    commentaire = {"--"}, commentairebloc = {"--[[", "]]"}, chaineslongues = {"[["}, definitions = "function", ;
    blocs = "motscles", structure = {routines = "function", conditions = "if", boucles = "for while repeat", branches = "else elseif", ;
      ouvrants = "function if for while repeat do", fermants = "end until", modificateurs = "local"}, ;
    symboles = {{mot = "function", genre = "fonction"}}})

  LANGAGE("pascal", {titre = "Pascal / Delphi", extensions = {".pas", ".pp", ".dpr", ".lpr", ".inc"}, casse = faux, ;
    motscles = "and array as begin case class const constructor destructor div do downto else end except exports file finalization " + ;
               "finally for function goto if implementation in inherited initialization interface is label library mod nil not object of " + ;
               "or packed procedure program property raise record repeat set shl shr then to try type unit until uses var while with xor", ;
    types = "integer cardinal int64 byte word longint real double single extended boolean char string ansistring widestring pointer variant", ;
    constantes = "true false nil", commentaire = {"//"}, commentairebloc = {"{", "}"}, definitions = "procedure function constructor destructor", ;
    blocs = "motscles", structure = {routines = "procedure function constructor destructor", conditions = "if case", boucles = "for while repeat", ;
      essais = "try", sections = "class record interface implementation", branches = "else except finally", ;
      ouvrants = "begin case try record repeat class", fermants = "end end; until"}, ;
    symboles = {{mot = "procedure", genre = "procédure"}, {mot = "function", genre = "fonction"}, {mot = "constructor", genre = "constructeur"}}})

  LANGAGE("basic", {titre = "Visual Basic / VBA", extensions = {".bas", ".vb", ".vbs", ".cls", ".frm"}, casse = faux, ;
    motscles = "and as boolean byref byval call case class const dim do each else elseif end enum exit for function get if in is " + ;
               "let loop module new next not nothing of on or private property public redim resume return select set static step " + ;
               "sub then to try catch finally type until wend while with", ;
    constantes = "true false nothing null", commentaire = {"'", "rem"}, chaines = "\"", echappement = faux, definitions = "sub function property class", ;
    blocs = "motscles", structure = {routines = "sub function property", conditions = "if select", boucles = "for do while", essais = "try", ;
      sections = "class module type enum", branches = "else elseif case catch finally", ;
      ouvrants = "sub function property if select for do while with class module type enum try", fermants = "end next loop wend"}, ;
    symboles = {{mot = "sub", genre = "procédure"}, {mot = "function", genre = "fonction"}, {mot = "class", genre = "classe"}}})

  LANGAGE("html", {titre = "HTML / XML / SVG", extensions = {".html", ".htm", ".xhtml", ".xml", ".svg", ".xsd", ".xsl", ".xslt", ".plist", ".csproj", ".vcxproj", ".pom", ".wsdl", ".rss", ".atom"}, ;
    balises = vrai, casse = faux, blocs = "balises", commentaire = {"<!--"}, ;
    structure = {sections = "html head body section article nav main header footer svg g table form defs"}, ;
    symboles = {{balise = vrai}}})

  LANGAGE("css", {titre = "CSS / SCSS / Less", extensions = {".css", ".scss", ".sass", ".less"}, ;
    motscles = "@media @import @font-face @keyframes @supports @mixin @include @extend @use @forward @if @else @each @for @function @return important", ;
    constantes = "inherit initial unset auto none", commentaire = {"//"}, commentairebloc = {"/*", "*/"}, commenter = "//", ;
    identificateurs = "-#.:", appels = vrai, blocs = "accolades", ;
    structure = {sections = "@media @supports @keyframes"}, indenterapres = {"{"}, ;
    symboles = {{selecteur = vrai}}})

  LANGAGE("json", {titre = "JSON", extensions = {".json", ".jsonc", ".geojson", ".ipynb", ".har", ".babelrc", ".eslintrc"}, ;
    constantes = "true false null", commentaire = {"//"}, appels = faux, blocs = "accolades", crochets = vrai, ;
    indenterapres = {"{", "["}, symboles = {{clef = vrai}}})

  LANGAGE("yaml", {titre = "YAML", extensions = {".yaml", ".yml", ".clang-format"}, ;
    constantes = "true false null yes no on off ~", commentaire = {"#"}, appels = faux, identificateurs = "-", ;
    blocs = "indentation", indenterapres = {":"}, symboles = {{clef = vrai}}})

  LANGAGE("toml", {titre = "TOML / INI", extensions = {".toml", ".ini", ".cfg", ".conf", ".properties", ".editorconfig", ".desktop", ".gitconfig"}, ;
    constantes = "true false", commentaire = {"#", ";"}, appels = faux, chaineslongues = {"\"\"\"", "'''"}, identificateurs = "-.", ;
    symboles = {{section = vrai}}})

  LANGAGE("makefile", {titre = "Makefile / CMake / Dockerfile", extensions = {"makefile", "gnumakefile", ".mk", ".mak", "cmakelists.txt", ".cmake", "dockerfile", ".dockerfile"}, ;
    casse = faux, motscles = "ifeq ifneq ifdef ifndef else endif include define endef export override " + ;
    "from run cmd entrypoint copy add env arg workdir expose volume user label healthcheck shell onbuild stopsignal maintainer as " + ;
    "if elseif endif foreach endforeach function endfunction macro endmacro while endwhile set project add_executable add_library target_link_libraries", ;
    commentaire = {"#"}, variable = "$", appels = faux, blocs = "motscles", ;
    structure = {routines = "define function macro", conditions = "ifeq ifneq ifdef ifndef if", boucles = "foreach while", ;
      branches = "else elseif", ouvrants = "ifeq ifneq ifdef ifndef define if foreach while function macro", ;
      fermants = "endif endef endforeach endwhile endfunction endmacro"}, ;
    symboles = {{cible = vrai}}})

  LANGAGE("r", {titre = "R", extensions = {".r", ".rmd"}, ;
    motscles = "if else repeat while function for in next break return switch library require", ;
    constantes = "TRUE FALSE NULL NA Inf NaN T F", fonctions = "c list data.frame print paste cat length nrow ncol apply sapply lapply", ;
    commentaire = {"#"}, identificateurs = ".", blocs = "accolades", ;
    structure = {routines = "function", conditions = "if else switch", boucles = "for while repeat", branches = "else"}, ;
    symboles = {{fleche = vrai, mot = "function", genre = "fonction"}}})

  LANGAGE("diff", {titre = "Diff / Patch", extensions = {".diff", ".patch", ".rej"}, appels = faux, chaines = "", ;
    commentaire = {"---", "+++", "@@", "-", "+"}, symboles = {{prefixe = "@@", genre = "bloc"}, {prefixe = "diff ", genre = "fichier"}}})

  LANGAGE("journal", {titre = "Journal (logs)", extensions = {".log", ".out", ".err", ".trace"}, appels = faux, chaines = "\"", ;
    motscles = "ERROR FATAL CRITICAL SEVERE ERREUR EXCEPTION Exception Traceback PANIC", ;
    types = "WARN WARNING AVERTISSEMENT ATTENTION", fonctions = "INFO NOTICE DEBUG TRACE VERBOSE", ;
    symboles = {{motcle = "ERROR", genre = "erreur"}, {motcle = "FATAL", genre = "erreur"}, {motcle = "Exception", genre = "erreur"}}})

  LANGAGE("csv", {titre = "CSV / TSV", extensions = {".csv", ".tsv", ".tab", ".psv"}, appels = faux, chaines = "\"", echappement = faux})
retourner
