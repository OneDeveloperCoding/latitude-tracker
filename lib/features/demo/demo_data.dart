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
          tags: const ['instagram', 'vip'],
          notes: 'Prefers silver. Always pays promptly.',
          createdAt: _ago(540),
        ),
        Buyer(
          id: 'demo-buyer-2',
          name: 'Mariana Costa',
          instagramHandle: 'mari_acessorios',
          phone: '916234567',
          tags: const ['instagram', 'regular'],
          createdAt: _ago(500),
        ),
        Buyer(
          id: 'demo-buyer-3',
          name: 'João Rodrigues',
          phone: '923456789',
          tags: const ['in-person'],
          notes: 'Met at Feira de Janeiro 2024.',
          createdAt: _ago(480),
        ),
        Buyer(
          id: 'demo-buyer-4',
          name: 'Sofia Lopes',
          instagramHandle: 'sofia_style',
          nif: '267891234',
          tags: const ['instagram'],
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
  // Sale 8 and 9 are multi-item sales to exercise the new UI.
  static List<Sale> _activeSales() => [
        // 1. OVERDUE — silver necklace, paid, in progress, NIF pending
        Sale(
          id: 'demo-sale-1',
          buyerId: 'demo-buyer-1',
          buyerName: 'Ana Ferreira',
          items: [
            SaleItem(
              id: 'demo-item-1-1',
              description: 'Silver necklace with natural pearls',
              category: 'Colares',
              price: 45.00,
              assemblyStatus: AssemblyStatus.inProgress,
              components: const [
                ComponentItem(
                    id: 'dc-1-1',
                    name: '45cm silver chain',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-1-2',
                    name: 'Silver lobster clasp',
                    isAvailable: true),
                ComponentItem(
                    id: 'dc-1-3',
                    name: '6mm natural pearls',
                    isAvailable: false),
              ],
              photoUrls: const ['demo://photo1', 'demo://photo2'],
            ),
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
          createdAt: _ago(21),
          scheduledDate: _ago(5),
        ),

        // 2. THIS WEEK — tote bag, unpaid, not started
        Sale(
          id: 'demo-sale-2',
          buyerId: 'demo-buyer-2',
          buyerName: 'Mariana Costa',
          items: [
            SaleItem(
              id: 'demo-item-2-1',
              description: 'Azulejo pattern linen tote bag',
              category: 'Tote Bags',
              price: 35.00,
              assemblyStatus: AssemblyStatus.notStarted,
              components: const [
                ComponentItem(
                    id: 'dc-2-1',
                    name: 'Blue linen fabric 50×40cm',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-2-2',
                    name: 'Natural leather handles',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-2-3',
                    name: 'Checkered cotton lining',
                    isAvailable: false),
              ],
              photoUrls: const ['demo://photo3'],
            ),
          ],
          payment: const SalePayment(
              status: PaymentStatus.unpaid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.pending),
          requiresNif: false,
          createdAt: _ago(14),
          scheduledDate: _from(2),
        ),

        // 3. WAITING FOR MATERIALS — beaded necklace, paid
        Sale(
          id: 'demo-sale-3',
          buyerId: 'demo-buyer-3',
          buyerName: 'João Rodrigues',
          items: [
            SaleItem(
              id: 'demo-item-3-1',
              description: 'Custom wooden bead necklace',
              category: 'Colares',
              price: 28.00,
              assemblyStatus: AssemblyStatus.waitingForMaterials,
              components: const [
                ComponentItem(
                    id: 'dc-3-1',
                    name: '8mm natural wood beads',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-3-2',
                    name: '1mm waxed black cord',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-3-3',
                    name: 'Gold magnetic clasp',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-3-4',
                    name: 'Anchor charm pendant',
                    isAvailable: false),
              ],
            ),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.bankTransfer),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.pending),
          requiresNif: false,
          createdAt: _ago(5),
          scheduledDate: _from(10),
        ),

        // 4. IN PROGRESS — macramé bracelet, one component missing
        Sale(
          id: 'demo-sale-4',
          buyerId: 'demo-buyer-4',
          buyerName: 'Sofia Lopes',
          items: [
            SaleItem(
              id: 'demo-item-4-1',
              description: 'Macramé bracelet with semi-precious stones',
              category: 'Pins',
              price: 22.50,
              assemblyStatus: AssemblyStatus.inProgress,
              components: const [
                ComponentItem(
                    id: 'dc-4-1',
                    name: '2mm natural cotton cord',
                    isAvailable: true),
                ComponentItem(
                    id: 'dc-4-2',
                    name: 'Labradorite stone',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-4-3',
                    name: 'Gold seed beads',
                    isAvailable: true),
              ],
              photoUrls: const ['demo://photo4'],
            ),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.sumup),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.pending,
            postalCode: '2750-345',
          ),
          requiresNif: false,
          createdAt: _ago(10),
        ),

        // 5. NIF FILED — coin purse, shipped, AT done
        Sale(
          id: 'demo-sale-5',
          buyerId: 'demo-buyer-2',
          buyerName: 'Mariana Costa',
          items: [
            SaleItem(
              id: 'demo-item-5-1',
              description: 'Engraved vegan leather coin purse',
              category: 'Crachás',
              price: 18.00,
              assemblyStatus: AssemblyStatus.ready,
              photoUrls: const ['demo://photo2'],
            ),
          ],
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
          createdAt: _ago(30),
          scheduledDate: _ago(14),
        ),

        // 6. DELIVERED — resin earrings, historical
        Sale(
          id: 'demo-sale-6',
          buyerId: 'demo-buyer-1',
          buyerName: 'Ana Ferreira',
          items: [
            SaleItem(
              id: 'demo-item-6-1',
              description: 'Ocean blue resin drop earrings',
              category: 'Brincos',
              price: 24.00,
              assemblyStatus: AssemblyStatus.ready,
              components: const [
                ComponentItem(
                    id: 'dc-6-1',
                    name: 'Clear epoxy resin',
                    isAvailable: true),
                ComponentItem(
                    id: 'dc-6-2',
                    name: 'Blue and white pigments',
                    isAvailable: true),
                ComponentItem(
                    id: 'dc-6-3',
                    name: 'Hypoallergenic earring hooks',
                    isAvailable: true),
              ],
              photoUrls: const ['demo://photo1', 'demo://photo3'],
            ),
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
          createdAt: _ago(60),
          scheduledDate: _ago(21),
        ),

        // 7. UNPAID — gold hoop earrings, next week
        Sale(
          id: 'demo-sale-7',
          buyerId: 'demo-buyer-3',
          buyerName: 'João Rodrigues',
          items: [
            SaleItem(
              id: 'demo-item-7-1',
              description: 'Gold hoop earrings 40mm',
              category: 'Brincos',
              price: 16.00,
              assemblyStatus: AssemblyStatus.notStarted,
            ),
          ],
          payment: const SalePayment(
              status: PaymentStatus.unpaid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.pending,
            postalCode: '4100-123',
          ),
          requiresNif: false,
          createdAt: _ago(7),
          scheduledDate: _from(9),
        ),

        // 8. MULTI-ITEM — necklace + earrings bundle, in progress
        Sale(
          id: 'demo-sale-8',
          buyerId: 'demo-buyer-5',
          buyerName: 'Rita Mendes',
          items: [
            SaleItem(
              id: 'demo-item-8-1',
              description: 'Gold-fill layered necklace',
              category: 'Colares',
              price: 38.00,
              assemblyStatus: AssemblyStatus.inProgress,
              components: const [
                ComponentItem(
                    id: 'dc-8-1',
                    name: '14k gold-fill cable chain 45cm',
                    isAvailable: true),
                ComponentItem(
                    id: 'dc-8-2',
                    name: 'Gold-fill lobster clasp',
                    isAvailable: false),
              ],
              photoUrls: const ['demo://photo1'],
            ),
            SaleItem(
              id: 'demo-item-8-2',
              description: 'Matching gold-fill stud earrings',
              category: 'Brincos',
              price: 22.00,
              assemblyStatus: AssemblyStatus.ready,
              components: const [
                ComponentItem(
                    id: 'dc-8-3',
                    name: 'Gold-fill disc blanks',
                    isAvailable: true),
                ComponentItem(
                    id: 'dc-8-4',
                    name: 'Gold-fill earring posts',
                    isAvailable: true),
              ],
              photoUrls: const ['demo://photo2'],
            ),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.pending,
            postalCode: '1100-001',
          ),
          requiresNif: false,
          createdAt: _ago(4),
          scheduledDate: _from(6),
        ),

        // 9. MULTI-ITEM — gift set with three pieces, waiting for materials
        Sale(
          id: 'demo-sale-9',
          buyerId: 'demo-buyer-6',
          buyerName: 'Carlos Sousa',
          items: [
            SaleItem(
              id: 'demo-item-9-1',
              description: 'Labradorite pendant necklace',
              category: 'Colares',
              price: 48.00,
              assemblyStatus: AssemblyStatus.waitingForMaterials,
              components: const [
                ComponentItem(
                    id: 'dc-9-1',
                    name: 'Labradorite cabochon 20mm',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-9-2',
                    name: 'Silver wire 0.6mm',
                    isAvailable: false),
              ],
            ),
            SaleItem(
              id: 'demo-item-9-2',
              description: 'Labradorite drop earrings',
              category: 'Brincos',
              price: 32.00,
              assemblyStatus: AssemblyStatus.waitingForMaterials,
              components: const [
                ComponentItem(
                    id: 'dc-9-3',
                    name: 'Labradorite chips 8mm',
                    isAvailable: false),
                ComponentItem(
                    id: 'dc-9-4',
                    name: 'Silver earring hooks',
                    isAvailable: false),
              ],
            ),
            SaleItem(
              id: 'demo-item-9-3',
              description: 'Linen gift pouch',
              category: 'Tote Bags',
              price: 8.00,
              assemblyStatus: AssemblyStatus.notStarted,
              components: const [
                ComponentItem(
                    id: 'dc-9-5',
                    name: 'Natural linen drawstring bag',
                    isAvailable: false),
              ],
            ),
          ],
          payment: const SalePayment(
              status: PaymentStatus.unpaid, method: PaymentMethod.bankTransfer),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.pending,
            postalCode: '4700-220',
            addressId: 'demo-addr-6',
          ),
          requiresNif: true,
          atSubmissionDone: false,
          createdAt: _ago(2),
          scheduledDate: _from(14),
        ),
      ];

  // ── Historical sale generator ─────────────────────────────────────────────
  //
  // Fixed seed (42) ensures identical data on every demo entry.
  // Monthly weights model seasonal demand: quiet Aug, busy Dec/pre-Easter.

  // (description, component names, min price, max price, category)
  static final _templates =
      <(String, List<String>, double, double, String)>[
    (
      'Silver ring with moonstone',
      ['Sterling silver band', 'Moonstone cabochon 6mm', 'Ring mandrel'],
      28.0, 48.0, 'Crachás'
    ),
    (
      'Resin drop earrings',
      ['UV resin 30ml', 'Mica pigment set', 'Gold earring hooks'],
      18.0, 32.0, 'Brincos'
    ),
    (
      'Macramé bracelet',
      ['2mm cotton cord natural', 'Seed beads mix', 'Gold lobster clasp'],
      20.0, 35.0, 'Pins'
    ),
    (
      'Linen tote bag',
      ['Natural linen fabric 50×40cm', 'Leather handles pair', 'Cotton lining'],
      32.0, 52.0, 'Tote Bags'
    ),
    (
      'Ceramic ring dish',
      ['Air-dry clay 200g', 'Acrylic paint set', 'Gloss varnish'],
      20.0, 35.0, 'Crachás'
    ),
    (
      'Polymer clay stud earrings',
      ['Polymer clay white 50g', 'Stainless steel earring posts', 'Liquid glaze'],
      14.0, 24.0, 'Brincos'
    ),
    (
      'Pressed flower resin pendant',
      ['UV resin 15ml', 'Dried wildflowers', 'Gold-fill bail', '45cm chain'],
      24.0, 40.0, 'Colares'
    ),
    (
      'Friendship bracelet set of 3',
      ['DMC embroidery floss assorted'],
      10.0, 18.0, 'Pins'
    ),
    (
      'Soy candle in amber jar',
      ['Soy wax 200g', 'Fragrance oil', 'Cotton wick', 'Amber glass jar'],
      15.0, 28.0, 'Crachás'
    ),
    (
      'Wire-wrapped crystal pendant',
      ['Copper wire 0.8mm', 'Clear quartz point', '45cm copper chain'],
      22.0, 38.0, 'Colares'
    ),
    (
      'Embroidered canvas pouch',
      ['Canvas fabric', 'Metal zipper 20cm', 'Embroidery floss set'],
      22.0, 36.0, 'Crachás'
    ),
    (
      'Tassel earrings',
      ['Size 11 seed beads', 'Gold earring hooks', 'Nylon beading thread'],
      16.0, 28.0, 'Brincos'
    ),
    (
      'Macramé wall hanging',
      ['5mm cotton rope 10m', 'Wooden dowel 40cm', 'Hanging cord'],
      42.0, 68.0, 'Crachás'
    ),
    (
      'Gold-fill hoop earrings',
      ['14k gold-fill wire 20 gauge', 'Ring mandrel'],
      18.0, 32.0, 'Brincos'
    ),
    (
      'Dried herb bookmark',
      ['Laminating pouches', 'Dried lavender and rosemary', 'Satin ribbon'],
      10.0, 16.0, 'Crachás'
    ),
    (
      'Labradorite pendant necklace',
      ['Labradorite cabochon', 'Silver wire 0.6mm', '45cm silver chain'],
      38.0, 58.0, 'Colares'
    ),
    (
      'Driftwood and shell mobile',
      ['Driftwood branch 40cm', 'Assorted seashells', 'Jute twine'],
      45.0, 72.0, 'Crachás'
    ),
    (
      'Crystal beaded anklet',
      ['3mm crystal beads mix', 'Elastic stretch cord', 'Gold lobster clasp'],
      14.0, 24.0, 'Pins'
    ),
    (
      'Drawstring cotton bag',
      ['Cotton muslin fabric', 'Natural drawstring cord', 'Iron-on label'],
      18.0, 30.0, 'Tote Bags'
    ),
    (
      'Hammered copper cuff',
      ['Copper sheet 1mm', 'Sandpaper assorted', 'Liver of sulfur patina'],
      26.0, 42.0, 'Crachás'
    ),
    (
      'Silk scrunchie set of 2',
      ['Silk charmeuse fabric', 'Elastic 1cm wide', 'Thread to match'],
      14.0, 22.0, 'Crachás'
    ),
    (
      'Hand-painted silk scarf',
      ['Silk habotai 90×90cm', 'Silk painting dyes', 'Gutta resist'],
      42.0, 68.0, 'Crachás'
    ),
    (
      'Natural wood bead necklace',
      ['8mm wood beads assorted', 'Waxed linen cord', 'Toggle clasp'],
      22.0, 38.0, 'Colares'
    ),
    (
      'Charm bracelet',
      ['Gold-fill cable chain', 'Gold jump rings', 'Assorted charms set'],
      28.0, 45.0, 'Pins'
    ),
    (
      'Vegan leather coin purse',
      ['Vegan leather 20×15cm', 'Metal zipper 15cm', 'Cotton lining'],
      16.0, 28.0, 'Crachás'
    ),
    (
      'Clay hair clip set of 3',
      ['Polymer clay mixed colours', 'Alligator clip bases', 'Strong glue'],
      14.0, 22.0, 'Crachás'
    ),
    (
      'Terracotta hoop earrings',
      ['Air-dry clay 100g', 'Acrylic paints', 'Gold earring findings'],
      16.0, 28.0, 'Brincos'
    ),
    (
      'Embroidered fabric keychain',
      ['Canvas fabric circle', 'Embroidery floss set', 'Split keyring'],
      10.0, 16.0, 'Crachás'
    ),
    (
      'Cotton rope plant hanger',
      ['5mm cotton rope 5m', 'Wooden ring 10cm', 'Scissors'],
      30.0, 50.0, 'Crachás'
    ),
    (
      'Glitter resin ring',
      ['UV resin 10ml', 'Holographic glitter', 'Adjustable ring blank'],
      18.0, 30.0, 'Crachás'
    ),
  ];

  static const _postalCodes = [
    '1000-001', '1100-001', '1200-190', '1300-001', '1500-001',
    '2750-345', '2800-001', '2900-001', '3000-001', '3810-001',
    '4050-234', '4100-123', '4200-001', '4400-001', '4700-220',
    '5000-001', '7000-001', '8000-001',
  ];

  // Sales count per month — index 0 = January.
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

        final rawPrice =
            template.$3 + rng.nextDouble() * (template.$4 - template.$3);
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
        final photoUrls =
            List.generate(photoCount, (j) => 'demo://photo${(j % 4) + 1}');

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
          items: [
            SaleItem(
              id: 'demo-hist-item-$seq',
              description: template.$1,
              category: template.$5,
              price: price,
              assemblyStatus: AssemblyStatus.ready,
              components: components,
              photoUrls: photoUrls,
            ),
          ],
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
          createdAt: createdAt,
          scheduledDate: scheduledDate,
        ));

        seq++;
      }
    }

    return sales;
  }
}
