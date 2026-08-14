import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'support_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subjectController.text.isEmpty) {
      _subjectController.text = AppLocalizations.of(context).contactSubject;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final result = await SupportService.sendContactMessage(
      replyEmail: _emailController.text,
      subject: _subjectController.text,
      message: _messageController.text,
      languageCode: loc.locale.languageCode,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    final message = switch (result) {
      ContactSendStatus.sent => loc.contactSent,
      ContactSendStatus.unavailable => loc.contactRelayUnavailable,
      ContactSendStatus.failed => loc.contactSendFailed,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (result == ContactSendStatus.sent) _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.contact)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.security_outlined),
                      const SizedBox(width: 12),
                      Expanded(child: Text(loc.contactPrivacyBody)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                decoration: InputDecoration(
                  labelText: loc.contactReplyEmail,
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty ||
                      !email.contains('@') ||
                      email.startsWith('@') ||
                      email.endsWith('@') ||
                      email.contains(RegExp(r'[\r\n]'))) {
                    return loc.contactEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _subjectController,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: loc.contactSubjectLabel,
                  prefixIcon: const Icon(Icons.subject),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? loc.contactSubjectRequired
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messageController,
                minLines: 6,
                maxLines: 12,
                maxLength: 4000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: loc.contactMessage,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().length < 10
                    ? loc.contactMessageRequired
                    : null,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(loc.contactSend),
              ),
              if (!SupportService.contactFormConfigured) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  loc.contactTestBuildNotice,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
