import 'package:url_launcher/url_launcher.dart';

class AppPolicyLinks {
  const AppPolicyLinks._();

  static final Uri privacyPolicy = Uri.parse(
    'https://shield-zabnix.vercel.app/privacy-policy.html',
  );

  static Future<bool> openPrivacyPolicy() {
    return launchUrl(privacyPolicy);
  }
}
