import 'package:url_launcher/url_launcher.dart';
import 'contacts_service.dart';

class CommunicationService {
  final ContactsService _contactsService = ContactsService();

  Future<String> makeCall({String? contactName, String? phoneNumber}) async {
    String? number = phoneNumber;
    if (contactName != null && number == null) {
      number = await _contactsService.getPhoneNumber(contactName);
      if (number == null) return 'Could not find contact "$contactName".';
    }
    if (number == null || number.isEmpty) return 'No phone number provided.';
    try {
      final uri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return 'Calling $number${contactName != null ? ' ($contactName)' : ''}...';
      }
      return 'Cannot make calls on this device.';
    } catch (e) { return 'Error making call: $e'; }
  }

  Future<String> sendSms({String? contactName, String? phoneNumber, required String message}) async {
    String? number = phoneNumber;
    if (contactName != null && number == null) {
      number = await _contactsService.getPhoneNumber(contactName);
      if (number == null) return 'Could not find contact "$contactName".';
    }
    if (number == null || number.isEmpty) return 'No phone number provided.';
    try {
      final uri = Uri(scheme: 'sms', path: number, queryParameters: {'body': message});
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return 'Opening SMS to $number';
      }
      return 'Cannot send SMS on this device.';
    } catch (e) { return 'Error sending SMS: $e'; }
  }

  Future<String> sendEmail({required String to, String? subject, String? body}) async {
    try {
      final uri = Uri(scheme: 'mailto', path: to, queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      });
      if (await canLaunchUrl(uri)) { await launchUrl(uri); return 'Opening email to $to'; }
      return 'Cannot send email on this device.';
    } catch (e) { return 'Error sending email: $e'; }
  }
}
