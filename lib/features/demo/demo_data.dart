import 'dart:math';

import '../buyers/models/buyer.dart';
import '../buyers/models/buyer_address.dart';
import '../sales/models/sale.dart';

class DemoData {
  DemoData._();

  static DateTime _ago(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  }

  static DateTime _from(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  // ── Buyers ───────────────────────────────────────────────────────────────

  static List<Buyer> buyers() => [
        Buyer(
          id: 'demo-buyer-1',
          name: 'Ana Ferreira',
          instagramHandle: 'ana.handcraft',
          nif: '213456789',
          createdAt: _ago(540),
        ),
        Buyer(
          id: 'demo-buyer-2',
          name: 'Mariana Costa',
          instagramHandle: 'mari_acessorios',
          phone: '916234567',
          createdAt: _ago(500),
        ),
        Buyer(
          id: 'demo-buyer-3',
          name: 'João Rodrigues',
          phone: '923456789',
          createdAt: _ago(480),
        ),
        Buyer(
          id: 'demo-buyer-4',
          name: 'Sofia Lopes',
          instagramHandle: 'sofia_style',
          nif: '267891234',
          createdAt: _ago(460),
        ),
        Buyer(
          id: 'demo-buyer-5',
          name: 'Rita Mendes',
          instagramHandle: 'rita.jewels',
          phone: '912345678',
          createdAt: _ago(450),
        ),
        Buyer(
          id: 'demo-buyer-6',
          name: 'Carlos Sousa',
          phone: '931234567',
          nif: '245678901',
          createdAt: _ago(440),
        ),
      ];

  static Map<String, List<BuyerAddress>> addresses() => {
        'demo-buyer-1': [
          const BuyerAddress(
            id: 'demo-addr-1',
            label: 'Home',
            street: 'Rua das Flores',
            houseNumber: '45',
            city: 'Lisboa',
            postalCode: '1200-190',
            isDefault: true,
          ),
        ],
        'demo-buyer-2': [
          const BuyerAddress(
            id: 'demo-addr-2',
            label: 'Home',
            street: 'Av. da República',
            houseNumber: '78',
            city: 'Porto',
            postalCode: '4050-234',
            isDefault: true,
          ),
        ],
        'demo-buyer-6': [
          const BuyerAddress(
            id: 'demo-addr-6',
            label: 'Home',
            street: 'Rua do Comércio',
            houseNumber: '12',
            city: 'Braga',
            postalCode: '4700-220',
            isDefault: true,
          ),
        ],
      };

  // ── Sales ─────────────────────────────────────────────────────────────────

  static List<Sale> sales() => [
        ..._activeSales(),
        ..._generateHistorical(Random(42)),
      ];

  // 7 hand-crafted sales that cover every active state visible in the UI.
  static List<Sale> _activeSales() => [
        // 1. OVERDUE — silver necklace, paid, in progress, NIF pending
        Sale(
          id: 'demo-sale-1',
          buyerId: 'demo-buyer-1',
          buyerName: 'Ana Ferreira',
          itemDescription: 'Silver necklace with natural pearls',
          price: 45.00,
          assemblyStatus: AssemblyStatus.inProgress,
          components: [
            const ComponentItem(
                id: 'dc-1-1', name: '45cm silver chain', isAvailable: false),
            const ComponentItem(
                id: 'dc-1-2', name: 'Silver lobster clasp', isAvailable: true),
            const ComponentItem(
                id: 'dc-1-3', name: '6mm natural pearls', isAvailable: false),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.pending,
            postalCode: '1200-190',
            addressId: 'demo-addr-1',
          ),
          requiresNif: true,
          atSubmissionDone: false,
          photoUrls: const ['demo://photo1', 'demo://photo2'],
          createdAt: _ago(21),
          scheduledDate: _ago(5),
        ),

        // 2. THIS WEEK — tote bag, unpaid, not started
        Sale(
          id: 'demo-sale-2',
          buyerId: 'demo-buyer-2',
          buyerName: 'Mariana Costa',
          itemDescription: 'Azulejo pattern linen tote bag',
          price: 35.00,
          assemblyStatus: AssemblyStatus.notStarted,
          components: [
            const ComponentItem(
                id: 'dc-2-1',
                name: 'Blue linen fabric 50×40cm',
                isAvailable: false),
            const ComponentItem(
                id: 'dc-2-2',
                name: 'Natural leather handles',
                isAvailable: false),
            const ComponentItem(
                id: 'dc-2-3',
                name: 'Checkered cotton lining',
                isAvailable: false),
          ],
          payment: const SalePayment(
              status: PaymentStatus.unpaid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.pending),
          requiresNif: false,
          photoUrls: const ['demo://photo3'],
          createdAt: _ago(14),
          scheduledDate: _from(2),
        ),

        // 3. WAITING FOR MATERIALS — beaded necklace, paid
        Sale(
          id: 'demo-sale-3',
          buyerId: 'demo-buyer-3',
          buyerName: 'João Rodrigues',
          itemDescription: 'Custom wooden bead necklace',
          price: 28.00,
          assemblyStatus: AssemblyStatus.waitingForMaterials,
          components: [
            const ComponentItem(
                id: 'dc-3-1',
                name: '8mm natural wood beads',
                isAvailable: false),
            const ComponentItem(
                id: 'dc-3-2',
                name: '1mm waxed black cord',
                isAvailable: false),
            const ComponentItem(
                id: 'dc-3-3',
                name: 'Gold magnetic clasp',
                isAvailable: false),
            const ComponentItem(
                id: 'dc-3-4',
                name: 'Anchor charm pendant',
                isAvailable: false),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid,
              method: PaymentMethod.bankTransfer),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.pending),
          requiresNif: false,
          photoUrls: const [],
          createdAt: _ago(5),
          scheduledDate: _from(10),
        ),

        // 4. IN PROGRESS — macramé bracelet, one component missing
        Sale(
          id: 'demo-sale-4',
          buyerId: 'demo-buyer-4',
          buyerName: 'Sofia Lopes',
          itemDescription: 'Macramé bracelet with semi-precious stones',
          price: 22.50,
          assemblyStatus: AssemblyStatus.inProgress,
          components: [
            const ComponentItem(
                id: 'dc-4-1',
                name: '2mm natural cotton cord',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-4-2',
                name: 'Labradorite stone',
                isAvailable: false),
            const ComponentItem(
                id: 'dc-4-3', name: 'Gold seed beads', isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.sumup),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.pending,
            postalCode: '2750-345',
          ),
          requiresNif: false,
          photoUrls: const ['demo://photo4'],
          createdAt: _ago(10),
        ),

        // 5. NIF FILED — coin purse, shipped, AT done
        Sale(
          id: 'demo-sale-5',
          buyerId: 'demo-buyer-2',
          buyerName: 'Mariana Costa',
          itemDescription: 'Engraved vegan leather coin purse',
          price: 18.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.shipped,
            postalCode: '4050-234',
            addressId: 'demo-addr-2',
            trackingCode: 'RY123456789PT',
          ),
          requiresNif: true,
          atSubmissionDone: true,
          photoUrls: const ['demo://photo2'],
          createdAt: _ago(30),
          scheduledDate: _ago(14),
        ),

        // 6. DELIVERED — resin earrings, historical
        Sale(
          id: 'demo-sale-6',
          buyerId: 'demo-buyer-1',
          buyerName: 'Ana Ferreira',
          itemDescription: 'Ocean blue resin drop earrings',
          price: 24.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-6-1', name: 'Clear epoxy resin', isAvailable: true),
            const ComponentItem(
                id: 'dc-6-2',
                name: 'Blue and white pigments',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-6-3',
                name: 'Hypoallergenic earring hooks',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.cash),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.delivered,
            postalCode: '1200-190',
            addressId: 'demo-addr-1',
            trackingCode: 'RY987654321PT',
          ),
          requiresNif: false,
          photoUrls: const ['demo://photo1', 'demo://photo3'],
          createdAt: _ago(60),
          scheduledDate: _ago(21),
        ),

        // 7. UNPAID — gold hoop earrings, next week
        Sale(
          id: 'demo-sale-7',
          buyerId: 'demo-buyer-3',
          buyerName: 'João Rodrigues',
          itemDescription: 'Gold hoop earrings 40mm',
          price: 16.00,
          assemblyStatus: AssemblyStatus.notStarted,
          components: [],
          payment: const SalePayment(
              status: PaymentStatus.unpaid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.pending,
            postalCode: '4100-123',
          ),
          requiresNif: false,
          photoUrls: const [],
          createdAt: _ago(7),
          scheduledDate: _from(9),
        ),
      ];

  // ── Historical sale generator ─────────────────────────────────────────────
  //
  // Fixed seed (42) ensures identical data on every demo entry.
  // Monthly weights model seasonal demand: quiet Aug, busy Dec/pre-Easter.

  // (description, component names, min price, max price)
  static final _templates = <(String, List<String>, double, double)>[
    (
      'Silver ring with moonstone',
      ['Sterling silver band', 'Moonstone cabochon 6mm', 'Ring mandrel'],
      28.0, 48.0
    ),
    (
      'Resin drop earrings',
      ['UV resin 30ml', 'Mica pigment set', 'Gold earring hooks'],
      18.0, 32.0
    ),
    (
      'Macramé bracelet',
      ['2mm cotton cord natural', 'Seed beads mix', 'Gold lobster clasp'],
      20.0, 35.0
    ),
    (
      'Linen tote bag',
      ['Natural linen fabric 50×40cm', 'Leather handles pair', 'Cotton lining'],
      32.0, 52.0
    ),
    (
      'Ceramic ring dish',
      ['Air-dry clay 200g', 'Acrylic paint set', 'Gloss varnish'],
      20.0, 35.0
    ),
    (
      'Polymer clay stud earrings',
      ['Polymer clay white 50g', 'Stainless steel earring posts', 'Liquid glaze'],
      14.0, 24.0
    ),
    (
      'Pressed flower resin pendant',
      ['UV resin 15ml', 'Dried wildflowers', 'Gold-fill bail', '45cm chain'],
      24.0, 40.0
    ),
    (
      'Friendship bracelet set of 3',
      ['DMC embroidery floss assorted'],
      10.0, 18.0
    ),
    (
      'Soy candle in amber jar',
      ['Soy wax 200g', 'Fragrance oil', 'Cotton wick', 'Amber glass jar'],
      15.0, 28.0
    ),
    (
      'Wire-wrapped crystal pendant',
      ['Copper wire 0.8mm', 'Clear quartz point', '45cm copper chain'],
      22.0, 38.0
    ),
    (
      'Embroidered canvas pouch',
      ['Canvas fabric', 'Metal zipper 20cm', 'Embroidery floss set'],
      22.0, 36.0
    ),
    (
      'Tassel earrings',
      ['Size 11 seed beads', 'Gold earring hooks', 'Nylon beading thread'],
      16.0, 28.0
    ),
    (
      'Macramé wall hanging',
      ['5mm cotton rope 10m', 'Wooden dowel 40cm', 'Hanging cord'],
      42.0, 68.0
    ),
    (
      'Gold-fill hoop earrings',
      ['14k gold-fill wire 20 gauge', 'Ring mandrel'],
      18.0, 32.0
    ),
    (
      'Dried herb bookmark',
      ['Laminating pouches', 'Dried lavender and rosemary', 'Satin ribbon'],
      10.0, 16.0
    ),
    (
      'Labradorite pendant necklace',
      ['Labradorite cabochon', 'Silver wire 0.6mm', '45cm silver chain'],
      38.0, 58.0
    ),
    (
      'Driftwood and shell mobile',
      ['Driftwood branch 40cm', 'Assorted seashells', 'Jute twine'],
      45.0, 72.0
    ),
    (
      'Crystal beaded anklet',
      ['3mm crystal beads mix', 'Elastic stretch cord', 'Gold lobster clasp'],
      14.0, 24.0
    ),
    (
      'Drawstring cotton bag',
      ['Cotton muslin fabric', 'Natural drawstring cord', 'Iron-on label'],
      18.0, 30.0
    ),
    (
      'Hammered copper cuff',
      ['Copper sheet 1mm', 'Sandpaper assorted', 'Liver of sulfur patina'],
      26.0, 42.0
    ),
    (
      'Silk scrunchie set of 2',
      ['Silk charmeuse fabric', 'Elastic 1cm wide', 'Thread to match'],
      14.0, 22.0
    ),
    (
      'Hand-painted silk scarf',
      ['Silk habotai 90×90cm', 'Silk painting dyes', 'Gutta resist'],
      42.0, 68.0
    ),
    (
      'Natural wood bead necklace',
      ['8mm wood beads assorted', 'Waxed linen cord', 'Toggle clasp'],
      22.0, 38.0
    ),
    (
      'Charm bracelet',
      ['Gold-fill cable chain', 'Gold jump rings', 'Assorted charms set'],
      28.0, 45.0
    ),
    (
      'Vegan leather coin purse',
      ['Vegan leather 20×15cm', 'Metal zipper 15cm', 'Cotton lining'],
      16.0, 28.0
    ),
    (
      'Clay hair clip set of 3',
      ['Polymer clay mixed colours', 'Alligator clip bases', 'Strong glue'],
      14.0, 22.0
    ),
    (
      'Terracotta hoop earrings',
      ['Air-dry clay 100g', 'Acrylic paints', 'Gold earring findings'],
      16.0, 28.0
    ),
    (
      'Embroidered fabric keychain',
      ['Canvas fabric circle', 'Embroidery floss set', 'Split keyring'],
      10.0, 16.0
    ),
    (
      'Cotton rope plant hanger',
      ['5mm cotton rope 5m', 'Wooden ring 10cm', 'Scissors'],
      30.0, 50.0
    ),
    (
      'Glitter resin ring',
      ['UV resin 10ml', 'Holographic glitter', 'Adjustable ring blank'],
      18.0, 30.0
    ),
  ];

  static const _postalCodes = [
    '1000-001', '1100-001', '1200-190', '1300-001', '1500-001',
    '2750-345', '2800-001', '2900-001', '3000-001', '3810-001',
    '4050-234', '4100-123', '4200-001', '4400-001', '4700-220',
    '5000-001', '7000-001', '8000-001',
  ];

  // Sales count per month — index 0 = January.
  // Peaks: December (pre-Christmas), March (pre-Easter), November (Black Friday).
  // Quiet: July–August (summer slowdown).
  static const _monthWeights = [11, 13, 17, 16, 13, 9, 7, 7, 12, 14, 17, 21];

  static const _buyerPool = [
    ('demo-buyer-1', 'Ana Ferreira'),
    ('demo-buyer-2', 'Mariana Costa'),
    ('demo-buyer-3', 'João Rodrigues'),
    ('demo-buyer-4', 'Sofia Lopes'),
    ('demo-buyer-5', 'Rita Mendes'),
    ('demo-buyer-6', 'Carlos Sousa'),
  ];

  // MBWay appears 3× to reflect its dominance in Portuguese handmade markets.
  static const _paymentPool = [
    PaymentMethod.mbWay,
    PaymentMethod.mbWay,
    PaymentMethod.mbWay,
    PaymentMethod.sumup,
    PaymentMethod.sumup,
    PaymentMethod.bankTransfer,
    PaymentMethod.cash,
  ];

  static List<Sale> _generateHistorical(Random rng) {
    final now = DateTime.now();
    final sales = <Sale>[];
    int seq = 1;

    for (int monthsBack = 1; monthsBack <= 18; monthsBack++) {
      int month = now.month - monthsBack;
      int year = now.year;
      while (month <= 0) {
        month += 12;
        year--;
      }

      final count = _monthWeights[month - 1];
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int i = 0; i < count; i++) {
        final day = rng.nextInt(daysInMonth) + 1;
        final createdAt = DateTime(year, month, day);
        if (createdAt.isAfter(now)) continue;

        final template = _templates[rng.nextInt(_templates.length)];
        final buyer = _buyerPool[rng.nextInt(_buyerPool.length)];

        final rawPrice = template.$3 + rng.nextDouble() * (template.$4 - template.$3);
        final price = (rawPrice * 2).round() / 2.0;

        final components = template.$2
            .asMap()
            .entries
            .map((e) => ComponentItem(
                  id: 'dc-h$seq-${e.key}',
                  name: e.value,
                  isAvailable: true,
                ))
            .toList();

        final isShipping = rng.nextDouble() < 0.65;
        final requiresNif = rng.nextDouble() < 0.15;
        final method = _paymentPool[rng.nextInt(_paymentPool.length)];

        final photoCount = rng.nextInt(3); // 0–2 photos
        final photoUrls = List.generate(
            photoCount, (j) => 'demo://photo${(j % 4) + 1}');

        final hasScheduled = rng.nextDouble() < 0.8;
        final scheduledDate = hasScheduled
            ? createdAt.add(Duration(days: 7 + rng.nextInt(22)))
            : null;

        final trackingCode = isShipping
            ? 'RY${(100000000 + rng.nextInt(899999999)).toString()}PT'
            : null;

        sales.add(Sale(
          id: 'demo-hist-$seq',
          buyerId: buyer.$1,
          buyerName: buyer.$2,
          itemDescription: template.$1,
          price: price,
          assemblyStatus: AssemblyStatus.ready,
          components: components,
          payment: SalePayment(status: PaymentStatus.paid, method: method),
          shipment: SaleShipment(
            type: isShipping ? DeliveryType.shipping : DeliveryType.pickup,
            status: ShipmentStatus.delivered,
            postalCode: isShipping
                ? _postalCodes[rng.nextInt(_postalCodes.length)]
                : null,
            trackingCode: trackingCode,
          ),
          requiresNif: requiresNif,
          atSubmissionDone: requiresNif,
          photoUrls: photoUrls,
          createdAt: createdAt,
          scheduledDate: scheduledDate,
        ));

        seq++;
      }
    }

    return sales;
  }
}
