import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/scanner/data/fake_product_lookup_repository.dart';
import 'package:team30_app/features/scanner/domain/entities/found_product.dart';
import 'package:team30_app/features/scanner/domain/entities/scanned_code.dart';
import 'package:team30_app/features/scanner/domain/repositories/product_lookup_repository.dart';
import 'package:team30_app/features/scanner/presentation/cubit/scan_cubit.dart';

/// Answers each lookup only when the test completes it.
class _SlowRepository implements ProductLookupRepository {
  final pending = <String, Completer<FoundProduct?>>{};

  @override
  Future<FoundProduct?> findByBarcode(String barcode) =>
      (pending[barcode] = Completer<FoundProduct?>()).future;
}

void main() {
  final now = DateTime(2026, 11, 21, 10);
  const metronidazole = ScannedCode(gtin: '6001007012342');
  const unknown = ScannedCode(gtin: '0000000000000');
  late FakeProductLookupRepository repository;

  setUp(() => repository = FakeProductLookupRepository(clock: () => now));

  blocTest<ScanCubit, ScanState>(
    'a known barcode is found with its batches',
    build: () => ScanCubit(repository),
    act: (cubit) => cubit.lookUp(metronidazole),
    expect: () => [
      const ScanLookingUp(metronidazole),
      isA<ScanFound>()
          .having((s) => s.found.product.name, 'name', 'Metronidazole 400mg')
          .having((s) => s.found.batches, 'batches', hasLength(2))
          .having((s) => s.scannedBatch, 'scanned batch', isNull),
    ],
  );

  blocTest<ScanCubit, ScanState>(
    'a DataMatrix batch number picks out that batch',
    build: () => ScanCubit(repository),
    act: (cubit) => cubit.lookUp(
      const ScannedCode(gtin: '6001007012342', batchNumber: 'mz2410'),
    ),
    skip: 1,
    expect: () => [
      isA<ScanFound>().having(
        (s) => s.scannedBatch?.id,
        'scanned batch',
        'b-mz2410',
      ),
    ],
  );

  blocTest<ScanCubit, ScanState>(
    'an unknown barcode is not found',
    build: () => ScanCubit(repository),
    act: (cubit) => cubit.lookUp(unknown),
    expect: () => [const ScanLookingUp(unknown), const ScanNotFound(unknown)],
  );

  blocTest<ScanCubit, ScanState>(
    'a failed lookup can be retried',
    build: () => ScanCubit(repository..fail = true),
    act: (cubit) async {
      await cubit.lookUp(metronidazole);
      repository.fail = false;
      await cubit.retry();
    },
    expect: () => [
      const ScanLookingUp(metronidazole),
      const ScanFailure(metronidazole, ScanCubit.lookupFailedMessage),
      const ScanLookingUp(metronidazole),
      isA<ScanFound>(),
    ],
  );

  test('a slow earlier lookup never replaces a newer scan', () async {
    final slow = _SlowRepository();
    final cubit = ScanCubit(slow);
    addTearDown(cubit.close);

    final first = cubit.lookUp(unknown);
    final second = cubit.lookUp(metronidazole);
    slow.pending[metronidazole.gtin]!.complete(null);
    await second;
    slow.pending[unknown.gtin]!.complete(null);
    await first;

    expect(cubit.state, const ScanNotFound(metronidazole));
  });

  blocTest<ScanCubit, ScanState>(
    'reset goes back to idle',
    build: () => ScanCubit(repository),
    act: (cubit) async {
      await cubit.lookUp(unknown);
      cubit.reset();
    },
    skip: 2,
    expect: () => [const ScanIdle()],
  );
}
