import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/payment_method.dart';
import 'package:team30_app/features/pos/presentation/cubit/payment_form_cubit.dart';

void main() {
  test('starts on cash with no cash received', () {
    final state = PaymentFormCubit().state;

    expect(state.method, PaymentMethods.cash);
    expect(state.isCash, isTrue);
    expect(state.cashReceived, isNull);
  });

  blocTest<PaymentFormCubit, PaymentFormState>(
    'reads the cash typed, ignoring anything but digits',
    build: PaymentFormCubit.new,
    act: (cubit) => cubit
      ..setCashReceived('10,000')
      ..setCashReceived('RWF 5 000')
      ..setCashReceived(''),
    expect: () => const [
      PaymentFormState(cashReceived: 10000),
      PaymentFormState(cashReceived: 5000),
      PaymentFormState(),
    ],
  );

  blocTest<PaymentFormCubit, PaymentFormState>(
    'switches method and keeps the cash typed',
    build: PaymentFormCubit.new,
    seed: () => const PaymentFormState(cashReceived: 2000),
    act: (cubit) => cubit.selectMethod(PaymentMethods.card),
    expect: () => const [
      PaymentFormState(method: PaymentMethods.card, cashReceived: 2000),
    ],
  );

  blocTest<PaymentFormCubit, PaymentFormState>(
    'ignores a method the app does not offer',
    build: PaymentFormCubit.new,
    act: (cubit) => cubit.selectMethod('Cheque'),
    expect: () => <PaymentFormState>[],
  );

  group('change for a total of 6,900', () {
    test('is unknown until cash is typed', () {
      const state = PaymentFormState();
      expect(state.changeFor(6900), isNull);
      expect(state.covers(6900), isFalse);
    });

    test('is null while the cash is short', () {
      const state = PaymentFormState(cashReceived: 5000);
      expect(state.changeFor(6900), isNull);
      expect(state.covers(6900), isFalse);
    });

    test('is 0 for the exact amount', () {
      const state = PaymentFormState(cashReceived: 6900);
      expect(state.changeFor(6900), 0);
      expect(state.covers(6900), isTrue);
    });

    test('is what is left over from more cash', () {
      const state = PaymentFormState(cashReceived: 10000);
      expect(state.changeFor(6900), 3100);
    });

    test('is always 0 for Mobile Money and Card, with no cash needed', () {
      for (final method in [PaymentMethods.mobileMoney, PaymentMethods.card]) {
        final state = PaymentFormState(method: method);
        expect(state.isCash, isFalse);
        expect(state.changeFor(6900), 0);
        expect(state.covers(6900), isTrue);
      }
    });
  });
}
