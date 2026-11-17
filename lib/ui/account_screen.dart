import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/account_api.dart';
import '../data/store.dart';
import 'components.dart';

String accountLocation(Uri returnTo) => Uri(
  path: '/account',
  queryParameters: {'return': returnTo.toString()},
).toString();

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final store = ref.read(storeProvider);
    if (store.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    try {
      await store.authenticate(
        _email.text.trim(),
        _password.text,
        name: _register ? _name.text.trim() : null,
      );
      TextInput.finishAutofillContext();
    } on AccountApiError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Не удалось открыть аккаунт. Попробуйте ещё раз.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(storeProvider).busy;
    return PageFrame(
      title: _register ? 'Создать аккаунт' : 'Войти в Tripavela',
      leading: BackButton(onPressed: busy ? null : () => context.go('/home')),
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Войдите, чтобы сохранять прогулки, поездки и открытия в атласе.',
              ),
              const SizedBox(height: 24),
              if (_register) ...[
                TextFormField(
                  controller: _name,
                  enabled: !busy,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Имя'),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Введите имя.' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                enabled: !busy,
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  counterText: '',
                ),
                validator: (value) =>
                    RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value!.trim())
                    ? null
                    : 'Введите корректный email.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                enabled: !busy,
                maxLength: 256,
                obscureText: !_showPassword,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: [
                  _register
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  counterText: '',
                  suffixIcon: IconButton(
                    tooltip: _showPassword
                        ? 'Скрыть пароль'
                        : 'Показать пароль',
                    onPressed: busy
                        ? null
                        : () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Введите пароль.';
                  if (_register && value.runes.length < 12) {
                    return 'Не менее 12 символов.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: busy ? null : _submit,
                child: Text(
                  busy
                      ? 'Подождите…'
                      : _register
                      ? 'Зарегистрироваться'
                      : 'Войти',
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () {
                        _form.currentState!.reset();
                        _password.clear();
                        setState(() {
                          _register = !_register;
                          _showPassword = false;
                          _error = null;
                        });
                      },
                child: Text(
                  _register ? 'Уже есть аккаунт? Войти' : 'Создать аккаунт',
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => context.go('/home'),
                child: const Text('Продолжить без аккаунта'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
