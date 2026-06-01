import 'package:flutter/material.dart';

import '../../features/sales/models/sale.dart';
import '../../features/sales/models/sale_filter.dart';
import '../../features/sales/services/sale_urgency.dart';
import 'locale_settings.dart';

class AppStrings {
  final bool _pt;

  // ── General actions ──────────────────────────────────────────────────────
  final String cancel;
  final String save;
  final String delete;
  final String edit;
  final String add;
  final String change;
  final String clear;
  final String setDate;
  final String ok;

  // ── Navigation ───────────────────────────────────────────────────────────
  final String navDashboard;
  final String navSales;
  final String navBuyers;
  final String navSettings;

  // ── Auth ─────────────────────────────────────────────────────────────────
  final String email;
  final String password;
  final String signIn;
  final String tryDemo;
  final String errInvalidCredentials;
  final String errNoInternet;
  final String errGeneric;
  final String signOut;
  final String signOutConfirm;

  // ── Demo ─────────────────────────────────────────────────────────────────
  final String demoBanner;
  final String exitDemo;
  final String demoTourTitle;
  final String gotIt;

  // Demo tutorial tip titles & bodies
  final String tipDashboardTitle;
  final String tipDashboardBody;
  final String tipSalesTitle;
  final String tipSalesBody;
  final String tipDetailTitle;
  final String tipDetailBody;
  final String tipComponentsTitle;
  final String tipComponentsBody;
  final String tipBuyersTitle;
  final String tipBuyersBody;
  final String tipShoppingTitle;
  final String tipShoppingBody;
  final String tipNifTitle;
  final String tipNifBody;

  // ── Dashboard ────────────────────────────────────────────────────────────
  final String dashboard;
  final String actionNeeded;
  final String pending;
  final String tooltipYear;
  final String tooltipMonth;
  final String tooltipWeek;
  final String unpaid;
  final String pendingShipment;
  final String assemblyNotReady;
  final String nifRequired;
  final String overdue;

  // ── Sales list ───────────────────────────────────────────────────────────
  final String searchSales;
  final String noSalesFound;
  final String filterSort;
  final String moreFilters;
  final String sortBy;
  final String newestFirst;
  final String oldestFirst;
  final String priceHighToLow;
  final String priceLowToHigh;
  final String noShippedSalesWithPostalCode;

  // ── Progress path / legend ───────────────────────────────────────────────
  final String legendTitle;
  final String nifSheetTitle;
  final String nifSheetBody;
  final String urgencySheetTitle;
  final String urgencyWaitingForMaterials;
  final String urgencyAssemblyNotReady;
  final String urgencyPaymentPending;
  final String urgencyNotYetShipped;
  final String assemblyLegendHeader;
  final String paymentLegendHeader;
  final String shipmentLegendHeader;

  // ── Shopping list ─────────────────────────────────────────────────────────
  final String shoppingList;
  final String nothingLeftToBuy;

  // ── NIF screen ───────────────────────────────────────────────────────────
  final String nifPendingTitle;
  final String noPendingNif;
  final String markAsFiled;
  final String markAsPending;
  final String noNifOnFile;

  // ── Sale form ────────────────────────────────────────────────────────────
  final String newSale;
  final String editSale;
  final String duplicateSale;
  final String sectionBuyer;
  final String sectionItem;
  final String sectionPhotos;
  final String sectionComponents;
  final String sectionPayment;
  final String sectionDelivery;
  final String sectionNotes;
  final String descriptionLabel;
  final String descriptionHint;
  final String descriptionRequired;
  final String assemblyStatusLabel;
  final String priceLabel;
  final String priceRequired;
  final String invalidPrice;
  final String paymentMethodDropdownLabel;
  final String paid;
  final String requiresNifLabel;
  final String shipping;
  final String pickup;
  final String shipToAddressLabel;
  final String postalCodeLabel;
  final String postalCodeHint;
  final String postalCodeRequired;
  final String cttTrackingLabel;
  final String cttTrackingHint;
  final String notesHint;
  final String tapToSelectBuyer;
  final String buyerLabel;
  final String buyerRequired;
  final String errorSavingSale;
  final String addComponentHint;
  final String haveIt;
  final String needToBuy;
  final String noReadyByDate;
  final String noScheduledDate;
  final String readyBy;
  final String scheduledLabel;
  final String removePhotoTitle;
  final String removePhoto;
  final String addPhoto;
  final String takePhoto;
  final String chooseFromGallery;

  // ── Sale detail ──────────────────────────────────────────────────────────
  final String saleFallbackTitle;
  final String duplicateSaleTooltip;
  final String deleteSaleTooltip;
  final String deleteShippedSaleTitle;
  final String deletePaidSaleTitle;
  final String deleteSaleTitle;
  final String markAsPaidLabel;
  final String addCttTracking;
  final String trackingCopied;
  final String shareTracking;
  final String openOnCtt;
  final String atFiled;
  final String atPending;
  final String setScheduledDate;
  final String addNotes;
  final String notesHintDetail;
  final String errorDeletingSale;
  final String errorLoadingDetail;
  final String delivered;
  final String shippedStatus;
  final String inPersonPickup;
  final String nifReceiptRequiredInfo;
  final String atReceiptFiled;
  final String atReceiptPending;
  final String atFiledWithAt;
  final String atFiledWithAtBody;
  final String nifAtSection;

  // ── Sales list ────────────────────────────────────────────────────────────
  final String viewList;
  final String viewTimeline;
  final String viewMap;
  final String locatingPostalCodes;
  final String timelineOverdue;
  final String timelineThisWeek;
  final String timelineNextWeek;
  final String timelineLater;
  final String today;
  final String tomorrow;
  final String pickupNoShipment;

  // ── Buyers list ──────────────────────────────────────────────────────────
  final String buyers;
  final String searchBuyers;
  final String changeView;
  final String alphabetical;
  final String groupByLastPurchase;
  final String buyerRanking;
  final String neverPurchased;
  final String totalSpentMetric;
  final String mostOrdersMetric;
  final String avgOrderMetric;
  final String unpaidBalanceMetric;

  // ── Buyer detail ─────────────────────────────────────────────────────────
  final String purchaseHistory;
  final String addresses;
  final String noPurchasesYet;
  final String noAddressesSaved;
  final String totalSalesLabel;
  final String totalPaidLabel;
  final String unpaidBalanceLabel;
  final String averageOrderLabel;
  final String lastPurchaseLabel;
  final String deleteAddressTitle;
  final String noContactDetails;
  final String defaultChip;
  final String all;
  final String allPaid;
  final String totalOutstanding;
  final String errorLoadingSales;

  // ── Buyer form ───────────────────────────────────────────────────────────
  final String newBuyer;
  final String editBuyer;
  final String addShippingAddress;
  final String addShippingAddressSubtitle;
  final String errSavingBuyer;

  // ── Address form ─────────────────────────────────────────────────────────
  final String newAddress;
  final String editAddress;
  final String defaultAddressLabel;
  final String defaultAddressSubtitle;
  final String errSavingAddress;
  final String addressLabelField;
  final String addressLabelHint;
  final String addressLabelRequired;
  final String addressCountry;
  final String addressCity;
  final String addressCityRequired;
  final String addressStreet;
  final String addressStreetRequired;
  final String addressHouseNumber;
  final String addressHouseNumberHint;
  final String addressHouseNumberRequired;
  final String addressFraction;
  final String addressFractionHint;
  final String addressNotes;
  final String addressNotesHint;

  // ── Buyer picker ─────────────────────────────────────────────────────────
  final String selectBuyer;
  final String noBuyersFound;

  // ── Settings ─────────────────────────────────────────────────────────────
  final String account;
  final String archive;
  final String app;
  final String signedInAs;
  final String exportYear;
  final String exportYearSubtitle;
  final String importArchive;
  final String importArchiveSubtitle;
  final String deleteArchivedYear;
  final String deleteArchivedYearSubtitle;
  final String version;
  final String language;
  final String exportWhichYear;
  final String deleteWhichYear;
  final String alsoDeletePhotos;
  final String alsoDeletePhotosSubtitle;
  final String deletePermanently;
  final String invalidArchive;

  // ── Plural word stems (used in methods below) ─────────────────────────────
  final String _saleSingular;
  final String _salePlural;
  final String _photoSingular;
  final String _photoPlural;
  final String _itemSingular;
  final String _itemPlural;
  final String _orderSingular;
  final String _orderPlural;

  const AppStrings._({
    required bool isPt,
    required this.cancel,
    required this.save,
    required this.delete,
    required this.edit,
    required this.add,
    required this.change,
    required this.clear,
    required this.setDate,
    required this.ok,
    required this.navDashboard,
    required this.navSales,
    required this.navBuyers,
    required this.navSettings,
    required this.email,
    required this.password,
    required this.signIn,
    required this.tryDemo,
    required this.errInvalidCredentials,
    required this.errNoInternet,
    required this.errGeneric,
    required this.signOut,
    required this.signOutConfirm,
    required this.demoBanner,
    required this.exitDemo,
    required this.demoTourTitle,
    required this.gotIt,
    required this.tipDashboardTitle,
    required this.tipDashboardBody,
    required this.tipSalesTitle,
    required this.tipSalesBody,
    required this.tipDetailTitle,
    required this.tipDetailBody,
    required this.tipComponentsTitle,
    required this.tipComponentsBody,
    required this.tipBuyersTitle,
    required this.tipBuyersBody,
    required this.tipShoppingTitle,
    required this.tipShoppingBody,
    required this.tipNifTitle,
    required this.tipNifBody,
    required this.dashboard,
    required this.actionNeeded,
    required this.pending,
    required this.tooltipYear,
    required this.tooltipMonth,
    required this.tooltipWeek,
    required this.unpaid,
    required this.pendingShipment,
    required this.assemblyNotReady,
    required this.nifRequired,
    required this.overdue,
    required this.searchSales,
    required this.noSalesFound,
    required this.filterSort,
    required this.moreFilters,
    required this.sortBy,
    required this.newestFirst,
    required this.oldestFirst,
    required this.priceHighToLow,
    required this.priceLowToHigh,
    required this.noShippedSalesWithPostalCode,
    required this.legendTitle,
    required this.nifSheetTitle,
    required this.nifSheetBody,
    required this.urgencySheetTitle,
    required this.urgencyWaitingForMaterials,
    required this.urgencyAssemblyNotReady,
    required this.urgencyPaymentPending,
    required this.urgencyNotYetShipped,
    required this.assemblyLegendHeader,
    required this.paymentLegendHeader,
    required this.shipmentLegendHeader,
    required this.shoppingList,
    required this.nothingLeftToBuy,
    required this.nifPendingTitle,
    required this.noPendingNif,
    required this.markAsFiled,
    required this.markAsPending,
    required this.noNifOnFile,
    required this.newSale,
    required this.editSale,
    required this.duplicateSale,
    required this.sectionBuyer,
    required this.sectionItem,
    required this.sectionPhotos,
    required this.sectionComponents,
    required this.sectionPayment,
    required this.sectionDelivery,
    required this.sectionNotes,
    required this.descriptionLabel,
    required this.descriptionHint,
    required this.descriptionRequired,
    required this.assemblyStatusLabel,
    required this.priceLabel,
    required this.priceRequired,
    required this.invalidPrice,
    required this.paymentMethodDropdownLabel,
    required this.paid,
    required this.requiresNifLabel,
    required this.shipping,
    required this.pickup,
    required this.shipToAddressLabel,
    required this.postalCodeLabel,
    required this.postalCodeHint,
    required this.postalCodeRequired,
    required this.cttTrackingLabel,
    required this.cttTrackingHint,
    required this.notesHint,
    required this.tapToSelectBuyer,
    required this.buyerLabel,
    required this.buyerRequired,
    required this.errorSavingSale,
    required this.addComponentHint,
    required this.haveIt,
    required this.needToBuy,
    required this.noReadyByDate,
    required this.noScheduledDate,
    required this.readyBy,
    required this.scheduledLabel,
    required this.removePhotoTitle,
    required this.removePhoto,
    required this.addPhoto,
    required this.takePhoto,
    required this.chooseFromGallery,
    required this.saleFallbackTitle,
    required this.duplicateSaleTooltip,
    required this.deleteSaleTooltip,
    required this.deleteShippedSaleTitle,
    required this.deletePaidSaleTitle,
    required this.deleteSaleTitle,
    required this.markAsPaidLabel,
    required this.addCttTracking,
    required this.trackingCopied,
    required this.shareTracking,
    required this.openOnCtt,
    required this.atFiled,
    required this.atPending,
    required this.setScheduledDate,
    required this.addNotes,
    required this.notesHintDetail,
    required this.errorDeletingSale,
    required this.errorLoadingDetail,
    required this.delivered,
    required this.shippedStatus,
    required this.inPersonPickup,
    required this.nifReceiptRequiredInfo,
    required this.atReceiptFiled,
    required this.atReceiptPending,
    required this.atFiledWithAt,
    required this.atFiledWithAtBody,
    required this.nifAtSection,
    required this.viewList,
    required this.viewTimeline,
    required this.viewMap,
    required this.locatingPostalCodes,
    required this.timelineOverdue,
    required this.timelineThisWeek,
    required this.timelineNextWeek,
    required this.timelineLater,
    required this.today,
    required this.tomorrow,
    required this.pickupNoShipment,
    required this.buyers,
    required this.searchBuyers,
    required this.changeView,
    required this.alphabetical,
    required this.groupByLastPurchase,
    required this.buyerRanking,
    required this.neverPurchased,
    required this.totalSpentMetric,
    required this.mostOrdersMetric,
    required this.avgOrderMetric,
    required this.unpaidBalanceMetric,
    required this.purchaseHistory,
    required this.addresses,
    required this.noPurchasesYet,
    required this.noAddressesSaved,
    required this.totalSalesLabel,
    required this.totalPaidLabel,
    required this.unpaidBalanceLabel,
    required this.averageOrderLabel,
    required this.lastPurchaseLabel,
    required this.deleteAddressTitle,
    required this.noContactDetails,
    required this.defaultChip,
    required this.all,
    required this.allPaid,
    required this.totalOutstanding,
    required this.errorLoadingSales,
    required this.newBuyer,
    required this.editBuyer,
    required this.addShippingAddress,
    required this.addShippingAddressSubtitle,
    required this.errSavingBuyer,
    required this.newAddress,
    required this.editAddress,
    required this.defaultAddressLabel,
    required this.defaultAddressSubtitle,
    required this.errSavingAddress,
    required this.addressLabelField,
    required this.addressLabelHint,
    required this.addressLabelRequired,
    required this.addressCountry,
    required this.addressCity,
    required this.addressCityRequired,
    required this.addressStreet,
    required this.addressStreetRequired,
    required this.addressHouseNumber,
    required this.addressHouseNumberHint,
    required this.addressHouseNumberRequired,
    required this.addressFraction,
    required this.addressFractionHint,
    required this.addressNotes,
    required this.addressNotesHint,
    required this.selectBuyer,
    required this.noBuyersFound,
    required this.account,
    required this.archive,
    required this.app,
    required this.signedInAs,
    required this.exportYear,
    required this.exportYearSubtitle,
    required this.importArchive,
    required this.importArchiveSubtitle,
    required this.deleteArchivedYear,
    required this.deleteArchivedYearSubtitle,
    required this.version,
    required this.language,
    required this.exportWhichYear,
    required this.deleteWhichYear,
    required this.alsoDeletePhotos,
    required this.alsoDeletePhotosSubtitle,
    required this.deletePermanently,
    required this.invalidArchive,
    required String saleSingular,
    required String salePlural,
    required String photoSingular,
    required String photoPlural,
    required String itemSingular,
    required String itemPlural,
    required String orderSingular,
    required String orderPlural,
  })  : _pt = isPt,
        _saleSingular = saleSingular,
        _salePlural = salePlural,
        _photoSingular = photoSingular,
        _photoPlural = photoPlural,
        _itemSingular = itemSingular,
        _itemPlural = itemPlural,
        _orderSingular = orderSingular,
        _orderPlural = orderPlural;

  static AppStrings of(BuildContext context) =>
      LocaleSettings.locale.value.languageCode == 'pt' ? pt : en;

  // ── Plural helpers ────────────────────────────────────────────────────────

  String nSales(int n) => '$n ${n == 1 ? _saleSingular : _salePlural}';
  String nPhotos(int n) => '$n ${n == 1 ? _photoSingular : _photoPlural}';
  String nItems(int n) => '$n ${n == 1 ? _itemSingular : _itemPlural}';
  String nOrders(int n) => '$n ${n == 1 ? _orderSingular : _orderPlural}';

  String itemsAcrossSales(int items, int sales) => _pt
      ? '${nItems(items)} em ${nSales(sales)}'
      : '${nItems(items)} across ${nSales(sales)}';

  String nUrgent(int n) => _pt ? '$n urgente${n == 1 ? '' : 's'}' : '$n urgent';

  String nUnpaid(int n) => _pt ? '$n por pagar' : '$n unpaid';

  String daysOverdue(int n) => _pt ? '${n}d em atraso' : '${n}d overdue';

  String nPending(int pending, int filed) => _pt
      ? '$pending pendente${pending == 1 ? '' : 's'} · $filed submetido${filed == 1 ? '' : 's'}'
      : '$pending pending · $filed filed';

  String previousSales(int n, String lastDate) {
    final base = _pt
        ? '${nSales(n)} anteriores'
        : '${nSales(n)} previous';
    return lastDate.isNotEmpty ? '$base · ${_pt ? 'última' : 'last'}: $lastDate' : base;
  }

  // ── Enum label helpers ────────────────────────────────────────────────────

  String filterLabel(SaleFilter f) => _pt
      ? switch (f) {
          SaleFilter.all => 'Todos',
          SaleFilter.unpaid => 'Por pagar',
          SaleFilter.nifRequired => 'NIF necessário',
          SaleFilter.scheduled => 'Agendado',
          SaleFilter.pendingShipment => 'Envio pendente',
          SaleFilter.shipped => 'Enviado',
          SaleFilter.pickup => 'Levantamento',
          SaleFilter.assemblyNotReady => 'Montagem não pronta',
          SaleFilter.overdue => 'Em atraso',
        }
      : switch (f) {
          SaleFilter.all => 'All',
          SaleFilter.unpaid => 'Unpaid',
          SaleFilter.nifRequired => 'NIF required',
          SaleFilter.scheduled => 'Scheduled',
          SaleFilter.pendingShipment => 'Pending shipment',
          SaleFilter.shipped => 'Shipped',
          SaleFilter.pickup => 'Pickup',
          SaleFilter.assemblyNotReady => 'Assembly not ready',
          SaleFilter.overdue => 'Overdue',
        };

  String assemblyLabel(AssemblyStatus s) => _pt
      ? switch (s) {
          AssemblyStatus.notStarted => 'Não iniciado',
          AssemblyStatus.waitingForMaterials => 'Aguarda materiais',
          AssemblyStatus.inProgress => 'Em curso',
          AssemblyStatus.ready => 'Pronto',
        }
      : switch (s) {
          AssemblyStatus.notStarted => 'Not started',
          AssemblyStatus.waitingForMaterials => 'Waiting for materials',
          AssemblyStatus.inProgress => 'In progress',
          AssemblyStatus.ready => 'Ready',
        };

  String paymentMethodLabel(PaymentMethod m) => switch (m) {
        PaymentMethod.mbWay => 'MBWay',
        PaymentMethod.sumup => 'SumUp',
        PaymentMethod.cash => _pt ? 'Numerário' : 'Cash',
        PaymentMethod.bankTransfer =>
          _pt ? 'Transferência bancária' : 'Bank Transfer',
      };

  String shipmentStatusLabel(ShipmentStatus s) => _pt
      ? switch (s) {
          ShipmentStatus.pending => 'Pendente',
          ShipmentStatus.shipped => 'Enviado',
          ShipmentStatus.delivered => 'Entregue',
        }
      : switch (s) {
          ShipmentStatus.pending => 'Pending',
          ShipmentStatus.shipped => 'Shipped',
          ShipmentStatus.delivered => 'Delivered',
        };

  // ── Dynamic string helpers ────────────────────────────────────────────────

  String deleteShippedSaleBody(String status, bool atDone, int photoCount) {
    if (_pt) {
      final photoClause = photoCount > 0
          ? ', e ${nPhotos(photoCount)}'
          : '';
      final atClause = atDone ? ', estado de submissão AT' : '';
      return 'Esta venda já foi $status. '
          'Eliminar remove todos os registos — incluindo histórico de envio'
          '$atClause$photoClause. '
          'Esta ação não pode ser desfeita.';
    }
    final photoClause = photoCount > 0
        ? ', and ${nPhotos(photoCount)}'
        : '';
    final atClause = atDone ? ', AT submission status' : '';
    return 'This sale has already been $status. '
        'Deleting it removes all records — including shipping history'
        '$atClause$photoClause. '
        'This cannot be undone.';
  }

  String deletePaidSaleBody(double price, int photoCount) {
    if (_pt) {
      final photoClause = photoCount > 0
          ? ', junto com ${nPhotos(photoCount)}'
          : '';
      return 'Esta venda tem um pagamento registado de €${price.toStringAsFixed(2)}. '
          'Eliminar remove todos os registos financeiros desta transação'
          '$photoClause. '
          'Esta ação não pode ser desfeita.';
    }
    final photoClause = photoCount > 0
        ? ', along with ${nPhotos(photoCount)}'
        : '';
    return 'This sale has a recorded payment of €${price.toStringAsFixed(2)}. '
        'Deleting it will remove all financial records for this transaction'
        '$photoClause. '
        'This cannot be undone.';
  }

  String deleteSaleBody(int photoCount) {
    if (_pt) {
      final photoClause =
          photoCount > 0 ? ', junto com ${nPhotos(photoCount)}' : '';
      return 'Esta venda será permanentemente eliminada$photoClause. '
          'Esta ação não pode ser desfeita.';
    }
    final photoClause =
        photoCount > 0 ? ', along with ${nPhotos(photoCount)}' : '';
    return 'This sale will be permanently removed$photoClause. '
        'This cannot be undone.';
  }

  String deleteBuyerTitle(String name) =>
      _pt ? 'Eliminar $name?' : 'Delete $name?';

  String deleteBuyerNoSalesBody(String name) => _pt
      ? '$name será permanentemente removido.'
      : '$name will be permanently removed.';

  String deleteBuyerWithSalesBody(String name, int count) {
    if (_pt) {
      return '$name tem ${nSales(count)} registadas. '
          'O histórico de vendas será mantido, mas o perfil de comprador e '
          'todas as moradas guardadas serão removidos.';
    }
    return '$name has ${nSales(count)} on record. '
        'Their sales history will be kept, but the buyer profile and all '
        'saved addresses will be removed.';
  }

  String deleteAddressConfirm(String label) =>
      _pt ? 'Remover "$label"?' : 'Remove "$label"?';

  String noBuyersYet(String query) => query.isEmpty
      ? (_pt
          ? 'Sem compradores. Toque em + para adicionar.'
          : 'No buyers yet. Tap + to add one.')
      : (_pt
          ? 'Nenhum comprador corresponde a "$query".'
          : 'No buyers match "$query".');

  String exportSubject(int year) => 'Latitude Tracker — $year archive';

  String exportingYear(int year) =>
      _pt ? 'A exportar $year...' : 'Exporting $year...';

  String deletingYear(int year, bool deletePhotos) {
    if (_pt) {
      return deletePhotos
          ? 'A eliminar dados e fotos de $year...'
          : 'A eliminar dados de $year...';
    }
    return deletePhotos
        ? 'Deleting $year data and photos...'
        : 'Deleting $year data...';
  }

  String deleteAllYearTitle(int year) =>
      _pt ? 'Eliminar todos os dados de $year?' : 'Delete all $year data?';

  String deleteAllYearBody(int year) => _pt
      ? 'Remove permanentemente todas as vendas de $year. '
          'Certifique-se de que exportou uma cópia de segurança primeiro.'
      : 'This permanently removes all sales from $year. '
          'Make sure you have exported a backup first.';

  String yearDataDeleted(int year) =>
      _pt ? 'Dados de $year eliminados' : '$year data deleted';

  String exportFailed(Object error) =>
      _pt ? 'Falha na exportação: $error' : 'Export failed: $error';

  String deleteFailed(Object error) =>
      _pt ? 'Falha na eliminação: $error' : 'Delete failed: $error';

  String errorSavingSaleMsg(Object error) =>
      _pt ? 'Erro ao guardar venda: $error' : 'Error saving sale: $error';

  String errorDeletingSaleMsg(Object error) =>
      _pt ? 'Erro ao eliminar venda: $error' : 'Error deleting sale: $error';

  String errorSavingBuyerMsg(Object error) =>
      _pt ? 'Erro ao guardar comprador: $error' : 'Error saving buyer: $error';

  String errorSavingAddressMsg(Object error) =>
      _pt ? 'Erro ao guardar morada: $error' : 'Error saving address: $error';

  String errorLoadingSalesMsg(Object error) =>
      _pt ? 'Erro ao carregar vendas: $error' : 'Error loading sales: $error';

  String errorMsg(Object error) =>
      _pt ? 'Erro: $error' : 'Error: $error';

  // Maps English timeline keys (used for ordering) to translated display labels.
  String urgencyReasonLabel(UrgencyReasonType type) => switch (type) {
        UrgencyReasonType.waitingForMaterials => urgencyWaitingForMaterials,
        UrgencyReasonType.assemblyNotReady => urgencyAssemblyNotReady,
        UrgencyReasonType.paymentPending => urgencyPaymentPending,
        UrgencyReasonType.notYetShipped => urgencyNotYetShipped,
      };

  String timelineLabel(String key) {
    if (!_pt) return key;
    return switch (key) {
      'Overdue' => timelineOverdue,
      'This week' => timelineThisWeek,
      'Next week' => timelineNextWeek,
      'Later' => timelineLater,
      _ => key, // Month names auto-translated by Intl.defaultLocale
    };
  }

  String nPostalCodes(int n) => _pt
      ? '$n código${n == 1 ? '' : 's'} postal${n == 1 ? '' : 'is'}'
      : '$n postal code${n == 1 ? '' : 's'}';

  // ─────────────────────────────────────────────────────────────────────────

  static const en = AppStrings._(
    isPt: false,
    cancel: 'Cancel',
    save: 'Save',
    delete: 'Delete',
    edit: 'Edit',
    add: 'Add',
    change: 'Change',
    clear: 'Clear',
    setDate: 'Set date',
    ok: 'OK',
    navDashboard: 'Dashboard',
    navSales: 'Sales',
    navBuyers: 'Buyers',
    navSettings: 'Settings',
    email: 'Email',
    password: 'Password',
    signIn: 'Sign in',
    tryDemo: 'Try demo',
    errInvalidCredentials: 'Invalid email or password.',
    errNoInternet: 'No internet connection.',
    errGeneric: 'Something went wrong. Please try again.',
    signOut: 'Sign out',
    signOutConfirm: 'Sign out?',
    demoBanner: 'Demo mode — changes are not saved',
    exitDemo: 'Exit demo',
    demoTourTitle: 'Demo tour',
    gotIt: 'Got it',
    tipDashboardTitle: 'Dashboard',
    tipDashboardBody:
        'Your month at a glance — total sales, revenue, and pending actions. Warning cards at the top surface unpaid orders and NIF receipts that need filing.',
    tipSalesTitle: 'Sales list',
    tipSalesBody:
        'All your orders, newest first. Each card shows a progress path — assembly → payment → shipping. Tap the path bar for a legend explaining each stage.',
    tipDetailTitle: 'Sale detail',
    tipDetailBody:
        'Tap any sale to open the full detail. From here you can edit every field, manage the materials list, add photos, record a tracking number, and duplicate or delete the order.',
    tipComponentsTitle: 'Components',
    tipComponentsBody:
        'Inside a sale, tick off materials as they arrive. When the last component is checked, the assembly status advances automatically. Swipe a component left to remove it.',
    tipBuyersTitle: 'Buyers',
    tipBuyersBody:
        'Buyer profiles store contact info, NIF, saved addresses, and a live purchase history. Tap any past order to jump straight to its detail screen.',
    tipShoppingTitle: 'Shopping list',
    tipShoppingBody:
        'Access from the Dashboard. Shows every component still needed across all active sales, grouped by urgency — overdue orders appear first so you know what to prioritise on your next supply run.',
    tipNifTitle: 'NIF / AT receipts',
    tipNifBody:
        'Sales that require a fiscal receipt are flagged with a purple badge. Open the NIF screen from the Dashboard to see all pending submissions in one place.',
    dashboard: 'Dashboard',
    actionNeeded: 'Action needed',
    pending: 'Pending',
    tooltipYear: 'Year',
    tooltipMonth: 'Month',
    tooltipWeek: 'Week',
    unpaid: 'Unpaid',
    pendingShipment: 'Pending shipment',
    assemblyNotReady: 'Assembly not ready',
    nifRequired: 'NIF required',
    overdue: 'Overdue',
    searchSales: 'Search buyer or item...',
    noSalesFound: 'No sales found.',
    filterSort: 'Filter & sort',
    moreFilters: 'More filters',
    sortBy: 'Sort by',
    newestFirst: 'Newest first',
    oldestFirst: 'Oldest first',
    priceHighToLow: 'Price: high to low',
    priceLowToHigh: 'Price: low to high',
    noShippedSalesWithPostalCode: 'No shipped sales with postal codes.',
    legendTitle: 'Sale progress',
    nifSheetTitle: 'NIF receipt required',
    nifSheetBody:
        'Payment received — file this sale\'s receipt with AT. The buyer\'s NIF is available on their profile.',
    urgencySheetTitle: 'Action needed',
    urgencyWaitingForMaterials: 'Waiting for materials',
    urgencyAssemblyNotReady: 'Assembly not ready',
    urgencyPaymentPending: 'Payment pending',
    urgencyNotYetShipped: 'Not yet shipped',
    assemblyLegendHeader: 'Assembly',
    paymentLegendHeader: 'Payment',
    shipmentLegendHeader: 'Shipment',
    shoppingList: 'Shopping list',
    nothingLeftToBuy: 'Nothing left to buy!',
    nifPendingTitle: 'NIF receipts pending',
    noPendingNif: 'No pending NIF receipts.',
    markAsFiled: 'Mark as filed',
    markAsPending: 'Mark as pending',
    noNifOnFile: 'No NIF on file',
    newSale: 'New Sale',
    editSale: 'Edit Sale',
    duplicateSale: 'Duplicate Sale',
    sectionBuyer: 'Buyer',
    sectionItem: 'Item',
    sectionPhotos: 'Photos',
    sectionComponents: 'Components needed',
    sectionPayment: 'Payment',
    sectionDelivery: 'Delivery',
    sectionNotes: 'Notes',
    descriptionLabel: 'Description *',
    descriptionHint: 'e.g. Silver necklace with blue beads',
    descriptionRequired: 'Description is required',
    assemblyStatusLabel: 'Assembly status',
    priceLabel: 'Price (€) *',
    priceRequired: 'Price is required',
    invalidPrice: 'Enter a valid price',
    paymentMethodDropdownLabel: 'Payment method',
    paid: 'Paid',
    requiresNifLabel: 'Requires NIF receipt',
    shipping: 'Shipping',
    pickup: 'Pickup',
    shipToAddressLabel: 'Ship to address',
    postalCodeLabel: 'Postal code *',
    postalCodeHint: '0000-000',
    postalCodeRequired: 'Postal code is required',
    cttTrackingLabel: 'CTT tracking code',
    cttTrackingHint: 'Fill in after dropping off at CTT',
    notesHint: 'Gift wrap, colour preference, special instructions...',
    tapToSelectBuyer: 'Tap to select a buyer',
    buyerLabel: 'Buyer *',
    buyerRequired: 'Please select a buyer',
    errorSavingSale: 'Error saving sale',
    addComponentHint: 'Add component...',
    haveIt: 'Have it',
    needToBuy: 'Need to buy',
    noReadyByDate: 'No ready-by date',
    noScheduledDate: 'No scheduled date',
    readyBy: 'Ready by',
    scheduledLabel: 'Scheduled',
    removePhotoTitle: 'Remove photo?',
    removePhoto: 'Remove',
    addPhoto: 'Add photo',
    takePhoto: 'Take photo',
    chooseFromGallery: 'Choose from gallery',
    saleFallbackTitle: 'Sale',
    duplicateSaleTooltip: 'Duplicate sale',
    deleteSaleTooltip: 'Delete sale',
    deleteShippedSaleTitle: 'Delete shipped sale?',
    deletePaidSaleTitle: 'Delete paid sale?',
    deleteSaleTitle: 'Delete sale?',
    markAsPaidLabel: 'Mark as paid',
    addCttTracking: 'Add CTT tracking code',
    trackingCopied: 'Tracking code copied',
    shareTracking: 'Share tracking info',
    openOnCtt: 'Open on CTT website',
    atFiled: 'Filed',
    atPending: 'Pending',
    setScheduledDate: 'Set scheduled date',
    addNotes: 'Add notes',
    notesHintDetail: 'e.g. Gift wrap requested, specific colour...',
    errorDeletingSale: 'Error deleting sale',
    errorLoadingDetail: 'Error',
    delivered: 'delivered',
    shippedStatus: 'shipped',
    inPersonPickup: 'In-person pickup',
    nifReceiptRequiredInfo: 'NIF receipt required',
    atReceiptFiled: 'AT receipt filed',
    atReceiptPending: 'AT receipt pending',
    atFiledWithAt: 'Filed with AT',
    atFiledWithAtBody: 'This receipt has been filed with AT.',
    nifAtSection: 'NIF / AT',
    viewList: 'List',
    viewTimeline: 'Timeline',
    viewMap: 'Map',
    locatingPostalCodes: 'Locating postal codes...',
    timelineOverdue: 'Overdue',
    timelineThisWeek: 'This week',
    timelineNextWeek: 'Next week',
    timelineLater: 'Later',
    today: 'Today',
    tomorrow: 'Tomorrow',
    pickupNoShipment: 'Pickup (no shipment needed)',
    buyers: 'Buyers',
    searchBuyers: 'Search buyers...',
    changeView: 'Change view',
    alphabetical: 'Alphabetical',
    groupByLastPurchase: 'Group by last purchase',
    buyerRanking: 'Buyer ranking',
    neverPurchased: 'Never purchased',
    totalSpentMetric: 'Total spent',
    mostOrdersMetric: 'Most orders',
    avgOrderMetric: 'Avg order',
    unpaidBalanceMetric: 'Unpaid',
    purchaseHistory: 'Purchase history',
    addresses: 'Addresses',
    noPurchasesYet: 'No purchases yet.',
    noAddressesSaved: 'No addresses saved.',
    totalSalesLabel: 'Total sales',
    totalPaidLabel: 'Total paid',
    unpaidBalanceLabel: 'Unpaid balance',
    averageOrderLabel: 'Average order',
    lastPurchaseLabel: 'Last purchase',
    deleteAddressTitle: 'Delete address?',
    noContactDetails: 'No contact details saved.',
    defaultChip: 'Default',
    all: 'All',
    allPaid: 'All paid up!',
    totalOutstanding: 'Total outstanding',
    errorLoadingSales: 'Error loading sales',
    newBuyer: 'New Buyer',
    editBuyer: 'Edit Buyer',
    addShippingAddress: 'Add shipping address',
    addShippingAddressSubtitle: 'Optional — can be added later',
    errSavingBuyer: 'Error saving buyer',
    newAddress: 'New Address',
    editAddress: 'Edit Address',
    defaultAddressLabel: 'Default address',
    defaultAddressSubtitle: 'Pre-filled when creating a new sale',
    errSavingAddress: 'Error saving address',
    addressLabelField: 'Label *',
    addressLabelHint: 'e.g. Home, Work',
    addressLabelRequired: 'Label is required',
    addressCountry: 'Country',
    addressCity: 'City *',
    addressCityRequired: 'City is required',
    addressStreet: 'Street *',
    addressStreetRequired: 'Street is required',
    addressHouseNumber: 'House number *',
    addressHouseNumberHint: 'e.g. 12, 12A, S/N',
    addressHouseNumberRequired: 'House number is required',
    addressFraction: 'Apartment / fraction',
    addressFractionHint: 'e.g. 2º Dto, R/C, Loja',
    addressNotes: 'Delivery notes',
    addressNotesHint: 'e.g. Intercom code 4521, leave with concierge',
    selectBuyer: 'Select Buyer',
    noBuyersFound: 'No buyers found. Tap + to add one.',
    account: 'Account',
    archive: 'Archive',
    app: 'App',
    signedInAs: 'Signed in as',
    exportYear: 'Export year',
    exportYearSubtitle: 'Save a backup of all sales data',
    importArchive: 'Import archive',
    importArchiveSubtitle: 'Browse a previously exported backup',
    deleteArchivedYear: 'Delete archived year',
    deleteArchivedYearSubtitle:
        'Removes a year\'s sales — photos are kept for archive viewing',
    version: 'Version',
    language: 'Language',
    exportWhichYear: 'Export which year?',
    deleteWhichYear: 'Delete which year?',
    alsoDeletePhotos: 'Also delete photos',
    alsoDeletePhotosSubtitle:
        'Removes photos from Storage — archive photo previews will no longer work',
    deletePermanently: 'Delete permanently',
    invalidArchive: 'Invalid archive file',
    saleSingular: 'sale',
    salePlural: 'sales',
    photoSingular: 'photo',
    photoPlural: 'photos',
    itemSingular: 'item',
    itemPlural: 'items',
    orderSingular: 'order',
    orderPlural: 'orders',
  );

  static const pt = AppStrings._(
    isPt: true,
    cancel: 'Cancelar',
    save: 'Guardar',
    delete: 'Eliminar',
    edit: 'Editar',
    add: 'Adicionar',
    change: 'Alterar',
    clear: 'Limpar',
    setDate: 'Definir data',
    ok: 'OK',
    navDashboard: 'Painel',
    navSales: 'Vendas',
    navBuyers: 'Compradores',
    navSettings: 'Definições',
    email: 'Email',
    password: 'Palavra-passe',
    signIn: 'Entrar',
    tryDemo: 'Experimentar',
    errInvalidCredentials: 'Email ou palavra-passe incorretos.',
    errNoInternet: 'Sem ligação à internet.',
    errGeneric: 'Algo correu mal. Tente novamente.',
    signOut: 'Terminar sessão',
    signOutConfirm: 'Terminar sessão?',
    demoBanner: 'Modo de demonstração — as alterações não são guardadas',
    exitDemo: 'Sair',
    demoTourTitle: 'Tour de demonstração',
    gotIt: 'Percebi',
    tipDashboardTitle: 'Painel',
    tipDashboardBody:
        'O seu mês de relance — total de vendas, receita e ações pendentes. Os cartões de aviso no topo mostram encomendas por pagar e recibos NIF por submeter.',
    tipSalesTitle: 'Lista de vendas',
    tipSalesBody:
        'Todas as suas encomendas, mais recentes primeiro. Cada cartão mostra o progresso — montagem → pagamento → envio. Toque na barra de progresso para ver a legenda.',
    tipDetailTitle: 'Detalhe da venda',
    tipDetailBody:
        'Toque numa venda para abrir o detalhe completo. Aqui pode editar todos os campos, gerir a lista de materiais, adicionar fotos, registar um código de rastreio, e duplicar ou eliminar a encomenda.',
    tipComponentsTitle: 'Componentes',
    tipComponentsBody:
        'Dentro de uma venda, assinale os materiais à medida que chegam. Quando o último componente for marcado, o estado de montagem avança automaticamente. Deslize um componente para a esquerda para o remover.',
    tipBuyersTitle: 'Compradores',
    tipBuyersBody:
        'Os perfis de compradores guardam contacto, NIF, moradas e histórico de compras. Toque numa encomenda anterior para ir diretamente ao seu detalhe.',
    tipShoppingTitle: 'Lista de compras',
    tipShoppingBody:
        'Acesse pelo Painel. Mostra todos os componentes ainda em falta nas vendas ativas, ordenados por urgência — as encomendas em atraso aparecem primeiro.',
    tipNifTitle: 'NIF / AT',
    tipNifBody:
        'As vendas que requerem recibo fiscal são sinalizadas com um indicador roxo. Abra o ecrã NIF no Painel para ver todas as submissões pendentes num só lugar.',
    dashboard: 'Painel',
    actionNeeded: 'Ações necessárias',
    pending: 'Pendente',
    tooltipYear: 'Ano',
    tooltipMonth: 'Mês',
    tooltipWeek: 'Semana',
    unpaid: 'Por pagar',
    pendingShipment: 'Envio pendente',
    assemblyNotReady: 'Montagem não pronta',
    nifRequired: 'NIF em falta',
    overdue: 'Em atraso',
    searchSales: 'Pesquisar comprador ou artigo...',
    noSalesFound: 'Sem vendas encontradas.',
    filterSort: 'Filtrar e ordenar',
    moreFilters: 'Mais filtros',
    sortBy: 'Ordenar por',
    newestFirst: 'Mais recentes',
    oldestFirst: 'Mais antigas',
    priceHighToLow: 'Preço: decrescente',
    priceLowToHigh: 'Preço: crescente',
    noShippedSalesWithPostalCode: 'Sem vendas enviadas com código postal.',
    legendTitle: 'Progresso da venda',
    nifSheetTitle: 'Recibo NIF necessário',
    nifSheetBody:
        'Pagamento recebido — submeta o recibo desta venda na AT. O NIF do comprador está disponível no seu perfil.',
    urgencySheetTitle: 'Ações necessárias',
    urgencyWaitingForMaterials: 'Aguarda materiais',
    urgencyAssemblyNotReady: 'Montagem não pronta',
    urgencyPaymentPending: 'Pagamento pendente',
    urgencyNotYetShipped: 'Ainda não enviado',
    assemblyLegendHeader: 'Montagem',
    paymentLegendHeader: 'Pagamento',
    shipmentLegendHeader: 'Envio',
    shoppingList: 'Lista de compras',
    nothingLeftToBuy: 'Nada para comprar!',
    nifPendingTitle: 'Recibos NIF pendentes',
    noPendingNif: 'Sem recibos NIF pendentes.',
    markAsFiled: 'Marcar como submetido',
    markAsPending: 'Marcar como pendente',
    noNifOnFile: 'Sem NIF registado',
    newSale: 'Nova Venda',
    editSale: 'Editar Venda',
    duplicateSale: 'Duplicar Venda',
    sectionBuyer: 'Comprador',
    sectionItem: 'Artigo',
    sectionPhotos: 'Fotos',
    sectionComponents: 'Materiais necessários',
    sectionPayment: 'Pagamento',
    sectionDelivery: 'Entrega',
    sectionNotes: 'Notas',
    descriptionLabel: 'Descrição *',
    descriptionHint: 'ex. Colar de prata com contas azuis',
    descriptionRequired: 'Descrição é obrigatória',
    assemblyStatusLabel: 'Estado de montagem',
    priceLabel: 'Preço (€) *',
    priceRequired: 'Preço é obrigatório',
    invalidPrice: 'Introduza um preço válido',
    paymentMethodDropdownLabel: 'Método de pagamento',
    paid: 'Pago',
    requiresNifLabel: 'Requer recibo com NIF',
    shipping: 'Correio',
    pickup: 'Levantamento',
    shipToAddressLabel: 'Endereço de envio',
    postalCodeLabel: 'Código postal *',
    postalCodeHint: '0000-000',
    postalCodeRequired: 'Código postal é obrigatório',
    cttTrackingLabel: 'Código de rastreio CTT',
    cttTrackingHint: 'Preencher após entrega nos CTT',
    notesHint: 'Embrulho para oferta, cor preferida, instruções especiais...',
    tapToSelectBuyer: 'Toque para selecionar comprador',
    buyerLabel: 'Comprador *',
    buyerRequired: 'Selecione um comprador',
    errorSavingSale: 'Erro ao guardar venda',
    addComponentHint: 'Adicionar material...',
    haveIt: 'Tenho',
    needToBuy: 'Preciso de comprar',
    noReadyByDate: 'Sem data de preparação',
    noScheduledDate: 'Sem data agendada',
    readyBy: 'Pronto a',
    scheduledLabel: 'Agendado',
    removePhotoTitle: 'Remover foto?',
    removePhoto: 'Remover',
    addPhoto: 'Adicionar foto',
    takePhoto: 'Tirar foto',
    chooseFromGallery: 'Escolher da galeria',
    saleFallbackTitle: 'Venda',
    duplicateSaleTooltip: 'Duplicar venda',
    deleteSaleTooltip: 'Eliminar venda',
    deleteShippedSaleTitle: 'Eliminar venda enviada?',
    deletePaidSaleTitle: 'Eliminar venda paga?',
    deleteSaleTitle: 'Eliminar venda?',
    markAsPaidLabel: 'Marcar como pago',
    addCttTracking: 'Adicionar código de rastreio CTT',
    trackingCopied: 'Código copiado',
    shareTracking: 'Partilhar rastreio',
    openOnCtt: 'Abrir no site CTT',
    atFiled: 'Submetido',
    atPending: 'Pendente',
    setScheduledDate: 'Definir data agendada',
    addNotes: 'Adicionar notas',
    notesHintDetail: 'ex. Embrulho para oferta, cor específica...',
    errorDeletingSale: 'Erro ao eliminar venda',
    errorLoadingDetail: 'Erro',
    delivered: 'entregue',
    shippedStatus: 'enviado',
    inPersonPickup: 'Levantamento presencial',
    nifReceiptRequiredInfo: 'Recibo NIF necessário',
    atReceiptFiled: 'Recibo AT submetido',
    atReceiptPending: 'Recibo AT pendente',
    atFiledWithAt: 'Submetido na AT',
    atFiledWithAtBody: 'Este recibo foi submetido na AT.',
    nifAtSection: 'NIF / AT',
    viewList: 'Lista',
    viewTimeline: 'Cronologia',
    viewMap: 'Mapa',
    locatingPostalCodes: 'A localizar códigos postais...',
    timelineOverdue: 'Em atraso',
    timelineThisWeek: 'Esta semana',
    timelineNextWeek: 'Próxima semana',
    timelineLater: 'Mais tarde',
    today: 'Hoje',
    tomorrow: 'Amanhã',
    pickupNoShipment: 'Levantamento (sem envio)',
    buyers: 'Compradores',
    searchBuyers: 'Pesquisar compradores...',
    changeView: 'Alterar vista',
    alphabetical: 'Alfabético',
    groupByLastPurchase: 'Agrupar por última compra',
    buyerRanking: 'Ranking de compradores',
    neverPurchased: 'Sem compras',
    totalSpentMetric: 'Total gasto',
    mostOrdersMetric: 'Mais encomendas',
    avgOrderMetric: 'Valor médio',
    unpaidBalanceMetric: 'Por pagar',
    purchaseHistory: 'Histórico de compras',
    addresses: 'Moradas',
    noPurchasesYet: 'Sem compras registadas.',
    noAddressesSaved: 'Sem moradas guardadas.',
    totalSalesLabel: 'Total de vendas',
    totalPaidLabel: 'Total pago',
    unpaidBalanceLabel: 'Saldo em falta',
    averageOrderLabel: 'Valor médio',
    lastPurchaseLabel: 'Última compra',
    deleteAddressTitle: 'Eliminar morada?',
    noContactDetails: 'Sem dados de contacto guardados.',
    defaultChip: 'Padrão',
    all: 'Todos',
    allPaid: 'Tudo pago!',
    totalOutstanding: 'Total em falta',
    errorLoadingSales: 'Erro ao carregar vendas',
    newBuyer: 'Novo Comprador',
    editBuyer: 'Editar Comprador',
    addShippingAddress: 'Adicionar morada de envio',
    addShippingAddressSubtitle: 'Opcional — pode ser adicionado mais tarde',
    errSavingBuyer: 'Erro ao guardar comprador',
    newAddress: 'Nova Morada',
    editAddress: 'Editar Morada',
    defaultAddressLabel: 'Morada predefinida',
    defaultAddressSubtitle:
        'Preenchida automaticamente na criação de uma venda',
    errSavingAddress: 'Erro ao guardar morada',
    addressLabelField: 'Etiqueta *',
    addressLabelHint: 'ex. Casa, Trabalho',
    addressLabelRequired: 'Etiqueta é obrigatória',
    addressCountry: 'País',
    addressCity: 'Cidade *',
    addressCityRequired: 'Cidade é obrigatória',
    addressStreet: 'Rua *',
    addressStreetRequired: 'Rua é obrigatória',
    addressHouseNumber: 'Número *',
    addressHouseNumberHint: 'ex. 12, 12A, S/N',
    addressHouseNumberRequired: 'Número é obrigatório',
    addressFraction: 'Fração / andar',
    addressFractionHint: 'ex. 2º Dto, R/C, Loja',
    addressNotes: 'Notas de entrega',
    addressNotesHint: 'ex. Código do intercomunicador 4521, deixar com o porteiro',
    selectBuyer: 'Selecionar Comprador',
    noBuyersFound: 'Sem compradores. Toque em + para adicionar.',
    account: 'Conta',
    archive: 'Arquivo',
    app: 'Aplicação',
    signedInAs: 'Sessão iniciada como',
    exportYear: 'Exportar ano',
    exportYearSubtitle: 'Guardar cópia de segurança dos dados de vendas',
    importArchive: 'Importar arquivo',
    importArchiveSubtitle: 'Abrir um arquivo exportado anteriormente',
    deleteArchivedYear: 'Eliminar dados do ano',
    deleteArchivedYearSubtitle:
        'Remove as vendas de um ano — as fotos são mantidas para visualização',
    version: 'Versão',
    language: 'Idioma',
    exportWhichYear: 'Exportar qual ano?',
    deleteWhichYear: 'Eliminar qual ano?',
    alsoDeletePhotos: 'Também eliminar fotos',
    alsoDeletePhotosSubtitle:
        'Remove fotos do armazenamento — as pré-visualizações do arquivo deixarão de funcionar',
    deletePermanently: 'Eliminar permanentemente',
    invalidArchive: 'Ficheiro de arquivo inválido',
    saleSingular: 'venda',
    salePlural: 'vendas',
    photoSingular: 'foto',
    photoPlural: 'fotos',
    itemSingular: 'artigo',
    itemPlural: 'artigos',
    orderSingular: 'encomenda',
    orderPlural: 'encomendas',
  );
}

extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
