import Foundation

// MARK: - LyricsRomanizer
/// Transliterates non-Latin lyrics (Urdu, Punjabi, Hindi, Bengali, Arabic, Cyrillic, CJK, etc.)
/// into natural, singable Latin script (Roman Urdu / Roman Punjabi / Romanized text) for the notch.
public final class LyricsRomanizer: Sendable {
    public static let shared = LyricsRomanizer()
    
    // MARK: - Comprehensive Urdu & Punjabi Lyrics Dictionary
    /// Extensive vocabulary covering the most common lyrics words in Urdu, Punjabi, and Hindi,
    /// ensuring accurate spelling and proper vowelization (e.g. "سن ذرا" -> "sun zara", "دل" -> "dil").
    private let lyricsDictionary: [String: String]
    
    public init() {
        var d: [String: String] = [:]
        
        // --- Core Lyric Particles, Conjunctions & Modifiers ---
        d["سن"] = "sun"
        d["سُنو"] = "suno"
        d["سنو"] = "suno"
        d["ذرا"] = "zara"
        d["ہی"] = "hi"
        d["بھی"] = "bhi"
        d["نہ"] = "na"
        d["نا"] = "na"
        d["نہیں"] = "nahin"
        d["نئیں"] = "nayin"
        d["ہاں"] = "haan"
        d["اور"] = "aur"
        d["کہ"] = "ke"
        d["یا"] = "ya"
        d["تو"] = "to"
        d["تُو"] = "tu"
        d["سا"] = "sa"
        d["سی"] = "si"
        d["سے"] = "se"
        d["سو"] = "so"
        d["پہ"] = "pe"
        d["پر"] = "par"
        d["تک"] = "tak"
        d["اب"] = "ab"
        d["جب"] = "jab"
        d["تب"] = "tab"
        d["سب"] = "sab"
        d["سبھی"] = "sabhi"
        d["کب"] = "kab"
        d["ہر"] = "har"
        
        // --- Pronouns & Demonstratives ---
        d["میں"] = "main"
        d["مینوں"] = "mainu"
        d["ہم"] = "hum"
        d["ہمیں"] = "humein"
        d["توں"] = "toon"
        d["تینوں"] = "tenu"
        d["تم"] = "tum"
        d["تمہیں"] = "tumhein"
        d["آپ"] = "aap"
        d["وہ"] = "woh"
        d["یہ"] = "yeh"
        d["اس"] = "is"
        d["اسے"] = "ise"
        d["اسکو"] = "isko"
        d["اسکی"] = "iski"
        d["اسکے"] = "iske"
        d["ان"] = "in"
        d["انہیں"] = "unhein"
        d["انکو"] = "unko"
        d["انکی"] = "unki"
        d["انکے"] = "unke"
        d["جو"] = "jo"
        d["جس"] = "jis"
        d["جسے"] = "jise"
        d["جسکو"] = "jisko"
        d["جسکی"] = "jiski"
        d["جسکے"] = "jiske"
        d["کون"] = "kaun"
        d["کوئی"] = "koi"
        d["کچھ"] = "kuch"
        d["کس"] = "kis"
        d["کسی"] = "kisi"
        d["کیا"] = "kya"
        d["کیوں"] = "kyun"
        d["کہاں"] = "kahan"
        d["یہاں"] = "yahan"
        d["وہاں"] = "wahan"
        d["جہاں"] = "jahan"
        
        // --- Possessives & Postpositions ---
        d["میرا"] = "mera"
        d["میری"] = "meri"
        d["میرے"] = "mere"
        d["تیرا"] = "tera"
        d["تیری"] = "teri"
        d["تیرے"] = "tere"
        d["ہمارا"] = "hamara"
        d["ہماری"] = "hamari"
        d["ہمارے"] = "hamare"
        d["تمہارا"] = "tumhara"
        d["تمہاری"] = "tumhari"
        d["تمہارے"] = "tumhare"
        d["اپنا"] = "apna"
        d["اپنی"] = "apni"
        d["اپنے"] = "apne"
        d["کا"] = "ka"
        d["کی"] = "ki"
        d["کے"] = "ke"
        d["کو"] = "ko"
        d["نے"] = "ne"
        d["بن"] = "bin"
        d["بنا"] = "bina"
        d["ساتھ"] = "saath"
        d["پاس"] = "paas"
        d["دور"] = "door"
        
        // --- Copulas & Auxiliaries ---
        d["ہے"] = "hai"
        d["ہیں"] = "hain"
        d["ہو"] = "ho"
        d["ہوں"] = "hoon"
        d["تھا"] = "tha"
        d["تھی"] = "thi"
        d["تھے"] = "the"
        d["ہوگا"] = "hoga"
        d["ہوگی"] = "hogi"
        d["ہوگے"] = "hoge"
        d["ہوتا"] = "hota"
        d["ہوتی"] = "hoti"
        d["ہوتے"] = "hote"
        d["ہوئے"] = "huye"
        d["ہوا"] = "hua"
        d["ہوئی"] = "hui"
        
        // --- High-Frequency Lyric Verbs ---
        // Sun (Listen/Hear)
        d["سنا"] = "suna"
        d["سنی"] = "suni"
        d["سنے"] = "sune"
        d["سنتا"] = "sunta"
        d["سنتی"] = "sunti"
        d["سنتے"] = "sunte"
        d["سناتا"] = "sunata"
        d["سناتی"] = "sunati"
        d["سناتے"] = "sunate"
        d["سنایا"] = "sunaaya"
        d["سنائی"] = "sunaayi"
        d["سنائے"] = "sunaaye"
        d["سنانا"] = "sunaana"
        
        // Dekh (See/Look)
        d["دیکھ"] = "dekh"
        d["دیکھو"] = "dekho"
        d["دیکھا"] = "dekha"
        d["دیکھی"] = "dekhi"
        d["دیکھے"] = "dekhe"
        d["دیکھتا"] = "dekhta"
        d["دیکھتی"] = "dekhti"
        d["دیکھتے"] = "dekhte"
        
        // Bol / Keh (Say/Speak)
        d["بول"] = "bol"
        d["بولو"] = "bolo"
        d["بولا"] = "bola"
        d["بولی"] = "boli"
        d["بولے"] = "bole"
        d["کہہ"] = "keh"
        d["کہو"] = "kaho"
        d["کہا"] = "kaha"
        d["کہی"] = "kahi"
        d["کہے"] = "kahe"
        
        // Aa / Ja (Come/Go)
        d["آ"] = "aa"
        d["آؤ"] = "aao"
        d["آیا"] = "aaya"
        d["آئی"] = "aayi"
        d["آئے"] = "aaye"
        d["آتا"] = "aata"
        d["آتی"] = "aati"
        d["آتے"] = "aate"
        d["آنا"] = "aana"
        d["جا"] = "jaa"
        d["جاؤ"] = "jaao"
        d["گیا"] = "gaya"
        d["گئی"] = "gayi"
        d["گئے"] = "gaye"
        d["جاتا"] = "jaata"
        d["جاتی"] = "jaati"
        d["جاتے"] = "jaate"
        d["جانا"] = "jaana"
        
        // Reh / Chal (Stay/Walk)
        d["رہ"] = "reh"
        d["رہو"] = "raho"
        d["رہا"] = "raha"
        d["رہی"] = "rahi"
        d["رہے"] = "rahe"
        d["رہتا"] = "rehta"
        d["رہتی"] = "rehti"
        d["رہتے"] = "rehte"
        d["چل"] = "chal"
        d["چلو"] = "chalo"
        d["چلا"] = "chala"
        d["چلی"] = "chali"
        d["چلے"] = "chale"
        
        // Kar (Do)
        d["کر"] = "kar"
        d["کرو"] = "karo"
        d["کرتا"] = "karta"
        d["کرتی"] = "karti"
        d["کرتے"] = "karte"
        d["کیا"] = "kiya"
        d["کئے"] = "kiye"
        d["کیے"] = "kiye"
        d["کرنا"] = "karna"
        
        // De / Le (Give/Take)
        d["دے"] = "de"
        d["دو"] = "do"
        d["دیا"] = "diya"
        d["دیے"] = "diye"
        d["دینا"] = "dena"
        d["لے"] = "le"
        d["لو"] = "lo"
        d["لیا"] = "liya"
        d["لیے"] = "liye"
        d["لینا"] = "lena"
        
        // Mil (Meet)
        d["مل"] = "mil"
        d["ملو"] = "milo"
        d["ملا"] = "mila"
        d["ملی"] = "mili"
        d["ملے"] = "mile"
        d["ملتا"] = "milta"
        d["ملتی"] = "milti"
        d["ملتے"] = "milte"
        
        // Samajh / Hans / Ro
        d["سمجھ"] = "samajh"
        d["سمجھا"] = "samajha"
        d["سمجھی"] = "samajhi"
        d["سمجھے"] = "samajhe"
        d["ہنس"] = "hans"
        d["ہنسا"] = "hansa"
        d["ہنسی"] = "hansi"
        d["ہنسے"] = "hanse"
        d["رو"] = "ro"
        d["رویا"] = "roya"
        d["روئی"] = "royi"
        d["روئے"] = "roye"
        
        // Jaga / Sula / Toot / Lag / Chah
        d["جگا"] = "jaga"
        d["سو"] = "so"
        d["سونا"] = "soona"
        d["ٹوٹ"] = "toot"
        d["ٹوٹا"] = "toota"
        d["ٹوٹی"] = "tooti"
        d["ٹوٹے"] = "toote"
        d["چھپا"] = "chhupa"
        d["چھپی"] = "chhupi"
        d["چھپے"] = "chhupe"
        d["پھنسا"] = "phansa"
        d["پھنسی"] = "phansi"
        d["پھنسے"] = "phanse"
        d["مٹا"] = "mita"
        d["مٹانا"] = "mitaana"
        d["مٹایا"] = "mitaaya"
        d["جتا"] = "jata"
        d["جتانا"] = "jataana"
        d["جتایا"] = "jataaya"
        d["بتا"] = "bata"
        d["بتاؤ"] = "batao"
        d["بتانا"] = "bataana"
        d["بتایا"] = "bataaya"
        d["لگ"] = "lag"
        d["لگو"] = "lago"
        d["لگا"] = "laga"
        d["لگی"] = "lagi"
        d["لگے"] = "lage"
        d["لگوں"] = "lagoon"
        d["چاہ"] = "chaah"
        d["چاہو"] = "chaaho"
        d["چاہا"] = "chaaha"
        d["چاہی"] = "chaahi"
        d["چاہے"] = "chaahe"
        d["چاہیے"] = "chahiye"
        d["ستا"] = "sata"
        d["ستایا"] = "sataaya"
        d["ستائے"] = "sataaye"
        d["گا"] = "ga"
        d["گایا"] = "gaaya"
        d["گائے"] = "gaaye"
        d["دھڑک"] = "dhadak"
        d["دھڑکا"] = "dhadka"
        d["دھڑکنے"] = "dhadakne"
        d["نکال"] = "nikaal"
        d["نکالا"] = "nikaala"
        d["نکالی"] = "nikaali"
        d["نکالے"] = "nikaale"
        d["بہکا"] = "behka"
        d["بہکی"] = "behki"
        d["بہکے"] = "behke"
        
        // --- Poetic Nouns & Concepts ---
        d["دل"] = "dil"
        d["جان"] = "jaan"
        d["روح"] = "rooh"
        d["عشق"] = "ishq"
        d["محبت"] = "mohabbat"
        d["پیار"] = "pyaar"
        d["یار"] = "yaar"
        d["یارا"] = "yaara"
        d["صنم"] = "sanam"
        d["دوست"] = "dost"
        d["آنسو"] = "aansu"
        d["آنسوؤں"] = "aansuon"
        d["آنکھ"] = "aankh"
        d["آنکھیں"] = "aankhein"
        d["نظر"] = "nazar"
        d["نظریں"] = "nazrein"
        d["نگاہ"] = "nigaah"
        d["نگاہیں"] = "nigaahein"
        d["ادا"] = "ada"
        d["ادائیں"] = "adaayein"
        d["فدا"] = "fida"
        d["بیتابیاں"] = "betaabiyan"
        d["جال"] = "jaal"
        d["چاند"] = "chaand"
        d["سورج"] = "sooraj"
        d["تارے"] = "taare"
        d["بادل"] = "baadal"
        d["آنچل"] = "aanchal"
        d["حال"] = "haal"
        d["بات"] = "baat"
        d["باتیں"] = "baatein"
        d["رات"] = "raat"
        d["راتیں"] = "raatein"
        d["دن"] = "din"
        d["صبح"] = "subah"
        d["شام"] = "shaam"
        d["زمانہ"] = "zamaana"
        d["دنیا"] = "duniya"
        d["محفل"] = "mehfil"
        d["رائے"] = "raaye"
        d["بندہ"] = "banda"
        d["قاتل"] = "qaatil"
        d["وجہ"] = "wajah"
        d["نقص"] = "nuqs"
        d["احسان"] = "ehsaan"
        d["احسانوں"] = "ehsaanon"
        d["گلے"] = "gale"
        d["یاد"] = "yaad"
        d["یادیں"] = "yaadein"
        d["درد"] = "dard"
        d["غم"] = "gham"
        d["خوشی"] = "khushi"
        d["زندگی"] = "zindagi"
        d["پوری"] = "poori"
        d["مجھی"] = "mujhi"
        d["سکا"] = "saka"
        d["سکی"] = "saki"
        d["سکے"] = "sake"
        d["رب"] = "rabb"
        d["سچ"] = "sach"
        d["جھوٹ"] = "jhooth"
        d["ہوا"] = "hawa"
        d["قدم"] = "qadam"
        d["سفر"] = "safar"
        d["راستہ"] = "raasta"
        d["راستے"] = "raaste"
        d["خواب"] = "khwaab"
        
        // --- Punjabi Specific Vocabulary ---
        d["سانوں"] = "saanu"
        d["تہانوں"] = "tuhanu"
        d["نوں"] = "nu"
        d["نال"] = "naal"
        d["دیاں"] = "diyan"
        d["گلاں"] = "gallan"
        d["آواں"] = "aavan"
        d["جاواں"] = "jaavan"
        d["ہووے"] = "hove"
        d["ہووےگا"] = "hovega"
        d["ہووےگی"] = "hovegi"
        d["ہوویگی"] = "hovegi"
        d["آواںگا"] = "aavanga"
        d["آواںگی"] = "aavangi"
        d["جاواںگا"] = "jaavanga"
        d["جاواںگی"] = "jaavangi"
        d["اگ"] = "agg"
        d["لاہواں"] = "laawan"
        d["مجبوری"] = "majboori"
        d["آݨ"] = "aan"
        d["جاݨ"] = "jaan"
        d["دی"] = "di"
        d["ਦਾ"] = "da"
        d["ਦੇ"] = "de"
        d["ਭਸੂੜੀ"] = "bhasoori"
        d["بھسوڑی"] = "bhasoori"
        d["زہر"] = "zehar"
        d["بݨے"] = "bane"
        d["پی"] = "pee"
        d["اکھ"] = "akh"
        d["چن"] = "chann"
        d["ਕਟੋਰੇ"] = "katore"
        d["ਦੁੱਧ"] = "doodh"
        d["ਵਾਂਗੂ"] = "vangu"
        d["ਸੁਹਾਨੀ"] = "suhani"
        d["ਰਾਤ"] = "raat"
        d["ਹੋਵੇਗੀ"] = "hovegi"
        d["ਜਦੋਂ"] = "jadon"
        d["ਜਦੋ"] = "jadon"
        d["ਜਦ"] = "jad"
        d["ਚੰਨ"] = "chann"
        d["ਵੇਖੇਂਗੀ"] = "vekhengi"
        d["ਤੇਰੀ"] = "teri"
        d["ਅੱਖ"] = "akh"
        d["ਰੋਵੇਗੀ"] = "rovegi"
        d["ਮੈਂ"] = "main"
        d["ਤੈਨੂੰ"] = "tenu"
        d["ਯਾਦ"] = "yaad"
        d["ਆਵਾਂਗਾ"] = "aavanga"
        d["ਗੇੜੀ"] = "gedi"
        d["ਸਿੱਧੀ"] = "sidhi"
        d["ਦੇਸੀ"] = "desi"
        d["ਮੁੰਡਿਆਂ"] = "mundeyan"
        d["ਵਿੱਚ"] = "vich"
        
        self.lyricsDictionary = d
    }
    
    // MARK: - Script Detection
    /// Determines whether a string contains any non-Latin characters needing transliteration.
    public func containsNonLatin(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if (v >= 0x0600 && v <= 0x08FF) || // Arabic / Urdu / Shahmukhi
               (v >= 0x0900 && v <= 0x0D7F) || // Indic (Devanagari, Gurmukhi, Bengali, Gujarati, Tamil, Telugu, etc.)
               (v >= 0x0400 && v <= 0x04FF) || // Cyrillic
               (v >= 0x0370 && v <= 0x03FF) || // Greek
               (v >= 0x3040 && v <= 0x30FF) || // Hiragana / Katakana
               (v >= 0x4E00 && v <= 0x9FFF) || // CJK Hanzi / Kanji
               (v >= 0xAC00 && v <= 0xD7AF)    // Korean Hangul
            {
                return true
            }
        }
        return false
    }
    
    // MARK: - Main Romanization Entry Point
    /// Converts a line of lyrics into natural, singable Latin script.
    /// Preserves existing English/Latin words intact (e.g. "It's obvious, میں تیرے ہی جال میں پھنسا").
    public func romanize(_ text: String) -> String {
        guard containsNonLatin(text) else { return text }
        
        let tokens = text.components(separatedBy: " ")
        var romanizedTokens: [String] = []
        
        for token in tokens {
            if !containsNonLatin(token) {
                // Pure Latin or numbers/English words (e.g. "It's", "obvious,", "truck"): preserve untouched!
                romanizedTokens.append(token)
                continue
            }
            
            // Extract leading and trailing punctuation (preserve internal apostrophes/hyphens)
            var raw = token
            var leadingPunct = ""
            var trailingPunct = ""
            
            let punctuationSet = CharacterSet(charactersIn: "!\"#$%&()*+,-./:;<=>?@[\\]^_`{|}~।؟،؛")
            
            while let first = raw.first, String(first).rangeOfCharacter(from: punctuationSet) != nil {
                leadingPunct.append(first)
                raw.removeFirst()
            }
            while let last = raw.last, String(last).rangeOfCharacter(from: punctuationSet) != nil {
                // Map Arabic punctuation to standard equivalents
                if last == "،" {
                    trailingPunct = "," + trailingPunct
                } else if last == "؟" {
                    trailingPunct = "?" + trailingPunct
                } else if last == "।" {
                    trailingPunct = "." + trailingPunct
                } else if last == "؛" {
                    trailingPunct = ";" + trailingPunct
                } else {
                    trailingPunct = String(last) + trailingPunct
                }
                raw.removeLast()
            }
            
            let romanizedWord = romanizeSingleWord(raw)
            romanizedTokens.append(leadingPunct + romanizedWord + trailingPunct)
        }
        
        var result = romanizedTokens.joined(separator: " ")
        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Script Group Detection
    
    private enum ScriptGroup {
        case arabic   // Urdu / Shahmukhi / Arabic (0600-08FF)
        case indic    // Devanagari / Bengali / Gujarati / Tamil etc. (0900-0D7F, excluding Gurmukhi)
        case gurmukhi // Punjabi Gurmukhi (0A00-0A7F)
        case other    // Cyrillic, CJK, Korean, etc.
    }
    
    /// Detects the dominant non-Latin script in a text for optimal GTX source language selection.
    private func detectDominantScript(_ text: String) -> ScriptGroup {
        var arabicCount = 0
        var indicCount = 0
        var gurmukhiCount = 0
        var otherCount = 0
        
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if v >= 0x0600 && v <= 0x08FF {
                arabicCount += 1
            } else if v >= 0x0A00 && v <= 0x0A7F {
                gurmukhiCount += 1
            } else if v >= 0x0900 && v <= 0x0D7F {
                indicCount += 1
            } else if (v >= 0x0400 && v <= 0x04FF) || (v >= 0x0370 && v <= 0x03FF) ||
                      (v >= 0x3040 && v <= 0x30FF) || (v >= 0x4E00 && v <= 0x9FFF) ||
                      (v >= 0xAC00 && v <= 0xD7AF) {
                otherCount += 1
            }
        }
        
        let max = max(arabicCount, indicCount, gurmukhiCount, otherCount)
        if max == 0 { return .other }
        if arabicCount == max { return .arabic }
        if indicCount == max { return .indic }
        if gurmukhiCount == max { return .gurmukhi }
        return .other
    }
    
    /// Returns the best GTX `sl=` source language parameter for a script group.
    private func sourceLanguage(for script: ScriptGroup) -> String {
        switch script {
        case .arabic: return "ur"
        case .indic: return "hi"
        case .gurmukhi: return "pa"
        case .other: return "auto"
        }
    }
    
    // MARK: - Neural ML Transliteration (Batch Engine)
    /// Converts a batch of lyric lines using neural ML transliteration for high-accuracy vowel restoration,
    /// and refines them with our lyric vocabulary and natural spelling conventions.
    /// Automatically falls back to offline dictionary and phonetic rules if network is unavailable.
    /// Handles payload chunking for long songs and per-script batching for consistent output.
    public func romanizeBatch(_ texts: [String]) async -> [String] {
        guard !texts.isEmpty else { return [] }
        
        // Step 1: Filter non-empty non-Latin lines and track their original indices
        var nonLatinIndices: [Int] = []
        var linesToTranslate: [String] = []
        
        for (i, t) in texts.enumerated() {
            let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && containsNonLatin(trimmed) {
                nonLatinIndices.append(i)
                linesToTranslate.append(trimmed)
            }
        }
        
        guard !linesToTranslate.isEmpty else {
            return texts
        }
        
        // Step 2: Detect dominant script for source language parameter
        let allNonLatin = linesToTranslate.joined(separator: " ")
        let dominantScript = detectDominantScript(allNonLatin)
        let sourceLang = sourceLanguage(for: dominantScript)
        
        // Step 3: Chunk lines to stay under GTX payload limit (~5000 UTF-8 bytes per chunk)
        let maxBatchBytes = 4500
        var chunks: [[String]] = []
        var currentChunk: [String] = []
        var currentBytes = 0
        
        for line in linesToTranslate {
            let lineBytes = line.utf8.count + 1 // +1 for \n separator
            if currentBytes + lineBytes > maxBatchBytes && !currentChunk.isEmpty {
                chunks.append(currentChunk)
                currentChunk = [line]
                currentBytes = lineBytes
            } else {
                currentChunk.append(line)
                currentBytes += lineBytes
            }
        }
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        // Step 4: Send each chunk to GTX and collect results
        var allRomanizedLines: [String] = []
        
        for chunk in chunks {
            let chunkResult = await sendGTXBatch(chunk, sourceLang: sourceLang)
            allRomanizedLines.append(contentsOf: chunkResult)
        }
        
        // Step 5: Map romanized lines back to original positions
        var output = texts
        for (k, targetIndex) in nonLatinIndices.enumerated() {
            if k < allRomanizedLines.count {
                output[targetIndex] = allRomanizedLines[k]
            }
            // If somehow missing, leave original text (better than garbage)
        }
        
        return output
    }
    
    /// Sends a single chunk of lines to the GTX transliteration endpoint.
    /// Returns an array of romanized lines matching the input count.
    private func sendGTXBatch(_ lines: [String], sourceLang: String) async -> [String] {
        let combined = lines.joined(separator: "\n")
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: sourceLang),
            URLQueryItem(name: "tl", value: "en"),
            URLQueryItem(name: "dt", value: "rm"),
            URLQueryItem(name: "q", value: combined)
        ]
        
        guard let url = components?.url else {
            return lines.map { romanize($0) }
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [Any],
                  let firstArr = json.first as? [Any] else {
                return lines.map { romanize($0) }
            }
            
            var fullRomanizedText = ""
            for item in firstArr {
                if let block = item as? [Any], block.count > 3, let chunk = block[3] as? String {
                    fullRomanizedText += chunk
                }
            }
            
            let romanizedLines = fullRomanizedText.components(separatedBy: "\n")
            
            if romanizedLines.count == lines.count {
                return zip(lines, romanizedLines).map { (orig, mlRoman) in
                    refineMLRomanizedLine(orig: orig, mlRoman: mlRoman)
                }
            } else if !romanizedLines.isEmpty {
                // Slight count mismatch (trailing newlines, etc.) — map what we have, fallback the rest
                return lines.enumerated().map { (k, orig) in
                    if k < romanizedLines.count && !romanizedLines[k].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return refineMLRomanizedLine(orig: orig, mlRoman: romanizedLines[k])
                    } else {
                        return romanize(orig)
                    }
                }
            } else {
                return lines.map { romanize($0) }
            }
        } catch {
            return lines.map { romanize($0) }
        }
    }
    
    // MARK: - ML Output Refinement
    
    private func refineMLRomanizedLine(orig: String, mlRoman: String) -> String {
        guard !mlRoman.isEmpty else { return orig }
        var s = mlRoman
        
        // Step 1: IAST-to-natural conversion BEFORE stripping diacritics
        // This preserves vowel length information (ā → aa, ī → ee, ū → oo)
        // and fixes IAST consonant conventions (c → ch)
        s = convertIASTToNatural(s)
        
        // Step 2: Strip any remaining diacritics
        let mut = NSMutableString(string: s)
        CFStringTransform(mut, nil, kCFStringTransformStripDiacritics, false)
        s = mut as String
        
        // Step 3: Apply word-level normalizations
        let tokens = s.components(separatedBy: " ")
        let refined = tokens.map { tok -> String in
            var leadingPunct = ""
            var trailingPunct = ""
            var core = tok
            while let f = core.first, f.isPunctuation {
                leadingPunct.append(f)
                core.removeFirst()
            }
            while let l = core.last, l.isPunctuation {
                trailingPunct.insert(l, at: trailingPunct.startIndex)
                core.removeLast()
            }
            
            let clean = core.lowercased()
            if let repl = standardWordMap[clean] {
                let formattedRepl: String
                if core.first?.isUppercase == true {
                    formattedRepl = repl.capitalized
                } else {
                    formattedRepl = repl
                }
                return leadingPunct + formattedRepl + trailingPunct
            }
            return tok
        }
        
        var res = refined.joined(separator: " ")
        res = res.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return res
    }
    
    /// Converts IAST (International Alphabet of Sanskrit Transliteration) diacritics
    /// into natural Hinglish/Roman Urdu conventions before generic diacritics stripping.
    private func convertIASTToNatural(_ text: String) -> String {
        var s = text
        
        // Long vowel digraphs (must come before single-char replacements)
        // Combined forms first to prevent partial matches
        s = s.replacingOccurrences(of: "āī", with: "aayi")
        s = s.replacingOccurrences(of: "āē", with: "aaye")
        s = s.replacingOccurrences(of: "āō", with: "aao")
        
        // Nasalized vowels with anusvara/chandrabindu (before vowel replacements)
        s = s.replacingOccurrences(of: "ām̐", with: "aan")
        s = s.replacingOccurrences(of: "āṁ", with: "aan")
        s = s.replacingOccurrences(of: "ēṁ", with: "ein")
        s = s.replacingOccurrences(of: "ēṅ", with: "ein")
        s = s.replacingOccurrences(of: "ē̃", with: "ein")
        s = s.replacingOccurrences(of: "ōṁ", with: "on")
        s = s.replacingOccurrences(of: "ō̃", with: "on")
        s = s.replacingOccurrences(of: "ūṁ", with: "oon")
        s = s.replacingOccurrences(of: "ū̃", with: "oon")
        s = s.replacingOccurrences(of: "īṁ", with: "een")
        s = s.replacingOccurrences(of: "ī̃", with: "een")
        s = s.replacingOccurrences(of: "aiṁ", with: "ain")
        s = s.replacingOccurrences(of: "aṁ", with: "an")
        s = s.replacingOccurrences(of: "uṁ", with: "un")
        s = s.replacingOccurrences(of: "iṁ", with: "in")
        
        // Long vowels → natural singable Latin script conventions
        // Special grammatical suffix forms first
        s = s.replacingOccurrences(of: "āvāṅgā", with: "aavanga")
        s = s.replacingOccurrences(of: "āvāṅgī", with: "aavangi")
        s = s.replacingOccurrences(of: "āvā", with: "aava")
        
        s = s.replacingOccurrences(of: "ā", with: "aa")
        s = s.replacingOccurrences(of: "ī", with: "i")
        s = s.replacingOccurrences(of: "ū", with: "u")
        s = s.replacingOccurrences(of: "ē", with: "e")
        s = s.replacingOccurrences(of: "ō", with: "o")
        
        // Retroflex/nasal consonants
        s = s.replacingOccurrences(of: "ṁ", with: "n")
        s = s.replacingOccurrences(of: "ṅ", with: "n")
        s = s.replacingOccurrences(of: "ñ", with: "n")
        s = s.replacingOccurrences(of: "ṇ", with: "n")
        s = s.replacingOccurrences(of: "ṭ", with: "t")
        s = s.replacingOccurrences(of: "ḍ", with: "d")
        s = s.replacingOccurrences(of: "ṛ", with: "r")
        
        // Sibilants
        s = s.replacingOccurrences(of: "ś", with: "sh")
        s = s.replacingOccurrences(of: "ṣ", with: "sh")
        
        // Aspiration marker and visarga
        s = s.replacingOccurrences(of: "ʱ", with: "h")
        s = s.replacingOccurrences(of: "ḥ", with: "h")
        
        // IAST 'c' = Hindi 'ch' — must be careful not to double existing 'ch'
        // Replace 'c' only when NOT already preceded by or followed by 'h' forming 'ch'
        // First protect existing 'ch' sequences
        s = s.replacingOccurrences(of: "chh", with: "ʘCHHʘ") // protect chh (aspirate)
        s = s.replacingOccurrences(of: "ch", with: "ʘCHʘ")   // protect ch
        s = s.replacingOccurrences(of: "c", with: "ch")        // IAST c → ch
        s = s.replacingOccurrences(of: "ʘCHHʘ", with: "chh")  // restore chh
        s = s.replacingOccurrences(of: "ʘCHʘ", with: "ch")    // restore ch
        
        // Chandrabindu combining mark
        s = s.replacingOccurrences(of: "\u{0310}", with: "n") // combining chandrabindu
        s = s.replacingOccurrences(of: "m̐", with: "n")
        
        // Clean up IAST artifacts
        s = s.replacingOccurrences(of: "y̰", with: "y")
        s = s.replacingOccurrences(of: "ḵẖ", with: "kh")
        s = s.replacingOccurrences(of: "◌̃", with: "n")
        s = s.replacingOccurrences(of: "◌", with: "")
        s = s.replacingOccurrences(of: "'", with: "")
        
        return s
    }
    
    // MARK: - Standard Word Normalizer
    /// Maps common GTX romanization variants to natural colloquial Roman Urdu/Hindi/Punjabi spelling.
    private let standardWordMap: [String: String] = [
        // Pronouns & particles
        "min": "main", "mein": "main", "maim": "main",
        "tam": "tum",
        "ham": "hum",
        "men": "mein", "mem": "mein",
        "hun": "hoon",
        "hen": "hain",
        "hay": "hai",
        "kah": "ke",
        "ya": "ye",
        "pah": "pe",
        "tu": "tu", "too": "tu",
        "ve": "ve",
        
        // Negation & conjunctions
        "nihen": "nahin", "nahen": "nahin",
        "lican": "lekin", "lecan": "lekin",
        
        // Possessives
        "tira": "tera", "tiraa": "tera",
        "tiri": "teri", "tiree": "teri",
        "tire": "tere",
        "tamahen": "tumhein", "tamahin": "tumhein",
        
        // Common nouns
        "dal": "dil",
        "bat": "baat",
        "batin": "baatein",
        "bation": "baaton",
        "raat": "raat",
        "sath": "saath",
        "duri": "doori",
        "dudha": "doodh",
        "stare": "sitare",
        
        // Verb forms
        "san": "sun",
        "huvay": "huye",
        "huway": "huye",
        "totay": "toote", "tote": "toote",
        "tanaha": "tanha",
        "ruktey": "rakhte",
        "gayi": "gayi",
        "gaya": "gaya",
        "gaye": "gaye",
        "hoi": "huyi",
        "rahin": "rahein",
        
        // Punjabi & Gurmukhi
        "vica": "vich",
        "kaci": "kachi",
        "yada": "yaad",
        "yaada": "yaad",
        "avanga": "aavanga",
        "aavaangaa": "aavanga",
        "aavangaa": "aavanga",
        "mainu": "mainu",
        "tainu": "tenu",
        "tainuu": "tenu",
        "launga": "laung",
        "laci": "laachi",
        "laaci": "laachi",
        "laachee": "laachi",
        "gavaci": "gavachi",
        "gavaaci": "gavachi",
        "gavaachee": "gavaachi",
        
        // Common GTX variants
        "kisa": "kaisa",
        "kise": "kaise",
        "ese": "aise",
        "mujaburi": "majboori",
        "amidon": "ummeedon",
        "pahuni": "pehni",
        "sanin": "sunein",
        "dalase": "dilaase",
        "chare": "chaare",
        "dhra": "zara",
        "dara": "zara",
        "dharne": "dharne",
        "shamon": "shaamon",
        "akhiyan": "akhiyan",
        "akhian": "akhiyan",
        
        // IAST post-strip artifacts (after convertIASTToNatural + strip)
        "calata": "chalta", "calataa": "chaltaa",
        "accha": "acchha", "acchaa": "achhaa",
        "rakhana": "rakhna", "rakhanaa": "rakhna",
        "raataa": "raat",
        "baataa": "baat",
        
        // Extended vocabulary from testing
        "kach": "kuch", "kachh": "kuch",
        "phar": "phir",
        "mot": "maut",
        "aasan": "aasaan",
        "halat": "haalat",
        "dolt": "daulat",
        "awaqat": "auqaat",
    ]
    
    // MARK: - Single Word Romanization
    private func romanizeSingleWord(_ word: String) -> String {
        guard !word.isEmpty else { return word }
        
        // 1. Direct lyrics dictionary lookup
        if let mapped = lyricsDictionary[word] {
            return mapped
        }
        
        var s = word
        
        // 2. Urdu / Arabic script phonetic character normalization
        let isArabic = s.unicodeScalars.contains { $0.value >= 0x0600 && $0.value <= 0x08FF }
        if isArabic {
            // Crucial Urdu consonant mappings (prevents "ذرا" -> "dhra", "ضرور" -> "dhroor")
            s = s.replacingOccurrences(of: "ذ", with: "z")
            s = s.replacingOccurrences(of: "ض", with: "z")
            s = s.replacingOccurrences(of: "ظ", with: "z")
            s = s.replacingOccurrences(of: "ث", with: "s")
            s = s.replacingOccurrences(of: "ص", with: "s")
            s = s.replacingOccurrences(of: "ط", with: "t")
            s = s.replacingOccurrences(of: "ح", with: "h")
            s = s.replacingOccurrences(of: "خ", with: "kh")
            s = s.replacingOccurrences(of: "غ", with: "gh")
            s = s.replacingOccurrences(of: "چ", with: "ch")
            s = s.replacingOccurrences(of: "پ", with: "p")
            s = s.replacingOccurrences(of: "گ", with: "g")
            s = s.replacingOccurrences(of: "ٹ", with: "t")
            s = s.replacingOccurrences(of: "ڈ", with: "d")
            s = s.replacingOccurrences(of: "ڑ", with: "r")
            s = s.replacingOccurrences(of: "ژ", with: "zh")
            s = s.replacingOccurrences(of: "\u{06BA}", with: "n") // noon ghunna ں
            s = s.replacingOccurrences(of: "ݨ", with: "n")        // rnoon
            s = s.replacingOccurrences(of: "ے", with: "e")        // bari ye
            s = s.replacingOccurrences(of: "آ", with: "aa")       // alif madda
            s = s.replacingOccurrences(of: "ۂ", with: "e")
        }
        
        // 3. Gurmukhi script pre-processing: Adhak (ੱ) doubles the following consonant
        let isGurmukhi = s.unicodeScalars.contains { $0.value >= 0x0A00 && $0.value <= 0x0A7F }
        if isGurmukhi {
            var expanded = ""
            let chars = Array(s)
            var i = 0
            while i < chars.count {
                let c = chars[i]
                if c == "\u{0A71}" && i + 1 < chars.count {
                    let nextC = chars[i + 1]
                    expanded.append(nextC)
                    expanded.append(nextC)
                    i += 2
                    continue
                }
                expanded.append(c)
                i += 1
            }
            s = expanded
        }
        
        // 4. CoreFoundation ICU transform to Latin
        let mut = NSMutableString(string: s)
        CFStringTransform(mut, nil, kCFStringTransformToLatin, false)
        var latin = mut as String
        
        // 5. Refine Indic / South Asian phonetics
        latin = refinePhonetics(latin)
        
        // 6. Natural Hindi/Punjabi Schwa deletion before stripping diacritics
        latin = deleteSchwa(latin)
        
        // 7. Strip remaining diacritics
        let mutStrip = NSMutableString(string: latin)
        CFStringTransform(mutStrip, nil, kCFStringTransformStripDiacritics, false)
        latin = mutStrip as String
        
        // 8. Clean up ICU artifacts & normalization
        latin = latin.replacingOccurrences(of: "ʱ", with: "h")
        latin = latin.replacingOccurrences(of: "ḥ", with: "h")
        latin = latin.replacingOccurrences(of: "y̰", with: "y")
        latin = latin.replacingOccurrences(of: "◌̃", with: "n")
        latin = latin.replacingOccurrences(of: "◌", with: "")
        latin = latin.replacingOccurrences(of: "'", with: "")
        
        // Word normalizations
        let lower = latin.lowercased()
        if lower == "maim" { latin = "main" }
        if lower == "tainu" { latin = "tenu" }
        if lower == "jadona" { latin = "jadon" }
        if lower == "yaada" { latin = "yaad" }
        if lower == "raata" { latin = "raat" }
        if lower == "baata" { latin = "baat" }
        if lower == "doodha" { latin = "doodh" }
        if lower == "dudha" { latin = "doodh" }
        if lower == "akhi" { latin = "akh" }
        
        return latin
    }
    
    // MARK: - Phonetic Refinements
    private func refinePhonetics(_ text: String) -> String {
        var s = text
        
        // Exact high-frequency word matches in IAST form:
        s = s.replacingOccurrences(of: "yāda", with: "yaad")
        s = s.replacingOccurrences(of: "rāta", with: "raat")
        s = s.replacingOccurrences(of: "bāta", with: "baat")
        s = s.replacingOccurrences(of: "dūdha", with: "doodh")
        s = s.replacingOccurrences(of: "āvāṅgā", with: "aavanga")
        s = s.replacingOccurrences(of: "āvāṅgī", with: "aavangi")
        
        // Aspirates and affricates (do not replace "ch" with "chh" to prevent "chhh"!)
        s = s.replacingOccurrences(of: "cẖ", with: "ch")
        s = s.replacingOccurrences(of: "c", with: "ch")
        s = s.replacingOccurrences(of: "ś", with: "sh")
        s = s.replacingOccurrences(of: "ṣ", with: "sh")
        s = s.replacingOccurrences(of: "ʱ", with: "h")
        s = s.replacingOccurrences(of: "ḥ", with: "h")
        s = s.replacingOccurrences(of: "ậ", with: "aa")
        s = s.replacingOccurrences(of: "y̰", with: "y")
        
        // Nasals / Anusvara / Chandrabindu:
        s = s.replacingOccurrences(of: "ā'ē̃", with: "aayein")
        s = s.replacingOccurrences(of: "ā'ēṁ", with: "aayein")
        s = s.replacingOccurrences(of: "ā'ēṅ", with: "aayein")
        s = s.replacingOccurrences(of: "'āṁ", with: "yan")
        s = s.replacingOccurrences(of: "āṁ", with: "an")
        s = s.replacingOccurrences(of: "ēṅ", with: "en")
        s = s.replacingOccurrences(of: "ēṁ", with: "en")
        s = s.replacingOccurrences(of: "ē̃", with: "ein")
        s = s.replacingOccurrences(of: "aiṁ", with: "ain")
        s = s.replacingOccurrences(of: "ōṁ", with: "on")
        s = s.replacingOccurrences(of: "ō̃", with: "on")
        s = s.replacingOccurrences(of: "ūṁ", with: "un")
        s = s.replacingOccurrences(of: "ū̃", with: "un")
        s = s.replacingOccurrences(of: "īṁ", with: "in")
        s = s.replacingOccurrences(of: "ī̃", with: "in")
        s = s.replacingOccurrences(of: "aṁ", with: "an")
        s = s.replacingOccurrences(of: "uṁ", with: "un")
        s = s.replacingOccurrences(of: "iṁ", with: "in")
        s = s.replacingOccurrences(of: "ṁ", with: "n")
        s = s.replacingOccurrences(of: "ṅ", with: "n")
        s = s.replacingOccurrences(of: "ñ", with: "n")
        s = s.replacingOccurrences(of: "ṇ", with: "n")
        s = s.replacingOccurrences(of: "◌̃", with: "n")
        s = s.replacingOccurrences(of: "◌", with: "")
        
        // Long vowels:
        s = s.replacingOccurrences(of: "yād", with: "yaad")
        s = s.replacingOccurrences(of: "rāt", with: "raat")
        s = s.replacingOccurrences(of: "bāt", with: "baat")
        s = s.replacingOccurrences(of: "āvā", with: "aava")
        s = s.replacingOccurrences(of: "dūdh", with: "doodh")
        
        return s
    }
    
    // MARK: - Schwa Deletion
    private func deleteSchwa(_ text: String) -> String {
        var bare = text
        // In Hindi/Punjabi, a final short 'a' (without macron 'ā') on multi-character words
        // is an inherent schwa that is dropped in modern speech (e.g., dila -> dil, tuma -> tum).
        // Exceptions: Words ending in long 'ā', 'aa', or short grammatical markers ('ga', 'na', 'da', etc.).
        if bare.count > 2 && bare.hasSuffix("a") && !bare.hasSuffix("ā") && !bare.hasSuffix("aa") && !bare.hasSuffix("ia") && !bare.hasSuffix("ya") && !bare.hasSuffix("wa") && !bare.hasSuffix("ga") && !bare.hasSuffix("na") && !bare.hasSuffix("da") && !bare.hasSuffix("la") && !bare.hasSuffix("ha") {
            bare.removeLast()
        } else if bare.count > 3 && (bare.hasSuffix("dha") || bare.hasSuffix("kha") || bare.hasSuffix("bha") || bare.hasSuffix("tha") || bare.hasSuffix("cha") || bare.hasSuffix("jha") || bare.hasSuffix("pha") || bare.hasSuffix("gha") || bare.hasSuffix("sha")) {
            bare.removeLast()
        }
        return bare
    }
}
