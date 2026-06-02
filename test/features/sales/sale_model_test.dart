import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

ComponentItem _component(String id, {required bool available}) =>
    ComponentItem(id: id, name: id, isAvailable: available);

void main() {
  group('Sale.deriveAssemblyStatus', () {
    test('waitingForMaterials is never changed', () {
      final allAvailable = [_component('a', available: true)];
      expect(
        Sale.deriveAssemblyStatus(allAvailable, AssemblyStatus.waitingForMaterials),
        AssemblyStatus.waitingForMaterials,
      );
    });

    test('notStarted + all available → ready', () {
      final components = [
        _component('a', available: true),
        _component('b', available: true),
      ];
      expect(
        Sale.deriveAssemblyStatus(components, AssemblyStatus.notStarted),
        AssemblyStatus.ready,
      );
    });

    test('inProgress + all available → ready', () {
      final components = [_component('a', available: true)];
      expect(
        Sale.deriveAssemblyStatus(components, AssemblyStatus.inProgress),
        AssemblyStatus.ready,
      );
    });

    test('ready + some unavailable → inProgress', () {
      final components = [
        _component('a', available: true),
        _component('b', available: false),
      ];
      expect(
        Sale.deriveAssemblyStatus(components, AssemblyStatus.ready),
        AssemblyStatus.inProgress,
      );
    });

    test('notStarted + some unavailable stays notStarted', () {
      final components = [_component('a', available: false)];
      expect(
        Sale.deriveAssemblyStatus(components, AssemblyStatus.notStarted),
        AssemblyStatus.notStarted,
      );
    });

    test('empty components + notStarted stays notStarted', () {
      // allAvailable requires isNotEmpty — empty list is treated as not ready.
      expect(
        Sale.deriveAssemblyStatus(const [], AssemblyStatus.notStarted),
        AssemblyStatus.notStarted,
      );
    });

    test('empty components + ready → inProgress', () {
      // If all components were removed after the assembly was marked ready,
      // it reverts to inProgress.
      expect(
        Sale.deriveAssemblyStatus(const [], AssemblyStatus.ready),
        AssemblyStatus.inProgress,
      );
    });
  });
}
