/// Central translation dictionary for TubePilot.
///
/// HOW THIS WORKS:
/// - Every translatable piece of UI text gets a short KEY (e.g. 'settings',
///   'dark_mode', 'logout').
/// - Each key maps to a translation per language code below.
/// - Screens call `AppStrings.of(context, 'key')` (see language_provider.dart
///   for the `context.tr('key')` extension) instead of hardcoding English
///   text directly.
///
/// IMPORTANT — SCOPE OF THIS FILE:
/// This file currently only contains keys for the screens we've actually
/// looked at (Settings, Profile). To translate the REST of the app
/// (Dashboard, Upload, Wallet, Diamond Store, Notifications, etc.), the
/// same pattern needs to be repeated for each screen:
///   1. Add new keys + translations here.
///   2. Replace hardcoded Text('...') strings in that screen with
///      Text(context.tr('key')).
/// This is intentionally left incremental so it doesn't require guessing at
/// screens whose code hasn't been shared.
class AppStrings {
  static const supportedLanguageCodes = ['en', 'hi', 'hinglish', 'ta', 'bn', 'mr', 'ur'];

  /// Maps the friendly names shown in the language picker to locale codes
  /// used internally / stored in Locale.languageCode.
  static const languageNameToCode = {
    'English': 'en',
    'Hindi': 'hi',
    'Hinglish': 'hinglish',
    'Tamil': 'ta',
    'Bengali': 'bn',
    'Marathi': 'mr',
    'Urdu': 'ur',
  };

  static const codeToLanguageName = {
    'en': 'English',
    'hi': 'Hindi',
    'hinglish': 'Hinglish',
    'ta': 'Tamil',
    'bn': 'Bengali',
    'mr': 'Marathi',
    'ur': 'Urdu',
  };

  static const Map<String, Map<String, String>> _strings = {
    // ---------------- Settings screen ----------------
    'settings_title': {
      'en': 'Settings',
      'hi': 'सेटिंग्स',
      'hinglish': 'Settings',
      'ta': 'அமைப்புகள்',
      'bn': 'সেটিংস',
      'mr': 'सेटिंग्ज',
      'ur': 'ترتیبات',
    },
    'signed_in_with': {
      'en': 'Signed in with',
      'hi': 'इससे साइन इन किया',
      'hinglish': 'Signed in with',
      'ta': 'இதன் மூலம் உள்நுழைந்துள்ளீர்கள்',
      'bn': 'সাইন ইন করা হয়েছে',
      'mr': 'यासह साइन इन केले',
      'ur': 'اس کے ساتھ سائن ان',
    },
    'no_email_on_account': {
      'en': 'No email on this account',
      'hi': 'इस खाते पर कोई ईमेल नहीं',
      'hinglish': 'Is account par koi email nahi hai',
      'ta': 'இந்தக் கணக்கில் மின்னஞ்சல் இல்லை',
      'bn': 'এই অ্যাকাউন্টে কোনো ইমেল নেই',
      'mr': 'या खात्यावर ईमेल नाही',
      'ur': 'اس اکاؤنٹ پر کوئی ای میل نہیں',
    },
    'preferences': {
      'en': 'Preferences',
      'hi': 'प्राथमिकताएँ',
      'hinglish': 'Preferences',
      'ta': 'விருப்பத்தேர்வுகள்',
      'bn': 'পছন্দসমূহ',
      'mr': 'प्राधान्ये',
      'ur': 'ترجیحات',
    },
    'dark_mode': {
      'en': 'Dark Mode',
      'hi': 'डार्क मोड',
      'hinglish': 'Dark Mode',
      'ta': 'இருண்ட பயன்முறை',
      'bn': 'ডার্ক মোড',
      'mr': 'डार्क मोड',
      'ur': 'ڈارک موڈ',
    },
    'default_is_light': {
      'en': 'Default is Light',
      'hi': 'डिफ़ॉल्ट लाइट है',
      'hinglish': 'Default Light hota hai',
      'ta': 'இயல்புநிலை வெளிச்சம்',
      'bn': 'ডিফল্ট লাইট',
      'mr': 'डीफॉल्ट लाइट आहे',
      'ur': 'ڈیفالٹ لائٹ ہے',
    },
    'app_language': {
      'en': 'App Language',
      'hi': 'ऐप की भाषा',
      'hinglish': 'App Language',
      'ta': 'ஆப் மொழி',
      'bn': 'অ্যাপ ভাষা',
      'mr': 'अ‍ॅप भाषा',
      'ur': 'ایپ کی زبان',
    },
    'auto_refill_diamonds': {
      'en': 'Auto-Refill Diamonds',
      'hi': 'ऑटो-रीफिल डायमंड',
      'hinglish': 'Auto-Refill Diamonds',
      'ta': 'தானியங்கி டைமண்ட் நிரப்புதல்',
      'bn': 'অটো-রিফিল ডায়মন্ড',
      'mr': 'ऑटो-रिफिल डायमंड',
      'ur': 'آٹو ری فل ڈائمنڈز',
    },
    'auto_refill_subtitle': {
      'en': 'Automatically top up when your balance runs low',
      'hi': 'बैलेंस कम होने पर अपने आप टॉप अप करें',
      'hinglish': 'Balance kam hone par apne aap top up ho jayega',
      'ta': 'இருப்பு குறையும்போது தானாக நிரப்பப்படும்',
      'bn': 'ব্যালেন্স কম হলে স্বয়ংক্রিয়ভাবে টপ আপ হবে',
      'mr': 'शिल्लक कमी झाल्यावर आपोआप टॉप अप होईल',
      'ur': 'بیلنس کم ہونے پر خودکار طور پر ٹاپ اپ ہوگا',
    },
    'storage': {
      'en': 'Storage',
      'hi': 'स्टोरेज',
      'hinglish': 'Storage',
      'ta': 'சேமிப்பகம்',
      'bn': 'স্টোরেজ',
      'mr': 'स्टोरेज',
      'ur': 'اسٹوریج',
    },
    'clear_local_cache': {
      'en': 'Clear Local Cache',
      'hi': 'लोकल कैश साफ़ करें',
      'hinglish': 'Local Cache Clear karo',
      'ta': 'உள்ளூர் தற்காலிக சேமிப்பை அழிக்கவும்',
      'bn': 'লোকাল ক্যাশে সাফ করুন',
      'mr': 'लोकल कॅशे साफ करा',
      'ur': 'لوکل کیشے صاف کریں',
    },
    'clear_cache_subtitle': {
      'en': 'Frees up space used by temporary previews',
      'hi': 'अस्थायी प्रीव्यू द्वारा उपयोग की गई जगह खाली करता है',
      'hinglish': 'Temporary previews ki wajah se li gayi space khali karta hai',
      'ta': 'தற்காலிக முன்னோட்டங்கள் பயன்படுத்தும் இடத்தை காலி செய்யும்',
      'bn': 'অস্থায়ী প্রিভিউ দ্বারা ব্যবহৃত স্থান খালি করে',
      'mr': 'तात्पुरत्या प्रिव्ह्यूने वापरलेली जागा मोकळी करते',
      'ur': 'عارضی پیش نظاروں کی جگہ خالی کرتا ہے',
    },
    'account': {
      'en': 'Account',
      'hi': 'खाता',
      'hinglish': 'Account',
      'ta': 'கணக்கு',
      'bn': 'অ্যাকাউন্ট',
      'mr': 'खाते',
      'ur': 'اکاؤنٹ',
    },
    'logout': {
      'en': 'Logout',
      'hi': 'लॉगआउट',
      'hinglish': 'Logout',
      'ta': 'வெளியேறு',
      'bn': 'লগআউট',
      'mr': 'लॉगआउट',
      'ur': 'لاگ آؤٹ',
    },
    'logout_confirm_title': {
      'en': 'Logout?',
      'hi': 'लॉगआउट करें?',
      'hinglish': 'Logout karein?',
      'ta': 'வெளியேறவா?',
      'bn': 'লগআউট করবেন?',
      'mr': 'लॉगआउट करायचे?',
      'ur': 'لاگ آؤٹ کریں؟',
    },
    'logout_confirm_body': {
      'en': 'You can sign back in anytime with the same account.',
      'hi': 'आप किसी भी समय उसी खाते से वापस साइन इन कर सकते हैं।',
      'hinglish': 'Aap kabhi bhi isi account se wapas sign in kar sakte hain.',
      'ta': 'இதே கணக்கில் எப்போது வேண்டுமானாலும் மீண்டும் உள்நுழையலாம்.',
      'bn': 'আপনি যেকোনো সময় একই অ্যাকাউন্ট দিয়ে আবার সাইন ইন করতে পারবেন।',
      'mr': 'तुम्ही याच खात्याने कधीही परत साइन इन करू शकता.',
      'ur': 'آپ کسی بھی وقت اسی اکاؤنٹ سے دوبارہ سائن ان کر سکتے ہیں۔',
    },
    'cancel': {
      'en': 'Cancel',
      'hi': 'रद्द करें',
      'hinglish': 'Cancel',
      'ta': 'ரத்து செய்',
      'bn': 'বাতিল করুন',
      'mr': 'रद्द करा',
      'ur': 'منسوخ کریں',
    },
    'delete_account': {
      'en': 'Delete Account',
      'hi': 'खाता हटाएं',
      'hinglish': 'Account Delete karein',
      'ta': 'கணக்கை நீக்கு',
      'bn': 'অ্যাকাউন্ট মুছুন',
      'mr': 'खाते हटवा',
      'ur': 'اکاؤنٹ حذف کریں',
    },
    'clear_cache_confirm_title': {
      'en': 'Clear local cache?',
      'hi': 'लोकल कैश साफ़ करें?',
      'hinglish': 'Local cache clear karein?',
      'ta': 'உள்ளூர் தற்காலிக சேமிப்பை அழிக்கவா?',
      'bn': 'লোকাল ক্যাশে সাফ করবেন?',
      'mr': 'लोकल कॅशे साफ करायचे?',
      'ur': 'لوکل کیشے صاف کریں؟',
    },
    'clear_cache_confirm_body': {
      'en': 'This clears temporarily cached thumbnails and preview files on this device. Your account, videos, and diamonds are not affected.',
      'hi': 'यह इस डिवाइस पर अस्थायी रूप से कैश की गई थंबनेल और प्रीव्यू फ़ाइलों को साफ़ करता है। आपका खाता, वीडियो और डायमंड प्रभावित नहीं होंगे।',
      'hinglish': 'Ye is device par temporary cache thumbnails aur preview files clear karta hai. Aapka account, videos aur diamonds affect nahi honge.',
      'ta': 'இது இந்தச் சாதனத்தில் தற்காலிகமாக சேமிக்கப்பட்ட சிறு படங்கள் மற்றும் முன்னோட்டக் கோப்புகளை அழிக்கும். உங்கள் கணக்கு, வீடியோக்கள் மற்றும் டைமண்டுகள் பாதிக்கப்படாது.',
      'bn': 'এটি এই ডিভাইসে সাময়িকভাবে ক্যাশে করা থাম্বনেইল এবং প্রিভিউ ফাইল সাফ করে। আপনার অ্যাকাউন্ট, ভিডিও এবং ডায়মন্ড প্রভাবিত হবে না।',
      'mr': 'हे या डिव्हाइसवर तात्पुरते साठवलेले थंबनेल आणि प्रिव्ह्यू फाइल्स साफ करते. तुमचे खाते, व्हिडिओ आणि डायमंड्सवर परिणाम होणार नाही.',
      'ur': 'یہ اس ڈیوائس پر عارضی طور پر محفوظ تھمب نیلز اور پیش نظارہ فائلیں صاف کرتا ہے۔ آپ کا اکاؤنٹ، ویڈیوز اور ڈائمنڈز متاثر نہیں ہوں گے۔',
    },
    'clear': {
      'en': 'Clear',
      'hi': 'साफ़ करें',
      'hinglish': 'Clear',
      'ta': 'அழி',
      'bn': 'সাফ করুন',
      'mr': 'साफ करा',
      'ur': 'صاف کریں',
    },

    // ---------------- Profile screen ----------------
    'profile_settings_title': {
      'en': 'Profile & Settings',
      'hi': 'प्रोफ़ाइल और सेटिंग्स',
      'hinglish': 'Profile & Settings',
      'ta': 'சுயவிவரம் & அமைப்புகள்',
      'bn': 'প্রোফাইল ও সেটিংস',
      'mr': 'प्रोफाइल आणि सेटिंग्ज',
      'ur': 'پروفائل اور ترتیبات',
    },
    'connected_accounts': {
      'en': 'Connected Accounts',
      'hi': 'जुड़े हुए खाते',
      'hinglish': 'Connected Accounts',
      'ta': 'இணைக்கப்பட்ட கணக்குகள்',
      'bn': 'সংযুক্ত অ্যাকাউন্ট',
      'mr': 'कनेक्ट केलेली खाती',
      'ur': 'منسلک اکاؤنٹس',
    },
    'buy_diamonds': {
      'en': 'Buy Diamonds',
      'hi': 'डायमंड खरीदें',
      'hinglish': 'Diamonds Kharido',
      'ta': 'டைமண்ட் வாங்கு',
      'bn': 'ডায়মন্ড কিনুন',
      'mr': 'डायमंड खरेदी करा',
      'ur': 'ڈائمنڈز خریدیں',
    },
    'subscription_wallet': {
      'en': 'Subscription & Wallet',
      'hi': 'सब्सक्रिप्शन और वॉलेट',
      'hinglish': 'Subscription & Wallet',
      'ta': 'சந்தா & பணப்பை',
      'bn': 'সাবস্ক্রিপশন ও ওয়ালেট',
      'mr': 'सबस्क्रिप्शन आणि वॉलेट',
      'ur': 'سبسکرپشن اور والیٹ',
    },
    'refer_earn': {
      'en': 'Refer & Earn',
      'hi': 'रेफर करें और कमाएं',
      'hinglish': 'Refer & Earn',
      'ta': 'பரிந்துரை & சம்பாதி',
      'bn': 'রেফার ও আয় করুন',
      'mr': 'रेफर करा आणि कमवा',
      'ur': 'ریفر کریں اور کمائیں',
    },
    'notifications': {
      'en': 'Notifications',
      'hi': 'सूचनाएं',
      'hinglish': 'Notifications',
      'ta': 'அறிவிப்புகள்',
      'bn': 'বিজ্ঞপ্তি',
      'mr': 'सूचना',
      'ur': 'اطلاعات',
    },
    'help_support': {
      'en': 'Help & Support',
      'hi': 'सहायता और समर्थन',
      'hinglish': 'Help & Support',
      'ta': 'உதவி & ஆதரவு',
      'bn': 'সাহায্য ও সহায়তা',
      'mr': 'मदत आणि सहाय्य',
      'ur': 'مدد اور معاونت',
    },
    'admin_panel': {
      'en': 'Admin Panel',
      'hi': 'एडमिन पैनल',
      'hinglish': 'Admin Panel',
      'ta': 'நிர்வாக பலகம்',
      'bn': 'অ্যাডমিন প্যানেল',
      'mr': 'अ‍ॅडमिन पॅनल',
      'ur': 'ایڈمن پینل',
    },
    'about': {
      'en': 'About',
      'hi': 'हमारे बारे में',
      'hinglish': 'About',
      'ta': 'எங்களைப் பற்றி',
      'bn': 'সম্পর্কে',
      'mr': 'आमच्याबद्दल',
      'ur': 'کے بارے میں',
    },
    'privacy_policy': {
      'en': 'Privacy Policy',
      'hi': 'गोपनीयता नीति',
      'hinglish': 'Privacy Policy',
      'ta': 'தனியுரிமைக் கொள்கை',
      'bn': 'গোপনীয়তা নীতি',
      'mr': 'गोपनीयता धोरण',
      'ur': 'رازداری کی پالیسی',
    },
    'rate_us': {
      'en': 'Rate Us',
      'hi': 'हमें रेट करें',
      'hinglish': 'Rate Us',
      'ta': 'எங்களை மதிப்பிடுங்கள்',
      'bn': 'আমাদের রেট করুন',
      'mr': 'आम्हाला रेट करा',
      'ur': 'ہمیں ریٹ کریں',
    },
    'settings_menu': {
      'en': 'Settings',
      'hi': 'सेटिंग्स',
      'hinglish': 'Settings',
      'ta': 'அமைப்புகள்',
      'bn': 'সেটিংস',
      'mr': 'सेटिंग्ज',
      'ur': 'ترتیبات',
    },
  };

  static String tr(String key, String languageCode) {
    final entry = _strings[key];
    if (entry == null) return key; // fallback: show the key itself so a
                                    // missing translation is obvious during
                                    // testing, not a blank string.
    return entry[languageCode] ?? entry['en'] ?? key;
  }
}