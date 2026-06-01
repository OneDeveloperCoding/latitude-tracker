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
          createdAt: _ago(150),
        ),
        Buyer(
          id: 'demo-buyer-3',
          name: 'João Rodrigues',
          phone: '923456789',
          createdAt: _ago(90),
        ),
        Buyer(
          id: 'demo-buyer-4',
          name: 'Sofia Lopes',
          instagramHandle: 'sofia_style',
          nif: '267891234',
          createdAt: _ago(30),
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
      };

  static List<Sale> sales() => [
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

        // 2. THIS WEEK — tote bag, unpaid, not started, components needed
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

        // 3. WAITING FOR MATERIALS — beaded necklace, paid, event order
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

        // 4. IN PROGRESS — macramé bracelet, paid, one component missing
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

        // 5. NIF FILED — coin purse, paid, shipped, AT done
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

        // 6. DELIVERED — resin earrings, historical record
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
      ];
}
