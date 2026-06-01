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

  static List<Buyer> buyers() => [
        Buyer(
          id: 'demo-buyer-1',
          name: 'Ana Ferreira',
          instagramHandle: 'ana.handcraft',
          nif: '213456789',
          createdAt: _ago(240),
        ),
        Buyer(
          id: 'demo-buyer-2',
          name: 'Mariana Costa',
          instagramHandle: 'mari_acessorios',
          phone: '916234567',
          createdAt: _ago(190),
        ),
        Buyer(
          id: 'demo-buyer-3',
          name: 'João Rodrigues',
          phone: '923456789',
          createdAt: _ago(170),
        ),
        Buyer(
          id: 'demo-buyer-4',
          name: 'Sofia Lopes',
          instagramHandle: 'sofia_style',
          nif: '267891234',
          createdAt: _ago(160),
        ),
        Buyer(
          id: 'demo-buyer-5',
          name: 'Rita Mendes',
          instagramHandle: 'rita.jewels',
          phone: '912345678',
          createdAt: _ago(155),
        ),
        Buyer(
          id: 'demo-buyer-6',
          name: 'Carlos Sousa',
          phone: '931234567',
          nif: '245678901',
          createdAt: _ago(150),
        ),
      ];

  static Map<String, List<BuyerAddress>> addresses() => {
        'demo-buyer-1': [
          const BuyerAddress(
            id: 'demo-addr-1',
            label: 'Home',
            street: 'Rua das Flores 45',
            city: 'Lisboa',
            postalCode: '1200-190',
            isDefault: true,
          ),
        ],
        'demo-buyer-2': [
          const BuyerAddress(
            id: 'demo-addr-2',
            label: 'Home',
            street: 'Av. da República 78',
            city: 'Porto',
            postalCode: '4050-234',
            isDefault: true,
          ),
        ],
        'demo-buyer-6': [
          const BuyerAddress(
            id: 'demo-addr-6',
            label: 'Home',
            street: 'Rua do Comércio 12',
            city: 'Braga',
            postalCode: '4700-220',
            isDefault: true,
          ),
        ],
      };

  static List<Sale> sales() => [
        // ── Active / in-progress sales ──────────────────────────────────────

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
                id: 'dc-6-1',
                name: 'Clear epoxy resin',
                isAvailable: true),
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

        // ── ~2 months ago ────────────────────────────────────────────────────

        // 8. Copper stacking ring — João, delivered
        Sale(
          id: 'demo-sale-8',
          buyerId: 'demo-buyer-3',
          buyerName: 'João Rodrigues',
          itemDescription: 'Hammered copper stacking ring',
          price: 19.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-8-1', name: '2mm copper wire', isAvailable: true),
            const ComponentItem(
                id: 'dc-8-2', name: 'Ring mandrel size 18', isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.delivered,
            postalCode: '4100-123',
            trackingCode: 'RY112233445PT',
          ),
          requiresNif: false,
          photoUrls: const ['demo://photo3'],
          createdAt: _ago(65),
          scheduledDate: _ago(45),
        ),

        // 9. Linen zippered pouch — Ana, delivered, NIF filed
        Sale(
          id: 'demo-sale-9',
          buyerId: 'demo-buyer-1',
          buyerName: 'Ana Ferreira',
          itemDescription: 'Linen zippered pouch with embroidery',
          price: 32.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-9-1', name: 'Natural linen 30×20cm', isAvailable: true),
            const ComponentItem(
                id: 'dc-9-2', name: '20cm zipper', isAvailable: true),
            const ComponentItem(
                id: 'dc-9-3',
                name: 'Embroidery thread set',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.bankTransfer),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.delivered,
            postalCode: '1200-190',
            addressId: 'demo-addr-1',
            trackingCode: 'RY556677889PT',
          ),
          requiresNif: true,
          atSubmissionDone: true,
          photoUrls: const ['demo://photo2', 'demo://photo4'],
          createdAt: _ago(72),
          scheduledDate: _ago(50),
        ),

        // 10. Ceramic bead bracelet — Rita, delivered
        Sale(
          id: 'demo-sale-10',
          buyerId: 'demo-buyer-5',
          buyerName: 'Rita Mendes',
          itemDescription: 'Ceramic bead stretch bracelet',
          price: 27.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-10-1',
                name: 'White ceramic beads 8mm',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-10-2',
                name: 'Elastic stretch cord',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.cash),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.delivered),
          requiresNif: false,
          photoUrls: const ['demo://photo1'],
          createdAt: _ago(80),
          scheduledDate: _ago(58),
        ),

        // ── ~3 months ago ────────────────────────────────────────────────────

        // 11. Embroidered keychain — Mariana, delivered
        Sale(
          id: 'demo-sale-11',
          buyerId: 'demo-buyer-2',
          buyerName: 'Mariana Costa',
          itemDescription: 'Hand-embroidered flower keychain',
          price: 14.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-11-1',
                name: 'Canvas fabric circle',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-11-2',
                name: 'Coloured embroidery floss',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-11-3', name: 'Split ring keychain', isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.delivered,
            postalCode: '4050-234',
            addressId: 'demo-addr-2',
            trackingCode: 'RY334455667PT',
          ),
          requiresNif: false,
          photoUrls: const ['demo://photo4'],
          createdAt: _ago(95),
          scheduledDate: _ago(72),
        ),

        // 12. Resin pendant — Sofia, delivered, NIF filed
        Sale(
          id: 'demo-sale-12',
          buyerId: 'demo-buyer-4',
          buyerName: 'Sofia Lopes',
          itemDescription: 'Pressed flower resin pendant',
          price: 38.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-12-1',
                name: 'UV resin 30ml',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-12-2',
                name: 'Dried violet flowers',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-12-3',
                name: 'Gold-filled bail',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.sumup),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.delivered),
          requiresNif: true,
          atSubmissionDone: true,
          photoUrls: const ['demo://photo2', 'demo://photo3'],
          createdAt: _ago(105),
          scheduledDate: _ago(82),
        ),

        // 13. Leather card wallet — Carlos, delivered
        Sale(
          id: 'demo-sale-13',
          buyerId: 'demo-buyer-6',
          buyerName: 'Carlos Sousa',
          itemDescription: 'Hand-stitched leather card wallet',
          price: 45.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-13-1',
                name: 'Vegetable tanned leather',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-13-2',
                name: 'Waxed linen thread',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-13-3',
                name: 'Leather dye',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.bankTransfer),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.delivered,
            postalCode: '4700-220',
            addressId: 'demo-addr-6',
            trackingCode: 'RY778899001PT',
          ),
          requiresNif: false,
          photoUrls: const ['demo://photo1'],
          createdAt: _ago(115),
          scheduledDate: _ago(90),
        ),

        // ── ~4 months ago ────────────────────────────────────────────────────

        // 14. Terracotta earrings — Ana, delivered
        Sale(
          id: 'demo-sale-14',
          buyerId: 'demo-buyer-1',
          buyerName: 'Ana Ferreira',
          itemDescription: 'Hand-painted terracotta hoop earrings',
          price: 21.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-14-1',
                name: 'Air-dry clay 200g',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-14-2',
                name: 'Acrylic paint set',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-14-3',
                name: 'Gold earring findings',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.delivered),
          requiresNif: false,
          photoUrls: const ['demo://photo3', 'demo://photo4'],
          createdAt: _ago(128),
          scheduledDate: _ago(105),
        ),

        // 15. Rope bracelet set — João, delivered
        Sale(
          id: 'demo-sale-15',
          buyerId: 'demo-buyer-3',
          buyerName: 'João Rodrigues',
          itemDescription: 'Nautical rope bracelet set of 3',
          price: 35.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-15-1',
                name: '3mm cotton rope natural',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-15-2',
                name: 'Sliding knot cord ends',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.cash),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.delivered),
          requiresNif: false,
          photoUrls: const ['demo://photo1'],
          createdAt: _ago(140),
          scheduledDate: _ago(115),
        ),

        // ── ~5–6 months ago ──────────────────────────────────────────────────

        // 16. Friendship bracelets — Rita, delivered
        Sale(
          id: 'demo-sale-16',
          buyerId: 'demo-buyer-5',
          buyerName: 'Rita Mendes',
          itemDescription: 'Woven friendship bracelet trio',
          price: 18.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-16-1',
                name: 'DMC embroidery floss mix',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.delivered),
          requiresNif: false,
          photoUrls: const ['demo://photo2'],
          createdAt: _ago(152),
          scheduledDate: _ago(130),
        ),

        // 17. Silk bookmarks — Mariana, delivered
        Sale(
          id: 'demo-sale-17',
          buyerId: 'demo-buyer-2',
          buyerName: 'Mariana Costa',
          itemDescription: 'Hand-painted silk bookmarks set of 2',
          price: 12.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-17-1', name: 'Silk ribbon 4cm wide', isAvailable: true),
            const ComponentItem(
                id: 'dc-17-2',
                name: 'Silk painting dyes',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.sumup),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.delivered,
            postalCode: '4050-234',
            addressId: 'demo-addr-2',
            trackingCode: 'RY001122334PT',
          ),
          requiresNif: false,
          photoUrls: const [],
          createdAt: _ago(162),
          scheduledDate: _ago(140),
        ),

        // 18. Driftwood mobile — Carlos, delivered
        Sale(
          id: 'demo-sale-18',
          buyerId: 'demo-buyer-6',
          buyerName: 'Carlos Sousa',
          itemDescription: 'Driftwood and shell hanging mobile',
          price: 55.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-18-1', name: 'Driftwood branch 40cm', isAvailable: true),
            const ComponentItem(
                id: 'dc-18-2',
                name: 'Assorted seashells',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-18-3', name: 'Jute twine', isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.bankTransfer),
          shipment: const SaleShipment(
            type: DeliveryType.shipping,
            status: ShipmentStatus.delivered,
            postalCode: '4700-220',
            addressId: 'demo-addr-6',
            trackingCode: 'RY445566778PT',
          ),
          requiresNif: false,
          photoUrls: const ['demo://photo4'],
          createdAt: _ago(170),
          scheduledDate: _ago(148),
        ),

        // 19. Ceramic ring dish — Sofia, delivered
        Sale(
          id: 'demo-sale-19',
          buyerId: 'demo-buyer-4',
          buyerName: 'Sofia Lopes',
          itemDescription: 'Hand-pinched ceramic ring dish',
          price: 29.00,
          assemblyStatus: AssemblyStatus.ready,
          components: [
            const ComponentItem(
                id: 'dc-19-1',
                name: 'Air-dry clay white 500g',
                isAvailable: true),
            const ComponentItem(
                id: 'dc-19-2',
                name: 'Gold leaf sheets',
                isAvailable: true),
          ],
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
              type: DeliveryType.pickup, status: ShipmentStatus.delivered),
          requiresNif: false,
          photoUrls: const ['demo://photo1', 'demo://photo2'],
          createdAt: _ago(178),
          scheduledDate: _ago(155),
        ),
      ];
}
