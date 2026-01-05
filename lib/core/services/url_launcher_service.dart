import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  // ✅ PHONE CALL
  static Future<void> makePhoneCall(
    BuildContext context,
    String phoneNumber,
  ) async {
    try {
      // Clean phone number (remove spaces, dashes, etc)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final uri = Uri(scheme: 'tel', path: cleanNumber);

      print('📞 Attempting to call: $cleanNumber');

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw Exception('Failed to launch phone dialer');
        }

        print('✅ Phone dialer opened successfully');
      } else {
        throw Exception('Cannot launch phone dialer');
      }
    } catch (e) {
      print('❌ Phone call error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka aplikasi telepon: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  // ✅ SEND EMAIL
  static Future<void> sendEmail(
    BuildContext context,
    String email, {
    String? subject,
    String? body,
  }) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        query: _encodeQueryParameters({
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        }),
      );

      print('📧 Attempting to email: $email');

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw Exception('Failed to launch email client');
        }

        print('✅ Email client opened successfully');
      } else {
        throw Exception('Cannot launch email client');
      }
    } catch (e) {
      print('❌ Email error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka aplikasi email: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  // ✅ SEND SMS
  static Future<void> sendSMS(
    BuildContext context,
    String phoneNumber, {
    String? body,
  }) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final uri = Uri(
        scheme: 'sms',
        path: cleanNumber,
        query: body != null ? 'body=$body' : null,
      );

      print('💬 Attempting to SMS: $cleanNumber');

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw Exception('Failed to launch SMS app');
        }

        print('✅ SMS app opened successfully');
      } else {
        throw Exception('Cannot launch SMS app');
      }
    } catch (e) {
      print('❌ SMS error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka aplikasi SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ OPEN URL
  static Future<void> openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      print('❌ URL error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper: Encode query parameters
  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
