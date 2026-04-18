import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/http_config_service.dart';
import '../services/locale_service.dart';
import '../localization/localization_service.dart';

/// Category and Package name translations (English -> Arabic)
const Map<String, String> categoryTranslations = {
  'sport': 'رياضة',
  'sports': 'رياضة',
  'electronics': 'إلكترونيات',
  'clothing': 'ملابس',
  'food': 'طعام',
  'books': 'كتب',
  'furniture': 'أثاث',
  'toys': 'ألعاب',
  'beauty': 'جمال',
  'health': 'صحة',
  'automotive': 'سيارات',
  'home': 'منزل',
  'office': 'مكتب',
  'general': 'عام',
};

const Map<String, String> packageTranslations = {
  'hot drink': 'المشروبات الساخنة',
  'hot drinks': 'المشروبات الساخنة',
  'cold drink': 'المشروبات الباردة',
  'cold drinks': 'المشروبات الباردة',
  'breakfast': 'فطور',
  'lunch': 'غداء',
  'dinner': 'عشاء',
  'snacks': 'وجبات خفيفة',
  'beverages': 'مشروبات',
  'office supplies': 'لوازم مكتبية',
  'stationery': 'قرطاسية',
  'general': 'عام',
};

/// Translation dictionary
/// Contains all translations for Arabic and English
const Map<String, Map<String, String>> translations = {
  'ar': {
    // Common
    'back': 'رجوع',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'edit': 'تعديل',
    'delete': 'حذف',
    'search': 'بحث',
    'loading': 'جاري التحميل...',
    'error': 'خطأ',
    'success': 'نجح',
    'confirm': 'تأكيد',
    'close': 'إغلاق',
    'ok': 'موافق',
    'confirm_action': 'تأكيد العملية',
    'are_you_sure_you_want_to': 'هل أنت متأكد أنك تريد {action}؟',

    // Navbar
    'makateb_store': 'مكاتب ستور',
    'search_products': 'ابحث عن المنتجات...',
    'sign_in': 'تسجيل الدخول',
    'profile': 'الملف الشخصي',
    'orders': 'الطلبات',
    'settings': 'الإعدادات',
    'logout': 'تسجيل الخروج',
    'contact_support': 'اتصل بالدعم',
    'admin_menu': 'قائمة الإدارة',
    'wishlist': 'قائمة الأمنيات',
    'my_wishlist': 'قائمة الأمنيات الخاصة بي',
    'cart': 'السلة',
    'chat': 'الدردشة',
    'dark_mode': 'الوضع الليلي',
    'light_mode': 'الوضع النهاري',
    'language': 'اللغة',
    'admin': 'الإدارة',
    'support_chat': 'دردشة الدعم',
    'copyright': '© 2026 مكاتب ستور. جميع الحقوق محفوظة.',

    // Home/Dashboard
    'welcome_to_makateb_store': 'مرحباً بك في مكاتب ستور',
    'welcome_description':
        'مرحباً بك في مكاتب ستور! كل ما يحتاجه مكتبك في مكان واحد.',
    'products': 'المنتجات',
    'packages': 'الباقات',
    'most_searched': 'الأكثر بحثاً',
    'view_all': 'عرض الكل',
    'add_to_cart': 'أضف إلى السلة',
    'add': 'أضف',
    'add_to_wishlist': 'أضف إلى قائمة الأمنيات',
    'out_of_stock': 'نفدت الكمية',
    'only_left': 'بقي فقط',
    'items': 'عناصر',
    'browse_products': 'تصفح المنتجات',
    'explore_curated_collection': 'استكشف مجموعتنا المختارة',

    // Product
    'product_details': 'تفاصيل المنتج',
    'back_to_products': 'رجوع إلى المنتجات',
    'category': 'الفئة',
    'select_category': 'اختر الفئة',
    'price': 'السعر',
    'description': 'الوصف',
    'quantity': 'الكمية',
    'stock': 'المخزون',
    'customer_reviews': 'تقييمات العملاء',
    'add_review': 'أضف تقييم',
    'rating': 'التقييم',
    'comment': 'تعليق',
    'submit': 'إرسال',

    // Package
    'package_details': 'تفاصيل الباقة',
    'back_to_packages': 'رجوع إلى الباقات',
    'special_package_deal': 'عرض باقة خاص',
    'original_price': 'السعر الأصلي',
    'whats_included': 'ما المضمن',
    'add_package_to_cart': 'أضف الباقة إلى السلة',

    // Cart
    'shopping_cart': 'سلة التسوق',
    'empty_cart': 'سلة التسوق فارغة',
    'start_shopping': 'ابدأ التسوق',
    'total': 'المجموع',
    'checkout': 'الدفع',
    'remove': 'إزالة',
    'view_your_cart': 'عرض سلة التسوق',

    // Checkout
    'checkout_page': 'صفحة الدفع',
    'order_summary': 'ملخص الطلب',
    'subtotal': 'المجموع الفرعي',
    'service_fees': 'رسوم الخدمة',
    'payment_method': 'طريقة الدفع',
    'cash_on_delivery': 'الدفع عند الاستلام',
    'credit_card': 'بطاقة ائتمان',
    'complete_purchase': 'إتمام الشراء',
    'shipping_address': 'عنوان الشحن',
    'city': 'المدينة',
    'address': 'العنوان',
    'phone': 'الهاتف',

    // Orders
    'order_history': 'سجل الطلبات',
    'no_orders': 'لا توجد طلبات',
    'order_id': 'رقم الطلب',
    'order': 'طلب',
    'order_date': 'تاريخ الطلب',
    'status': 'الحالة',
    'pending': 'قيد الانتظار',
    'processing': 'قيد المعالجة',
    'shipped': 'تم الشحن',
    'delivered': 'تم التسليم',
    'cancelled': 'ملغي',

    // Settings
    'basic_information': 'المعلومات الأساسية',
    'first_name': 'الاسم الأول',
    'last_name': 'اسم العائلة',
    'email_address': 'عنوان البريد الإلكتروني',
    'save_changes': 'حفظ التغييرات',
    'saving': 'جاري الحفظ...',
    'change_password': 'تغيير كلمة المرور',
    'current_password': 'كلمة المرور الحالية',
    'new_password': 'كلمة المرور الجديدة',
    'confirm_password': 'تأكيد كلمة المرور',
    'changing': 'جاري التغيير...',
    'danger_zone': 'منطقة الخطر',
    'delete_account': 'حذف الحساب',
    'delete_account_warning': 'بمجرد حذف حسابك، لا يمكن التراجع. يرجى التأكد.',
    'are_you_sure': 'هل أنت متأكد تماماً؟',
    'yes_delete': 'نعم، احذف حسابي',
    'select_language': 'اختر اللغة',
    'arabic': 'العربية',
    'english': 'الإنجليزية',
    'account_required': 'حساب مطلوب',
    'account_required_for_orders_support':
        'يجب إنشاء حساب لعرض سجل الطلبات أو التواصل مع الدعم',
    'continue_shopping': 'متابعة التسوق',

    // Profile
    'user_information': 'معلومات المستخدم',
    'edit_information': 'تعديل المعلومات',
    'location': 'الموقع',
    'bio': 'السيرة الذاتية',
    'privacy_settings': 'إعدادات الخصوصية',
    'profile_visibility': 'رؤية الملف الشخصي',
    'public': 'عام',
    'private': 'خاص',
    'not_provided': 'غير متوفر',
    'does_not_create_account': 'لم يقم بإنشاء حساب',
    'order_information': 'معلومات الطلب',

    // Chat
    'messages': 'الرسائل',
    'customer_chat': 'دردشة العملاء',
    'select_user': 'اختر مستخدماً لبدء الدردشة',
    'type_message': 'اكتب رسالتك...',
    'send': 'إرسال',
    'no_conversations': 'لا توجد محادثات',
    'are_you_sure_clear_chat': 'هل أنت متأكد من مسح هذه المحادثة؟',
    'please_select_image_file': 'يرجى اختيار ملف صورة',
    'please_enter_valid_url': 'يرجى إدخال رابط صحيح',
    'upload_to_cloudinary': 'رفع إلى Cloudinary',
    'select_file': 'اختر ملف',
    'drag_drop_or_click_to_upload_cloudinary':
        'اسحب وأفلت أو انقر للرفع إلى Cloudinary',
    'image_link': 'رابط الصورة',
    'cloudinary': 'Cloudinary',
    'preview': 'معاينة',
    'failed_to_send_message': 'فشل إرسال الرسالة',
    'failed_to_fetch_conversations': 'فشل جلب المحادثات',
    'failed_to_fetch_messages': 'فشل جلب الرسائل',
    'failed_to_clear_chat': 'فشل مسح المحادثة',
    'chat_cleared_successfully': 'تم مسح المحادثة بنجاح!',
    'search_users': 'ابحث عن المستخدمين...',

    // Search
    'search_page': 'صفحة البحث',
    'filter': 'تصفية',
    'sort_by': 'ترتيب حسب',
    'price_range': 'نطاق السعر',
    'min': 'الحد الأدنى',
    'max': 'الحد الأقصى',
    'apply': 'تطبيق',
    'reset': 'إعادة تعيين',
    'no_products_found': 'لم يتم العثور على منتجات',
    'most_relevant': 'الأكثر صلة',
    'price_low_to_high': 'السعر: من الأقل إلى الأعلى',
    'price_high_to_low': 'السعر: من الأعلى إلى الأقل',
    'highest_rated': 'الأعلى تقييماً',
    'found': 'تم العثور على',
    'for': 'لـ',
    'try_adjusting_search':
        'حاول تعديل البحث أو الفلاتر للعثور على ما تبحث عنه.',
    'clear_all_filters': 'مسح جميع الفلاتر',

    // Login
    'welcome_back': 'مرحباً بعودتك',
    'sign_in_account': 'تسجيل الدخول إلى حسابك',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'role': 'الدور',
    'select_role': 'اختر الدور',
    'customer': 'عميل',
    'dont_have_account': 'ليس لديك حساب؟',
    'sign_up': 'سجل',
    'create_account': 'إنشاء حساب',
    'already_have_account': 'هل لديك حساب بالفعل؟',
    'card_number': 'رقم البطاقة',
    'expiry_date': 'تاريخ انتهاء الصلاحية',
    'cvv': 'رمز الأمان',
    'continue_as_guest': 'المتابعة كضيف',
    'please_login_to_access_settings': 'يرجى تسجيل الدخول للوصول إلى الإعدادات',
    'shop_now': 'تسوق الآن',
    'special_package_deals': 'عروض الباقات الخاصة',
    'categories': 'الفئات',
    'all': 'الكل',
    'all_products': 'جميع المنتجات',
    'no_search_data': 'لا توجد بيانات بحث متاحة بعد',
    'no_packages_available': 'لا توجد باقات متاحة',
    'adding': 'جاري الإضافة...',
    'please_login_to_add_items': 'يرجى تسجيل الدخول لإضافة العناصر',
    'removed_from_wishlist': 'تمت الإزالة من قائمة الأمنيات',
    'added_to_wishlist': 'تمت الإضافة إلى قائمة الأمنيات',
    'added_to_cart': 'تمت الإضافة إلى السلة',
    'failed_to_add_to_cart': 'فشلت إضافة العنصر إلى السلة',
    'failed_to_update_wishlist': 'فشل تحديث قائمة الأمنيات',
    'package_added_to_cart': 'تمت إضافة الباقة إلى السلة',
    'failed_to_add_package_to_cart': 'فشلت إضافة الباقة إلى السلة',
    'uncategorized': 'غير مصنف',
    'reviews': 'تقييمات',
    'no_description_available': 'لا يوجد وصف متاح',
    'only_left_in_stock': 'بقي فقط',
    'left_in_stock': 'في المخزون',
    'no_products_in_package': 'لا توجد منتجات في هذه الباقة',
    'your_cart_is_empty': 'سلة التسوق فارغة',
    'add_some_products': 'أضف بعض المنتجات الجميلة للبدء',
    'calculated_at_checkout': 'يتم حسابه عند الدفع',
    'proceed_to_checkout': 'المتابعة إلى الدفع',
    'please_login_to_view_orders': 'يرجى تسجيل الدخول لعرض طلباتك',
    'start_shopping_and_orders': 'ابدأ التسوق وستظهر طلباتك هنا',
    'placed_on': 'تم الطلب في',
    'items_count': 'عناصر',
    'view_details': 'عرض التفاصيل',
    'contact_information': 'معلومات الاتصال',
    'full_name': 'الاسم الكامل',
    'zip_code': 'الرمز البريدي',
    'select_location': 'اختر الموقع',
    'select_user_to_chat': 'اختر مستخدماً لبدء الدردشة',
    'no_messages': 'لا توجد رسائل',
    'type_your_message': 'اكتب رسالتك...',
  },
  'en': {
    // Common
    'back': 'Back',
    'save': 'Save',
    'cancel': 'Cancel',
    'edit': 'Edit',
    'delete': 'Delete',
    'search': 'Search',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'confirm': 'Confirm',
    'close': 'Close',
    'ok': 'OK',
    'confirm_action': 'Confirm Action',
    'are_you_sure_you_want_to': 'Are you sure you want to {action}?',

    // Navbar
    'makateb_store': 'Makateb Store',
    'search_products': 'Search products...',
    'sign_in': 'Sign In',
    'profile': 'Profile',
    'orders': 'Orders',
    'settings': 'Settings',
    'logout': 'Logout',
    'contact_support': 'Contact Support',
    'admin_menu': 'Admin Menu',
    'wishlist': 'Wishlist',
    'cart': 'Cart',
    'chat': 'Chat',

    // Home/Dashboard
    'welcome_to_makateb_store': 'Welcome to Makateb Store',
    'welcome_description':
        'Welcome to Makateb Store! Everything your office needs, all in one place.',
    'products': 'Products',
    'packages': 'Packages',
    'most_searched': 'Most Searched',
    'view_all': 'View All',
    'add_to_cart': 'Add to Cart',
    'add': 'Add',
    'add_to_wishlist': 'Add to Wishlist',
    'out_of_stock': 'Out of Stock',
    'only_left': 'Only',
    'items': 'items',
    'explore_curated_collection': 'Explore our curated collection',

    // Product
    'product_details': 'Product Details',
    'back_to_products': 'Back to Products',
    'category': 'Category',
    'price': 'Price',
    'description': 'Description',
    'quantity': 'Quantity',
    'stock': 'Stock',
    'customer_reviews': 'Customer Reviews',
    'add_review': 'Add Review',
    'rating': 'Rating',
    'comment': 'Comment',
    'submit': 'Submit',

    // Package
    'package_details': 'Package Details',
    'back_to_packages': 'Back to Packages',
    'special_package_deal': 'Special Package Deal',
    'original_price': 'Original Price',
    'whats_included': "What's Included",
    'add_package_to_cart': 'Add Package to Cart',

    // Cart
    'shopping_cart': 'Shopping Cart',
    'empty_cart': 'Your cart is empty',
    'start_shopping': 'Start Shopping',
    'total': 'Total',
    'checkout': 'Checkout',
    'view_your_cart': 'View Your Cart',

    // Checkout
    'checkout_page': 'Checkout',
    'service_fees': 'Service Fees',
    'payment_method': 'Payment Method',
    'cash_on_delivery': 'Cash on Delivery',
    'credit_card': 'Credit Card',
    'complete_purchase': 'Complete Purchase',
    'shipping_address': 'Shipping Address',
    'city': 'City',
    'address': 'Address',
    'phone': 'Phone',

    // Orders
    'order_history': 'Order History',
    'no_orders': 'No orders yet',
    'order_id': 'Order ID',
    'order': 'Order',
    'order_date': 'Order Date',
    'status': 'Status',
    'pending': 'Pending',
    'processing': 'Processing',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',

    // Settings
    'basic_information': 'Basic Information',
    'first_name': 'First Name',
    'last_name': 'Last Name',
    'email_address': 'Email Address',
    'save_changes': 'Save Changes',
    'saving': 'Saving...',
    'change_password': 'Change Password',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_password': 'Confirm New Password',
    'changing': 'Changing...',
    'danger_zone': 'Danger Zone',
    'delete_account': 'Delete Account',
    'delete_account_warning':
        'Once you delete your account, there is no going back. Please be certain.',
    'are_you_sure': 'Are you absolutely sure?',
    'yes_delete': 'Yes, Delete My Account',
    'select_language': 'Select Language',
    'arabic': 'Arabic',
    'english': 'English',
    'account_required': 'Account Required',
    'account_required_for_orders_support':
        'You must create an account to view order history or contact support',
    'continue_shopping': 'Continue Shopping',

    // Profile
    'user_information': 'User Information',
    'edit_information': 'Edit Information',
    'bio': 'Bio',
    'privacy_settings': 'Privacy Settings',
    'profile_visibility': 'Profile visibility',
    'public': 'Public',
    'private': 'Private',
    'not_provided': 'Not provided',
    'does_not_create_account': 'Does not create account',
    'order_information': 'Order Information',

    // Chat
    'messages': 'Messages',
    'customer_chat': 'Customer Chat',
    'select_user': 'Select a user to start chatting',
    'type_message': 'Type your message...',
    'send': 'Send',
    'no_conversations': 'No conversations',
    'are_you_sure_clear_chat': 'Are you sure you want to clear this chat?',
    'please_select_image_file': 'Please select an image file',
    'failed_to_send_message': 'Failed to send message',
    'failed_to_fetch_conversations': 'Failed to fetch conversations',
    'failed_to_fetch_messages': 'Failed to fetch messages',
    'failed_to_clear_chat': 'Failed to clear chat',
    'chat_cleared_successfully': 'Chat cleared successfully!',

    // Search
    'search_page': 'Search',
    'filter': 'Filter',
    'sort_by': 'Sort By',
    'price_range': 'Price Range',
    'min': 'Min',
    'max': 'Max',
    'apply': 'Apply',
    'reset': 'Reset',
    'no_products_found': 'No products found',

    // Login
    'welcome_back': 'Welcome Back',
    'sign_in_account': 'Sign in to your account',
    'email': 'Email Address',
    'password': 'Password',
    'role': 'Role',
    'select_role': 'Select Role',
    'customer': 'Customer',
    'admin': 'Admin',
    'dont_have_account': "Don't have an account?",
    'sign_up': 'Sign up',
    'continue_as_guest': 'Continue as guest',
    'please_login_to_access_settings': 'Please login to access settings',
    'light_mode': 'Light Mode',
    'dark_mode': 'Dark Mode',
    'shop_now': 'Shop Now',
    'special_package_deals': 'Special Package Deals',
    'categories': 'Categories',
    'all': 'All',
    'all_products': 'All Products',
    'no_search_data': 'No search data available yet',
    'no_packages_available': 'No packages available',
    'adding': 'Adding...',
    'general': 'General',
    'please_login_to_add_items': 'Please login to add items',
    'removed_from_wishlist': 'Removed from wishlist',
    'added_to_wishlist': 'Added to wishlist',
    'added_to_cart': 'Added to cart',
    'failed_to_add_to_cart': 'Failed to add to cart',
    'failed_to_update_wishlist': 'Failed to update wishlist',
    'package_added_to_cart': 'Package added to cart!',
    'failed_to_add_package_to_cart': 'Failed to add package to cart',
    'uncategorized': 'Uncategorized',
    'reviews': 'reviews',
    'no_description_available': 'No description available',
    'all_packages': 'All Packages',
    'showing_all_packages': 'Showing all packages ({count})',
    'off': 'off',
    'only_left_in_stock': 'Only',
    'left_in_stock': 'left in stock!',
    'no_products_in_package': 'No products found in this package',
    'your_cart_is_empty': 'Your cart is empty',
    'add_some_products': 'Add some beautiful products to get started!',
    'calculated_at_checkout': 'Calculated at checkout',
    'proceed_to_checkout': 'Proceed to Checkout',
    'please_login_to_view_orders': 'Please login to view your orders',
    'start_shopping_and_orders':
        'Start shopping and your orders will appear here!',
    'placed_on': 'Placed on',
    'items_count': 'items',
    'view_details': 'View Details',
    'contact_information': 'Contact Information',
    'full_name': 'Full Name',
    'zip_code': 'ZIP Code',
    'select_location': 'Select Location',
    'select_user_to_chat': 'Select a user to start chatting',
    'type_your_message': 'Type your message...',
  },
};

/// LanguageState - State class for language store
///
/// Contains the state managed by the language store.
/// Equivalent to Vue Pinia language store state.
class LanguageState {
  final String currentLanguage;

  const LanguageState({this.currentLanguage = 'ar'});

  /// Check if current language is RTL
  bool get isRTL => currentLanguage == 'ar';

  /// Create a copy with updated fields
  LanguageState copyWith({String? currentLanguage}) {
    return LanguageState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
    );
  }
}

/// LanguageStoreNotifier - StateNotifier for language store
///
/// Equivalent to Vue Pinia language store actions and state management.
/// Handles language switching, translations, and localization.
class LanguageStoreNotifier extends StateNotifier<LanguageState> {
  LanguageStoreNotifier() : super(const LanguageState()) {
    _loadFromStorage();
  }

  /// Storage key
  static const String _keyLanguage = 'language';

  /// Load language from storage
  /// Equivalent to Vue's localStorage.getItem('language')
  Future<void> _loadFromStorage() async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) {
        await storage.initialize();
      }

      final savedLanguage = storage.getString(_keyLanguage) ?? 'ar';
      state = state.copyWith(currentLanguage: savedLanguage);

      // Update LocaleService and HttpConfigService
      await _updateServices(savedLanguage);
    } catch (e) {
      debugPrint('Error loading language from storage: $e');
    }
  }

  /// Update LocaleService, LocalizationService, and HttpConfigService
  Future<void> _updateServices(String language) async {
    // Update LocaleService
    await LocaleService.instance.setLanguage(language);

    // Update LocalizationService (for MaterialApp locale)
    await LocalizationService().changeLocale(language);

    // Update HttpConfigService
    final httpConfig = HttpConfigService.instance;
    if (httpConfig.isInitialized) {
      await httpConfig.setLanguage(language);
    }
  }

  // ==================== Actions ====================

  /// Set language
  /// Equivalent to Vue's setLanguage()
  ///
  /// [lang] - Language code ('ar' or 'en')
  Future<void> setLanguage(String lang) async {
    state = state.copyWith(currentLanguage: lang);

    // Save to storage
    final storage = StorageService.instance;
    await storage.setString(_keyLanguage, lang);

    // Update services
    await _updateServices(lang);
  }

  // ==================== Translation Functions ====================

  /// Translate a key
  /// Equivalent to Vue's t() computed function
  ///
  /// [key] - Translation key
  /// [params] - Optional parameters for string interpolation
  String t(String key, [Map<String, String>? params]) {
    final lang = state.currentLanguage;
    final langTranslations = translations[lang] ?? translations['ar']!;
    String translation =
        langTranslations[key] ?? translations['ar']![key] ?? key;

    // Handle string interpolation (e.g., "Are you sure you want to {action}?")
    if (params != null) {
      params.forEach((paramKey, value) {
        translation = translation.replaceAll('{$paramKey}', value);
      });
    }

    return translation;
  }

  /// Translate category name
  /// Equivalent to Vue's translateCategoryName()
  ///
  /// [name] - Category name to translate
  String translateCategoryName(String? name) {
    return translateName(name, 'category');
  }

  /// Translate package name
  /// Equivalent to Vue's translatePackageName()
  ///
  /// [name] - Package name to translate
  String translatePackageName(String? name) {
    return translateName(name, 'package');
  }

  /// Translate name (category or package)
  /// Equivalent to Vue's translateName()
  ///
  /// [name] - Name to translate
  /// [type] - Type: 'category' or 'package'
  String translateName(String? name, [String type = 'category']) {
    if (name == null || name.isEmpty) return name ?? '';

    final lang = state.currentLanguage;
    if (lang != 'ar') return name;

    final translationsMap = type == 'category'
        ? categoryTranslations
        : packageTranslations;
    final nameLower = name.toLowerCase().trim();

    // Direct match
    if (translationsMap.containsKey(nameLower)) {
      return translationsMap[nameLower]!;
    }

    // Partial match (contains)
    for (final entry in translationsMap.entries) {
      final en = entry.key;
      final ar = entry.value;
      if (nameLower.contains(en) || en.contains(nameLower)) {
        return ar;
      }
    }

    return name; // Return original if no translation found
  }

  /// Get localized name for an item
  /// Equivalent to Vue's getLocalizedName()
  ///
  /// [item] - Item with name_ar, name_en, or name fields
  String getLocalizedName(Map<String, dynamic>? item) {
    if (item == null) return '';

    final isArabic = state.currentLanguage == 'ar';
    return isArabic
        ? (item['name_ar'] as String? ??
              item['name_en'] as String? ??
              item['name'] as String? ??
              '')
        : (item['name_en'] as String? ??
              item['name_ar'] as String? ??
              item['name'] as String? ??
              '');
  }

  /// Get localized description for an item
  /// Equivalent to Vue's getLocalizedDescription()
  ///
  /// [item] - Item with description_ar, description_en, or description fields
  String getLocalizedDescription(Map<String, dynamic>? item) {
    if (item == null) return '';

    final isArabic = state.currentLanguage == 'ar';
    return isArabic
        ? (item['description_ar'] as String? ??
              item['description_en'] as String? ??
              item['description'] as String? ??
              '')
        : (item['description_en'] as String? ??
              item['description_ar'] as String? ??
              item['description'] as String? ??
              '');
  }
}

/// LanguageStoreProvider - Riverpod provider for language store
///
/// This is the main provider that exposes the language store state and actions.
final languageStoreProvider =
    StateNotifierProvider<LanguageStoreNotifier, LanguageState>(
      (ref) => LanguageStoreNotifier(),
    );

/// Computed/Selector Providers
///
/// These providers compute derived values from the language store state.
/// Equivalent to Vue's computed properties.

/// Current language provider
final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(languageStoreProvider).currentLanguage;
});

/// Is RTL provider
/// Equivalent to Vue's isRTL computed
final isRTLProvider = Provider<bool>((ref) {
  return ref.watch(languageStoreProvider).isRTL;
});

/// Translation function provider
/// Equivalent to Vue's t() computed
final translationProvider =
    Provider<String Function(String, [Map<String, String>?])>((ref) {
      final notifier = ref.watch(languageStoreProvider.notifier);
      return (key, [params]) => notifier.t(key, params);
    });

/// Translate category name provider
final translateCategoryNameProvider = Provider<String Function(String?)>((ref) {
  final notifier = ref.watch(languageStoreProvider.notifier);
  return (name) => notifier.translateCategoryName(name);
});

/// Translate package name provider
final translatePackageNameProvider = Provider<String Function(String?)>((ref) {
  final notifier = ref.watch(languageStoreProvider.notifier);
  return (name) => notifier.translatePackageName(name);
});

/// Get localized name provider
final getLocalizedNameProvider =
    Provider<String Function(Map<String, dynamic>?)>((ref) {
      final notifier = ref.watch(languageStoreProvider.notifier);
      return (item) => notifier.getLocalizedName(item);
    });

/// Get localized description provider
final getLocalizedDescriptionProvider =
    Provider<String Function(Map<String, dynamic>?)>((ref) {
      final notifier = ref.watch(languageStoreProvider.notifier);
      return (item) => notifier.getLocalizedDescription(item);
    });


