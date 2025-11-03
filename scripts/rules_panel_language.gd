extends Control

func _ready() -> void:
	Global.dbg('RulesPanel: ENTER')
	if Global.LANGUAGE in title_text:
		$Title.text = title_text.get(Global.LANGUAGE, '')
	if Global.LANGUAGE in rules_text:
		$ScrollContainer/Label.text = rules_text.get(Global.LANGUAGE, '')

func _exit_tree() -> void:
	Global.dbg('RulesPanel: LEAVE')

const title_text = {
	'ar': 'قواعد لعبة مونريدج رومي',
	'bn': 'মুনরিজ রামি খেলার নিয়ম',
	'de': 'Regeln für Moonridge Rummy',
	'en': 'Rules for Moonridge Rummy',
	'es': 'Reglas de Moonridge Rummy',
	'fr': 'Règles du Moonridge Rummy',
	'he': 'חוקי מונרידג׳ ראמי',
	'hi': 'मूनरिज रम्मी के नियम',
	'id': 'Aturan untuk Moonridge Rummy',
	'it': 'Regole per Moonridge Rummy',
	'ja': 'ムーンリッジラミーのルール',
	'ko': '문리지 러미 규칙',
	'nl': 'Spelregels for Moonridge Rummy',
	'pl': 'Zasady gry w Moonridge Rummy',
	'pt': 'Regras para Moonridge Rummy',
	'ru': 'Правила игры Мунридж Рамми',
	'th': 'กฎของมูนริดจ์รัมมี่',
	'tr': 'Moonridge Rummy Kuralları',
	'zh-Hans': '月岭拉米牌规则',
	'zh-Hant': '月嶺拉米牌規則',
}

const rules_text = {
	'ar': """# مونريدج رومي: جميع الجولات ومتطلباتها

مونريدج رومي هو نوع من لعبة ليفربول رومي يتم لعبه على مدار سبع جولات، لكل منها مجموعة محددة من المجموعات (الكتب) والتسلسلات (الرن) التي يجب على اللاعبين وضعها للخروج. تصبح متطلبات كل جولة أكثر صعوبة بشكل تدريجي. إليك متطلبات كل جولة:

      |                                                             | إجمالي البطاقات
الجولة | المتطلب                                                      | المطلوبة
------|------------------------------------------------------------|------------
  1   | مجموعتان من ثلاثة (مجموعتان من 3 بطاقات)                     | 6
  2   | مجموعة واحدة من ثلاثة وتسلسل واحد من أربعة                    | 7
  3   | تسلسلان من أربعة                                             | 8
  4   | ثلاث مجموعات من ثلاثة                                        | 9
  5   | مجموعتان من ثلاثة وتسلسل واحد من أربعة                      | 10
  6   | مجموعة واحدة من ثلاثة وتسلسلان من أربعة                       | 11
  7   | ثلاث تسلسلات من أربعة (لا بطاقات متبقية، لا يسمح بالرمي)      | 12

## شرح المصطلحات

* المجموعة (الكتاب):
  ثلاث بطاقات أو أكثر من نفس الرتبة (على سبيل المثال، 8♥ 8♣ 8♠).

* التسلسل (الرن):
  أربع بطاقات متتالية أو أكثر من نفس النوع (على سبيل المثال، 3♥ 4♥ 5♥ 6♥).
  يمكن أن تكون الآسات عالية أو منخفضة، لكن التسلسلات لا يمكن أن "تلتف" من الملك إلى الآس إلى 2.

## ملاحظات خاصة

* في الجولة الأخيرة (الجولة 7)، يجب عليك استخدام جميع بطاقاتك في المجموعات المطلوبة ولا يمكنك الانتهاء برمي بطاقة.

* يجب تلبية عقد كل جولة تمامًا كما هو محدد قبل أن تتمكن من وضع بطاقاتك.
""",
	'bn': """# মুনরিজ রামি: সমস্ত রাউন্ড এবং তাদের প্রয়োজনীয়তা

মুনরিজ রামি লিভারপুল রামি-এর একটি ভিন্ন সংস্করণ যা সাতটি রাউন্ডে খেলা হয়, প্রত্যেকটিতে সেট (বুক) এবং রান (সিকোয়েন্স)-এর একটি নির্দিষ্ট সংমিশ্রণ থাকে যা খেলোয়াড়দের বাইরে যাওয়ার জন্য বিছিয়ে রাখতে হয়। প্রতিটি রাউন্ডের প্রয়োজনীয়তা ক্রমান্বয়ে আরও চ্যালেঞ্জিং হয়ে ওঠে। এখানে রাউন্ড-বাই-রাউন্ড প্রয়োজনীয়তা রয়েছে:

      |                                                             | মোট কার্ড
রাউন্ড | প্রয়োজনীয়তা                                                | প্রয়োজন
------|------------------------------------------------------------|------------
  1   | তিনটি করে দুটি বই (3টি কার্ডের 2টি সেট)                      | 6
  2   | তিনটি করে একটি বই এবং চারটি করে একটি রান                      | 7
  3   | চারটি করে দুটি রান                                           | 8
  4   | তিনটি করে তিনটি বই                                         | 9
  5   | তিনটি করে দুটি বই এবং চারটি করে একটি রান                      | 10
  6   | তিনটি করে একটি বই এবং চারটি করে দুটি রান                      | 11
  7   | চারটি করে তিনটি রান (কোনো অবশিষ্ট কার্ড নেই, বাতিল করার অনুমতি নেই) | 12

## পরিভাষার ব্যাখ্যা

* বই (সেট/গ্রুপ):
  একই র‍্যাঙ্কের তিন বা ততোধিক কার্ড (যেমন, 8♥ 8♣ 8♠)।

* রান (সিকোয়েন্স):
  একই স্যুটের চার বা ততোধিক পরপর কার্ড (যেমন, 3♥ 4♥ 5♥ 6♥)।
  টেক্কা উচ্চ বা নিম্ন হতে পারে, কিন্তু রান রাজা থেকে টেক্কা থেকে ২ পর্যন্ত "মোড়ানো" হতে পারে না।

## বিশেষ নোট

* চূড়ান্ত রাউন্ডে (রাউন্ড 7), আপনাকে অবশ্যই আপনার সমস্ত কার্ড প্রয়োজনীয় মেল্ডে ব্যবহার করতে হবে এবং বাতিল করে শেষ করতে পারবেন না।

* আপনার কার্ড বিছিয়ে দেওয়ার আগে প্রতিটি রাউন্ডের চুক্তি ঠিক নির্দিষ্ট হিসাবে পূরণ করতে হবে।
""",
	'de': """# Moonridge Rummy: Alle Runden und ihre Anforderungen

Moonridge Rummy wird über sieben Runden gespielt, wobei jede Runde eine bestimmte
Kombination aus Sätzen (Büchern) und Folgen (Sequenzen) erfordert, die ein Spieler
ablegen muss, um auszusteigen. Die Anforderungen werden mit jeder Runde anspruchsvoller.
Hier sind die Anforderungen für jede Runde:

      |                                                                     | Karten gesamt
Runde | Anforderung                                                         | benötigt
------|--------------------------------------------------------------------|-------------
  1   | Zwei Sätze zu drei Karten (2 Gruppen à 3 Karten)                    | 6
  2   | Ein Satz zu drei und eine Folge von vier Karten                     | 7
  3   | Zwei Folgen von vier Karten                                         | 8
  4   | Drei Sätze zu drei Karten                                           | 9
  5   | Zwei Sätze zu drei und eine Folge von vier Karten                   | 10
  6   | Ein Satz zu drei und zwei Folgen von vier Karten                    | 11
  7   | Drei Folgen von vier Karten (keine Restkarten, kein Abwurf erlaubt) | 12

## Erklärung der Begriffe

* Satz (Gruppe/Buch):
  Drei oder mehr Karten gleichen Rangs (z. B. 8♥ 8♣ 8♠).

* Folge (Sequenz):
  Vier oder mehr aufeinanderfolgende Karten derselben Farbe (z. B. 3♥ 4♥ 5♥ 6♥).
  Asse können hoch oder niedrig sein, aber Folgen dürfen nicht „umlaufen“
(z. B. König–Ass–2).

## Besondere Hinweise

* In der letzten Runde (Runde 7) müssen alle Karten in den geforderten
  Kombinationen verwendet werden, und ein Abwurf am Ende ist nicht erlaubt.

* Die Vorgaben für jede Runde müssen exakt erfüllt werden, bevor
Karten abgelegt werden können.
""",
	'en': """# Moonridge Rummy: All Rounds and Their Requirements

Moonridge Rummy is a variation of Liverpool Rummy that is played
over seven rounds, each with a specific combination of sets (books)
and runs (sequences) that players must lay down to go out. The
requirements for each round become progressively more
challenging. Here are the round-by-round requirements:

      |                                                             | Total Cards
Round | Requirement                                                 | Needed
------|------------------------------------------------------------|------------
  1   | Two books of three (2 sets of 3 cards)                      | 6
  2   | One book of three and one run of four                       | 7
  3   | Two runs of four                                            | 8
  4   | Three books of three                                        | 9
  5   | Two books of three and one run of four                      | 10
  6   | One book of three and two runs of four                      | 11
  7   | Three runs of four (no remaining cards, no discard allowed) | 12

## Explanation of Terms

* Book (Set/Group):
  Three or more cards of the same rank (e.g., 8♥ 8♣ 8♠).

* Run (Sequence):
  Four or more consecutive cards of the same suit (e.g., 3♥ 4♥ 5♥ 6♥).
  Aces can be high or low, but runs cannot "wraparound" from King to Ace to 2.

## Special Notes

* In the final round (Round 7), you must use all your cards in the required
  melds and cannot finish with a discard.

* The contract for each round must be met exactly as specified before you
  can lay down your cards.
""",
	'es': """# Moonridge Rummy: Todas las rondas y sus requisitos

Moonridge Rummy es una variante de Liverpool Rummy que se juega
en siete rondas, cada una con una combinación específica de tríos (libros)
y escaleras (secuencias) que los jugadores deben bajar para cerrar. Los
requisitos de cada ronda se vuelven progresivamente más
desafiantes. Aquí están los requisitos ronda por ronda:

      |                                                             | Total de Cartas
Ronda | Requisito                                                   | Necesarias
------|------------------------------------------------------------|------------
  1   | Dos libros de tres (2 tríos de 3 cartas)                    | 6
  2   | Un libro de tres y una escalera de cuatro                   | 7
  3   | Dos escaleras de cuatro                                     | 8
  4   | Tres libros de tres                                         | 9
  5   | Dos libros de tres y una escalera de cuatro                 | 10
  6   | Un libro de tres y dos escaleras de cuatro                  | 11
  7   | Tres escaleras de cuatro (sin cartas restantes, no se permite descarte) | 12

## Explicación de Términos

* Libro (Trío/Grupo):
  Tres o más cartas del mismo valor (p. ej., 8♥ 8♣ 8♠).

* Escalera (Secuencia):
  Cuatro o más cartas consecutivas del mismo palo (p. ej., 3♥ 4♥ 5♥ 6♥).
  Los ases pueden ser altos o bajos, pero las escaleras no pueden "dar la vuelta" de Rey a As a 2.

## Notas Especiales

* En la ronda final (Ronda 7), debes usar todas tus cartas en las
  combinaciones requeridas y no puedes terminar con un descarte.

* El contrato de cada ronda debe cumplirse exactamente como se especifica antes de que
  puedas bajar tus cartas.
""",
	'fr': """# Moonridge Rummy : Toutes les manches et leurs exigences

Le Moonridge Rummy est une variante du Liverpool Rummy qui se joue
en sept manches, chacune avec une combinaison spécifique de brelans (livres)
et de suites (séquences) que les joueurs doivent poser pour terminer. Les
exigences de chaque manche deviennent progressivement plus
difficiles. Voici les exigences manche par manche :

      |                                                             | Total de Cartes
Manche| Exigence                                                    | Nécessaires
------|------------------------------------------------------------|------------
  1   | Deux livres de trois (2 brelans de 3 cartes)                | 6
  2   | Un livre de trois et une suite de quatre                    | 7
  3   | Deux suites de quatre                                       | 8
  4   | Trois livres de trois                                       | 9
  5   | Deux livres de trois et une suite de quatre                 | 10
  6   | Un livre de trois et deux suites de quatre                  | 11
  7   | Trois suites de quatre (pas de cartes restantes, pas de défausse autorisée) | 12

## Explication des termes

* Livre (Brelan/Groupe) :
  Trois cartes ou plus de même rang (par ex., 8♥ 8♣ 8♠).

* Suite (Séquence) :
  Quatre cartes consécutives ou plus de la même couleur (par ex., 3♥ 4♥ 5♥ 6♥).
  Les As peuvent être hauts ou bas, mais les suites ne peuvent pas « boucler » du Roi à l'As au 2.

## Notes spéciales

* Dans la manche finale (Manche 7), vous devez utiliser toutes vos cartes dans les
  combinaisons requises et ne pouvez pas terminer par une défausse.

* Le contrat de chaque manche doit être rempli exactly comme spécifié avant que vous
  ne puissiez poser vos cartes.
""",
	'he': """# מונרידג׳ ראמי: כל הסיבובים והדרישות שלהם

מונרידג׳ ראמי הוא גרסה של ליברפול ראמי המשוחקת על פני שבעה סיבובים, כל אחד עם שילוב ספציפי של סטים (ספרים) ורצפים (סדרות) שהשחקנים חייבים להניח כדי לצאת. הדרישות לכל סיבוב הופכות לקשות יותר בהדרגה. להלן הדרישות לפי סיבוב:

      |                                                             | סך הכל קלפים
סיבוב | דרישה                                                        | נדרשים
------|------------------------------------------------------------|------------
  1   | שני ספרים של שלושה (2 סטים של 3 קלפים)                      | 6
  2   | ספר אחד של שלושה ורצף אחד של ארבעה                          | 7
  3   | שני רצפים של ארבעה                                          | 8
  4   | שלושה ספרים של שלושה                                        | 9
  5   | שני ספרים של שלושה ורצף אחד של ארבעה                        | 10
  6   | ספר אחד של שלושה ושני רצפים של ארבעה                        | 11
  7   | שלושה רצפים של ארבעה (אין קלפים נותרים, אסור להשליך)        | 12

## הסבר מונחים

* ספר (סט/קבוצה):
  שלושה קלפים או יותר מאותה דרגה (למשל, 8♥ 8♣ 8♠).

* רצף (סדרה):
  ארבעה קלפים עוקבים או יותר מאותה סדרה (למשל, 3♥ 4♥ 5♥ 6♥).
  אסים יכולים להיות גבוהים או נמוכים, אך רצפים אינם יכולים "להתעגל" ממלך לאס ל-2.

## הערות מיוחדות

* בסיבוב האחרון (סיבוב 7), עליך להשתמש בכל הקלפים שלך בירידות הנדרשות ואינך יכול לסיים עם השלכה.

* יש לעמוד בחוזה של כל סיבוב בדיוק כפי שצוין לפני שתוכל להניח את הקלפים שלך.
""",
	'hi': """# मूनरिज रम्मी: सभी राउंड और उनकी आवश्यकताएं

मूनरिज रम्मी लिवरपूल रम्मी का एक प्रकार है जो सात राउंड में खेला जाता है, प्रत्येक में सेट (किताबें) और रन (अनुक्रम) का एक विशिष्ट संयोजन होता है जिसे खिलाड़ियों को बाहर जाने के लिए रखना पड़ता है। प्रत्येक राउंड की आवश्यकताएं उत्तरोत्तर अधिक चुनौतीपूर्ण होती जाती हैं। यहाँ राउंड-दर-राउंड आवश्यकताएं हैं:

      |                                                             | कुल कार्ड
राउंड | आवश्यकता                                                    | चाहिए
------|------------------------------------------------------------|------------
  1   | तीन की दो किताबें (3 कार्ड के 2 सेट)                         | 6
  2   | तीन की एक किताब और चार का एक रन                             | 7
  3   | चार के दो रन                                                | 8
  4   | तीन की तीन किताबें                                          | 9
  5   | तीन की दो किताबें और चार का एक रन                           | 10
  6   | तीन की एक किताब और चार के दो रन                             | 11
  7   | चार के तीन रन (कोई शेष कार्ड नहीं, कोई त्याग नहीं)           | 12

## शब्दों की व्याख्या

* किताब (सेट/समूह):
  एक ही रैंक के तीन या अधिक कार्ड (जैसे, 8♥ 8♣ 8♠)।

* रन (अनुक्रम):
  एक ही सूट के चार या अधिक लगातार कार्ड (जैसे, 3♥ 4♥ 5♥ 6♥)।
  इक्के ऊंचे या नीचे हो सकते हैं, लेकिन रन किंग से ऐस से 2 तक "रैपअराउंड" नहीं हो सकते।

## विशेष नोट्स

* अंतिम राउंड (राउंड 7) में, आपको अपने सभी कार्डों का उपयोग आवश्यक मेल्ड में करना होगा और आप त्याग के साथ समाप्त नहीं कर सकते।

* प्रत्येक राउंड के लिए अनुबंध को ठीक उसी तरह पूरा किया जाना चाहिए जैसा कि आपके कार्ड रखने से पहले निर्दिष्ट किया गया है।
""",
	'id': """# Moonridge Rummy: Semua Putaran dan Persyaratannya

Moonridge Rummy adalah variasi dari Liverpool Rummy yang dimainkan
selama tujuh putaran, masing-masing dengan kombinasi set (buku)
dan run (urutan) tertentu yang harus diletakkan pemain untuk keluar.
Persyaratan untuk setiap putaran menjadi semakin lebih
menantang. Berikut adalah persyaratan putaran demi putaran:

      |                                                             | Total Kartu
Putaran| Persyaratan                                                 | Dibutuhkan
------|------------------------------------------------------------|------------
  1   | Dua buku tiga (2 set 3 kartu)                               | 6
  2   | Satu buku tiga dan satu run empat                           | 7
  3   | Dua run empat                                               | 8
  4   | Tiga buku tiga                                              | 9
  5   | Dua buku tiga dan satu run empat                            | 10
  6   | Satu buku tiga dan dua run empat                            | 11
  7   | Tiga run empat (tidak ada kartu tersisa, tidak boleh buang) | 12

## Penjelasan Istilah

* Buku (Set/Grup):
  Tiga atau lebih kartu dengan peringkat yang sama (mis., 8♥ 8♣ 8♠).

* Run (Urutan):
  Empat atau lebih kartu berurutan dari jenis yang sama (mis., 3♥ 4♥ 5♥ 6♥).
  As bisa tinggi atau rendah, tetapi run tidak bisa "melingkar" dari Raja ke As ke 2.

## Catatan Khusus

* Di putaran final (Putaran 7), Anda harus menggunakan semua kartu Anda dalam
  meld yang diperlukan dan tidak bisa selesai dengan buangan.

* Kontrak untuk setiap putaran harus dipenuhi persis seperti yang ditentukan sebelum Anda
  dapat meletakkan kartu Anda.
""",
	'it': """# Moonridge Rummy: Tutti i round e i loro requisiti

Moonridge Rummy è una variante del Liverpool Rummy che si gioca
in sette round, ognuno con una combinazione specifica di set (libri)
e scale (sequenze) che i giocatori devono calare per chiudere. I
requisiti per ogni round diventano progressivamente più
impegnativi. Ecco i requisiti round per round:

      |                                                             | Totale Carte
Round | Requisito                                                   | Necessarie
------|------------------------------------------------------------|------------
  1   | Due libri da tre (2 set di 3 carte)                         | 6
  2   | Un libro da tre e una scala da quattro                      | 7
  3   | Due scale da quattro                                        | 8
  4   | Tre libri da tre                                            | 9
  5   | Due libri da tre e una scala da quattro                     | 10
  6   | Un libro da tre e due scale da quattro                      | 11
  7   | Tre scale da quattro (nessuna carta rimanente, nessuno scarto consentito) | 12

## Spiegazione dei Termini

* Libro (Set/Gruppo):
  Tre o più carte dello stesso valore (es. 8♥ 8♣ 8♠).

* Scala (Sequenza):
  Quattro o più carte consecutive dello stesso seme (es. 3♥ 4♥ 5♥ 6♥).
  Gli assi possono essere alti o bassi, ma le scale non possono "fare il giro" da Re ad Asso a 2.

## Note Speciali

* Nel round finale (Round 7), devi usare tutte le tue carte nelle
  combinazioni richieste e non puoi finire con uno scarto.

* Il contratto per ogni round deve essere soddisfatto esattamente come specificato prima di
  poter calare le tue carte.
""",
	'ja': """# ムーンリッジラミー：全ラウンドとその要件

ムーンリッジラミーはリバプールラミーのバリエーションで、7ラウンドにわたってプレイされます。各ラウンドには、プレイヤーが上がるためにレイダウンしなければならないセット（ブック）とラン（シーケンス）の特定の組み合わせがあります。各ラウンドの要件は徐々に難しくなります。以下はラウンドごとの要件です：

      |                                                             | 合計カード
ラウンド| 要件                                                        | 必要枚数
------|------------------------------------------------------------|------------
  1   | 3枚のブック2組（3枚のカードの2セット）                      | 6
  2   | 3枚のブック1組と4枚のラン1組                                | 7
  3   | 4枚のラン2組                                                | 8
  4   | 3枚のブック3組                                              | 9
  5   | 3枚のブック2組と4枚のラン1組                                | 10
  6   | 3枚のブック1組と4枚のラン2組                                | 11
  7   | 4枚のラン3組（残りカードなし、捨て札不可）                  | 12

## 用語の説明

* ブック（セット/グループ）：
  同じランクの3枚以上のカード（例：8♥ 8♣ 8♠）。

* ラン（シーケンス）：
  同じスートの4枚以上の連続したカード（例：3♥ 4♥ 5♥ 6♥）。
  エースは高くも低くもできますが、ランはキングからエース、2へと「ラップアラウンド」することはできません。

## 特記事項

* 最終ラウンド（ラウンド7）では、必要なメルドですべてのカードを使い切る必要があり、捨て札で終わることはできません。

* 各ラウンドのコントラクトは、カードをレイダウンする前に指定どおりに正確に満たす必要があります。
""",
	'ko': """# 문리지 러미: 모든 라운드와 요구 사항

문리지 러미는 리버풀 러미의 변형으로, 7라운드에 걸쳐 진행됩니다. 각 라운드마다 플레이어가 이기기 위해 내려놓아야 하는 특정 조합의 세트(북)와 런(시퀀스)이 있습니다. 각 라운드의 요구 사항은 점차 더 어려워집니다. 다음은 라운드별 요구 사항입니다.

      |                                                             | 총 카드
라운드 | 요구 사항                                                   | 필요
------|------------------------------------------------------------|------------
  1   | 3장짜리 북 2개 (3장 카드 2세트)                             | 6
  2   | 3장짜리 북 1개와 4장짜리 런 1개                             | 7
  3   | 4장짜리 런 2개                                              | 8
  4   | 3장짜리 북 3개                                              | 9
  5   | 3장짜리 북 2개와 4장짜리 런 1개                             | 10
  6   | 3장짜리 북 1개와 4장짜리 런 2개                             | 11
  7   | 4장짜리 런 3개 (남는 카드 없음, 버리기 불가)                | 12

## 용어 설명

* 북 (세트/그룹):
  같은 랭크의 카드 3장 이상 (예: 8♥ 8♣ 8♠).

* 런 (시퀀스):
  같은 무늬의 연속된 카드 4장 이상 (예: 3♥ 4♥ 5♥ 6♥).
  에이스는 높거나 낮을 수 있지만, 런은 킹에서 에이스, 2로 "이어질" 수 없습니다.

## 특이 사항

* 마지막 라운드(7라운드)에서는 필요한 멜드에 모든 카드를 사용해야 하며, 버리기로 끝낼 수 없습니다.

* 각 라운드의 계약은 카드를 내려놓기 전에 지정된 대로 정확히 충족되어야 합니다.
""",
	'nl': """# Moonridge Rummy: Alle rondes en hun vereisten

Moonridge Rummy is een variant van Liverpool Rummy die wordt gespeeld
over zeven rondes, elk met een specifieke combinatie van sets (boeken)
en runs (reeksen) die spelers moeten neerleggen om uit te gaan. De
vereisten voor elke ronde worden steeds uitdagender.
Hier zijn de vereisten per ronde:

      |                                                             | Totaal Kaarten
Ronde | Vereiste                                                    | Nodig
------|------------------------------------------------------------|------------
  1   | Twee boeken van drie (2 sets van 3 kaarten)                 | 6
  2   | Eén boek van drie en één run van vier                       | 7
  3   | Twee runs van vier                                          | 8
  4   | Drie boeken van drie                                        | 9
  5   | Twee boeken van drie en één run van vier                    | 10
  6   | Eén boek van drie en twee runs van vier                     | 11
  7   | Drie runs van vier (geen resterende kaarten, geen afleg)    | 12

## Uitleg van termen

* Boek (Set/Groep):
  Drie of meer kaarten van dezelfde waarde (bijv. 8♥ 8♣ 8♠).

* Run (Reeks):
  Vier of meer opeenvolgende kaarten van dezelfde soort (bijv. 3♥ 4♥ 5♥ 6♥).
  Azen kunnen hoog of laag zijn, maar runs kunnen niet "rondlopen" van Koning naar Aas naar 2.

## Speciale opmerkingen

* In de laatste ronde (Ronde 7) moet je al je kaarten gebruiken in de vereiste
  melds en kun je niet eindigen met een afleg.

* Het contract voor elke ronde moet exact worden nageleefd zoals gespecificeerd voordat je
  je kaarten kunt neerleggen.
""",
	'pl': """# Moonridge Rummy: Wszystkie rundy i ich wymagania

Moonridge Rummy to odmiana remika Liverpool, w którą gra się
przez siedem rund, każda z określoną kombinacją zestawów (książek)
i sekwensów (biegów), które gracze muszą wyłożyć, aby zakończyć.
Wymagania dla każdej rundy stają się coraz bardziej
wymagające. Oto wymagania dla poszczególnych rund:

      |                                                             | Łączna liczba kart
Runda | Wymaganie                                                   | Potrzebna
------|------------------------------------------------------------|------------
  1   | Dwie książki po trzy (2 zestawy po 3 karty)                 | 6
  2   | Jedna książka po trzy i jeden bieg z czterech               | 7
  3   | Dwa biegi z czterech                                        | 8
  4   | Trzy książki po trzy                                        | 9
  5   | Dwie książki po trzy i jeden bieg z czterech                | 10
  6   | Jedna książka po trzy i dwa biegi z czterech                | 11
  7   | Trzy biegi z czterech (brak pozostałych kart, bez odrzucania)| 12

## Wyjaśnienie terminów

* Książka (Zestaw/Grupa):
  Trzy lub więcej kart tej samej rangi (np. 8♥ 8♣ 8♠).

* Bieg (Sekwens):
  Cztery lub więcej kolejnych kart w tym samym kolorze (np. 3♥ 4♥ 5♥ 6♥).
  Asy mogą być wysokie lub niskie, ale biegi nie mogą "zawijać się" od Króla przez Asa do 2.

## Uwagi specjalne

* W ostatniej rundzie (Runda 7) musisz użyć wszystkich swoich kart w wymaganych
  meldunkach i nie możesz zakończyć odrzuceniem karty.

* Kontrakt na każdą rundę musi być spełniony dokładnie tak, jak określono, zanim
  będziesz mógł wyłożyć swoje karty.
""",
	'pt': """# Moonridge Rummy: Todas as rodadas e seus requisitos

Moonridge Rummy é uma variação do Liverpool Rummy que é jogado
ao longo de sete rodadas, cada uma com uma combinação específica de conjuntos (livros)
e sequências (corridas) que os jogadores devem baixar para sair. Os
requisitos para cada rodada tornam-se progressivamente mais
desafiadores. Aqui estão os requisitos rodada a rodada:

      |                                                             | Total de Cartas
Rodada| Requisito                                                   | Necessárias
------|------------------------------------------------------------|------------
  1   | Dois livros de três (2 conjuntos de 3 cartas)               | 6
  2   | Um livro de três e uma corrida de quatro                    | 7
  3   | Duas corridas de quatro                                     | 8
  4   | Três livros de três                                         | 9
  5   | Dois livros de três e uma corrida de quatro                 | 10
  6   | Um livro de três e duas corridas de quatro                  | 11
  7   | Três corridas de quatro (sem cartas restantes, sem descarte permitido) | 12

## Explicação dos Termos

* Livro (Conjunto/Grupo):
  Três ou mais cartas do mesmo valor (ex: 8♥ 8♣ 8♠).

* Corrida (Sequência):
  Quatro ou mais cartas consecutivas do mesmo naipe (ex: 3♥ 4♥ 5♥ 6♥).
  Ases podem ser altos ou baixos, mas as corridas não podem "dar a volta" do Rei para o Ás para o 2.

## Notas Especiais

* Na rodada final (Rodada 7), você deve usar todas as suas cartas nas
  combinações exigidas e não pode terminar com um descarte.

* O contrato para cada rodada deve ser cumprido exatamente como especificado antes que você
  possa baixar suas cartas.
""",
	'ru': """# Мунридж Рамми: Все раунды и их требования

Мунридж Рамми - это разновидность Ливерпульского Рамми, которая играется
в течение семи раундов, каждый с определенной комбинацией наборов (книг)
и рядов (последовательностей), которые игроки должны выложить, чтобы выйти.
Требования для каждого раунда становятся все более
сложными. Вот требования по раундам:

      |                                                             | Всего карт
Раунд | Требование                                                  | Нужно
------|------------------------------------------------------------|------------
  1   | Две книги по три (2 набора по 3 карты)                      | 6
  2   | Одна книга из трех и один ряд из четырех                    | 7
  3   | Два ряда по четыре                                          | 8
  4   | Три книги по три                                            | 9
  5   | Две книги по три и один ряд из четырех                      | 10
  6   | Одна книга из трех и два ряда по четыре                     | 11
  7   | Три ряда по четыре (без оставшихся карт, без сброса)        | 12

## Объяснение терминов

* Книга (Набор/Группа):
  Три или более карт одного ранга (например, 8♥ 8♣ 8♠).

* Ряд (Последовательность):
  Четыре или более последовательных карт одной масти (например, 3♥ 4♥ 5♥ 6♥).
  Тузы могут быть старшими или младшими, но ряды не могут "заворачиваться" от Короля к Тузу и к 2.

## Особые примечания

* В последнем раунде (Раунд 7) вы должны использовать все свои карты в требуемых
  комбинациях и не можете закончить сбросом.

* Контракт для каждого раунда должен быть выполнен в точности, как указано, прежде чем вы
  сможете выложить свои карты.
""",
	'th': """# มูนริดจ์รัมมี่: ทุกรอบและข้อกำหนด

มูนริดจ์รัมมี่เป็นเกมไพ่ลิเวอร์พูลรัมมี่รูปแบบหนึ่งที่เล่นกันเจ็ดรอบ โดยแต่ละรอบจะมีการผสมผสานระหว่างชุด (หนังสือ) และเรียง (ลำดับ) ที่ผู้เล่นต้องวางเพื่อที่จะชนะ ข้อกำหนดสำหรับแต่ละรอบจะท้าทายมากขึ้นเรื่อยๆ นี่คือข้อกำหนดในแต่ละรอบ:

      |                                                             | การ์ดทั้งหมด
รอบ   | ข้อกำหนด                                                    | ที่ต้องการ
------|------------------------------------------------------------|------------
  1   | หนังสือสองเล่มสามใบ (ชุด 3 ใบ 2 ชุด)                        | 6
  2   | หนังสือหนึ่งเล่มสามใบและเรียงหนึ่งชุดสี่ใบ                   | 7
  3   | เรียงสองชุดสี่ใบ                                            | 8
  4   | หนังสือสามเล่มสามใบ                                         | 9
  5   | หนังสือสองเล่มสามใบและเรียงหนึ่งชุดสี่ใบ                    | 10
  6   | หนังสือหนึ่งเล่มสามใบและเรียงสองชุดสี่ใบ                     | 11
  7   | เรียงสามชุดสี่ใบ (ไม่มีการ์ดเหลือ, ห้ามทิ้ง)                | 12

## คำอธิบายศัพท์

* หนังสือ (ชุด/กลุ่ม):
  ไพ่สามใบขึ้นไปที่มีแต้มเดียวกัน (เช่น 8♥ 8♣ 8♠)

* เรียง (ลำดับ):
  ไพ่สี่ใบขึ้นไปที่เรียงตามลำดับและมีดอกเดียวกัน (เช่น 3♥ 4♥ 5♥ 6♥)
  เอซสามารถเป็นแต้มสูงหรือต่ำก็ได้ แต่การเรียงไม่สามารถ "วน" จากคิงไปเอซไป 2 ได้

## หมายเหตุพิเศษ

* ในรอบสุดท้าย (รอบที่ 7) คุณต้องใช้ไพ่ทั้งหมดของคุณในชุดที่กำหนดและไม่สามารถจบด้วยการทิ้งไพ่ได้

* คุณต้องทำตามสัญญาของแต่ละรอบให้ตรงตามที่กำหนดไว้ก่อนจึงจะสามารถวางไพ่ของคุณได้
""",
	'tr': """# Moonridge Rummy: Tüm Turlar ve Gereksinimleri

Moonridge Rummy, Liverpool Rummy'nin yedi tur üzerinden oynanan
bir çeşididir. Her turda oyuncuların oyunu bitirmek için ortaya
koyması gereken belirli set (kitap) ve sıralı (dizi) kombinasyonları
vardır. Her turun gereksinimleri giderek daha zorlayıcı hale gelir.
İşte tur bazında gereksinimler:

      |                                                             | Toplam Kart
Tur   | Gereksinim                                                  | Gerekli
------|------------------------------------------------------------|------------
  1   | Üçlü iki kitap (2 adet 3 kartlık set)                       | 6
  2   | Üçlü bir kitap ve dörtlü bir sıralı                         | 7
  3   | Dörtlü iki sıralı                                           | 8
  4   | Üçlü üç kitap                                               | 9
  5   | Üçlü iki kitap ve dörtlü bir sıralı                         | 10
  6   | Üçlü bir kitap ve dörtlü iki sıralı                         | 11
  7   | Dörtlü üç sıralı (kalan kart yok, atışa izin verilmez)      | 12

## Terimlerin Açıklaması

* Kitap (Set/Grup):
  Aynı değere sahip üç veya daha fazla kart (ör. 8♥ 8♣ 8♠).

* Sıralı (Dizi):
  Aynı türden dört veya daha fazla ardışık kart (ör. 3♥ 4♥ 5♥ 6♥).
  Aslar yüksek veya düşük olabilir, ancak sıralılar Papaz'dan As'a ve 2'ye "dönemez".

## Özel Notlar

* Son turda (Tur 7), tüm kartlarınızı gerekli meldlerde kullanmalı
  ve bir atışla bitiremezsiniz.

* Her turun sözleşmesi, kartlarınızı ortaya koymadan önce belirtildiği
  gibi tam olarak karşılanmalıdır.
""",
	'zh-Hans': """# 月岭拉米牌：所有回合及其要求

月岭拉米牌是利物浦拉米牌的一种变体，共进行七个回合，每个回合都有一组特定的牌组（书）和顺子（序列），玩家必须打出这些牌才能出局。每个回合的要求会逐渐变得更具挑战性。以下是每个回合的要求：

      |                                                             | 总牌数
回合 | 要求                                                        | 需要
------|------------------------------------------------------------|------------
  1   | 两本三张（2组3张牌）                                        | 6
  2   | 一本三张和一个四张的顺子                                    | 7
  3   | 两个四张的顺子                                              | 8
  4   | 三本三张                                                    | 9
  5   | 两本三张和一个四张的顺子                                    | 10
  6   | 一本三张和两个四张的顺子                                    | 11
  7   | 三个四张的顺子（无剩余牌，不允许出牌）                      | 12

## 术语解释

* 书（组/套）：
  三张或更多相同点数的牌（例如，8♥ 8♣ 8♠）。

* 顺子（序列）：
  四张或更多相同花色的连续牌（例如，3♥ 4♥ 5♥ 6♥）。
  A可以当最大或最小的牌，但顺子不能“环绕”，例如从K到A到2。

## 特别说明

* 在最后一回合（第7回合），您必须在所需的组合中使用所有牌，并且不能以出牌结束。

* 在出牌之前，必须完全满足每个回合的合同要求。
""",
	'zh-Hant': """# 月嶺拉米牌：所有回合及其要求

月嶺拉米牌是利物浦拉米牌的一種變體，共進行七個回合，每個回合都有一組特定的牌組（書）和順子（序列），玩家必須打出這些牌才能出局。每個回合的要求會逐漸變得更具挑戰性。以下是每個回合的要求：

      |                                                             | 總牌數
回合 | 要求                                                        | 需要
------|------------------------------------------------------------|------------
  1   | 兩本三張（2組3張牌）                                        | 6
  2   | 一本三張和一個四張的順子                                    | 7
  3   | 兩個四張的順子                                              | 8
  4   | 三本三張                                                    | 9
  5   | 兩本三張和一個四張的順子                                    | 10
  6   | 一本三張和兩個四張的順子                                    | 11
  7   | 三個四張的順子（無剩餘牌，不允許出牌）                      | 12

## 術語解釋

* 書（組/套）：
  三張或更多相同點數的牌（例如，8♥ 8♣ 8♠）。

* 順子（序列）：
  四張或更多相同花色的連續牌（例如，3♥ 4♥ 5♥ 6♥）。
  A可以當最大或最小的牌，但順子不能“環繞”，例如從K到A到2。

## 特別說明

* 在最後一回合（第7回合），您必須在所需的組合中使用所有牌，並且不能以出牌結束。

* 在出牌之前，必須完全滿足每個回合的合同要求。
""",
}