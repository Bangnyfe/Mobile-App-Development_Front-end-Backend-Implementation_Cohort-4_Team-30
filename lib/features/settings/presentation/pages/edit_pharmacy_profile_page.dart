import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../domain/entities/pharmacy_account.dart';
import '../../domain/pharmacy_profile_rules.dart';
import '../cubit/account_cubit.dart';
import '../widgets/account_subpage.dart';

/// Settings > Pharmacy profile > Edit: the owner changes the pharmacy's
/// name, location and contact. Saving goes back to Pharmacy profile.
class EditPharmacyProfilePage extends StatelessWidget {
  const EditPharmacyProfilePage({super.key});

  static const savedMessage = 'Pharmacy profile saved';
  static const ownerOnlyMessage =
      'Only the pharmacy owner can edit the pharmacy profile.';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      // Build the form once, from the details when the page opened, so
      // typing isn't undone if the account reloads.
      buildWhen: (previous, current) => previous is! AccountLoaded,
      builder: (context, state) => switch (state) {
        AccountLoaded(:final account) when account.user.isOwner => _ProfileForm(
          pharmacy: account.pharmacy,
        ),
        AccountLoaded() => Scaffold(
          appBar: AppBar(title: const Text('Edit pharmacy profile')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(ownerOnlyMessage, textAlign: TextAlign.center),
            ),
          ),
        ),
        AccountFailure(:final message) => Scaffold(
          appBar: AppBar(title: const Text('Edit pharmacy profile')),
          body: AccountErrorView(message: message),
        ),
        AccountLoading() => Scaffold(
          appBar: AppBar(title: const Text('Edit pharmacy profile')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.pharmacy.name);
  late final _district = TextEditingController(text: widget.pharmacy.district);
  late final _city = TextEditingController(text: widget.pharmacy.city);
  late final _phone = TextEditingController(text: widget.pharmacy.phone);
  late final _address = TextEditingController(text: widget.pharmacy.address);
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _district, _city, _phone, _address]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    String? optional(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : text;
    }

    final error = await context.read<AccountCubit>().updatePharmacy(
      Pharmacy(
        id: widget.pharmacy.id,
        name: _name.text.trim(),
        district: _district.text.trim(),
        city: _city.text.trim(),
        phone: optional(_phone),
        address: optional(_address),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text(EditPharmacyProfilePage.savedMessage)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit pharmacy profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        TextFormField(
                          key: const Key('pharmacyNameField'),
                          controller: _name,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Pharmacy name',
                          ),
                          validator: PharmacyProfileRules.name,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('districtField'),
                          controller: _district,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'District',
                            hintText: 'e.g. Nyarugenge',
                          ),
                          validator: PharmacyProfileRules.district,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('cityField'),
                          controller: _city,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            hintText: 'e.g. Kigali',
                          ),
                          validator: PharmacyProfileRules.city,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('addressField'),
                          controller: _address,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Address (optional)',
                            hintText: 'e.g. KN 4 Ave',
                          ),
                          validator: PharmacyProfileRules.address,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('phoneField'),
                          controller: _phone,
                          enabled: !_saving,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            hintText: 'e.g. +250 788 123 456',
                          ),
                          validator: PharmacyProfileRules.phone,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PinnedBottomBar(
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Saving',
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
