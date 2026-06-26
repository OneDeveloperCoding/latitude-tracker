import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/locale_settings.dart';
import 'package:latitude_tracker/features/dashboard/models/dashboard_stats.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency.dart';

enum AppStrings {
  en._(
    isPt: false,
    cancel: 'Cancel',
    save: 'Save',
    delete: 'Delete',
    edit: 'Edit',
    add: 'Add',
    copy: 'Copy',
    change: 'Change',
    clear: 'Clear',
    setDate: 'Set date',
    ok: 'OK',
    discard: 'Discard',
    discardChanges: 'Discard changes?',
    discardChangesMessage: 'You have unsaved changes. Are you sure you want to'
    ' discard them?',
    navDashboard: 'Dashboard',
    navSales: 'Sales',
    navBuyers: 'Buyers',
    navSettings: 'Settings',
    email: 'Email',
    emailRequired: 'Email is required',
    password: 'Password',
    passwordRequired: 'Password is required',
    signIn: 'Sign in',
    signInWithGoogle: 'Sign in with Google',
    tryDemo: 'Try demo',
    errInvalidCredentials: 'Invalid email or password.',
    errNoInternet: 'No internet connection.',
    errGeneric: 'Something went wrong. Please try again.',
    errGoogleCredentialInUse:
        'This Google account is already linked to a different account.'
        ' Sign in with email/password instead.',
    errGoogleNoData: 'This Google account has no app data.'
        ' Sign in with email first, then connect Google in Settings.',
    signOut: 'Sign out',
    signOutConfirm: 'Sign out?',
    demoBanner: 'Demo mode — changes are not saved',
    exitDemo: 'Exit demo',
    demoUser: 'Demo user',
    demoTourTitle: 'Demo tour',
    appTour: 'App tour',
    tutorialNext: 'Next',
    tutorialBack: 'Back',
    tutorialGetStarted: 'Get started',
    tourWelcomeTitle: 'Welcome to Latitude Tracker',
    tourWelcomeBody:
        'Your private sales journal for handmade accessories. Track every sale'
        ' — from Instagram DM or market stall — through assembly, payment, and'
        ' shipment, all in one place.',
    tourCreateSaleTitle: 'Creating a sale',
    tourCreateSaleBody:
        'Tap + on the Sales tab to start. Pick or create a buyer, then add one'
        ' or more items — each with its own description, category, price,'
        ' assembly status, and photos. Finish with payment method, delivery'
        ' details, and any special notes.',
    tourSaleDetailTitle: 'Managing a sale',
    tourSaleDetailBody:
        'Tap any sale card to open its detail. Toggle payment with one tap, advance assembly per item, record a CTT tracking code when you ship, and follow the NIF/AT compliance row from "receipt requested" to "filed".',
    tourDashboardTitle: 'Your dashboard',
    tourDashboardBody:
        'See revenue for any period — scroll the month chips or switch between'
        ' weekly, monthly, and yearly. Tap the insights icon to explore'
        ' analytics by category. Below the revenue card, action rows for Money,'
        ' Production, and Planning show exactly what needs attention; tap any'
        ' row to jump to the filtered sales list.',
    tourBuyersTitle: 'Buyer profiles',
    tourBuyersBody:
        'Every buyer builds a profile over time: saved addresses with'
        ' Portuguese postal-code auto-fill, NIF for fiscal receipts, and a full'
        ' purchase history you can drill into by year and month. Returning'
        ' buyers get a hint when you create a new sale.',
    tourAnalyticsTitle: 'Analytics',
    tourAnalyticsBody:
        'Tap the insights icon on the revenue card to open the Analytics'
        ' screen. A stacked bar chart shows revenue by category across 6'
        ' periods. Filter by category, toggle between revenue and count, and'
        ' check the payment method breakdown to see how buyers prefer to pay.',
    tourDiscoverTitle: 'More to explore',
    tourDiscoverBody: 'Four screens worth knowing:',
    tourGemShoppingTitle: 'Shopping list',
    tourGemShoppingBody:
        'Every component still needed across open sales, grouped by sale — so'
        ' you know exactly what to buy on your next supply run.',
    tourGemMapTitle: 'Sales heat map',
    tourGemMapBody:
        'A geographic view of where your shipped sales go, grouped by postal'
        ' code on a map of Portugal.',
    tourGemUnpaidTitle: 'Unpaid balances',
    tourGemUnpaidBody:
        'Outstanding payments grouped by buyer, sorted by total amount owed —'
        ' your go-to for follow-ups.',
    tourGemNifTitle: 'NIF receipts',
    tourGemNifBody:
        'All pending AT submissions in one place, with a one-tap toggle to mark'
        ' each one filed.',
    dashboard: 'Dashboard',
    actionNeeded: 'Action needed',
    pending: 'Pending',
    tooltipYear: 'Year',
    tooltipMonth: 'Month',
    tooltipWeek: 'Week',
    unpaid: 'Unpaid',
    pendingShipment: 'Pending shipment',
    assemblyNotReady: 'Needs materials',
    readyToAssemble: 'Ready to assemble',
    nifRequired: 'NIF required',
    overdue: 'Overdue',
    dashboardTrends: 'Analytics',
    dashboardGroupMoney: 'Finances',
    dashboardGroupLogistics: 'Logistics',
    dashboardGroupCompliance: 'Compliance',
    dashboardGroupProduction: 'Production',
    dashboardGroupPlanning: 'Planning',
    inTransit: 'In transit',
    upcomingScheduled: 'Upcoming',
    dashboardTopCategories: 'Top categories',
    dashboardViewTrends: 'View analytics',
    trendsTitle: 'Analytics',
    trendsNoPreviousData: 'No data for this period',
    trendsMetricRevenue: 'Revenue',
    trendsMetricCount: 'Count',
    trendsAllCategories: 'All',
    trendsPaymentMethods: 'Payment methods',
    trendsRevenueByCategory: 'Revenue by category',
    searchSales: 'Search buyer or item...',
    noSalesFound: 'No sales found.',
    filterSort: 'Filter & sort',
    moreFilters: 'Filters',
    sortBy: 'Sort by',
    sortDimensionDate: 'Date',
    sortDimensionPrice: 'Price',
    noShippedSalesWithPostalCode: 'No shipped sales with postal codes.',
    clearAllFilters: 'Clear all',
    year: 'Year',
    buyer: 'Buyer',
    stageDone: 'Done',
    nifSheetTitle: 'NIF receipt required',
    nifSheetBody:
        "Payment received — file this sale's receipt with AT."
        " The buyer's NIF is available on their profile.",
    readyButUnpaidTitle: 'Ready but unpaid',
    readyButUnpaidBody:
        'Everything is assembled and ready to go, but payment has not been'
        ' received yet.',
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
    addNif: 'Add NIF',
    categoryLabel: 'Category *',
    categoryRequired: 'Category is required',
    categoryPickerHint: 'Tap to choose',
    searchOrAddCategory: 'Search or add a category...',
    categoryFilterHeader: 'Category',
    tagsLabel: 'Tags',
    addTagHint: 'Add a tag...',
    buyerTagsFilterHeader: 'Tags',
    buyerNotesHint: 'Notes about this buyer...',
    newSale: 'New Sale',
    editSale: 'Edit Sale',
    sectionBuyer: 'Buyer',
    sectionItem: 'Item',
    sectionItems: 'Items',
    addItem: 'Add item',
    editItem: 'Edit item',
    saleTotal: 'Total',
    atLeastOneItem: 'Add at least one item',
    sectionPhotos: 'Photos',
    sectionComponents: 'Components needed',
    sectionPayment: 'Payment',
    sectionDelivery: 'Delivery',
    deliveryStatusLabel: 'Delivery status',
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
    handDelivery: 'Hand delivery',
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
    componentNotesHint: 'e.g. darker blue, 45cm length',
    componentNotesLabel: 'Notes',
    noPhotos: 'No photos',
    noReadyByDate: 'No ready-by date',
    noScheduledDate: 'No scheduled date',
    readyBy: 'Ready by',
    scheduledLabel: 'Scheduled',
    receivedLabel: 'Received',
    removePhotoTitle: 'Remove photo?',
    removePhoto: 'Remove',
    addPhoto: 'Add photo',
    takePhoto: 'Take photo',
    chooseFromGallery: 'Choose from gallery',
    saleFallbackTitle: 'Sale',
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
    shippedAtLabel: 'Shipped at',
    setShippedAt: 'Set shipped date & time',
    addNotes: 'Add notes',
    notesHintDetail: 'e.g. Gift wrap requested, specific colour...',
    errorDeletingSale: 'Error deleting sale',
    saleDeletedUndo: 'Sale deleted',
    undo: 'Undo',
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
    viewMap: 'Map',
    geographicSalesTitle: 'Sales by Location',
    allYears: 'All',
    locatingPostalCodes: 'Locating postal codes...',
    geoSalesPortugal: 'Portugal',
    geoSalesInternational: 'International',
    geoSalesSwitchToMap: 'Map view',
    geoSalesSwitchToList: 'List view',
    timelineOverdue: 'Overdue',
    timelineThisWeek: 'This week',
    timelineNextWeek: 'Next week',
    timelineLater: 'Later',
    today: 'Today',
    tomorrow: 'Tomorrow',
    buyers: 'Buyers',
    searchBuyers: 'Search buyers...',
    changeView: 'Change view',
    alphabetical: 'Alphabetical',
    groupByLastPurchase: 'Group by last purchase',
    buyerRanking: 'Buyer ranking',
    neverPurchased: 'Never purchased',
    totalSpentMetric: 'Total spent',
    mostSalesMetric: 'Most sales',
    avgSaleMetric: 'Avg sale',
    unpaidBalanceMetric: 'Unpaid',
    purchaseHistory: 'Purchase history',
    addresses: 'Addresses',
    noPurchasesYet: 'No purchases yet.',
    last3Months: 'Last 3 months',
    noAddressesSaved: 'No addresses saved.',
    totalSalesLabel: 'Total sales',
    totalPaidLabel: 'Total paid',
    unpaidBalanceLabel: 'Unpaid balance',
    averageSaleLabel: 'Average sale',
    lastPurchaseLabel: 'Last purchase',
    addressCopied: 'Address copied',
    deleteAddressTitle: 'Delete address?',
    noContactDetails: 'No contact details saved.',
    couldNotOpenInstagram: 'Could not open Instagram',
    couldNotOpenMaps: 'Could not open Maps',
    call: 'Call',
    sendMessage: 'Send message',
    couldNotCall: 'Could not open phone app',
    couldNotSendMessage: 'Could not open messaging app',
    openInMaps: 'Open in Maps',
    defaultChip: 'Default',
    all: 'All',
    allPaid: 'All paid up!',
    totalOutstanding: 'Total outstanding',
    errorLoadingSales: 'Error loading sales',
    errorLoadingRepairs: 'Error loading repairs',
    errorLoadingBuyers: 'Error loading buyers',
    errorLoadingData: 'Error loading data',
    retry: 'Retry',
    newBuyer: 'New Buyer',
    editBuyer: 'Edit Buyer',
    buyerNameLabel: 'Name',
    buyerNameRequired: 'Name is required',
    instagramHandleLabel: 'Instagram handle',
    phoneNumberLabel: 'Phone number',
    nifLabel: 'NIF',
    nifInvalid: 'NIF must be 9 digits',
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
    addressDefaultLabel: 'Home',
    addressCountry: 'Country',
    countryDisplayNames: {
      'Portugal': 'Portugal',
      'Spain': 'Spain',
      'France': 'France',
      'Germany': 'Germany',
      'United Kingdom': 'United Kingdom',
      'Netherlands': 'Netherlands',
      'Belgium': 'Belgium',
      'Italy': 'Italy',
      'Switzerland': 'Switzerland',
      'Other': 'Other',
    },
    postalCodeInvalidFormat: 'Format: 0000-000',
    postalCodeNoResults: 'No results found for this postal code',
    selectStreet: 'Select street',
    addressCity: 'Locality *',
    addressCityRequired: 'Locality is required',
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
    connectGoogle: 'Connect Google account',
    googleConnected: 'Google account connected',
    exportYear: 'Export year',
    exportYearSubtitle: 'Save a backup of all sales data',
    importArchive: 'Import archive',
    importArchiveSubtitle: 'Browse a previously exported backup',
    deleteArchivedYear: 'Delete archived year',
    deleteArchivedYearSubtitle:
        "Removes a year's sales — photos are kept for archive viewing",
    version: 'Version',
    checkForUpdates: 'Check for updates',
    updateChecking: 'Checking for updates…',
    updateDownloading: 'Downloading update…',
    updateCheckFailed: 'Check failed — tap to retry',
    updateDownloadFailed: 'Download failed — tap to retry',
    updateInstallBlocked:
        'Install permission denied. Enable "Install unknown apps" in Settings.',
    language: 'Language',
    exportWhichYear: 'Export which year?',
    deleteWhichYear: 'Delete which year?',
    alsoDeletePhotos: 'Also delete photos',
    alsoDeletePhotosSubtitle:
        'Removes photos from Storage — archive photo previews will no longer'
        ' work',
    deletePermanently: 'Delete permanently',
    invalidArchive: 'Invalid archive file',
    continueAction: 'Continue',
    dangerZone: 'Danger zone',
    resetApp: 'Reset app',
    resetAppSubtitle: 'Delete all data and start fresh',
    resetAppConfirmTitle: 'Reset the app?',
    resetAppConfirmBody:
        'This will permanently delete all Sales, Buyers, and Addresses. '
        'Export a backup first if you want to keep your data.',
    resetAppFinalTitle: 'This cannot be undone',
    resetAppFinalBody:
        'You are about to permanently delete everything. '
        'There is no way to recover this data.',
    resetEverything: 'Delete everything',
    resettingApp: 'Resetting app…',
    resetAppFailed: 'Reset failed',
    selectSalePrompt: 'Select a sale to view details',
    repairs: 'Repairs',
    newRepair: 'New Repair',
    repairProblemLabel: 'Problem',
    repairReturnStatusLabel: 'Return delivery status',
    repairFilterActiveOnly: 'Active only',
    repairFilterShowAll: 'Show all',
    searchRepairs: 'Search repairs...',
    editRepair: 'Edit Repair',
    deleteRepair: 'Delete repair',
    deleteRepairTitle: 'Delete repair?',
    noRepairsFound: 'No repairs yet.',
    repairContact: 'Contact *',
    repairContactRequired: 'Contact is required',
    repairContactHint: 'Name or Instagram handle',
    repairContactFreeText: 'Free-text name',
    repairItemDescription: 'Item description *',
    repairItemDescriptionRequired: 'Item description is required',
    repairProblemDescription: 'Problem description *',
    repairProblemDescriptionRequired: 'Problem description is required',
    repairWorkDone: 'Work done',
    repairMaterialsCost: 'Materials cost (€)',
    repairStatusLabel: 'Status',
    repairLinkedSale: 'Linked sale',
    repairLinkedSaleNone: 'No linked sale',
    repairReturnDelivery: 'Return delivery',
    repairSectionContact: 'Contact',
    repairSectionItem: 'Item',
    repairSectionWork: 'Work',
    repairSectionReturn: 'Return',
    repairSectionLinked: 'Linked sale',
    promoteToBuyer: 'Promote to Buyer',
    promoteToBuyerTitle: 'Promote to Buyer?',
    promoteToBuyerBody:
        'A new Buyer profile will be created with this name. You can add'
        ' contact details from the Buyer detail screen.',
    repairsOnSale: 'Repairs',
    noLinkedRepairs: 'No repairs linked to this sale.',
    errorSavingRepair: 'Error saving repair',
    errorDeletingRepair: 'Error deleting repair',
    markAsSent: 'Mark as Sent',
    markAsDelivered: 'Mark as Delivered',
    analyticsSalesTab: 'Sales',
    analyticsRepairsTab: 'Repairs',
    repairRevenue: 'Repair revenue',
    repairCount: 'Repairs',
    repairTopCategories: 'Top categories',
    repairStatusByCount: 'By status',
    noRepairDataForPeriod: 'No repair data for this period',
    archiveImportTitle: 'Import to app?',
    archiveImportAction: 'Import',
    archiveReadOnly: 'Read-only archive',
    archiveImported: 'Imported',
    archiveTotalRevenue: 'Total revenue',
    archiveNoSales: 'No sales in this archive.',
    archiveUnknown: 'Unknown',
    archiveNothingToImport: 'Nothing to import — all records already exist',
    appearance: 'Appearance',
    themePreset: 'Colour palette',
    themeBrightness: 'Brightness',
    presetTerracotta: 'Terracotta',
    presetOcean: 'Ocean',
    presetForest: 'Forest',
    presetSlate: 'Slate',
    presetFuchsia: 'Fuchsia',
    presetIndigo: 'Indigo',
    catalogueSection: 'Catalogue',
    categoriesTitle: 'Categories',
    categoriesSubtitle: 'Rename, hide, or remove item categories',
    renameCategoryTitle: 'Rename category',
    renameCategoryHint: 'Category name',
    renameCategoryEmpty: 'Name cannot be empty',
    renameCategoryDuplicate: 'A category with this name already exists',
    rename: 'Rename',
    hide: 'Hide',
    unhide: 'Show',
    hiddenLabel: 'hidden',
    renamingCategory: 'Renaming…',
    swipeActionMarkPaid: 'Mark Paid',
    swipeActionMarkShipped: 'Mark Shipped',
    markAsPaidTitle: 'Mark as Paid',
    markAsShippedTitle: 'Confirm Shipment',
    saleSingular: 'sale',
    salePlural: 'sales',
    photoSingular: 'photo',
    photoPlural: 'photos',
    itemSingular: 'item',
    itemPlural: 'items',
  ),
  pt._(
    isPt: true,
    cancel: 'Cancelar',
    save: 'Guardar',
    delete: 'Eliminar',
    edit: 'Editar',
    add: 'Adicionar',
    copy: 'Copiar',
    change: 'Alterar',
    clear: 'Limpar',
    setDate: 'Definir data',
    ok: 'OK',
    discard: 'Descartar',
    discardChanges: 'Descartar alterações?',
    discardChangesMessage: 'Tens alterações não guardadas. Tens a certeza que'
    ' queres descartá-las?',
    navDashboard: 'Painel',
    navSales: 'Vendas',
    navBuyers: 'Compradores',
    navSettings: 'Definições',
    email: 'Email',
    emailRequired: 'Email é obrigatório',
    password: 'Palavra-passe',
    passwordRequired: 'Palavra-passe é obrigatória',
    signIn: 'Entrar',
    signInWithGoogle: 'Entrar com Google',
    tryDemo: 'Experimentar',
    errInvalidCredentials: 'Email ou palavra-passe incorretos.',
    errNoInternet: 'Sem ligação à internet.',
    errGeneric: 'Algo correu mal. Tente novamente.',
    errGoogleCredentialInUse:
        'Esta conta Google já está ligada a outra conta.'
        ' Inicia sessão com email e palavra-passe.',
    errGoogleNoData: 'Esta conta Google não tem dados da aplicação.'
        ' Inicia sessão com email primeiro e depois liga o Google'
        ' nas Definições.',
    signOut: 'Terminar sessão',
    signOutConfirm: 'Terminar sessão?',
    demoBanner: 'Modo de demonstração — as alterações não são guardadas',
    exitDemo: 'Sair',
    demoUser: 'Utilizador de demonstração',
    demoTourTitle: 'Tour de demonstração',
    appTour: 'Tour da aplicação',
    tutorialNext: 'Seguinte',
    tutorialBack: 'Voltar',
    tutorialGetStarted: 'Começar',
    tourWelcomeTitle: 'Bem-vindo ao Latitude Tracker',
    tourWelcomeBody:
        'O seu diário privado de vendas de acessórios artesanais. Acompanhe'
        ' cada venda — do DM do Instagram ou mercado — da montagem ao pagamento'
        ' e envio, tudo num só lugar.',
    tourCreateSaleTitle: 'Criar uma venda',
    tourCreateSaleBody:
        'Toque em + no separador Vendas para começar. Selecione ou crie um'
        ' comprador, depois adicione um ou mais artigos — cada um com'
        ' descrição, categoria, preço, estado de montagem e fotos. Termine com'
        ' o método de pagamento, detalhes de entrega e notas.',
    tourSaleDetailTitle: 'Gerir uma venda',
    tourSaleDetailBody:
        'Toque num cartão de venda para abrir o detalhe. Marque o pagamento com um toque, avance o estado de montagem por artigo, registe o código CTT ao enviar, e siga a linha NIF/AT de "recibo solicitado" até "submetido".',
    tourDashboardTitle: 'O seu painel',
    tourDashboardBody:
        'Veja a receita de qualquer período — deslize os chips de mês ou mude'
        ' entre semanal, mensal e anual. Toque no ícone de insights para'
        ' explorar análises por categoria. Abaixo do cartão de receita, as'
        ' linhas de Finanças, Produção e Planeamento mostram o que precisa de'
        ' atenção; toque numa linha para ver as vendas filtradas.',
    tourBuyersTitle: 'Perfis de compradores',
    tourBuyersBody:
        'Cada comprador constrói um perfil ao longo do tempo: moradas guardadas'
        ' com preenchimento automático de código postal português, NIF para'
        ' recibos fiscais, e histórico completo de compras por ano e mês.'
        ' Compradores recorrentes recebem uma dica ao criar nova venda.',
    tourAnalyticsTitle: 'Análises',
    tourAnalyticsBody:
        'Toque no ícone de insights no cartão de receita para abrir as'
        ' Análises. Um gráfico de barras empilhadas mostra a receita por'
        ' categoria ao longo de 6 períodos. Filtre por categoria, alterne entre'
        ' receita e contagem, e veja como os compradores preferem pagar.',
    tourDiscoverTitle: 'Mais para explorar',
    tourDiscoverBody: 'Quatro ecrãs que vale a pena conhecer:',
    tourGemShoppingTitle: 'Lista de compras',
    tourGemShoppingBody:
        'Todos os componentes em falta nas vendas ativas, agrupados por venda —'
        ' para saber exatamente o que comprar na próxima ida à loja.',
    tourGemMapTitle: 'Mapa de calor',
    tourGemMapBody:
        'Vista geográfica de onde vão os seus envios, agrupados por código'
        ' postal num mapa de Portugal.',
    tourGemUnpaidTitle: 'Saldos em dívida',
    tourGemUnpaidBody:
        'Pagamentos em falta agrupados por comprador, ordenados por valor —'
        ' ideal para acompanhamento.',
    tourGemNifTitle: 'Recibos NIF',
    tourGemNifBody:
        'Todas as submissões AT pendentes num só lugar, com toggle para marcar'
        ' cada uma como submetida.',
    dashboard: 'Painel',
    actionNeeded: 'Ações necessárias',
    pending: 'Pendente',
    tooltipYear: 'Ano',
    tooltipMonth: 'Mês',
    tooltipWeek: 'Semana',
    unpaid: 'Por pagar',
    pendingShipment: 'Envio pendente',
    assemblyNotReady: 'Faltam materiais',
    readyToAssemble: 'Pronto a montar',
    nifRequired: 'NIF em falta',
    overdue: 'Em atraso',
    dashboardTrends: 'Análises',
    dashboardGroupMoney: 'Finanças',
    dashboardGroupLogistics: 'Logística',
    dashboardGroupCompliance: 'Documentação',
    dashboardGroupProduction: 'Produção',
    dashboardGroupPlanning: 'Planeamento',
    inTransit: 'Em trânsito',
    upcomingScheduled: 'Próximas',
    dashboardTopCategories: 'Principais categorias',
    dashboardViewTrends: 'Ver análises',
    trendsTitle: 'Análises',
    trendsNoPreviousData: 'Sem dados para este período',
    trendsMetricRevenue: 'Receita',
    trendsMetricCount: 'Nº vendas',
    trendsAllCategories: 'Todas',
    trendsPaymentMethods: 'Métodos de pagamento',
    trendsRevenueByCategory: 'Receita por categoria',
    searchSales: 'Pesquisar comprador ou artigo...',
    noSalesFound: 'Sem vendas encontradas.',
    filterSort: 'Filtrar e ordenar',
    moreFilters: 'Filtros',
    sortBy: 'Ordenar por',
    sortDimensionDate: 'Data',
    sortDimensionPrice: 'Preço',
    noShippedSalesWithPostalCode: 'Sem vendas enviadas com código postal.',
    clearAllFilters: 'Limpar tudo',
    year: 'Ano',
    buyer: 'Comprador',
    stageDone: 'Concluída',
    nifSheetTitle: 'Recibo NIF necessário',
    nifSheetBody:
        'Pagamento recebido — submeta o recibo desta venda na AT. O NIF do'
        ' comprador está disponível no seu perfil.',
    readyButUnpaidTitle: 'Pronto mas não pago',
    readyButUnpaidBody:
        'Tudo está montado e pronto para envio, mas o pagamento ainda não foi'
        ' recebido.',
    urgencySheetTitle: 'Ações necessárias',
    urgencyWaitingForMaterials: 'A aguardar materiais',
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
    addNif: 'Adicionar NIF',
    categoryLabel: 'Categoria *',
    categoryRequired: 'Categoria é obrigatória',
    categoryPickerHint: 'Toque para escolher',
    searchOrAddCategory: 'Pesquisar ou adicionar categoria...',
    categoryFilterHeader: 'Categoria',
    tagsLabel: 'Etiquetas',
    addTagHint: 'Adicionar etiqueta...',
    buyerTagsFilterHeader: 'Etiquetas',
    buyerNotesHint: 'Notas sobre este comprador...',
    newSale: 'Nova Venda',
    editSale: 'Editar Venda',
    sectionBuyer: 'Comprador',
    sectionItem: 'Artigo',
    sectionItems: 'Artigos',
    addItem: 'Adicionar artigo',
    editItem: 'Editar artigo',
    saleTotal: 'Total',
    atLeastOneItem: 'Adicione pelo menos um artigo',
    sectionPhotos: 'Fotos',
    sectionComponents: 'Materiais necessários',
    sectionPayment: 'Pagamento',
    sectionDelivery: 'Entrega',
    deliveryStatusLabel: 'Estado de entrega',
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
    handDelivery: 'Entrega em mão',
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
    componentNotesHint: 'ex: azul escuro, comprimento 45cm',
    componentNotesLabel: 'Notas',
    noPhotos: 'Sem fotos',
    noReadyByDate: 'Sem data de preparação',
    noScheduledDate: 'Sem data agendada',
    readyBy: 'Pronto a',
    scheduledLabel: 'Agendado',
    receivedLabel: 'Recebido',
    removePhotoTitle: 'Remover foto?',
    removePhoto: 'Remover',
    addPhoto: 'Adicionar foto',
    takePhoto: 'Tirar foto',
    chooseFromGallery: 'Escolher da galeria',
    saleFallbackTitle: 'Venda',
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
    shippedAtLabel: 'Enviado a',
    setShippedAt: 'Definir data e hora de envio',
    addNotes: 'Adicionar notas',
    notesHintDetail: 'ex. Embrulho para oferta, cor específica...',
    errorDeletingSale: 'Erro ao eliminar venda',
    saleDeletedUndo: 'Venda eliminada',
    undo: 'Desfazer',
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
    viewMap: 'Mapa',
    geographicSalesTitle: 'Vendas por Localização',
    allYears: 'Todos',
    locatingPostalCodes: 'A localizar códigos postais...',
    geoSalesPortugal: 'Portugal',
    geoSalesInternational: 'Internacional',
    geoSalesSwitchToMap: 'Vista de mapa',
    geoSalesSwitchToList: 'Vista de lista',
    timelineOverdue: 'Em atraso',
    timelineThisWeek: 'Esta semana',
    timelineNextWeek: 'Próxima semana',
    timelineLater: 'Mais tarde',
    today: 'Hoje',
    tomorrow: 'Amanhã',
    buyers: 'Compradores',
    searchBuyers: 'Pesquisar compradores...',
    changeView: 'Alterar vista',
    alphabetical: 'Alfabético',
    groupByLastPurchase: 'Agrupar por última compra',
    buyerRanking: 'Ranking de compradores',
    neverPurchased: 'Sem compras',
    totalSpentMetric: 'Total gasto',
    mostSalesMetric: 'Mais vendas',
    avgSaleMetric: 'Valor médio',
    unpaidBalanceMetric: 'Por pagar',
    purchaseHistory: 'Histórico de compras',
    addresses: 'Moradas',
    noPurchasesYet: 'Sem compras registadas.',
    last3Months: 'Últimos 3 meses',
    noAddressesSaved: 'Sem moradas guardadas.',
    totalSalesLabel: 'Total de vendas',
    totalPaidLabel: 'Total pago',
    unpaidBalanceLabel: 'Saldo em falta',
    averageSaleLabel: 'Valor médio',
    lastPurchaseLabel: 'Última compra',
    addressCopied: 'Morada copiada',
    deleteAddressTitle: 'Eliminar morada?',
    noContactDetails: 'Sem dados de contacto guardados.',
    couldNotOpenInstagram: 'Não foi possível abrir o Instagram',
    couldNotOpenMaps: 'Não foi possível abrir o Maps',
    call: 'Ligar',
    sendMessage: 'Enviar mensagem',
    couldNotCall: 'Não foi possível abrir o telefone',
    couldNotSendMessage: 'Não foi possível abrir o app de mensagens',
    openInMaps: 'Abrir no Maps',
    defaultChip: 'Padrão',
    all: 'Todos',
    allPaid: 'Tudo pago!',
    totalOutstanding: 'Total em falta',
    errorLoadingSales: 'Erro ao carregar vendas',
    errorLoadingRepairs: 'Erro ao carregar reparações',
    errorLoadingBuyers: 'Erro ao carregar compradores',
    errorLoadingData: 'Erro ao carregar dados',
    retry: 'Tentar novamente',
    newBuyer: 'Novo Comprador',
    editBuyer: 'Editar Comprador',
    buyerNameLabel: 'Nome',
    buyerNameRequired: 'Nome é obrigatório',
    instagramHandleLabel: 'Instagram',
    phoneNumberLabel: 'Telefone',
    nifLabel: 'NIF',
    nifInvalid: 'O NIF deve ter 9 dígitos',
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
    addressDefaultLabel: 'Casa',
    addressCountry: 'País',
    countryDisplayNames: {
      'Portugal': 'Portugal',
      'Spain': 'Espanha',
      'France': 'França',
      'Germany': 'Alemanha',
      'United Kingdom': 'Reino Unido',
      'Netherlands': 'Países Baixos',
      'Belgium': 'Bélgica',
      'Italy': 'Itália',
      'Switzerland': 'Suíça',
      'Other': 'Outro',
    },
    postalCodeInvalidFormat: 'Formato: 0000-000',
    postalCodeNoResults: 'Nenhum resultado para este código postal',
    selectStreet: 'Selecionar rua',
    addressCity: 'Localidade *',
    addressCityRequired: 'Localidade é obrigatória',
    addressStreet: 'Rua *',
    addressStreetRequired: 'Rua é obrigatória',
    addressHouseNumber: 'Número *',
    addressHouseNumberHint: 'ex. 12, 12A, S/N',
    addressHouseNumberRequired: 'Número é obrigatório',
    addressFraction: 'Fração / andar',
    addressFractionHint: 'ex. 2º Dto, R/C, Loja',
    addressNotes: 'Notas de entrega',
    addressNotesHint: 'ex. Código do intercomunicador 4521, deixar com o'
    ' porteiro',
    selectBuyer: 'Selecionar Comprador',
    noBuyersFound: 'Sem compradores. Toque em + para adicionar.',
    account: 'Conta',
    archive: 'Arquivo',
    app: 'Aplicação',
    signedInAs: 'Sessão iniciada como',
    connectGoogle: 'Ligar conta Google',
    googleConnected: 'Conta Google ligada',
    exportYear: 'Exportar ano',
    exportYearSubtitle: 'Guardar cópia de segurança dos dados de vendas',
    importArchive: 'Importar arquivo',
    importArchiveSubtitle: 'Abrir um arquivo exportado anteriormente',
    deleteArchivedYear: 'Eliminar dados do ano',
    deleteArchivedYearSubtitle:
        'Remove as vendas de um ano — as fotos são mantidas para visualização',
    version: 'Versão',
    checkForUpdates: 'Verificar atualizações',
    updateChecking: 'A verificar atualizações…',
    updateDownloading: 'A descarregar atualização…',
    updateCheckFailed: 'Falha ao verificar — toque para tentar novamente',
    updateDownloadFailed: 'Falha no download — toque para tentar novamente',
    updateInstallBlocked:
        'Permissão de instalação negada. Ativa "Instalar apps desconhecidas"'
        ' nas Definições.',
    language: 'Idioma',
    exportWhichYear: 'Exportar qual ano?',
    deleteWhichYear: 'Eliminar qual ano?',
    alsoDeletePhotos: 'Também eliminar fotos',
    alsoDeletePhotosSubtitle:
        'Remove fotos do armazenamento — as pré-visualizações do arquivo'
        ' deixarão de funcionar',
    deletePermanently: 'Eliminar permanentemente',
    invalidArchive: 'Ficheiro de arquivo inválido',
    continueAction: 'Continuar',
    dangerZone: 'Zona de perigo',
    resetApp: 'Repor app',
    resetAppSubtitle: 'Eliminar todos os dados e começar do zero',
    resetAppConfirmTitle: 'Repor a app?',
    resetAppConfirmBody:
        'Isto eliminará permanentemente todas as Vendas, Compradores e Moradas.'
        ' '
        'Exporta uma cópia de segurança primeiro se quiseres guardar os dados.',
    resetAppFinalTitle: 'Esta ação é irreversível',
    resetAppFinalBody:
        'Estás prestes a eliminar tudo permanentemente. '
        'Não é possível recuperar estes dados.',
    resetEverything: 'Eliminar tudo',
    resettingApp: 'A repor app…',
    resetAppFailed: 'Falha ao repor',
    selectSalePrompt: 'Seleciona uma venda para ver os detalhes',
    repairs: 'Reparações',
    newRepair: 'Nova Reparação',
    repairProblemLabel: 'Problema',
    repairReturnStatusLabel: 'Estado da devolução',
    repairFilterActiveOnly: 'Apenas ativos',
    repairFilterShowAll: 'Mostrar todos',
    searchRepairs: 'Pesquisar reparações...',
    editRepair: 'Editar Reparação',
    deleteRepair: 'Eliminar reparação',
    deleteRepairTitle: 'Eliminar reparação?',
    noRepairsFound: 'Sem reparações ainda.',
    repairContact: 'Contacto *',
    repairContactRequired: 'Contacto é obrigatório',
    repairContactHint: 'Nome ou Instagram',
    repairContactFreeText: 'Nome livre',
    repairItemDescription: 'Descrição do artigo *',
    repairItemDescriptionRequired: 'Descrição do artigo é obrigatória',
    repairProblemDescription: 'Descrição do problema *',
    repairProblemDescriptionRequired: 'Descrição do problema é obrigatória',
    repairWorkDone: 'Trabalho realizado',
    repairMaterialsCost: 'Custo de materiais (€)',
    repairStatusLabel: 'Estado',
    repairLinkedSale: 'Venda associada',
    repairLinkedSaleNone: 'Sem venda associada',
    repairReturnDelivery: 'Devolução',
    repairSectionContact: 'Contacto',
    repairSectionItem: 'Artigo',
    repairSectionWork: 'Trabalho',
    repairSectionReturn: 'Devolução',
    repairSectionLinked: 'Venda associada',
    promoteToBuyer: 'Promover a Comprador',
    promoteToBuyerTitle: 'Promover a Comprador?',
    promoteToBuyerBody:
        'Será criado um novo perfil de Comprador com este nome. Pode adicionar'
        ' detalhes de contacto no ecrã do Comprador.',
    repairsOnSale: 'Reparações',
    noLinkedRepairs: 'Sem reparações associadas a esta venda.',
    errorSavingRepair: 'Erro ao guardar reparação',
    errorDeletingRepair: 'Erro ao eliminar reparação',
    markAsSent: 'Marcar como enviado',
    markAsDelivered: 'Marcar como entregue',
    analyticsSalesTab: 'Vendas',
    analyticsRepairsTab: 'Reparações',
    repairRevenue: 'Receita de reparações',
    repairCount: 'Reparações',
    repairTopCategories: 'Principais categorias',
    repairStatusByCount: 'Por estado',
    noRepairDataForPeriod: 'Sem dados de reparações para este período',
    archiveImportTitle: 'Importar para a app?',
    archiveImportAction: 'Importar',
    archiveReadOnly: 'Arquivo só de leitura',
    archiveImported: 'Importado',
    archiveTotalRevenue: 'Receita total',
    archiveNoSales: 'Sem vendas neste arquivo.',
    archiveUnknown: 'Desconhecido',
    archiveNothingToImport: 'Nada para importar — todos os registos já existem',
    appearance: 'Aparência',
    themePreset: 'Paleta de cores',
    themeBrightness: 'Brilho',
    presetTerracotta: 'Terracota',
    presetOcean: 'Oceano',
    presetForest: 'Floresta',
    presetSlate: 'Ardósia',
    presetFuchsia: 'Fúcsia',
    presetIndigo: 'Índigo',
    catalogueSection: 'Catálogo',
    categoriesTitle: 'Categorias',
    categoriesSubtitle: 'Renomear, ocultar ou remover categorias',
    renameCategoryTitle: 'Renomear categoria',
    renameCategoryHint: 'Nome da categoria',
    renameCategoryEmpty: 'O nome não pode estar vazio',
    renameCategoryDuplicate: 'Já existe uma categoria com este nome',
    rename: 'Renomear',
    hide: 'Ocultar',
    unhide: 'Mostrar',
    hiddenLabel: 'oculta',
    renamingCategory: 'A renomear…',
    swipeActionMarkPaid: 'Marcar Pago',
    swipeActionMarkShipped: 'Marcar Enviado',
    markAsPaidTitle: 'Marcar como Pago',
    markAsShippedTitle: 'Confirmar Envio',
    saleSingular: 'venda',
    salePlural: 'vendas',
    photoSingular: 'foto',
    photoPlural: 'fotos',
    itemSingular: 'artigo',
    itemPlural: 'artigos',
  );


  const AppStrings._({
    required bool isPt,
    required this.cancel,
    required this.save,
    required this.delete,
    required this.edit,
    required this.add,
    required this.copy,
    required this.change,
    required this.clear,
    required this.setDate,
    required this.ok,
    required this.discard,
    required this.discardChanges,
    required this.discardChangesMessage,
    required this.navDashboard,
    required this.navSales,
    required this.navBuyers,
    required this.navSettings,
    required this.email,
    required this.emailRequired,
    required this.password,
    required this.passwordRequired,
    required this.signIn,
    required this.signInWithGoogle,
    required this.tryDemo,
    required this.errInvalidCredentials,
    required this.errNoInternet,
    required this.errGeneric,
    required this.errGoogleCredentialInUse,
    required this.errGoogleNoData,
    required this.signOut,
    required this.signOutConfirm,
    required this.demoBanner,
    required this.exitDemo,
    required this.demoUser,
    required this.demoTourTitle,
    required this.appTour,
    required this.tutorialNext,
    required this.tutorialBack,
    required this.tutorialGetStarted,
    required this.tourWelcomeTitle,
    required this.tourWelcomeBody,
    required this.tourCreateSaleTitle,
    required this.tourCreateSaleBody,
    required this.tourSaleDetailTitle,
    required this.tourSaleDetailBody,
    required this.tourDashboardTitle,
    required this.tourDashboardBody,
    required this.tourBuyersTitle,
    required this.tourBuyersBody,
    required this.tourAnalyticsTitle,
    required this.tourAnalyticsBody,
    required this.tourDiscoverTitle,
    required this.tourDiscoverBody,
    required this.tourGemShoppingTitle,
    required this.tourGemShoppingBody,
    required this.tourGemMapTitle,
    required this.tourGemMapBody,
    required this.tourGemUnpaidTitle,
    required this.tourGemUnpaidBody,
    required this.tourGemNifTitle,
    required this.tourGemNifBody,
    required this.dashboard,
    required this.actionNeeded,
    required this.pending,
    required this.tooltipYear,
    required this.tooltipMonth,
    required this.tooltipWeek,
    required this.unpaid,
    required this.pendingShipment,
    required this.assemblyNotReady,
    required this.readyToAssemble,
    required this.nifRequired,
    required this.overdue,
    required this.dashboardTrends,
    required this.dashboardGroupMoney,
    required this.dashboardGroupLogistics,
    required this.dashboardGroupCompliance,
    required this.dashboardGroupProduction,
    required this.dashboardGroupPlanning,
    required this.inTransit,
    required this.upcomingScheduled,
    required this.dashboardTopCategories,
    required this.dashboardViewTrends,
    required this.trendsTitle,
    required this.trendsNoPreviousData,
    required this.trendsMetricRevenue,
    required this.trendsMetricCount,
    required this.trendsAllCategories,
    required this.trendsPaymentMethods,
    required this.trendsRevenueByCategory,
    required this.searchSales,
    required this.noSalesFound,
    required this.filterSort,
    required this.moreFilters,
    required this.sortBy,
    required this.sortDimensionDate,
    required this.sortDimensionPrice,
    required this.noShippedSalesWithPostalCode,
    required this.clearAllFilters,
    required this.year,
    required this.buyer,

    required this.stageDone,
    required this.nifSheetTitle,
    required this.nifSheetBody,
    required this.readyButUnpaidTitle,
    required this.readyButUnpaidBody,
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
    required this.addNif,
    required this.categoryLabel,
    required this.categoryRequired,
    required this.categoryPickerHint,
    required this.searchOrAddCategory,
    required this.categoryFilterHeader,
    required this.tagsLabel,
    required this.addTagHint,
    required this.buyerTagsFilterHeader,
    required this.buyerNotesHint,
    required this.newSale,
    required this.editSale,
    required this.sectionBuyer,
    required this.sectionItem,
    required this.sectionItems,
    required this.addItem,
    required this.editItem,
    required this.saleTotal,
    required this.atLeastOneItem,
    required this.sectionPhotos,
    required this.sectionComponents,
    required this.sectionPayment,
    required this.sectionDelivery,
    required this.deliveryStatusLabel,
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
    required this.handDelivery,
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
    required this.componentNotesHint,
    required this.componentNotesLabel,
    required this.noPhotos,
    required this.noReadyByDate,
    required this.noScheduledDate,
    required this.readyBy,
    required this.scheduledLabel,
    required this.receivedLabel,
    required this.removePhotoTitle,
    required this.removePhoto,
    required this.addPhoto,
    required this.takePhoto,
    required this.chooseFromGallery,
    required this.saleFallbackTitle,
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
    required this.shippedAtLabel,
    required this.setShippedAt,
    required this.addNotes,
    required this.notesHintDetail,
    required this.errorDeletingSale,
    required this.saleDeletedUndo,
    required this.undo,
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
    required this.viewMap,
    required this.geographicSalesTitle,
    required this.allYears,
    required this.locatingPostalCodes,
    required this.geoSalesPortugal,
    required this.geoSalesInternational,
    required this.geoSalesSwitchToMap,
    required this.geoSalesSwitchToList,
    required this.timelineOverdue,
    required this.timelineThisWeek,
    required this.timelineNextWeek,
    required this.timelineLater,
    required this.today,
    required this.tomorrow,
    required this.buyers,
    required this.searchBuyers,
    required this.changeView,
    required this.alphabetical,
    required this.groupByLastPurchase,
    required this.buyerRanking,
    required this.neverPurchased,
    required this.totalSpentMetric,
    required this.mostSalesMetric,
    required this.avgSaleMetric,
    required this.unpaidBalanceMetric,
    required this.purchaseHistory,
    required this.addresses,
    required this.noPurchasesYet,
    required this.last3Months,
    required this.noAddressesSaved,
    required this.totalSalesLabel,
    required this.totalPaidLabel,
    required this.unpaidBalanceLabel,
    required this.averageSaleLabel,
    required this.lastPurchaseLabel,
    required this.addressCopied,
    required this.deleteAddressTitle,
    required this.noContactDetails,
    required this.couldNotOpenInstagram,
    required this.couldNotOpenMaps,
    required this.call,
    required this.sendMessage,
    required this.couldNotCall,
    required this.couldNotSendMessage,
    required this.openInMaps,
    required this.defaultChip,
    required this.all,
    required this.allPaid,
    required this.totalOutstanding,
    required this.errorLoadingSales,
    required this.errorLoadingRepairs,
    required this.errorLoadingBuyers,
    required this.errorLoadingData,
    required this.retry,
    required this.newBuyer,
    required this.editBuyer,
    required this.buyerNameLabel,
    required this.buyerNameRequired,
    required this.instagramHandleLabel,
    required this.phoneNumberLabel,
    required this.nifLabel,
    required this.nifInvalid,
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
    required this.addressDefaultLabel,
    required this.addressCountry,
    required this.countryDisplayNames,
    required this.postalCodeInvalidFormat,
    required this.postalCodeNoResults,
    required this.addressCity,
    required this.addressCityRequired,
    required this.selectStreet,
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
    required this.connectGoogle,
    required this.googleConnected,
    required this.exportYear,
    required this.exportYearSubtitle,
    required this.importArchive,
    required this.importArchiveSubtitle,
    required this.deleteArchivedYear,
    required this.deleteArchivedYearSubtitle,
    required this.version,
    required this.checkForUpdates,
    required this.updateChecking,
    required this.updateDownloading,
    required this.updateCheckFailed,
    required this.updateDownloadFailed,
    required this.updateInstallBlocked,
    required this.language,
    required this.exportWhichYear,
    required this.deleteWhichYear,
    required this.alsoDeletePhotos,
    required this.alsoDeletePhotosSubtitle,
    required this.deletePermanently,
    required this.invalidArchive,
    required this.continueAction,
    required this.dangerZone,
    required this.resetApp,
    required this.resetAppSubtitle,
    required this.resetAppConfirmTitle,
    required this.resetAppConfirmBody,
    required this.resetAppFinalTitle,
    required this.resetAppFinalBody,
    required this.resetEverything,
    required this.resettingApp,
    required this.resetAppFailed,
    required this.selectSalePrompt,
    required this.repairs,
    required this.newRepair,
    required this.repairProblemLabel,
    required this.repairReturnStatusLabel,
    required this.repairFilterActiveOnly,
    required this.repairFilterShowAll,
    required this.searchRepairs,
    required this.editRepair,
    required this.deleteRepair,
    required this.deleteRepairTitle,
    required this.noRepairsFound,
    required this.repairContact,
    required this.repairContactRequired,
    required this.repairContactHint,
    required this.repairContactFreeText,
    required this.repairItemDescription,
    required this.repairItemDescriptionRequired,
    required this.repairProblemDescription,
    required this.repairProblemDescriptionRequired,
    required this.repairWorkDone,
    required this.repairMaterialsCost,
    required this.repairStatusLabel,
    required this.repairLinkedSale,
    required this.repairLinkedSaleNone,
    required this.repairReturnDelivery,
    required this.repairSectionContact,
    required this.repairSectionItem,
    required this.repairSectionWork,
    required this.repairSectionReturn,
    required this.repairSectionLinked,
    required this.promoteToBuyer,
    required this.promoteToBuyerTitle,
    required this.promoteToBuyerBody,
    required this.repairsOnSale,
    required this.noLinkedRepairs,
    required this.errorSavingRepair,
    required this.errorDeletingRepair,
    required this.markAsSent,
    required this.markAsDelivered,
    required this.analyticsSalesTab,
    required this.analyticsRepairsTab,
    required this.repairRevenue,
    required this.repairCount,
    required this.repairTopCategories,
    required this.repairStatusByCount,
    required this.noRepairDataForPeriod,
    required this.archiveImportTitle,
    required this.archiveImportAction,
    required this.archiveReadOnly,
    required this.archiveImported,
    required this.archiveTotalRevenue,
    required this.archiveNoSales,
    required this.archiveUnknown,
    required this.archiveNothingToImport,
    required this.appearance,
    required this.themePreset,
    required this.themeBrightness,
    required this.presetTerracotta,
    required this.presetOcean,
    required this.presetForest,
    required this.presetSlate,
    required this.presetFuchsia,
    required this.presetIndigo,
    required this.catalogueSection,
    required this.categoriesTitle,
    required this.categoriesSubtitle,
    required this.renameCategoryTitle,
    required this.renameCategoryHint,
    required this.renameCategoryEmpty,
    required this.renameCategoryDuplicate,
    required this.rename,
    required this.hide,
    required this.unhide,
    required this.hiddenLabel,
    required this.renamingCategory,
    required this.swipeActionMarkPaid,
    required this.swipeActionMarkShipped,
    required this.markAsPaidTitle,
    required this.markAsShippedTitle,
    required String saleSingular,
    required String salePlural,
    required String photoSingular,
    required String photoPlural,
    required String itemSingular,
    required String itemPlural,
  })  : _pt = isPt,
        _saleSingular = saleSingular,
        _salePlural = salePlural,
        _photoSingular = photoSingular,
        _photoPlural = photoPlural,
        _itemSingular = itemSingular,
        _itemPlural = itemPlural;
  final bool _pt;

  // ── General actions ──────────────────────────────────────────────────────
  final String cancel;
  final String save;
  final String delete;
  final String edit;
  final String add;
  final String copy;
  final String change;
  final String clear;
  final String setDate;
  final String ok;
  final String discard;
  final String discardChanges;
  final String discardChangesMessage;

  // ── Navigation ───────────────────────────────────────────────────────────
  final String navDashboard;
  final String navSales;
  final String navBuyers;
  final String navSettings;

  // ── Auth ─────────────────────────────────────────────────────────────────
  final String email;
  final String emailRequired;
  final String password;
  final String passwordRequired;
  final String signIn;
  final String signInWithGoogle;
  final String tryDemo;
  final String errInvalidCredentials;
  final String errNoInternet;
  final String errGeneric;
  final String errGoogleCredentialInUse;
  final String errGoogleNoData;
  final String signOut;
  final String signOutConfirm;

  // ── Demo ─────────────────────────────────────────────────────────────────
  final String demoBanner;
  final String exitDemo;
  final String demoUser;
  final String demoTourTitle;

  // App tour (paged walkthrough)
  final String appTour;
  final String tutorialNext;
  final String tutorialBack;
  final String tutorialGetStarted;
  final String tourWelcomeTitle;
  final String tourWelcomeBody;
  final String tourCreateSaleTitle;
  final String tourCreateSaleBody;
  final String tourSaleDetailTitle;
  final String tourSaleDetailBody;
  final String tourDashboardTitle;
  final String tourDashboardBody;
  final String tourBuyersTitle;
  final String tourBuyersBody;
  final String tourAnalyticsTitle;
  final String tourAnalyticsBody;
  final String tourDiscoverTitle;
  final String tourDiscoverBody;
  final String tourGemShoppingTitle;
  final String tourGemShoppingBody;
  final String tourGemMapTitle;
  final String tourGemMapBody;
  final String tourGemUnpaidTitle;
  final String tourGemUnpaidBody;
  final String tourGemNifTitle;
  final String tourGemNifBody;

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
  final String readyToAssemble;
  final String nifRequired;
  final String overdue;
  final String dashboardTrends;
  final String dashboardGroupMoney;
  final String dashboardGroupLogistics;
  final String dashboardGroupCompliance;
  final String dashboardGroupProduction;
  final String dashboardGroupPlanning;
  final String inTransit;
  final String upcomingScheduled;
  final String dashboardTopCategories;
  final String dashboardViewTrends;
  final String trendsTitle;
  final String trendsNoPreviousData;
  final String trendsMetricRevenue;
  final String trendsMetricCount;
  final String trendsAllCategories;
  final String trendsPaymentMethods;
  final String trendsRevenueByCategory;

  // ── Sales list ───────────────────────────────────────────────────────────
  final String searchSales;
  final String noSalesFound;
  final String filterSort;
  final String moreFilters;
  final String sortBy;
  final String sortDimensionDate;
  final String sortDimensionPrice;
  final String noShippedSalesWithPostalCode;
  final String clearAllFilters;
  final String year;
  final String buyer;

  // ── Sale card ────────────────────────────────────────────────────────────
  final String stageDone;
  final String nifSheetTitle;
  final String nifSheetBody;
  final String readyButUnpaidTitle;
  final String readyButUnpaidBody;
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
  final String addNif;

  // ── Category picker ──────────────────────────────────────────────────────
  final String categoryLabel;
  final String categoryRequired;
  final String categoryPickerHint;
  final String searchOrAddCategory;
  final String categoryFilterHeader;

  // ── Sale form ────────────────────────────────────────────────────────────
  final String newSale;
  final String editSale;
  final String sectionBuyer;
  final String sectionItem;
  final String sectionItems;
  final String addItem;
  final String editItem;
  final String saleTotal;
  final String atLeastOneItem;
  final String sectionPhotos;
  final String sectionComponents;
  final String sectionPayment;
  final String sectionDelivery;
  final String deliveryStatusLabel;
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
  final String handDelivery;
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
  final String componentNotesHint;
  final String componentNotesLabel;
  final String noPhotos;
  final String noReadyByDate;
  final String noScheduledDate;
  final String readyBy;
  final String scheduledLabel;
  final String removePhotoTitle;
  final String removePhoto;
  final String addPhoto;
  final String takePhoto;
  final String chooseFromGallery;

  final String receivedLabel;

  // ── Sale detail ──────────────────────────────────────────────────────────
  final String saleFallbackTitle;
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
  final String shippedAtLabel;
  final String setShippedAt;
  final String addNotes;
  final String notesHintDetail;
  final String errorDeletingSale;
  final String saleDeletedUndo;
  final String undo;
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
  final String viewMap;
  final String geographicSalesTitle;
  final String allYears;
  final String locatingPostalCodes;
  final String geoSalesPortugal;
  final String geoSalesInternational;
  final String geoSalesSwitchToMap;
  final String geoSalesSwitchToList;
  final String timelineOverdue;
  final String timelineThisWeek;
  final String timelineNextWeek;
  final String timelineLater;
  final String today;
  final String tomorrow;

  // ── Buyers list ──────────────────────────────────────────────────────────
  final String buyers;
  final String searchBuyers;
  final String changeView;
  final String alphabetical;
  final String groupByLastPurchase;
  final String buyerRanking;
  final String neverPurchased;
  final String totalSpentMetric;
  final String mostSalesMetric;
  final String avgSaleMetric;
  final String unpaidBalanceMetric;

  // ── Buyer detail ─────────────────────────────────────────────────────────
  final String purchaseHistory;
  final String addresses;
  final String noPurchasesYet;
  final String last3Months;
  final String noAddressesSaved;
  final String totalSalesLabel;
  final String totalPaidLabel;
  final String unpaidBalanceLabel;
  final String averageSaleLabel;
  final String lastPurchaseLabel;
  final String addressCopied;
  final String deleteAddressTitle;
  final String noContactDetails;
  final String couldNotOpenInstagram;
  final String couldNotOpenMaps;
  final String call;
  final String sendMessage;
  final String couldNotCall;
  final String couldNotSendMessage;
  final String openInMaps;
  final String defaultChip;
  final String all;
  final String allPaid;
  final String totalOutstanding;
  final String errorLoadingSales;
  final String errorLoadingRepairs;
  final String errorLoadingBuyers;
  final String errorLoadingData;
  final String retry;

  // ── Buyer tags & notes ───────────────────────────────────────────────────
  final String tagsLabel;
  final String addTagHint;
  final String buyerTagsFilterHeader;
  final String buyerNotesHint;

  // ── Buyer form ───────────────────────────────────────────────────────────
  final String newBuyer;
  final String editBuyer;
  final String buyerNameLabel;
  final String buyerNameRequired;
  final String instagramHandleLabel;
  final String phoneNumberLabel;
  final String nifLabel;
  final String nifInvalid;
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
  final String addressDefaultLabel;
  final String addressCountry;
  final Map<String, String> countryDisplayNames;
  final String postalCodeInvalidFormat;
  final String postalCodeNoResults;
  final String addressCity;
  final String addressCityRequired;
  final String selectStreet;
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
  final String connectGoogle;
  final String googleConnected;
  final String exportYear;
  final String exportYearSubtitle;
  final String importArchive;
  final String importArchiveSubtitle;
  final String deleteArchivedYear;
  final String deleteArchivedYearSubtitle;
  final String version;
  final String checkForUpdates;
  final String updateChecking;
  final String updateDownloading;
  final String updateCheckFailed;
  final String updateDownloadFailed;
  final String updateInstallBlocked;
  final String language;
  final String exportWhichYear;
  final String deleteWhichYear;
  final String alsoDeletePhotos;
  final String alsoDeletePhotosSubtitle;
  final String deletePermanently;
  final String invalidArchive;
  final String continueAction;
  final String dangerZone;
  final String resetApp;
  final String resetAppSubtitle;
  final String resetAppConfirmTitle;
  final String resetAppConfirmBody;
  final String resetAppFinalTitle;
  final String resetAppFinalBody;
  final String resetEverything;
  final String resettingApp;
  final String resetAppFailed;
  final String selectSalePrompt;

  // ── Repairs ──────────────────────────────────────────────────────────────
  final String repairs;
  final String newRepair;
  final String repairProblemLabel;
  final String repairReturnStatusLabel;
  final String repairFilterActiveOnly;
  final String repairFilterShowAll;
  final String searchRepairs;
  final String editRepair;
  final String deleteRepair;
  final String deleteRepairTitle;
  final String noRepairsFound;
  final String repairContact;
  final String repairContactRequired;
  final String repairContactHint;
  final String repairContactFreeText;
  final String repairItemDescription;
  final String repairItemDescriptionRequired;
  final String repairProblemDescription;
  final String repairProblemDescriptionRequired;
  final String repairWorkDone;
  final String repairMaterialsCost;
  final String repairStatusLabel;
  final String repairLinkedSale;
  final String repairLinkedSaleNone;
  final String repairReturnDelivery;
  final String repairSectionContact;
  final String repairSectionItem;
  final String repairSectionWork;
  final String repairSectionReturn;
  final String repairSectionLinked;
  final String promoteToBuyer;
  final String promoteToBuyerTitle;
  final String promoteToBuyerBody;
  final String repairsOnSale;
  final String noLinkedRepairs;
  final String errorSavingRepair;
  final String errorDeletingRepair;
  final String markAsSent;
  final String markAsDelivered;
  final String analyticsSalesTab;
  final String analyticsRepairsTab;
  final String repairRevenue;
  final String repairCount;
  final String repairTopCategories;
  final String repairStatusByCount;
  final String noRepairDataForPeriod;

  // ── Archive import ───────────────────────────────────────────────────────
  final String archiveImportTitle;
  final String archiveImportAction;
  final String archiveReadOnly;
  final String archiveImported;
  final String archiveTotalRevenue;
  final String archiveNoSales;
  final String archiveUnknown;
  final String archiveNothingToImport;

  // ── Appearance ───────────────────────────────────────────────────────────
  final String appearance;
  final String themePreset;
  final String themeBrightness;
  final String presetTerracotta;
  final String presetOcean;
  final String presetForest;
  final String presetSlate;
  final String presetFuchsia;
  final String presetIndigo;

  // ── Category maintenance ──────────────────────────────────────────────────
  final String catalogueSection;
  final String categoriesTitle;
  final String categoriesSubtitle;
  final String renameCategoryTitle;
  final String renameCategoryHint;
  final String renameCategoryEmpty;
  final String renameCategoryDuplicate;
  final String rename;
  final String hide;
  final String unhide;
  final String hiddenLabel;
  final String renamingCategory;

  // ── Swipe actions ────────────────────────────────────────────────────────
  final String swipeActionMarkPaid;
  final String swipeActionMarkShipped;
  final String markAsPaidTitle;
  final String markAsShippedTitle;

  // ── Plural word stems (used in methods below) ─────────────────────────────
  final String _saleSingular;
  final String _salePlural;
  final String _photoSingular;
  final String _photoPlural;
  final String _itemSingular;
  final String _itemPlural;

  static AppStrings of(BuildContext context) {
    final code = AppLocaleScope.of(context).languageCode;
    return code == 'pt' ? pt : en;
  }

  // ── Plural helpers ────────────────────────────────────────────────────────

  String nSales(int n) => '$n ${n == 1 ? _saleSingular : _salePlural}';
  String nPhotos(int n) => '$n ${n == 1 ? _photoSingular : _photoPlural}';
  String nItems(int n) => '$n ${n == 1 ? _itemSingular : _itemPlural}';
  String itemsAcrossSales(int items, int sales) => _pt
      ? '${nItems(items)} em ${nSales(sales)}'
      : '${nItems(items)} across ${nSales(sales)}';

  String materialsAcrossItems(int materials, int items) {
    final mat = _pt
        ? '$materials ${materials == 1 ? 'material' : 'materiais'}'
        : '$materials ${materials == 1 ? 'material' : 'materials'}';
    return _pt ? '$mat em ${nItems(items)}' : '$mat across ${nItems(items)}';
  }

  String nUrgent(int n) => _pt ? '$n urgente${n == 1 ? '' : 's'}' : '$n urgent';
  String andXMore(int n) => _pt ? 'e mais $n' : 'and $n more';
  String nMoreItems(int n) => _pt ? '+ $n' : '+ $n';

  String nUnpaid(int n) => _pt ? '$n por pagar' : '$n unpaid';

  String daysOverdue(int n) => _pt ? '${n}d em atraso' : '${n}d overdue';

  String nPending(int pending, int filed) {
    if (_pt) {
      final ps = pending == 1 ? '' : 's';
      final fs = filed == 1 ? '' : 's';
      return '$pending pendente$ps · $filed submetido$fs';
    }
    return '$pending pending · $filed filed';
  }

  String previousSales(int n, String lastDate) {
    final base = _pt
        ? '${nSales(n)} anteriores'
        : '${nSales(n)} previous';
    if (lastDate.isEmpty) return base;
    final label = _pt ? 'última' : 'last';
    return '$base · $label: $lastDate';
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
          SaleFilter.handDelivery => 'Entrega em mão',
          SaleFilter.assemblyNotReady => 'Faltam materiais',
          SaleFilter.readyToAssemble => 'Pronto a montar',
          SaleFilter.overdue => 'Em atraso',
          SaleFilter.upcomingScheduled => 'Próximas',
        }
      : switch (f) {
          SaleFilter.all => 'All',
          SaleFilter.unpaid => 'Unpaid',
          SaleFilter.nifRequired => 'NIF required',
          SaleFilter.scheduled => 'Scheduled',
          SaleFilter.pendingShipment => 'Pending shipment',
          SaleFilter.shipped => 'Shipped',
          SaleFilter.pickup => 'Pickup',
          SaleFilter.handDelivery => 'Hand delivery',
          SaleFilter.assemblyNotReady => 'Needs materials',
          SaleFilter.readyToAssemble => 'Ready to assemble',
          SaleFilter.overdue => 'Overdue',
          SaleFilter.upcomingScheduled => 'Upcoming',
        };

  String assemblyLabel(AssemblyStatus s) => _pt
      ? switch (s) {
          AssemblyStatus.notStarted => 'Não iniciado',
          AssemblyStatus.waitingForMaterials => 'Aguarda materiais',
          AssemblyStatus.inProgress => 'Em progresso',
          AssemblyStatus.ready => 'Pronto',
        }
      : switch (s) {
          AssemblyStatus.notStarted => 'Not started',
          AssemblyStatus.waitingForMaterials => 'Waiting for materials',
          AssemblyStatus.inProgress => 'In progress',
          AssemblyStatus.ready => 'Ready',
        };

  String paymentMethodLabel(PaymentMethod m) => switch (m) {
        PaymentMethod.mbWay => 'MB Way',
        PaymentMethod.revolut => 'Revolut',
        PaymentMethod.paypal => 'PayPal',
        PaymentMethod.cash => _pt ? 'Numerário' : 'Cash',
        PaymentMethod.sumup => 'SumUp',
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

  String repairStatusLabelFor(RepairStatus s) => _pt
      ? switch (s) {
          RepairStatus.received => 'Recebido',
          RepairStatus.waitingForMaterials => 'A aguardar materiais',
          RepairStatus.inProgress => 'Em progresso',
          RepairStatus.done => 'Concluído',
          RepairStatus.returned => 'Devolvido',
        }
      : switch (s) {
          RepairStatus.received => 'Received',
          RepairStatus.waitingForMaterials => 'Waiting for materials',
          RepairStatus.inProgress => 'In progress',
          RepairStatus.done => 'Done',
          RepairStatus.returned => 'Returned',
        };

  // ── Dynamic string helpers ────────────────────────────────────────────────

  String deleteShippedSaleBody(
    String status, {
    required bool atDone,
    required int photoCount,
  }) {
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
      return 'Esta venda tem um pagamento registado de'
      ' €${price.toStringAsFixed(2)}. '
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

  String updateAvailableTile(String version) => _pt
      ? 'Nova versão disponível (v$version)'
      : 'New version available (v$version)';

  String exportSubject(int year) => 'Latitude Tracker — $year archive';

  String exportingYear(int year) =>
      _pt ? 'A exportar $year...' : 'Exporting $year...';

  String deletingYear(int year, {required bool deletePhotos}) {
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

  String deleteYearPartialFailed(int year, Object error) => _pt
      ? 'Vendas de $year eliminadas, mas falha ao eliminar reparações: $error'
      : '$year sales deleted, but repair deletion failed: $error';

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

  String errorUploadingPhotoMsg(Object error) =>
      _pt ? 'Erro ao carregar foto: $error' : 'Error uploading photo: $error';

  String importFailedMsg(Object error) =>
      _pt ? 'Falha na importação: $error' : 'Import failed: $error';

  String errorDeletingBuyerMsg(Object error) => _pt
      ? 'Erro ao eliminar comprador: $error'
      : 'Error deleting buyer: $error';

  String promotedToBuyerMsg(String name) =>
      _pt ? '$name promovido a Comprador' : '$name promoted to Buyer';

  String archiveExportedAt(String date) =>
      _pt ? 'Exportado $date' : 'Exported $date';

  String archiveImportBody(int sales, int buyers) {
    if (_pt) {
      return 'Isto irá adicionar ${nSales(sales)} e '
          '${_nBuyers(buyers)} à sua app.\n\n'
          'Registos que já existam serão ignorados — '
          'os seus dados atuais não serão substituídos.';
    }
    return 'This will add ${nSales(sales)} and '
        '${_nBuyers(buyers)} to your app.\n\n'
        'Records that already exist will be skipped — '
        'your current data will not be overwritten.';
  }

  String archiveResultBrief(int sales, int buyers, int repairs, int skipped) {
    final parts = <String>[];
    if (sales > 0) parts.add(nSales(sales));
    if (buyers > 0) parts.add(_nBuyers(buyers));
    if (repairs > 0) parts.add(_nRepairs(repairs));
    if (skipped > 0) {
      parts.add(_pt
          ? '$skipped ignorado${skipped == 1 ? '' : 's'}'
          : '$skipped skipped');
    }
    if (parts.isEmpty) return archiveNothingToImport;
    return parts.join(' · ');
  }

  String archiveSalesImportedMsg(int n) => _pt
      ? '${nSales(n)} importada${n == 1 ? '' : 's'}'
      : '${nSales(n)} imported';

  String archiveBuyersImportedMsg(int n) => _pt
      ? '${_nBuyers(n)} importado${n == 1 ? '' : 's'}'
      : '${_nBuyers(n)} imported';

  String archiveRepairsImportedMsg(int n) => _pt
      ? '${_nRepairs(n)} importada${n == 1 ? '' : 's'}'
      : '${_nRepairs(n)} imported';

  String archiveSkippedMsg(int n) => _pt
      ? '$n ignorado${n == 1 ? '' : 's'} (já existem)'
      : '$n skipped (already exist)';

  String _nBuyers(int n) => _pt
      ? '$n comprador${n == 1 ? '' : 'es'}'
      : '$n buyer${n == 1 ? '' : 's'}';

  String _nRepairs(int n) => _pt
      ? '$n reparaç${n == 1 ? 'ão' : 'ões'}'
      : '$n repair${n == 1 ? '' : 's'}';

  // Maps English timeline keys (used for ordering) to translated display
  // labels.
  String saleStageLabel(SaleStage stage) => switch (stage) {
        SaleStage.assembly => assemblyLegendHeader,
        SaleStage.payment => paymentLegendHeader,
        SaleStage.shipment => shipmentLegendHeader,
        SaleStage.done => stageDone,
      };

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

  String addCategoryLabel(String query) =>
      _pt ? 'Adicionar "$query"' : 'Add "$query"';

  String nUses(int n) =>
      _pt ? '$n ${n == 1 ? 'uso' : 'usos'}' : '$n ${n == 1 ? 'use' : 'uses'}';

  String categoryDeleteTitle(String name) =>
      _pt ? 'Eliminar "$name"?' : 'Delete "$name"?';

  String categoryDeleteBody(String name) => _pt
      ? '"$name" não tem utilizações e será removida da lista de categorias.'
      : '"$name" has no uses and will be removed from the category list.';

  List<String> trendComparisonLabels(DashboardPeriod period) =>
      switch (period) {
        DashboardPeriod.weekly => _pt
            ? ['Semana anterior', 'Há 4 semanas', 'Mesma semana do ano passado']
            : ['Previous week', '4 weeks ago', 'Same week last year'],
        DashboardPeriod.monthly => _pt
            ? ['Mês anterior', 'Há 3 meses', 'Há 6 meses',
                'Mesmo mês do ano passado']
            : ['Previous month', '3 months ago', '6 months ago',
                'Same month last year'],
        DashboardPeriod.yearly => _pt
            ? ['Ano anterior', 'Há 3 anos', 'Há 5 anos']
            : ['Previous year', '3 years ago', '5 years ago'],
      };
}

extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
