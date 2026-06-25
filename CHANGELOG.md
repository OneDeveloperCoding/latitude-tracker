# Changelog

## [1.12.0](https://github.com/OneDeveloperCoding/latitude-tracker/compare/v1.11.0...v1.12.0) (2026-06-25)


### Features

* add BuyerAddress creation from within New Sale delivery section ([31f5131](https://github.com/OneDeveloperCoding/latitude-tracker/commit/31f51318e6b1cc896035731659a2b53caa5883e0))
* add curated theme presets with dark/light toggle in Settings ([#187](https://github.com/OneDeveloperCoding/latitude-tracker/issues/187)) ([c66bf4d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c66bf4d467a127b7e10c0c4cf2a826e4f5e45673))
* add dark mode toggle in Settings ([#121](https://github.com/OneDeveloperCoding/latitude-tracker/issues/121)) ([e691da7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e691da7fad08982d0efde3fb09f661fb55d7bf25))
* add Google Sign-In via account linking ([#216](https://github.com/OneDeveloperCoding/latitude-tracker/issues/216)) ([c1ab836](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c1ab83630490b456cfa750a7cf269d4b745c6f6b))
* add hand delivery as a third delivery type ([e62b3a2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e62b3a2d7fde1872c1c78da8ccec3c1976cb35a2)), closes [#34](https://github.com/OneDeveloperCoding/latitude-tracker/issues/34)
* add photo and notes support to ComponentChecklist items ([#149](https://github.com/OneDeveloperCoding/latitude-tracker/issues/149)) ([a46d4e2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a46d4e29f36757edd677c52cb727253a4cc202c9))
* add quantity field to ComponentItem and make AssemblyStatus fully manual ([#155](https://github.com/OneDeveloperCoding/latitude-tracker/issues/155)) ([8adbe02](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8adbe028f20293e38a72c79f5cc6c87343e54ee1))
* add Repair feature — track repair jobs linked to sales or standalone ([9436059](https://github.com/OneDeveloperCoding/latitude-tracker/commit/94360593d78bc9d3688c5a2f165ff157997094a7))
* add Revolut and PayPal payment methods with brand colours ([eeef5e2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/eeef5e260ca587fe3aa4ef3c295b4624ead05360)), closes [#33](https://github.com/OneDeveloperCoding/latitude-tracker/issues/33)
* add watchBuyer stream to BuyerRepository and use it in BuyerDetailScreen ([#82](https://github.com/OneDeveloperCoding/latitude-tracker/issues/82)) ([2f63799](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2f6379947606fead06eff9ee71b507f502d77fe9))
* aggregate same-named ComponentItems across SaleItems in ShoppingList ([#161](https://github.com/OneDeveloperCoding/latitude-tracker/issues/161)) ([0893550](https://github.com/OneDeveloperCoding/latitude-tracker/commit/08935504e61a3df9c08e81d67446aca74630eb98))
* archive analytics — view yearly/monthly trends for imported archives ([#32](https://github.com/OneDeveloperCoding/latitude-tracker/issues/32)) ([02563a6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/02563a69f8eaadd9fcff28a9fc5e845d38d495a8))
* category maintenance — rename, hide, delete ([#35](https://github.com/OneDeveloperCoding/latitude-tracker/issues/35)) ([a1b0bf8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a1b0bf80ac9d99ea6f5b832167f7b54145e13d0f))
* collapse search toolbar in Sales and Buyers screens ([#75](https://github.com/OneDeveloperCoding/latitude-tracker/issues/75)) ([e6a764a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e6a764a9d45d002a047d40100adbb55843d7b9a7)), closes [#74](https://github.com/OneDeveloperCoding/latitude-tracker/issues/74)
* compact sort UI in Sales filter sheet and move Buyers ranking metric picker into tune sheet ([#77](https://github.com/OneDeveloperCoding/latitude-tracker/issues/77)) ([9bf3968](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9bf39680ba8ad6b9fdd8290790c01bc427370659))
* copy formatted address from buyer detail + fix buyer form i18n ([368f39b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/368f39b91213889a4c0b9089fafdb290f4ecb3ed))
* dashboard analytics section — category trends and period comparisons ([1db7ef6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1db7ef63e61023c4bdb6acce2159677d4fc03122)), closes [#8](https://github.com/OneDeveloperCoding/latitude-tracker/issues/8)
* dashboard layout revamp — trends card, grouped actions, clean revenue card ([2f59dda](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2f59dda8e49de34000feddef0d9e8598afe91273)), closes [#4](https://github.com/OneDeveloperCoding/latitude-tracker/issues/4)
* enhanced TrendsScreen with stacked category chart and interactive analysis ([162a1df](https://github.com/OneDeveloperCoding/latitude-tracker/commit/162a1dfc8ff093290d9dd8c95ec1e4275aedf4e8))
* filter and sort revamp — multi-select, year/month drill-down, active-only default ([1037942](https://github.com/OneDeveloperCoding/latitude-tracker/commit/103794206377e89290d32f6c805699e7f31927f8)), closes [#6](https://github.com/OneDeveloperCoding/latitude-tracker/issues/6)
* fix needs-materials counter and add ready-to-assemble dashboard card ([#228](https://github.com/OneDeveloperCoding/latitude-tracker/issues/228)) ([5db7221](https://github.com/OneDeveloperCoding/latitude-tracker/commit/5db722159aab8778e5413f70d3f780fe9be9d328))
* heat map overhaul — dedicated screen, geocoding cache, tile cache, background warm-up ([d6b6bc9](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d6b6bc9e7b61164c8df3cf91279a8059fda50383))
* implement GeocodingService.warmUp() via GeocodingWarmUp listener ([#178](https://github.com/OneDeveloperCoding/latitude-tracker/issues/178)) ([fe1ee60](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fe1ee607f2f97fdd94ef224c47e0f84921c2428e))
* in-app update checker and APK installer via GitHub Releases ([#214](https://github.com/OneDeveloperCoding/latitude-tracker/issues/214)) ([1902cd5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1902cd52c493001a2c87d3e5739de732c921f1a3))
* inline RepairStatus picker on Repair detail screen ([7ff63b1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7ff63b1cf9459c607cf07a6856ce4abc21a63908))
* inline RepairStatus picker on Repair detail screen ([2d60660](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2d60660315f15a551fe4146d6dbb9f3ad121a2b3))
* item category on Sales, buyer tags and buyer notes ([3259e76](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3259e762cd6cc7d0876e427df475f3938a12e477))
* make Notes text selectable in sale and buyer detail screens ([8f65e20](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8f65e208973e49275181aadde9cf7642ea2c0b94))
* make Notes text selectable in sale and buyer detail screens ([a66cd3f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a66cd3f0aa64e8bcaefaf5e139b91f3d0f4c695a))
* master-detail split view for Sales list on tablet ([3b9dcac](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3b9dcacf61727a8ccd554fea676432d7e4edd748)), closes [#28](https://github.com/OneDeveloperCoding/latitude-tracker/issues/28)
* new AnalyticsScreen merging InsightsCard and TrendsScreen, restore action rows ([cf7f27e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/cf7f27e671dab9403151e0ca332ec921f95aaaec))
* note indicator on sale cards with tap-to-preview ([1a9d42f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1a9d42f9720ebb6756d7f11a1e6af7508b881342))
* open BuyerAddress in Google Maps from Sale detail and Buyer detail ([#100](https://github.com/OneDeveloperCoding/latitude-tracker/issues/100)) ([49d4445](https://github.com/OneDeveloperCoding/latitude-tracker/commit/49d4445fb6e1e37a577c629571b188d2a7e9af52))
* redesign dashboard action section as compact 3-per-row button grid ([e979e84](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e979e84426a946eb2ffedb84dc2744080a156085)), closes [#25](https://github.com/OneDeveloperCoding/latitude-tracker/issues/25)
* redesign dashboard period control and unify search bars across screens ([11ad656](https://github.com/OneDeveloperCoding/latitude-tracker/commit/11ad6561ab2caf973f8f36d2368846fe88c8c67b))
* redesign RepairCard and fix demo mode guards ([#201](https://github.com/OneDeveloperCoding/latitude-tracker/issues/201)) ([0a275f3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0a275f330d5a808420849d7d58579f6c6bd37019))
* rename Trends to Analytics and swap card order in analytics screen ([c6c36c8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c6c36c8788c169b8b330610361e5eaf2c76f7b60)), closes [#30](https://github.com/OneDeveloperCoding/latitude-tracker/issues/30)
* repair detail — quick action buttons to advance ReturnDelivery status ([#94](https://github.com/OneDeveloperCoding/latitude-tracker/issues/94)) ([a35250b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a35250bb9622bfae30057aff61540023ddda56fc))
* repairs list — drop nested AppBar, add search/filter row, show ReturnDelivery on card ([c15d40d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c15d40d2075a30960b7e997f9ab8d622a06dbd43))
* repairs list — drop nested AppBar, add search/filter row, show ReturnDelivery on card ([ebbe439](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ebbe439214dd0fee7c8565c2ee47beb982d244b2))
* replace linked-sale dropdown with buyer-scoped sale picker ([c5b8436](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c5b84368fe37dfdb5fff06ce137ce290d50ef846))
* replace SalesHeatMap with GeographicSalesView (list default + map toggle) ([#163](https://github.com/OneDeveloperCoding/latitude-tracker/issues/163)) ([7b74847](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7b74847a95b71772b285041b973e2928fb3abefb))
* reset app, item photo thumbnails, Flutter 3.44 upgrade ([4f339ee](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4f339ee55c6471ca058cf59da52b1aa96bb2929f))
* revamp demo tour as 7-page paged walkthrough ([de93643](https://github.com/OneDeveloperCoding/latitude-tracker/commit/de936432fe607b29111e4e5e8390f0a24b2d4106)), closes [#16](https://github.com/OneDeveloperCoding/latitude-tracker/issues/16)
* round colored status bubbles on SaleCard strip and Sale detail ([#197](https://github.com/OneDeveloperCoding/latitude-tracker/issues/197)) ([7a2e7f0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7a2e7f00bd0007ff4236f27d8a5c6cac22c7dd57))
* sale card age indicator and ready-but-unpaid badge ([b8b357f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b8b357ffb71722024c04bece7a01b18400697937))
* SaleItem as sub-entity — multi-item sales ([7c91f3d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7c91f3dcf0bb22c7d056c94d4d82342b64acbe5f))
* shipped date on SaleCard, repair strip and detail reorder ([#200](https://github.com/OneDeveloperCoding/latitude-tracker/issues/200)) ([bd65440](https://github.com/OneDeveloperCoding/latitude-tracker/commit/bd654409259688e22acb8c7d20f2225b2811d64d))
* show buyer's repair history in Buyer detail screen ([0d22e7f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0d22e7f3a66b10dac86b5ea14878c7bd930c4e79))
* show buyer's repair history in Buyer detail screen ([266df51](https://github.com/OneDeveloperCoding/latitude-tracker/commit/266df5115642b38e8f57eb3334f0723aaf486f83))
* swipe-to-update payment and shipment status from Sales list ([#189](https://github.com/OneDeveloperCoding/latitude-tracker/issues/189)) ([fd66b77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fd66b7702f2426f27aa82693a4e23032532d4f81))
* tappable Instagram handle opens profile in app or browser ([348ddcf](https://github.com/OneDeveloperCoding/latitude-tracker/commit/348ddcf8276dc4adc0359f08d8ae506481c895a7))
* tapping phone number in Buyer Detail prompts call or message ([349f135](https://github.com/OneDeveloperCoding/latitude-tracker/commit/349f135c4f64c58271ef09594f29105929852fd8))
* tapping phone number in Buyer Detail prompts call or message ([96a3a99](https://github.com/OneDeveloperCoding/latitude-tracker/commit/96a3a996c2652f18d166e81bf06200500efe5909))
* tri-indicator status strip on SaleCard, RepairCard, and detail section headers ([#194](https://github.com/OneDeveloperCoding/latitude-tracker/issues/194)) ([dda2065](https://github.com/OneDeveloperCoding/latitude-tracker/commit/dda2065313794334993a05a0586bf177ea4e71b7))
* unified edit mode for RepairDetailScreen with read-only default ([#206](https://github.com/OneDeveloperCoding/latitude-tracker/issues/206)) ([8bfbe34](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8bfbe340a9d246b6a3f68ce5e67ed1e114910b6e))
* unified edit mode for SaleDetailScreen with read-only default ([#205](https://github.com/OneDeveloperCoding/latitude-tracker/issues/205)) ([77a867e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/77a867eabce68b73967ca4148e6f54b9362096ee))
* unified NIF/AT compliance row with inline NIF entry ([fa85fe3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fa85fe3226c381ac1ea7838b223dde70e833cd77))
* v1.1.0 — tabs, crash fixes, postal code, autofill, dashboard, tests ([edf2ef1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/edf2ef1d0e5b397e3624c3fc5ad9c6eef2d48469))
* year → month drill-down filter for buyer purchase history ([48365c1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/48365c18caae4734774aa28c9d85ae3acba2aff5))


### Bug Fixes

* accessibility improvements — icon button labels, touch targets, CircleAvatar semantics ([#101](https://github.com/OneDeveloperCoding/latitude-tracker/issues/101)) ([e64987b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e64987b8f46b4d9b1b8ed433fe28d89423a4e200))
* add SafeArea to SalesRepairsTabScreen so tab bar clears status bar ([#159](https://github.com/OneDeveloperCoding/latitude-tracker/issues/159)) ([c4b2e77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c4b2e77a3d32b066e8f57d9fabd81388b167bf47))
* add StoreErrorWidget with retry to all store-driven screens ([#84](https://github.com/OneDeveloperCoding/latitude-tracker/issues/84)) ([be82bea](https://github.com/OneDeveloperCoding/latitude-tracker/commit/be82bea79f703cfee0e92c0756d6a7f8b26ea0a6))
* add unsaved-changes PopScope guard to BuyerFormScreen and BuyerAddressFormScreen ([#90](https://github.com/OneDeveloperCoding/latitude-tracker/issues/90)) ([fccf94c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fccf94c0073ab05226398856650a95793cabc78c))
* address code review findings from PR [#130](https://github.com/OneDeveloperCoding/latitude-tracker/issues/130) ([45d52dd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/45d52dd33328282d906c1808904ed0bcaba3ad78))
* address code review findings on auth stream PR ([57cee65](https://github.com/OneDeveloperCoding/latitude-tracker/commit/57cee65f07799085055066d04d6c4db0e53d9779))
* address code review findings on release-please workflow ([e1069e8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e1069e878e92b7ee858fb1df99d432a7773fb729))
* align repair date format and icon with sale detail conventions ([e3796dd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3796ddb4b3ab7cc64e5a86ad09ed1d3c4065c9b))
* bump google-services to 4.4.2 for Crashlytics plugin v3 compatibility ([1909b47](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1909b47a922c3152f3063ee1f1b064929785f919))
* cache auth stream in _AuthGate to prevent tab state reset on navigation ([9231a01](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9231a0166429ef78f48fa631236ebbecb5ea7243))
* cache auth stream in _AuthGate to prevent tab state reset on navigation ([72c6843](https://github.com/OneDeveloperCoding/latitude-tracker/commit/72c6843a058d1835be5d0d07435964d62eefe45e))
* chunk year-delete batches and fix operation order to prevent orphans ([#64](https://github.com/OneDeveloperCoding/latitude-tracker/issues/64)) ([955f67a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/955f67abfe7886ce3ee1d242d13f4154286ae0bd)), closes [#36](https://github.com/OneDeveloperCoding/latitude-tracker/issues/36)
* clear stale optimistic RepairStatus on external update ([133aa43](https://github.com/OneDeveloperCoding/latitude-tracker/commit/133aa43d4044438690b148ef28a70ac7e835615d))
* close two gaps in Repair feature found during review ([3ed823a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3ed823ae5d4b1911ce14495dfe90a08304d13e6b))
* complete error handling audit and wire up full Crashlytics coverage ([f503a97](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f503a971d1f7bb0d39502d0d2e56ef1df5f0cec5)), closes [#17](https://github.com/OneDeveloperCoding/latitude-tracker/issues/17)
* convert _AddressDisplay to StatefulWidget to prevent Firestore listener churn ([b027c77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b027c77fa4d41d818b12d25ff40959625e67520e))
* convert RepairDetailScreen to StatefulWidget and move stream to initState ([#81](https://github.com/OneDeveloperCoding/latitude-tracker/issues/81)) ([4a5314c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4a5314c3f4e632b648a3cd326633328868b7ad17))
* correct import order and comment reference lint errors ([ce521b0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ce521b00b34190f40d3dad984fbd786df15f849d))
* correct release-please tag format and build trigger ([9452fc6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9452fc6080dd91668042545cc4629c871d67f879))
* correct release-please tag format and build trigger ([a689a1e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a689a1efdc478768d78214e9ccaa41e7643d2d6f))
* demo mode sign out and signed-in label in Settings ([13be88c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/13be88cae8879e16c82ebeee5d5b0cbe1ee85731))
* exit cleanly when develop is already in sync with main ([b4fbe52](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b4fbe528b2947990036b127909d6e3fdb9d574f6))
* form and label UX hardening across multiple screens ([#93](https://github.com/OneDeveloperCoding/latitude-tracker/issues/93)) ([2a3cd1d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2a3cd1dfc0ba41de160e44618bc9b19873e36e9a))
* global store lifecycle fragility — dispose race, StoreLoading deadlock, stale auth data ([#72](https://github.com/OneDeveloperCoding/latitude-tracker/issues/72)) ([a7d9fcd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a7d9fcd98afd36777912f59b2706c9ae17223679))
* global stores stuck permanently in StoreError after first stream error ([#70](https://github.com/OneDeveloperCoding/latitude-tracker/issues/70)) ([342b323](https://github.com/OneDeveloperCoding/latitude-tracker/commit/342b32312ca39b4adcf8ad86f227577964fc816d))
* guard BuyerDetailScreen pop against double-pop race condition ([#157](https://github.com/OneDeveloperCoding/latitude-tracker/issues/157)) ([96d4749](https://github.com/OneDeveloperCoding/latitude-tracker/commit/96d474941c37adc5bc20c8f86dd963eabb7bbde3))
* guard fromFirestore and fromMap deserialisers against null fields and unknown enum strings ([#65](https://github.com/OneDeveloperCoding/latitude-tracker/issues/65)) ([205b1e0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/205b1e0b72ab5e09967d5a2966ef8696c45b8f5f))
* guard hideCategory against duplicate hidden entries ([#107](https://github.com/OneDeveloperCoding/latitude-tracker/issues/107)) ([5d3028d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/5d3028dae2d6ef87d727060b93c183c99f83ffcb))
* guard Merge PR step when develop is already in sync with main ([f98dd81](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f98dd812be689fc868c6e9dd779e35061706622b))
* guard Merge PR step when develop is already in sync with main ([64a023d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/64a023dc530ae81f63128ac2f728ff42545c5bca))
* harden auth-revocation handling after review ([d0f163a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d0f163ac85f46f12f370ac3f6b6426e7ec767bc5))
* ItemDetailSheet local state not updating on component changes ([afc3e61](https://github.com/OneDeveloperCoding/latitude-tracker/commit/afc3e616d75652382ccf6c5cca07bba966f891d0))
* keep only valid base64 chars from RELEASE_KEYSTORE before decode ([19b540d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/19b540d62e42ed57eba5291b201bf97ca85ad83b))
* keep only valid base64 chars from RELEASE_KEYSTORE before decode ([40a25d6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/40a25d6d2b1959ddb398bba127314b57c6555719))
* migrate shared_prefs_cache_test to package:test ([#131](https://github.com/OneDeveloperCoding/latitude-tracker/issues/131)) ([c094cf8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c094cf80c5a1ba061409e0722bd090d96330ba5a))
* migrate shared_prefs_cache_test to package:test ([#131](https://github.com/OneDeveloperCoding/latitude-tracker/issues/131)) ([99659ea](https://github.com/OneDeveloperCoding/latitude-tracker/commit/99659ea70f9e202e5d865926070058e0eecc10bb))
* move repair received-date into Item section card ([d9b9d4c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d9b9d4c182d003b9b9dc86e6a43c9c0c9cb85c66))
* move repair received-date into Item section card ([0675ea3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0675ea327ffcde50071d69ca68fdc83f5e404dc8))
* parse PR number from URL instead of --json flag on gh pr create ([780bda3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/780bda31eabc49d19ba3fab061cb8e9a0d61a5a9))
* parse PR number from URL instead of --json on gh pr create ([ac0e318](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ac0e318d2a2a40a0913d85d0644e2cf866c09f1f))
* poll until checks register before gh pr checks --watch ([40d9b88](https://github.com/OneDeveloperCoding/latitude-tracker/commit/40d9b8826fcf6416b55403d78b799aaabe371236))
* poll until checks register before gh pr checks --watch ([698d6e1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/698d6e1e99edd2aceb88569bbe9ce6ca76bf52de))
* pop detail screens when stream emits null after deletion ([#85](https://github.com/OneDeveloperCoding/latitude-tracker/issues/85)) ([2defda0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2defda0d9e385267d4a609600c224462e1e77617))
* postal code form — no-results feedback and field reset on clear ([bed2da7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/bed2da713ab7152423d319b4e26d22a5fd993dd8))
* preserve sales filter state and handle loading/error in buyer repair history ([e66ad77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e66ad77ed5ace01c4e82b91932d7d45053817ca4))
* prevent Nominatim server errors from being cached as geocoding misses ([#92](https://github.com/OneDeveloperCoding/latitude-tracker/issues/92)) ([1ab2d78](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1ab2d785e859f59596957cb07fb74ae6b6bc4d4a)), closes [#59](https://github.com/OneDeveloperCoding/latitude-tracker/issues/59)
* reapply post-review fixes lost in PR squash ([1668a30](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1668a304e79bcc17c69ef5551232c6d84722238a))
* reinstate isActive default, fix sort icon, extract SheetSectionLabel ([be04ab2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/be04ab245308343c6ebc4ab3027fe6f733bd364a))
* remove AddressesStore to prevent collectionGroup permission-denied sign-out ([da09385](https://github.com/OneDeveloperCoding/latitude-tracker/commit/da093853c3fd05ebf18d9571357661fdd11ee263))
* remove AddressesStore to prevent collectionGroup silent sign-out ([7519fe5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7519fe59230ecefb746066393a592d30a635450e))
* rename order/encomenda to sale/venda across all UI strings and models ([#41](https://github.com/OneDeveloperCoding/latitude-tracker/issues/41)) ([f465514](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f4655147e9a60c5bd9c49a448763a2c9db67ee17))
* rename PT label 'Em curso' to 'Em progresso' for AssemblyStatus and RepairStatus ([741adbd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/741adbd7663ca7e4b75226d28552124034a51603))
* replace _AddressDisplay per-widget stream with AddressesStore ([#73](https://github.com/OneDeveloperCoding/latitude-tracker/issues/73)) ([aac7d6a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/aac7d6ab5548a1255e0bba777070325a0be9107e))
* replace 📅 emoji with Icons.event on sale card scheduled date ([#150](https://github.com/OneDeveloperCoding/latitude-tracker/issues/150)) ([8261718](https://github.com/OneDeveloperCoding/latitude-tracker/commit/82617183af6e81f60d8c0762a5f3eaf8ff120a0e))
* replace AppBar edit icon with FAB on Sale and Repair detail screens ([#198](https://github.com/OneDeveloperCoding/latitude-tracker/issues/198)) ([cee3d84](https://github.com/OneDeveloperCoding/latitude-tracker/commit/cee3d84dd96871198d2fea9c8946970796122d33))
* replace AppBar edit icon with FAB on Sale and Repair detail screens ([#198](https://github.com/OneDeveloperCoding/latitude-tracker/issues/198)) ([a5d2624](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a5d262455c1e369cf680ab15f55ab2d6d3e50e20))
* replace assembly icon and label with shopping cart and 'Needs materials' ([e3a8123](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3a8123954e72742af5bf2f0eed491491d5638fa))
* replace currentUser! force-unwraps with null-guarded throws ([c2ea560](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c2ea56054bbacc53daae75533d61123170c0d330))
* replace currentUser! force-unwraps with null-guarded throws ([55fd7b8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/55fd7b8a163c70200538b0633065a03bdaf5fe72)), closes [#58](https://github.com/OneDeveloperCoding/latitude-tracker/issues/58)
* replace map icon with location pin on open-in-maps buttons ([#147](https://github.com/OneDeveloperCoding/latitude-tracker/issues/147)) ([8145445](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8145445337cd06e121767d3cd1437b5d8e163e06))
* run renameCategory ops sequentially to limit partial-failure blast radius ([#117](https://github.com/OneDeveloperCoding/latitude-tracker/issues/117)) ([1868cc4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1868cc4bbec79f95b5c961c0a0adf2e5579fbbe2))
* safe CI secret injection and partial year-delete error message ([03a4918](https://github.com/OneDeveloperCoding/latitude-tracker/commit/03a49186904d802012a314b0491a7dc6a952716f))
* ship exits cleanly when develop is already in sync with main ([0e226c7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0e226c71bf6c5ee43d0d5e1f6ad909ce4687b6a2))
* ship workflow gh pr create --json flag compatibility ([6822495](https://github.com/OneDeveloperCoding/latitude-tracker/commit/682249524004abe6253278334d091e7d3c2f9007))
* ship workflow null PR number and extract needsMaterials getter ([080dd3f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/080dd3f5f1072f29f583130efb72a4d8e074a382))
* ship workflow null PR number and extract needsMaterials getter ([66483c5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/66483c5955e1e9ae667ae146e94c1fdce06d3a2a)), closes [#229](https://github.com/OneDeveloperCoding/latitude-tracker/issues/229)
* sort chips show arrow and checkmark simultaneously; date chip hides default direction ([#78](https://github.com/OneDeveloperCoding/latitude-tracker/issues/78)) ([a7991e4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a7991e46c4ea1b8308752d7f463232d2fd2a2ee6)), closes [#76](https://github.com/OneDeveloperCoding/latitude-tracker/issues/76)
* strip whitespace from RELEASE_KEYSTORE before base64 decode ([d5c4667](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d5c4667db0538a56ce27e2910cbac1d5b346644e))
* strip whitespace from RELEASE_KEYSTORE before base64 decode ([e3820f2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3820f2305f70e5a4f7cb1a5ef0f507f6adec0ab))
* surface errors instead of silent failures across store, streams, and network services ([f696f1a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f696f1adc104a57b1a5bc402402ca4f052cc94b5))
* update _item state immediately in _ItemDetailSheet ([#195](https://github.com/OneDeveloperCoding/latitude-tracker/issues/195)) ([697cba2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/697cba277b2dcebf7c446688bfc09e70b58ad910))
* wire AppLocaleScope InheritedWidget for reactive locale switching ([4725e5c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4725e5cac7947964dd44c0e9f13ca3504ba2c147))
* wire Crashlytics to store stream errors and plug silent catch gaps ([9647e50](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9647e501337306728f7e5fea0c7e13e2ef61adb7))
* wire Crashlytics to UI write catch blocks and guard _cancel navigation ([#68](https://github.com/OneDeveloperCoding/latitude-tracker/issues/68)) ([105fb31](https://github.com/OneDeveloperCoding/latitude-tracker/commit/105fb3126aef274dd5372be954bda55324880c9f))


### Performance Improvements

* add cacheWidth/cacheHeight to thumbnail Image.network calls ([#91](https://github.com/OneDeveloperCoding/latitude-tracker/issues/91)) ([b030fb9](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b030fb9954e237af4d19378066f5c2d4e4a6235d))
* cache analytics computation in AnalyticsScreen state ([#112](https://github.com/OneDeveloperCoding/latitude-tracker/issues/112)) ([e1ce2be](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e1ce2bef9c1a4835e4d6c56920a088d0a2520f83))
* cache and single-pass optimisations across core screens ([21f7bda](https://github.com/OneDeveloperCoding/latitude-tracker/commit/21f7bda65c612dae1aba85dee49a4ba0ddac18a2))
* fix O(buyers×sales) quadratic rebuild in BuyersListScreen ([#83](https://github.com/OneDeveloperCoding/latitude-tracker/issues/83)) ([d5261c4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d5261c48f0411af4c973351074aee7f29a8030a6))
* SalesListScreen micro-optimizations — buyer scan, DateFormat, year/month recompute ([#120](https://github.com/OneDeveloperCoding/latitude-tracker/issues/120)) ([2817e2a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2817e2a97aadc4a063c5f4a8b1f8c5ce5a253347))

## [1.11.0](https://github.com/OneDeveloperCoding/latitude-tracker/compare/v1.10.0...v1.11.0) (2026-06-25)


### Features

* add BuyerAddress creation from within New Sale delivery section ([31f5131](https://github.com/OneDeveloperCoding/latitude-tracker/commit/31f51318e6b1cc896035731659a2b53caa5883e0))
* add curated theme presets with dark/light toggle in Settings ([#187](https://github.com/OneDeveloperCoding/latitude-tracker/issues/187)) ([c66bf4d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c66bf4d467a127b7e10c0c4cf2a826e4f5e45673))
* add dark mode toggle in Settings ([#121](https://github.com/OneDeveloperCoding/latitude-tracker/issues/121)) ([e691da7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e691da7fad08982d0efde3fb09f661fb55d7bf25))
* add Google Sign-In via account linking ([#216](https://github.com/OneDeveloperCoding/latitude-tracker/issues/216)) ([c1ab836](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c1ab83630490b456cfa750a7cf269d4b745c6f6b))
* add hand delivery as a third delivery type ([e62b3a2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e62b3a2d7fde1872c1c78da8ccec3c1976cb35a2)), closes [#34](https://github.com/OneDeveloperCoding/latitude-tracker/issues/34)
* add photo and notes support to ComponentChecklist items ([#149](https://github.com/OneDeveloperCoding/latitude-tracker/issues/149)) ([a46d4e2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a46d4e29f36757edd677c52cb727253a4cc202c9))
* add quantity field to ComponentItem and make AssemblyStatus fully manual ([#155](https://github.com/OneDeveloperCoding/latitude-tracker/issues/155)) ([8adbe02](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8adbe028f20293e38a72c79f5cc6c87343e54ee1))
* add Repair feature — track repair jobs linked to sales or standalone ([9436059](https://github.com/OneDeveloperCoding/latitude-tracker/commit/94360593d78bc9d3688c5a2f165ff157997094a7))
* add Revolut and PayPal payment methods with brand colours ([eeef5e2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/eeef5e260ca587fe3aa4ef3c295b4624ead05360)), closes [#33](https://github.com/OneDeveloperCoding/latitude-tracker/issues/33)
* add watchBuyer stream to BuyerRepository and use it in BuyerDetailScreen ([#82](https://github.com/OneDeveloperCoding/latitude-tracker/issues/82)) ([2f63799](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2f6379947606fead06eff9ee71b507f502d77fe9))
* aggregate same-named ComponentItems across SaleItems in ShoppingList ([#161](https://github.com/OneDeveloperCoding/latitude-tracker/issues/161)) ([0893550](https://github.com/OneDeveloperCoding/latitude-tracker/commit/08935504e61a3df9c08e81d67446aca74630eb98))
* archive analytics — view yearly/monthly trends for imported archives ([#32](https://github.com/OneDeveloperCoding/latitude-tracker/issues/32)) ([02563a6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/02563a69f8eaadd9fcff28a9fc5e845d38d495a8))
* category maintenance — rename, hide, delete ([#35](https://github.com/OneDeveloperCoding/latitude-tracker/issues/35)) ([a1b0bf8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a1b0bf80ac9d99ea6f5b832167f7b54145e13d0f))
* collapse search toolbar in Sales and Buyers screens ([#75](https://github.com/OneDeveloperCoding/latitude-tracker/issues/75)) ([e6a764a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e6a764a9d45d002a047d40100adbb55843d7b9a7)), closes [#74](https://github.com/OneDeveloperCoding/latitude-tracker/issues/74)
* compact sort UI in Sales filter sheet and move Buyers ranking metric picker into tune sheet ([#77](https://github.com/OneDeveloperCoding/latitude-tracker/issues/77)) ([9bf3968](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9bf39680ba8ad6b9fdd8290790c01bc427370659))
* copy formatted address from buyer detail + fix buyer form i18n ([368f39b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/368f39b91213889a4c0b9089fafdb290f4ecb3ed))
* dashboard analytics section — category trends and period comparisons ([1db7ef6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1db7ef63e61023c4bdb6acce2159677d4fc03122)), closes [#8](https://github.com/OneDeveloperCoding/latitude-tracker/issues/8)
* dashboard layout revamp — trends card, grouped actions, clean revenue card ([2f59dda](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2f59dda8e49de34000feddef0d9e8598afe91273)), closes [#4](https://github.com/OneDeveloperCoding/latitude-tracker/issues/4)
* enhanced TrendsScreen with stacked category chart and interactive analysis ([162a1df](https://github.com/OneDeveloperCoding/latitude-tracker/commit/162a1dfc8ff093290d9dd8c95ec1e4275aedf4e8))
* filter and sort revamp — multi-select, year/month drill-down, active-only default ([1037942](https://github.com/OneDeveloperCoding/latitude-tracker/commit/103794206377e89290d32f6c805699e7f31927f8)), closes [#6](https://github.com/OneDeveloperCoding/latitude-tracker/issues/6)
* fix needs-materials counter and add ready-to-assemble dashboard card ([#228](https://github.com/OneDeveloperCoding/latitude-tracker/issues/228)) ([5db7221](https://github.com/OneDeveloperCoding/latitude-tracker/commit/5db722159aab8778e5413f70d3f780fe9be9d328))
* heat map overhaul — dedicated screen, geocoding cache, tile cache, background warm-up ([d6b6bc9](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d6b6bc9e7b61164c8df3cf91279a8059fda50383))
* implement GeocodingService.warmUp() via GeocodingWarmUp listener ([#178](https://github.com/OneDeveloperCoding/latitude-tracker/issues/178)) ([fe1ee60](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fe1ee607f2f97fdd94ef224c47e0f84921c2428e))
* in-app update checker and APK installer via GitHub Releases ([#214](https://github.com/OneDeveloperCoding/latitude-tracker/issues/214)) ([1902cd5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1902cd52c493001a2c87d3e5739de732c921f1a3))
* inline RepairStatus picker on Repair detail screen ([7ff63b1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7ff63b1cf9459c607cf07a6856ce4abc21a63908))
* inline RepairStatus picker on Repair detail screen ([2d60660](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2d60660315f15a551fe4146d6dbb9f3ad121a2b3))
* item category on Sales, buyer tags and buyer notes ([3259e76](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3259e762cd6cc7d0876e427df475f3938a12e477))
* make Notes text selectable in sale and buyer detail screens ([8f65e20](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8f65e208973e49275181aadde9cf7642ea2c0b94))
* make Notes text selectable in sale and buyer detail screens ([a66cd3f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a66cd3f0aa64e8bcaefaf5e139b91f3d0f4c695a))
* master-detail split view for Sales list on tablet ([3b9dcac](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3b9dcacf61727a8ccd554fea676432d7e4edd748)), closes [#28](https://github.com/OneDeveloperCoding/latitude-tracker/issues/28)
* new AnalyticsScreen merging InsightsCard and TrendsScreen, restore action rows ([cf7f27e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/cf7f27e671dab9403151e0ca332ec921f95aaaec))
* note indicator on sale cards with tap-to-preview ([1a9d42f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1a9d42f9720ebb6756d7f11a1e6af7508b881342))
* open BuyerAddress in Google Maps from Sale detail and Buyer detail ([#100](https://github.com/OneDeveloperCoding/latitude-tracker/issues/100)) ([49d4445](https://github.com/OneDeveloperCoding/latitude-tracker/commit/49d4445fb6e1e37a577c629571b188d2a7e9af52))
* redesign dashboard action section as compact 3-per-row button grid ([e979e84](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e979e84426a946eb2ffedb84dc2744080a156085)), closes [#25](https://github.com/OneDeveloperCoding/latitude-tracker/issues/25)
* redesign dashboard period control and unify search bars across screens ([11ad656](https://github.com/OneDeveloperCoding/latitude-tracker/commit/11ad6561ab2caf973f8f36d2368846fe88c8c67b))
* redesign RepairCard and fix demo mode guards ([#201](https://github.com/OneDeveloperCoding/latitude-tracker/issues/201)) ([0a275f3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0a275f330d5a808420849d7d58579f6c6bd37019))
* rename Trends to Analytics and swap card order in analytics screen ([c6c36c8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c6c36c8788c169b8b330610361e5eaf2c76f7b60)), closes [#30](https://github.com/OneDeveloperCoding/latitude-tracker/issues/30)
* repair detail — quick action buttons to advance ReturnDelivery status ([#94](https://github.com/OneDeveloperCoding/latitude-tracker/issues/94)) ([a35250b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a35250bb9622bfae30057aff61540023ddda56fc))
* repairs list — drop nested AppBar, add search/filter row, show ReturnDelivery on card ([c15d40d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c15d40d2075a30960b7e997f9ab8d622a06dbd43))
* repairs list — drop nested AppBar, add search/filter row, show ReturnDelivery on card ([ebbe439](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ebbe439214dd0fee7c8565c2ee47beb982d244b2))
* replace linked-sale dropdown with buyer-scoped sale picker ([c5b8436](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c5b84368fe37dfdb5fff06ce137ce290d50ef846))
* replace SalesHeatMap with GeographicSalesView (list default + map toggle) ([#163](https://github.com/OneDeveloperCoding/latitude-tracker/issues/163)) ([7b74847](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7b74847a95b71772b285041b973e2928fb3abefb))
* reset app, item photo thumbnails, Flutter 3.44 upgrade ([4f339ee](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4f339ee55c6471ca058cf59da52b1aa96bb2929f))
* revamp demo tour as 7-page paged walkthrough ([de93643](https://github.com/OneDeveloperCoding/latitude-tracker/commit/de936432fe607b29111e4e5e8390f0a24b2d4106)), closes [#16](https://github.com/OneDeveloperCoding/latitude-tracker/issues/16)
* round colored status bubbles on SaleCard strip and Sale detail ([#197](https://github.com/OneDeveloperCoding/latitude-tracker/issues/197)) ([7a2e7f0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7a2e7f00bd0007ff4236f27d8a5c6cac22c7dd57))
* sale card age indicator and ready-but-unpaid badge ([b8b357f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b8b357ffb71722024c04bece7a01b18400697937))
* SaleItem as sub-entity — multi-item sales ([7c91f3d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7c91f3dcf0bb22c7d056c94d4d82342b64acbe5f))
* shipped date on SaleCard, repair strip and detail reorder ([#200](https://github.com/OneDeveloperCoding/latitude-tracker/issues/200)) ([bd65440](https://github.com/OneDeveloperCoding/latitude-tracker/commit/bd654409259688e22acb8c7d20f2225b2811d64d))
* show buyer's repair history in Buyer detail screen ([0d22e7f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0d22e7f3a66b10dac86b5ea14878c7bd930c4e79))
* show buyer's repair history in Buyer detail screen ([266df51](https://github.com/OneDeveloperCoding/latitude-tracker/commit/266df5115642b38e8f57eb3334f0723aaf486f83))
* swipe-to-update payment and shipment status from Sales list ([#189](https://github.com/OneDeveloperCoding/latitude-tracker/issues/189)) ([fd66b77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fd66b7702f2426f27aa82693a4e23032532d4f81))
* tappable Instagram handle opens profile in app or browser ([348ddcf](https://github.com/OneDeveloperCoding/latitude-tracker/commit/348ddcf8276dc4adc0359f08d8ae506481c895a7))
* tapping phone number in Buyer Detail prompts call or message ([349f135](https://github.com/OneDeveloperCoding/latitude-tracker/commit/349f135c4f64c58271ef09594f29105929852fd8))
* tapping phone number in Buyer Detail prompts call or message ([96a3a99](https://github.com/OneDeveloperCoding/latitude-tracker/commit/96a3a996c2652f18d166e81bf06200500efe5909))
* tri-indicator status strip on SaleCard, RepairCard, and detail section headers ([#194](https://github.com/OneDeveloperCoding/latitude-tracker/issues/194)) ([dda2065](https://github.com/OneDeveloperCoding/latitude-tracker/commit/dda2065313794334993a05a0586bf177ea4e71b7))
* unified edit mode for RepairDetailScreen with read-only default ([#206](https://github.com/OneDeveloperCoding/latitude-tracker/issues/206)) ([8bfbe34](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8bfbe340a9d246b6a3f68ce5e67ed1e114910b6e))
* unified edit mode for SaleDetailScreen with read-only default ([#205](https://github.com/OneDeveloperCoding/latitude-tracker/issues/205)) ([77a867e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/77a867eabce68b73967ca4148e6f54b9362096ee))
* unified NIF/AT compliance row with inline NIF entry ([fa85fe3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fa85fe3226c381ac1ea7838b223dde70e833cd77))
* v1.1.0 — tabs, crash fixes, postal code, autofill, dashboard, tests ([edf2ef1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/edf2ef1d0e5b397e3624c3fc5ad9c6eef2d48469))
* year → month drill-down filter for buyer purchase history ([48365c1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/48365c18caae4734774aa28c9d85ae3acba2aff5))


### Bug Fixes

* accessibility improvements — icon button labels, touch targets, CircleAvatar semantics ([#101](https://github.com/OneDeveloperCoding/latitude-tracker/issues/101)) ([e64987b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e64987b8f46b4d9b1b8ed433fe28d89423a4e200))
* add SafeArea to SalesRepairsTabScreen so tab bar clears status bar ([#159](https://github.com/OneDeveloperCoding/latitude-tracker/issues/159)) ([c4b2e77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c4b2e77a3d32b066e8f57d9fabd81388b167bf47))
* add StoreErrorWidget with retry to all store-driven screens ([#84](https://github.com/OneDeveloperCoding/latitude-tracker/issues/84)) ([be82bea](https://github.com/OneDeveloperCoding/latitude-tracker/commit/be82bea79f703cfee0e92c0756d6a7f8b26ea0a6))
* add unsaved-changes PopScope guard to BuyerFormScreen and BuyerAddressFormScreen ([#90](https://github.com/OneDeveloperCoding/latitude-tracker/issues/90)) ([fccf94c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fccf94c0073ab05226398856650a95793cabc78c))
* address code review findings from PR [#130](https://github.com/OneDeveloperCoding/latitude-tracker/issues/130) ([45d52dd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/45d52dd33328282d906c1808904ed0bcaba3ad78))
* address code review findings on auth stream PR ([57cee65](https://github.com/OneDeveloperCoding/latitude-tracker/commit/57cee65f07799085055066d04d6c4db0e53d9779))
* address code review findings on release-please workflow ([e1069e8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e1069e878e92b7ee858fb1df99d432a7773fb729))
* align repair date format and icon with sale detail conventions ([e3796dd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3796ddb4b3ab7cc64e5a86ad09ed1d3c4065c9b))
* bump google-services to 4.4.2 for Crashlytics plugin v3 compatibility ([1909b47](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1909b47a922c3152f3063ee1f1b064929785f919))
* cache auth stream in _AuthGate to prevent tab state reset on navigation ([9231a01](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9231a0166429ef78f48fa631236ebbecb5ea7243))
* cache auth stream in _AuthGate to prevent tab state reset on navigation ([72c6843](https://github.com/OneDeveloperCoding/latitude-tracker/commit/72c6843a058d1835be5d0d07435964d62eefe45e))
* chunk year-delete batches and fix operation order to prevent orphans ([#64](https://github.com/OneDeveloperCoding/latitude-tracker/issues/64)) ([955f67a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/955f67abfe7886ce3ee1d242d13f4154286ae0bd)), closes [#36](https://github.com/OneDeveloperCoding/latitude-tracker/issues/36)
* clear stale optimistic RepairStatus on external update ([133aa43](https://github.com/OneDeveloperCoding/latitude-tracker/commit/133aa43d4044438690b148ef28a70ac7e835615d))
* close two gaps in Repair feature found during review ([3ed823a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3ed823ae5d4b1911ce14495dfe90a08304d13e6b))
* complete error handling audit and wire up full Crashlytics coverage ([f503a97](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f503a971d1f7bb0d39502d0d2e56ef1df5f0cec5)), closes [#17](https://github.com/OneDeveloperCoding/latitude-tracker/issues/17)
* convert _AddressDisplay to StatefulWidget to prevent Firestore listener churn ([b027c77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b027c77fa4d41d818b12d25ff40959625e67520e))
* convert RepairDetailScreen to StatefulWidget and move stream to initState ([#81](https://github.com/OneDeveloperCoding/latitude-tracker/issues/81)) ([4a5314c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4a5314c3f4e632b648a3cd326633328868b7ad17))
* correct import order and comment reference lint errors ([ce521b0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ce521b00b34190f40d3dad984fbd786df15f849d))
* correct release-please tag format and build trigger ([9452fc6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9452fc6080dd91668042545cc4629c871d67f879))
* correct release-please tag format and build trigger ([a689a1e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a689a1efdc478768d78214e9ccaa41e7643d2d6f))
* demo mode sign out and signed-in label in Settings ([13be88c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/13be88cae8879e16c82ebeee5d5b0cbe1ee85731))
* exit cleanly when develop is already in sync with main ([b4fbe52](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b4fbe528b2947990036b127909d6e3fdb9d574f6))
* form and label UX hardening across multiple screens ([#93](https://github.com/OneDeveloperCoding/latitude-tracker/issues/93)) ([2a3cd1d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2a3cd1dfc0ba41de160e44618bc9b19873e36e9a))
* global store lifecycle fragility — dispose race, StoreLoading deadlock, stale auth data ([#72](https://github.com/OneDeveloperCoding/latitude-tracker/issues/72)) ([a7d9fcd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a7d9fcd98afd36777912f59b2706c9ae17223679))
* global stores stuck permanently in StoreError after first stream error ([#70](https://github.com/OneDeveloperCoding/latitude-tracker/issues/70)) ([342b323](https://github.com/OneDeveloperCoding/latitude-tracker/commit/342b32312ca39b4adcf8ad86f227577964fc816d))
* guard BuyerDetailScreen pop against double-pop race condition ([#157](https://github.com/OneDeveloperCoding/latitude-tracker/issues/157)) ([96d4749](https://github.com/OneDeveloperCoding/latitude-tracker/commit/96d474941c37adc5bc20c8f86dd963eabb7bbde3))
* guard fromFirestore and fromMap deserialisers against null fields and unknown enum strings ([#65](https://github.com/OneDeveloperCoding/latitude-tracker/issues/65)) ([205b1e0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/205b1e0b72ab5e09967d5a2966ef8696c45b8f5f))
* guard hideCategory against duplicate hidden entries ([#107](https://github.com/OneDeveloperCoding/latitude-tracker/issues/107)) ([5d3028d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/5d3028dae2d6ef87d727060b93c183c99f83ffcb))
* guard Merge PR step when develop is already in sync with main ([f98dd81](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f98dd812be689fc868c6e9dd779e35061706622b))
* guard Merge PR step when develop is already in sync with main ([64a023d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/64a023dc530ae81f63128ac2f728ff42545c5bca))
* harden auth-revocation handling after review ([d0f163a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d0f163ac85f46f12f370ac3f6b6426e7ec767bc5))
* ItemDetailSheet local state not updating on component changes ([afc3e61](https://github.com/OneDeveloperCoding/latitude-tracker/commit/afc3e616d75652382ccf6c5cca07bba966f891d0))
* keep only valid base64 chars from RELEASE_KEYSTORE before decode ([19b540d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/19b540d62e42ed57eba5291b201bf97ca85ad83b))
* keep only valid base64 chars from RELEASE_KEYSTORE before decode ([40a25d6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/40a25d6d2b1959ddb398bba127314b57c6555719))
* migrate shared_prefs_cache_test to package:test ([#131](https://github.com/OneDeveloperCoding/latitude-tracker/issues/131)) ([c094cf8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c094cf80c5a1ba061409e0722bd090d96330ba5a))
* migrate shared_prefs_cache_test to package:test ([#131](https://github.com/OneDeveloperCoding/latitude-tracker/issues/131)) ([99659ea](https://github.com/OneDeveloperCoding/latitude-tracker/commit/99659ea70f9e202e5d865926070058e0eecc10bb))
* move repair received-date into Item section card ([d9b9d4c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d9b9d4c182d003b9b9dc86e6a43c9c0c9cb85c66))
* move repair received-date into Item section card ([0675ea3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0675ea327ffcde50071d69ca68fdc83f5e404dc8))
* parse PR number from URL instead of --json flag on gh pr create ([780bda3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/780bda31eabc49d19ba3fab061cb8e9a0d61a5a9))
* parse PR number from URL instead of --json on gh pr create ([ac0e318](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ac0e318d2a2a40a0913d85d0644e2cf866c09f1f))
* poll until checks register before gh pr checks --watch ([40d9b88](https://github.com/OneDeveloperCoding/latitude-tracker/commit/40d9b8826fcf6416b55403d78b799aaabe371236))
* poll until checks register before gh pr checks --watch ([698d6e1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/698d6e1e99edd2aceb88569bbe9ce6ca76bf52de))
* pop detail screens when stream emits null after deletion ([#85](https://github.com/OneDeveloperCoding/latitude-tracker/issues/85)) ([2defda0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2defda0d9e385267d4a609600c224462e1e77617))
* postal code form — no-results feedback and field reset on clear ([bed2da7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/bed2da713ab7152423d319b4e26d22a5fd993dd8))
* preserve sales filter state and handle loading/error in buyer repair history ([e66ad77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e66ad77ed5ace01c4e82b91932d7d45053817ca4))
* prevent Nominatim server errors from being cached as geocoding misses ([#92](https://github.com/OneDeveloperCoding/latitude-tracker/issues/92)) ([1ab2d78](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1ab2d785e859f59596957cb07fb74ae6b6bc4d4a)), closes [#59](https://github.com/OneDeveloperCoding/latitude-tracker/issues/59)
* reapply post-review fixes lost in PR squash ([1668a30](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1668a304e79bcc17c69ef5551232c6d84722238a))
* reinstate isActive default, fix sort icon, extract SheetSectionLabel ([be04ab2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/be04ab245308343c6ebc4ab3027fe6f733bd364a))
* remove AddressesStore to prevent collectionGroup permission-denied sign-out ([da09385](https://github.com/OneDeveloperCoding/latitude-tracker/commit/da093853c3fd05ebf18d9571357661fdd11ee263))
* remove AddressesStore to prevent collectionGroup silent sign-out ([7519fe5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7519fe59230ecefb746066393a592d30a635450e))
* rename order/encomenda to sale/venda across all UI strings and models ([#41](https://github.com/OneDeveloperCoding/latitude-tracker/issues/41)) ([f465514](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f4655147e9a60c5bd9c49a448763a2c9db67ee17))
* rename PT label 'Em curso' to 'Em progresso' for AssemblyStatus and RepairStatus ([741adbd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/741adbd7663ca7e4b75226d28552124034a51603))
* replace _AddressDisplay per-widget stream with AddressesStore ([#73](https://github.com/OneDeveloperCoding/latitude-tracker/issues/73)) ([aac7d6a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/aac7d6ab5548a1255e0bba777070325a0be9107e))
* replace 📅 emoji with Icons.event on sale card scheduled date ([#150](https://github.com/OneDeveloperCoding/latitude-tracker/issues/150)) ([8261718](https://github.com/OneDeveloperCoding/latitude-tracker/commit/82617183af6e81f60d8c0762a5f3eaf8ff120a0e))
* replace AppBar edit icon with FAB on Sale and Repair detail screens ([#198](https://github.com/OneDeveloperCoding/latitude-tracker/issues/198)) ([cee3d84](https://github.com/OneDeveloperCoding/latitude-tracker/commit/cee3d84dd96871198d2fea9c8946970796122d33))
* replace AppBar edit icon with FAB on Sale and Repair detail screens ([#198](https://github.com/OneDeveloperCoding/latitude-tracker/issues/198)) ([a5d2624](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a5d262455c1e369cf680ab15f55ab2d6d3e50e20))
* replace assembly icon and label with shopping cart and 'Needs materials' ([e3a8123](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3a8123954e72742af5bf2f0eed491491d5638fa))
* replace currentUser! force-unwraps with null-guarded throws ([c2ea560](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c2ea56054bbacc53daae75533d61123170c0d330))
* replace currentUser! force-unwraps with null-guarded throws ([55fd7b8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/55fd7b8a163c70200538b0633065a03bdaf5fe72)), closes [#58](https://github.com/OneDeveloperCoding/latitude-tracker/issues/58)
* replace map icon with location pin on open-in-maps buttons ([#147](https://github.com/OneDeveloperCoding/latitude-tracker/issues/147)) ([8145445](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8145445337cd06e121767d3cd1437b5d8e163e06))
* run renameCategory ops sequentially to limit partial-failure blast radius ([#117](https://github.com/OneDeveloperCoding/latitude-tracker/issues/117)) ([1868cc4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1868cc4bbec79f95b5c961c0a0adf2e5579fbbe2))
* safe CI secret injection and partial year-delete error message ([03a4918](https://github.com/OneDeveloperCoding/latitude-tracker/commit/03a49186904d802012a314b0491a7dc6a952716f))
* ship exits cleanly when develop is already in sync with main ([0e226c7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0e226c71bf6c5ee43d0d5e1f6ad909ce4687b6a2))
* ship workflow gh pr create --json flag compatibility ([6822495](https://github.com/OneDeveloperCoding/latitude-tracker/commit/682249524004abe6253278334d091e7d3c2f9007))
* ship workflow null PR number and extract needsMaterials getter ([080dd3f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/080dd3f5f1072f29f583130efb72a4d8e074a382))
* ship workflow null PR number and extract needsMaterials getter ([66483c5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/66483c5955e1e9ae667ae146e94c1fdce06d3a2a)), closes [#229](https://github.com/OneDeveloperCoding/latitude-tracker/issues/229)
* sort chips show arrow and checkmark simultaneously; date chip hides default direction ([#78](https://github.com/OneDeveloperCoding/latitude-tracker/issues/78)) ([a7991e4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a7991e46c4ea1b8308752d7f463232d2fd2a2ee6)), closes [#76](https://github.com/OneDeveloperCoding/latitude-tracker/issues/76)
* strip whitespace from RELEASE_KEYSTORE before base64 decode ([d5c4667](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d5c4667db0538a56ce27e2910cbac1d5b346644e))
* strip whitespace from RELEASE_KEYSTORE before base64 decode ([e3820f2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3820f2305f70e5a4f7cb1a5ef0f507f6adec0ab))
* surface errors instead of silent failures across store, streams, and network services ([f696f1a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f696f1adc104a57b1a5bc402402ca4f052cc94b5))
* update _item state immediately in _ItemDetailSheet ([#195](https://github.com/OneDeveloperCoding/latitude-tracker/issues/195)) ([697cba2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/697cba277b2dcebf7c446688bfc09e70b58ad910))
* wire AppLocaleScope InheritedWidget for reactive locale switching ([4725e5c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4725e5cac7947964dd44c0e9f13ca3504ba2c147))
* wire Crashlytics to store stream errors and plug silent catch gaps ([9647e50](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9647e501337306728f7e5fea0c7e13e2ef61adb7))
* wire Crashlytics to UI write catch blocks and guard _cancel navigation ([#68](https://github.com/OneDeveloperCoding/latitude-tracker/issues/68)) ([105fb31](https://github.com/OneDeveloperCoding/latitude-tracker/commit/105fb3126aef274dd5372be954bda55324880c9f))


### Performance Improvements

* add cacheWidth/cacheHeight to thumbnail Image.network calls ([#91](https://github.com/OneDeveloperCoding/latitude-tracker/issues/91)) ([b030fb9](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b030fb9954e237af4d19378066f5c2d4e4a6235d))
* cache analytics computation in AnalyticsScreen state ([#112](https://github.com/OneDeveloperCoding/latitude-tracker/issues/112)) ([e1ce2be](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e1ce2bef9c1a4835e4d6c56920a088d0a2520f83))
* cache and single-pass optimisations across core screens ([21f7bda](https://github.com/OneDeveloperCoding/latitude-tracker/commit/21f7bda65c612dae1aba85dee49a4ba0ddac18a2))
* fix O(buyers×sales) quadratic rebuild in BuyersListScreen ([#83](https://github.com/OneDeveloperCoding/latitude-tracker/issues/83)) ([d5261c4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d5261c48f0411af4c973351074aee7f29a8030a6))
* SalesListScreen micro-optimizations — buyer scan, DateFormat, year/month recompute ([#120](https://github.com/OneDeveloperCoding/latitude-tracker/issues/120)) ([2817e2a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2817e2a97aadc4a063c5f4a8b1f8c5ce5a253347))

## [1.10.0](https://github.com/OneDeveloperCoding/latitude-tracker/compare/latitude_tracker-v1.9.3...latitude_tracker-v1.10.0) (2026-06-25)


### Features

* add BuyerAddress creation from within New Sale delivery section ([31f5131](https://github.com/OneDeveloperCoding/latitude-tracker/commit/31f51318e6b1cc896035731659a2b53caa5883e0))
* add curated theme presets with dark/light toggle in Settings ([#187](https://github.com/OneDeveloperCoding/latitude-tracker/issues/187)) ([c66bf4d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c66bf4d467a127b7e10c0c4cf2a826e4f5e45673))
* add dark mode toggle in Settings ([#121](https://github.com/OneDeveloperCoding/latitude-tracker/issues/121)) ([e691da7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e691da7fad08982d0efde3fb09f661fb55d7bf25))
* add Google Sign-In via account linking ([#216](https://github.com/OneDeveloperCoding/latitude-tracker/issues/216)) ([c1ab836](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c1ab83630490b456cfa750a7cf269d4b745c6f6b))
* add hand delivery as a third delivery type ([e62b3a2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e62b3a2d7fde1872c1c78da8ccec3c1976cb35a2)), closes [#34](https://github.com/OneDeveloperCoding/latitude-tracker/issues/34)
* add photo and notes support to ComponentChecklist items ([#149](https://github.com/OneDeveloperCoding/latitude-tracker/issues/149)) ([a46d4e2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a46d4e29f36757edd677c52cb727253a4cc202c9))
* add quantity field to ComponentItem and make AssemblyStatus fully manual ([#155](https://github.com/OneDeveloperCoding/latitude-tracker/issues/155)) ([8adbe02](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8adbe028f20293e38a72c79f5cc6c87343e54ee1))
* add Repair feature — track repair jobs linked to sales or standalone ([9436059](https://github.com/OneDeveloperCoding/latitude-tracker/commit/94360593d78bc9d3688c5a2f165ff157997094a7))
* add Revolut and PayPal payment methods with brand colours ([eeef5e2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/eeef5e260ca587fe3aa4ef3c295b4624ead05360)), closes [#33](https://github.com/OneDeveloperCoding/latitude-tracker/issues/33)
* add watchBuyer stream to BuyerRepository and use it in BuyerDetailScreen ([#82](https://github.com/OneDeveloperCoding/latitude-tracker/issues/82)) ([2f63799](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2f6379947606fead06eff9ee71b507f502d77fe9))
* aggregate same-named ComponentItems across SaleItems in ShoppingList ([#161](https://github.com/OneDeveloperCoding/latitude-tracker/issues/161)) ([0893550](https://github.com/OneDeveloperCoding/latitude-tracker/commit/08935504e61a3df9c08e81d67446aca74630eb98))
* archive analytics — view yearly/monthly trends for imported archives ([#32](https://github.com/OneDeveloperCoding/latitude-tracker/issues/32)) ([02563a6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/02563a69f8eaadd9fcff28a9fc5e845d38d495a8))
* category maintenance — rename, hide, delete ([#35](https://github.com/OneDeveloperCoding/latitude-tracker/issues/35)) ([a1b0bf8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a1b0bf80ac9d99ea6f5b832167f7b54145e13d0f))
* collapse search toolbar in Sales and Buyers screens ([#75](https://github.com/OneDeveloperCoding/latitude-tracker/issues/75)) ([e6a764a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e6a764a9d45d002a047d40100adbb55843d7b9a7)), closes [#74](https://github.com/OneDeveloperCoding/latitude-tracker/issues/74)
* compact sort UI in Sales filter sheet and move Buyers ranking metric picker into tune sheet ([#77](https://github.com/OneDeveloperCoding/latitude-tracker/issues/77)) ([9bf3968](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9bf39680ba8ad6b9fdd8290790c01bc427370659))
* copy formatted address from buyer detail + fix buyer form i18n ([368f39b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/368f39b91213889a4c0b9089fafdb290f4ecb3ed))
* dashboard analytics section — category trends and period comparisons ([1db7ef6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1db7ef63e61023c4bdb6acce2159677d4fc03122)), closes [#8](https://github.com/OneDeveloperCoding/latitude-tracker/issues/8)
* dashboard layout revamp — trends card, grouped actions, clean revenue card ([2f59dda](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2f59dda8e49de34000feddef0d9e8598afe91273)), closes [#4](https://github.com/OneDeveloperCoding/latitude-tracker/issues/4)
* enhanced TrendsScreen with stacked category chart and interactive analysis ([162a1df](https://github.com/OneDeveloperCoding/latitude-tracker/commit/162a1dfc8ff093290d9dd8c95ec1e4275aedf4e8))
* filter and sort revamp — multi-select, year/month drill-down, active-only default ([1037942](https://github.com/OneDeveloperCoding/latitude-tracker/commit/103794206377e89290d32f6c805699e7f31927f8)), closes [#6](https://github.com/OneDeveloperCoding/latitude-tracker/issues/6)
* fix needs-materials counter and add ready-to-assemble dashboard card ([#228](https://github.com/OneDeveloperCoding/latitude-tracker/issues/228)) ([5db7221](https://github.com/OneDeveloperCoding/latitude-tracker/commit/5db722159aab8778e5413f70d3f780fe9be9d328))
* heat map overhaul — dedicated screen, geocoding cache, tile cache, background warm-up ([d6b6bc9](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d6b6bc9e7b61164c8df3cf91279a8059fda50383))
* implement GeocodingService.warmUp() via GeocodingWarmUp listener ([#178](https://github.com/OneDeveloperCoding/latitude-tracker/issues/178)) ([fe1ee60](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fe1ee607f2f97fdd94ef224c47e0f84921c2428e))
* in-app update checker and APK installer via GitHub Releases ([#214](https://github.com/OneDeveloperCoding/latitude-tracker/issues/214)) ([1902cd5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1902cd52c493001a2c87d3e5739de732c921f1a3))
* inline RepairStatus picker on Repair detail screen ([7ff63b1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7ff63b1cf9459c607cf07a6856ce4abc21a63908))
* inline RepairStatus picker on Repair detail screen ([2d60660](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2d60660315f15a551fe4146d6dbb9f3ad121a2b3))
* item category on Sales, buyer tags and buyer notes ([3259e76](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3259e762cd6cc7d0876e427df475f3938a12e477))
* make Notes text selectable in sale and buyer detail screens ([8f65e20](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8f65e208973e49275181aadde9cf7642ea2c0b94))
* make Notes text selectable in sale and buyer detail screens ([a66cd3f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a66cd3f0aa64e8bcaefaf5e139b91f3d0f4c695a))
* master-detail split view for Sales list on tablet ([3b9dcac](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3b9dcacf61727a8ccd554fea676432d7e4edd748)), closes [#28](https://github.com/OneDeveloperCoding/latitude-tracker/issues/28)
* new AnalyticsScreen merging InsightsCard and TrendsScreen, restore action rows ([cf7f27e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/cf7f27e671dab9403151e0ca332ec921f95aaaec))
* note indicator on sale cards with tap-to-preview ([1a9d42f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1a9d42f9720ebb6756d7f11a1e6af7508b881342))
* open BuyerAddress in Google Maps from Sale detail and Buyer detail ([#100](https://github.com/OneDeveloperCoding/latitude-tracker/issues/100)) ([49d4445](https://github.com/OneDeveloperCoding/latitude-tracker/commit/49d4445fb6e1e37a577c629571b188d2a7e9af52))
* redesign dashboard action section as compact 3-per-row button grid ([e979e84](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e979e84426a946eb2ffedb84dc2744080a156085)), closes [#25](https://github.com/OneDeveloperCoding/latitude-tracker/issues/25)
* redesign dashboard period control and unify search bars across screens ([11ad656](https://github.com/OneDeveloperCoding/latitude-tracker/commit/11ad6561ab2caf973f8f36d2368846fe88c8c67b))
* redesign RepairCard and fix demo mode guards ([#201](https://github.com/OneDeveloperCoding/latitude-tracker/issues/201)) ([0a275f3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0a275f330d5a808420849d7d58579f6c6bd37019))
* rename Trends to Analytics and swap card order in analytics screen ([c6c36c8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c6c36c8788c169b8b330610361e5eaf2c76f7b60)), closes [#30](https://github.com/OneDeveloperCoding/latitude-tracker/issues/30)
* repair detail — quick action buttons to advance ReturnDelivery status ([#94](https://github.com/OneDeveloperCoding/latitude-tracker/issues/94)) ([a35250b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a35250bb9622bfae30057aff61540023ddda56fc))
* repairs list — drop nested AppBar, add search/filter row, show ReturnDelivery on card ([c15d40d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c15d40d2075a30960b7e997f9ab8d622a06dbd43))
* repairs list — drop nested AppBar, add search/filter row, show ReturnDelivery on card ([ebbe439](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ebbe439214dd0fee7c8565c2ee47beb982d244b2))
* replace linked-sale dropdown with buyer-scoped sale picker ([c5b8436](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c5b84368fe37dfdb5fff06ce137ce290d50ef846))
* replace SalesHeatMap with GeographicSalesView (list default + map toggle) ([#163](https://github.com/OneDeveloperCoding/latitude-tracker/issues/163)) ([7b74847](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7b74847a95b71772b285041b973e2928fb3abefb))
* reset app, item photo thumbnails, Flutter 3.44 upgrade ([4f339ee](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4f339ee55c6471ca058cf59da52b1aa96bb2929f))
* revamp demo tour as 7-page paged walkthrough ([de93643](https://github.com/OneDeveloperCoding/latitude-tracker/commit/de936432fe607b29111e4e5e8390f0a24b2d4106)), closes [#16](https://github.com/OneDeveloperCoding/latitude-tracker/issues/16)
* round colored status bubbles on SaleCard strip and Sale detail ([#197](https://github.com/OneDeveloperCoding/latitude-tracker/issues/197)) ([7a2e7f0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7a2e7f00bd0007ff4236f27d8a5c6cac22c7dd57))
* sale card age indicator and ready-but-unpaid badge ([b8b357f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b8b357ffb71722024c04bece7a01b18400697937))
* SaleItem as sub-entity — multi-item sales ([7c91f3d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7c91f3dcf0bb22c7d056c94d4d82342b64acbe5f))
* shipped date on SaleCard, repair strip and detail reorder ([#200](https://github.com/OneDeveloperCoding/latitude-tracker/issues/200)) ([bd65440](https://github.com/OneDeveloperCoding/latitude-tracker/commit/bd654409259688e22acb8c7d20f2225b2811d64d))
* show buyer's repair history in Buyer detail screen ([0d22e7f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0d22e7f3a66b10dac86b5ea14878c7bd930c4e79))
* show buyer's repair history in Buyer detail screen ([266df51](https://github.com/OneDeveloperCoding/latitude-tracker/commit/266df5115642b38e8f57eb3334f0723aaf486f83))
* swipe-to-update payment and shipment status from Sales list ([#189](https://github.com/OneDeveloperCoding/latitude-tracker/issues/189)) ([fd66b77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fd66b7702f2426f27aa82693a4e23032532d4f81))
* tappable Instagram handle opens profile in app or browser ([348ddcf](https://github.com/OneDeveloperCoding/latitude-tracker/commit/348ddcf8276dc4adc0359f08d8ae506481c895a7))
* tapping phone number in Buyer Detail prompts call or message ([349f135](https://github.com/OneDeveloperCoding/latitude-tracker/commit/349f135c4f64c58271ef09594f29105929852fd8))
* tapping phone number in Buyer Detail prompts call or message ([96a3a99](https://github.com/OneDeveloperCoding/latitude-tracker/commit/96a3a996c2652f18d166e81bf06200500efe5909))
* tri-indicator status strip on SaleCard, RepairCard, and detail section headers ([#194](https://github.com/OneDeveloperCoding/latitude-tracker/issues/194)) ([dda2065](https://github.com/OneDeveloperCoding/latitude-tracker/commit/dda2065313794334993a05a0586bf177ea4e71b7))
* unified edit mode for RepairDetailScreen with read-only default ([#206](https://github.com/OneDeveloperCoding/latitude-tracker/issues/206)) ([8bfbe34](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8bfbe340a9d246b6a3f68ce5e67ed1e114910b6e))
* unified edit mode for SaleDetailScreen with read-only default ([#205](https://github.com/OneDeveloperCoding/latitude-tracker/issues/205)) ([77a867e](https://github.com/OneDeveloperCoding/latitude-tracker/commit/77a867eabce68b73967ca4148e6f54b9362096ee))
* unified NIF/AT compliance row with inline NIF entry ([fa85fe3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fa85fe3226c381ac1ea7838b223dde70e833cd77))
* v1.1.0 — tabs, crash fixes, postal code, autofill, dashboard, tests ([edf2ef1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/edf2ef1d0e5b397e3624c3fc5ad9c6eef2d48469))
* year → month drill-down filter for buyer purchase history ([48365c1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/48365c18caae4734774aa28c9d85ae3acba2aff5))


### Bug Fixes

* accessibility improvements — icon button labels, touch targets, CircleAvatar semantics ([#101](https://github.com/OneDeveloperCoding/latitude-tracker/issues/101)) ([e64987b](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e64987b8f46b4d9b1b8ed433fe28d89423a4e200))
* add SafeArea to SalesRepairsTabScreen so tab bar clears status bar ([#159](https://github.com/OneDeveloperCoding/latitude-tracker/issues/159)) ([c4b2e77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c4b2e77a3d32b066e8f57d9fabd81388b167bf47))
* add StoreErrorWidget with retry to all store-driven screens ([#84](https://github.com/OneDeveloperCoding/latitude-tracker/issues/84)) ([be82bea](https://github.com/OneDeveloperCoding/latitude-tracker/commit/be82bea79f703cfee0e92c0756d6a7f8b26ea0a6))
* add unsaved-changes PopScope guard to BuyerFormScreen and BuyerAddressFormScreen ([#90](https://github.com/OneDeveloperCoding/latitude-tracker/issues/90)) ([fccf94c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/fccf94c0073ab05226398856650a95793cabc78c))
* address code review findings from PR [#130](https://github.com/OneDeveloperCoding/latitude-tracker/issues/130) ([45d52dd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/45d52dd33328282d906c1808904ed0bcaba3ad78))
* address code review findings on auth stream PR ([57cee65](https://github.com/OneDeveloperCoding/latitude-tracker/commit/57cee65f07799085055066d04d6c4db0e53d9779))
* address code review findings on release-please workflow ([e1069e8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e1069e878e92b7ee858fb1df99d432a7773fb729))
* align repair date format and icon with sale detail conventions ([e3796dd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3796ddb4b3ab7cc64e5a86ad09ed1d3c4065c9b))
* bump google-services to 4.4.2 for Crashlytics plugin v3 compatibility ([1909b47](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1909b47a922c3152f3063ee1f1b064929785f919))
* cache auth stream in _AuthGate to prevent tab state reset on navigation ([9231a01](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9231a0166429ef78f48fa631236ebbecb5ea7243))
* cache auth stream in _AuthGate to prevent tab state reset on navigation ([72c6843](https://github.com/OneDeveloperCoding/latitude-tracker/commit/72c6843a058d1835be5d0d07435964d62eefe45e))
* chunk year-delete batches and fix operation order to prevent orphans ([#64](https://github.com/OneDeveloperCoding/latitude-tracker/issues/64)) ([955f67a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/955f67abfe7886ce3ee1d242d13f4154286ae0bd)), closes [#36](https://github.com/OneDeveloperCoding/latitude-tracker/issues/36)
* clear stale optimistic RepairStatus on external update ([133aa43](https://github.com/OneDeveloperCoding/latitude-tracker/commit/133aa43d4044438690b148ef28a70ac7e835615d))
* close two gaps in Repair feature found during review ([3ed823a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/3ed823ae5d4b1911ce14495dfe90a08304d13e6b))
* complete error handling audit and wire up full Crashlytics coverage ([f503a97](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f503a971d1f7bb0d39502d0d2e56ef1df5f0cec5)), closes [#17](https://github.com/OneDeveloperCoding/latitude-tracker/issues/17)
* convert _AddressDisplay to StatefulWidget to prevent Firestore listener churn ([b027c77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b027c77fa4d41d818b12d25ff40959625e67520e))
* convert RepairDetailScreen to StatefulWidget and move stream to initState ([#81](https://github.com/OneDeveloperCoding/latitude-tracker/issues/81)) ([4a5314c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4a5314c3f4e632b648a3cd326633328868b7ad17))
* correct import order and comment reference lint errors ([ce521b0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ce521b00b34190f40d3dad984fbd786df15f849d))
* demo mode sign out and signed-in label in Settings ([13be88c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/13be88cae8879e16c82ebeee5d5b0cbe1ee85731))
* exit cleanly when develop is already in sync with main ([b4fbe52](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b4fbe528b2947990036b127909d6e3fdb9d574f6))
* form and label UX hardening across multiple screens ([#93](https://github.com/OneDeveloperCoding/latitude-tracker/issues/93)) ([2a3cd1d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2a3cd1dfc0ba41de160e44618bc9b19873e36e9a))
* global store lifecycle fragility — dispose race, StoreLoading deadlock, stale auth data ([#72](https://github.com/OneDeveloperCoding/latitude-tracker/issues/72)) ([a7d9fcd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a7d9fcd98afd36777912f59b2706c9ae17223679))
* global stores stuck permanently in StoreError after first stream error ([#70](https://github.com/OneDeveloperCoding/latitude-tracker/issues/70)) ([342b323](https://github.com/OneDeveloperCoding/latitude-tracker/commit/342b32312ca39b4adcf8ad86f227577964fc816d))
* guard BuyerDetailScreen pop against double-pop race condition ([#157](https://github.com/OneDeveloperCoding/latitude-tracker/issues/157)) ([96d4749](https://github.com/OneDeveloperCoding/latitude-tracker/commit/96d474941c37adc5bc20c8f86dd963eabb7bbde3))
* guard fromFirestore and fromMap deserialisers against null fields and unknown enum strings ([#65](https://github.com/OneDeveloperCoding/latitude-tracker/issues/65)) ([205b1e0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/205b1e0b72ab5e09967d5a2966ef8696c45b8f5f))
* guard hideCategory against duplicate hidden entries ([#107](https://github.com/OneDeveloperCoding/latitude-tracker/issues/107)) ([5d3028d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/5d3028dae2d6ef87d727060b93c183c99f83ffcb))
* guard Merge PR step when develop is already in sync with main ([f98dd81](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f98dd812be689fc868c6e9dd779e35061706622b))
* guard Merge PR step when develop is already in sync with main ([64a023d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/64a023dc530ae81f63128ac2f728ff42545c5bca))
* harden auth-revocation handling after review ([d0f163a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d0f163ac85f46f12f370ac3f6b6426e7ec767bc5))
* ItemDetailSheet local state not updating on component changes ([afc3e61](https://github.com/OneDeveloperCoding/latitude-tracker/commit/afc3e616d75652382ccf6c5cca07bba966f891d0))
* keep only valid base64 chars from RELEASE_KEYSTORE before decode ([19b540d](https://github.com/OneDeveloperCoding/latitude-tracker/commit/19b540d62e42ed57eba5291b201bf97ca85ad83b))
* keep only valid base64 chars from RELEASE_KEYSTORE before decode ([40a25d6](https://github.com/OneDeveloperCoding/latitude-tracker/commit/40a25d6d2b1959ddb398bba127314b57c6555719))
* migrate shared_prefs_cache_test to package:test ([#131](https://github.com/OneDeveloperCoding/latitude-tracker/issues/131)) ([c094cf8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c094cf80c5a1ba061409e0722bd090d96330ba5a))
* migrate shared_prefs_cache_test to package:test ([#131](https://github.com/OneDeveloperCoding/latitude-tracker/issues/131)) ([99659ea](https://github.com/OneDeveloperCoding/latitude-tracker/commit/99659ea70f9e202e5d865926070058e0eecc10bb))
* move repair received-date into Item section card ([d9b9d4c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d9b9d4c182d003b9b9dc86e6a43c9c0c9cb85c66))
* move repair received-date into Item section card ([0675ea3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0675ea327ffcde50071d69ca68fdc83f5e404dc8))
* parse PR number from URL instead of --json flag on gh pr create ([780bda3](https://github.com/OneDeveloperCoding/latitude-tracker/commit/780bda31eabc49d19ba3fab061cb8e9a0d61a5a9))
* parse PR number from URL instead of --json on gh pr create ([ac0e318](https://github.com/OneDeveloperCoding/latitude-tracker/commit/ac0e318d2a2a40a0913d85d0644e2cf866c09f1f))
* poll until checks register before gh pr checks --watch ([40d9b88](https://github.com/OneDeveloperCoding/latitude-tracker/commit/40d9b8826fcf6416b55403d78b799aaabe371236))
* poll until checks register before gh pr checks --watch ([698d6e1](https://github.com/OneDeveloperCoding/latitude-tracker/commit/698d6e1e99edd2aceb88569bbe9ce6ca76bf52de))
* pop detail screens when stream emits null after deletion ([#85](https://github.com/OneDeveloperCoding/latitude-tracker/issues/85)) ([2defda0](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2defda0d9e385267d4a609600c224462e1e77617))
* postal code form — no-results feedback and field reset on clear ([bed2da7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/bed2da713ab7152423d319b4e26d22a5fd993dd8))
* preserve sales filter state and handle loading/error in buyer repair history ([e66ad77](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e66ad77ed5ace01c4e82b91932d7d45053817ca4))
* prevent Nominatim server errors from being cached as geocoding misses ([#92](https://github.com/OneDeveloperCoding/latitude-tracker/issues/92)) ([1ab2d78](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1ab2d785e859f59596957cb07fb74ae6b6bc4d4a)), closes [#59](https://github.com/OneDeveloperCoding/latitude-tracker/issues/59)
* reapply post-review fixes lost in PR squash ([1668a30](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1668a304e79bcc17c69ef5551232c6d84722238a))
* reinstate isActive default, fix sort icon, extract SheetSectionLabel ([be04ab2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/be04ab245308343c6ebc4ab3027fe6f733bd364a))
* remove AddressesStore to prevent collectionGroup permission-denied sign-out ([da09385](https://github.com/OneDeveloperCoding/latitude-tracker/commit/da093853c3fd05ebf18d9571357661fdd11ee263))
* remove AddressesStore to prevent collectionGroup silent sign-out ([7519fe5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/7519fe59230ecefb746066393a592d30a635450e))
* rename order/encomenda to sale/venda across all UI strings and models ([#41](https://github.com/OneDeveloperCoding/latitude-tracker/issues/41)) ([f465514](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f4655147e9a60c5bd9c49a448763a2c9db67ee17))
* rename PT label 'Em curso' to 'Em progresso' for AssemblyStatus and RepairStatus ([741adbd](https://github.com/OneDeveloperCoding/latitude-tracker/commit/741adbd7663ca7e4b75226d28552124034a51603))
* replace _AddressDisplay per-widget stream with AddressesStore ([#73](https://github.com/OneDeveloperCoding/latitude-tracker/issues/73)) ([aac7d6a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/aac7d6ab5548a1255e0bba777070325a0be9107e))
* replace 📅 emoji with Icons.event on sale card scheduled date ([#150](https://github.com/OneDeveloperCoding/latitude-tracker/issues/150)) ([8261718](https://github.com/OneDeveloperCoding/latitude-tracker/commit/82617183af6e81f60d8c0762a5f3eaf8ff120a0e))
* replace AppBar edit icon with FAB on Sale and Repair detail screens ([#198](https://github.com/OneDeveloperCoding/latitude-tracker/issues/198)) ([cee3d84](https://github.com/OneDeveloperCoding/latitude-tracker/commit/cee3d84dd96871198d2fea9c8946970796122d33))
* replace AppBar edit icon with FAB on Sale and Repair detail screens ([#198](https://github.com/OneDeveloperCoding/latitude-tracker/issues/198)) ([a5d2624](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a5d262455c1e369cf680ab15f55ab2d6d3e50e20))
* replace assembly icon and label with shopping cart and 'Needs materials' ([e3a8123](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3a8123954e72742af5bf2f0eed491491d5638fa))
* replace currentUser! force-unwraps with null-guarded throws ([c2ea560](https://github.com/OneDeveloperCoding/latitude-tracker/commit/c2ea56054bbacc53daae75533d61123170c0d330))
* replace currentUser! force-unwraps with null-guarded throws ([55fd7b8](https://github.com/OneDeveloperCoding/latitude-tracker/commit/55fd7b8a163c70200538b0633065a03bdaf5fe72)), closes [#58](https://github.com/OneDeveloperCoding/latitude-tracker/issues/58)
* replace map icon with location pin on open-in-maps buttons ([#147](https://github.com/OneDeveloperCoding/latitude-tracker/issues/147)) ([8145445](https://github.com/OneDeveloperCoding/latitude-tracker/commit/8145445337cd06e121767d3cd1437b5d8e163e06))
* run renameCategory ops sequentially to limit partial-failure blast radius ([#117](https://github.com/OneDeveloperCoding/latitude-tracker/issues/117)) ([1868cc4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/1868cc4bbec79f95b5c961c0a0adf2e5579fbbe2))
* safe CI secret injection and partial year-delete error message ([03a4918](https://github.com/OneDeveloperCoding/latitude-tracker/commit/03a49186904d802012a314b0491a7dc6a952716f))
* ship exits cleanly when develop is already in sync with main ([0e226c7](https://github.com/OneDeveloperCoding/latitude-tracker/commit/0e226c71bf6c5ee43d0d5e1f6ad909ce4687b6a2))
* ship workflow gh pr create --json flag compatibility ([6822495](https://github.com/OneDeveloperCoding/latitude-tracker/commit/682249524004abe6253278334d091e7d3c2f9007))
* ship workflow null PR number and extract needsMaterials getter ([080dd3f](https://github.com/OneDeveloperCoding/latitude-tracker/commit/080dd3f5f1072f29f583130efb72a4d8e074a382))
* ship workflow null PR number and extract needsMaterials getter ([66483c5](https://github.com/OneDeveloperCoding/latitude-tracker/commit/66483c5955e1e9ae667ae146e94c1fdce06d3a2a)), closes [#229](https://github.com/OneDeveloperCoding/latitude-tracker/issues/229)
* sort chips show arrow and checkmark simultaneously; date chip hides default direction ([#78](https://github.com/OneDeveloperCoding/latitude-tracker/issues/78)) ([a7991e4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/a7991e46c4ea1b8308752d7f463232d2fd2a2ee6)), closes [#76](https://github.com/OneDeveloperCoding/latitude-tracker/issues/76)
* strip whitespace from RELEASE_KEYSTORE before base64 decode ([d5c4667](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d5c4667db0538a56ce27e2910cbac1d5b346644e))
* strip whitespace from RELEASE_KEYSTORE before base64 decode ([e3820f2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e3820f2305f70e5a4f7cb1a5ef0f507f6adec0ab))
* surface errors instead of silent failures across store, streams, and network services ([f696f1a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/f696f1adc104a57b1a5bc402402ca4f052cc94b5))
* update _item state immediately in _ItemDetailSheet ([#195](https://github.com/OneDeveloperCoding/latitude-tracker/issues/195)) ([697cba2](https://github.com/OneDeveloperCoding/latitude-tracker/commit/697cba277b2dcebf7c446688bfc09e70b58ad910))
* wire AppLocaleScope InheritedWidget for reactive locale switching ([4725e5c](https://github.com/OneDeveloperCoding/latitude-tracker/commit/4725e5cac7947964dd44c0e9f13ca3504ba2c147))
* wire Crashlytics to store stream errors and plug silent catch gaps ([9647e50](https://github.com/OneDeveloperCoding/latitude-tracker/commit/9647e501337306728f7e5fea0c7e13e2ef61adb7))
* wire Crashlytics to UI write catch blocks and guard _cancel navigation ([#68](https://github.com/OneDeveloperCoding/latitude-tracker/issues/68)) ([105fb31](https://github.com/OneDeveloperCoding/latitude-tracker/commit/105fb3126aef274dd5372be954bda55324880c9f))


### Performance Improvements

* add cacheWidth/cacheHeight to thumbnail Image.network calls ([#91](https://github.com/OneDeveloperCoding/latitude-tracker/issues/91)) ([b030fb9](https://github.com/OneDeveloperCoding/latitude-tracker/commit/b030fb9954e237af4d19378066f5c2d4e4a6235d))
* cache analytics computation in AnalyticsScreen state ([#112](https://github.com/OneDeveloperCoding/latitude-tracker/issues/112)) ([e1ce2be](https://github.com/OneDeveloperCoding/latitude-tracker/commit/e1ce2bef9c1a4835e4d6c56920a088d0a2520f83))
* cache and single-pass optimisations across core screens ([21f7bda](https://github.com/OneDeveloperCoding/latitude-tracker/commit/21f7bda65c612dae1aba85dee49a4ba0ddac18a2))
* fix O(buyers×sales) quadratic rebuild in BuyersListScreen ([#83](https://github.com/OneDeveloperCoding/latitude-tracker/issues/83)) ([d5261c4](https://github.com/OneDeveloperCoding/latitude-tracker/commit/d5261c48f0411af4c973351074aee7f29a8030a6))
* SalesListScreen micro-optimizations — buyer scan, DateFormat, year/month recompute ([#120](https://github.com/OneDeveloperCoding/latitude-tracker/issues/120)) ([2817e2a](https://github.com/OneDeveloperCoding/latitude-tracker/commit/2817e2a97aadc4a063c5f4a8b1f8c5ce5a253347))

## [Unreleased]

---

## [1.9.3] — 2026-06-25

### Fixes
- Navigation: going back from a Sale or Buyer detail screen always returned to the Dashboard tab regardless of which tab was active; root cause was `FirebaseAuth.instance.authStateChanges()` called inline inside a builder callback, creating a new stream reference on every animation frame during route transitions — extracted into `_AuthGate` `StatefulWidget` so the stream reference is stable

### Infrastructure
- Ship workflow: `gh pr merge` now guarded with `if: steps.pr.outputs.number != ''` to prevent running with an empty PR number when develop is already in sync with main

---

## [1.9.2] — 2026-06-25

### Fixes
- Ship workflow: polling loop now uses `--json name --jq 'length'` to distinguish "no checks registered yet" (empty array) from "checks failed" (non-zero exit), preventing premature `gh pr checks --watch` calls before CI registers
- Ship workflow: exits cleanly when develop is already in sync with main instead of proceeding with an empty PR number

---

## [1.9.1] — 2026-06-25

### Fixes
- Ship workflow: PR number now parsed from the URL that `gh pr create` prints to stdout; the `--json` flag is not available on `gh pr create` on all runner versions

---

## [1.9.0] — 2026-06-25

### Features
- Dashboard "Ready to assemble" card: counts and links to sales where all components are acquired and assembly hasn't started yet
- Dashboard "Needs materials" counter fixed to cover only sales with missing components or `waitingForMaterials` status (previously counted all non-ready assembly states)

### Fixes
- Ship workflow: `gh pr list` returned the string `"null"` on an empty result set, causing PR creation to be skipped on every first run; fixed with an explicit length guard

### Infrastructure
- Ship workflow added: single `workflow_dispatch` trigger that merges `develop → main`, waits for CI, and calls the Release workflow — one-click releases from GitHub Actions
- Release workflow now supports `workflow_call` so Ship can invoke it as a reusable step

### Chores
- `Sale.needsMaterials` getter extracted as single source of truth for the missing-components predicate used by the dashboard counter

---

## [1.8.0] — 2026-06-25

### Features
- Google Sign-In added alongside email/password; a "Connect Google account" tile in Settings → Account links the seller's Google credentials to her existing Firebase account via `linkWithCredential`, preserving the UID and all data; both methods coexist permanently with email/password kept as fallback
- In-app update checker: app checks GitHub Releases on every cold start and shows an "update available" tile in Settings → App when a newer version is published; tapping downloads and installs the APK directly
- Sale and Repair detail screens default to read-only; a FAB switches to edit mode — reduces accidental edits and declutters the AppBar
- RepairCard redesigned with the same tri-indicator strip as SaleCard (payment · work status · return delivery); demo mode guards added to block Firestore writes in demo mode
- Shipped date shown on SaleCard when a `shipping`-type Shipment has been marked as shipped; Repair detail section order aligned with Sale detail conventions

### Fixes
- Portuguese label for `in_progress` corrected from "Em curso" to "Em progresso" for both `AssemblyStatus` and `RepairStatus`
- Sale and Repair item count label simplified to "+ N" (was "+ N more" / "+ N mais")

### Infrastructure
- CI restore step now base64-decodes both `FIREBASE_OPTIONS_DART` and `GOOGLE_SERVICES_JSON` before running tests or builds
- `firebase.json` added to `.gitignore`; restored from CI secret in the release workflow
- Personal info and internal config details removed from README
- Release workflow now bakes version into APK via `--build-name`/`--build-number` flags instead of committing a pubspec change — no direct push to `main` required; tag push only

### Chores
- Completed migration from `flutter_lints` to `very_good_analysis` — all ~50 additional lint rules are now active; `analysis_options.yaml` only disables `public_member_api_docs` (not applicable for a private app). Fixes applied: `on Object catch` on all broad catch clauses, `unawaited()` on 53 fire-and-forget futures, `doc.data()!` on four model deserialisers, named bool params on three methods, 80-char line wrapping throughout.

---

## [1.7.0] — 2026-06-17

### Features
- Inline RepairStatus picker on Repair detail screen — status can be changed directly in the detail view without navigating away; stale optimistic state is cleared on external Firestore update
- Buyer detail screen now shows the buyer's full repair history alongside their sale history; sales filter state is preserved across tab switches
- `ComponentItem` now has a quantity field; `AssemblyStatus` is set manually rather than derived from checklist completion

### Fixes
- `BuyerDetailScreen` pop guarded against a double-pop race condition that could crash navigation when the screen was dismissed while a stream update was in flight
- `SafeArea` added to `SalesRepairsTabScreen` so content clears the status bar correctly

---

## [1.6.0] — 2026-06-14

### Features
- ComponentChecklist items now support photos and notes — each checklist item can have an attached photo and a free-text note alongside its completion state

### Fixes
- `AddressesStore` removed — it held a `collectionGroup` query that triggered Firestore permission-denied errors on accounts without the rule, causing a silent sign-out; buyer addresses are now fetched per-buyer inside their detail screen only
- `_AddressDisplay` converted to `StatefulWidget` — the previous stateless form recreated the Firestore listener on every parent rebuild, causing unnecessary churn
- Repair received-date moved into the Item section card and its format and icon aligned with Sale detail conventions
- Map icon on "Open in Maps" buttons replaced with a location-pin icon to match platform conventions
- Scheduled-date chip on the sale card now uses `Icons.event` instead of the 📅 emoji — consistent with the rest of the icon system

---

## [1.5.0] — 2026-06-08

### Features
- Dark mode toggle added to Settings — persists across sessions via SharedPreferences

### Performance
- `SalesListScreen`: buyer lookup, `DateFormat`, and year/month values are now computed once per build cycle instead of per-item — eliminates redundant work on large lists
- `AnalyticsScreen`: analytics computation is cached in widget state and only re-runs when data changes

### Fixes
- `renameCategory` now runs its Firestore batch operations sequentially — reduces partial-failure blast radius when a rename touches many documents

### Architecture
- `StreamStore<T>` generic base class extracted — `SalesStore` and `BuyersStore` now share a single implementation instead of duplicating stream subscription logic
- `BasePhotoService` extracted — removes duplication between the sale and repair photo services
- `ArchiveService.importArchive` now routes writes through the repository layer instead of accessing Firestore directly
- `DashboardStats` split: analytics-only methods moved to a dedicated class, keeping `DashboardStats` focused on dashboard concerns
- Sale and buyer IDs now generated with the `uuid` package instead of `FirebaseFirestore.instance.collection().doc().id` — removes an unnecessary Firestore round-trip

### Testing
- Pure-logic test files migrated from `flutter_test` to `package:test` — faster execution and no Flutter framework dependency for tests that don't need it

### Infrastructure
- Lint rules expanded with targeted `flutter_lints` additions to catch common patterns specific to this codebase
- Release signing, version tracking, and CI workflows unified into a single consistent pipeline
- Naming fixes: `SaleFilterLabel` removed, `AssemblyStatusUI` centralised, `BuyerStats` updated to single-pass computation; `AssemblyStatusUI` extension applied across `SaleDetailScreen` and `ShoppingListScreen`

---

## [1.4.0] — 2026-06-07

### Features
- Buyer addresses are now tappable links — tapping opens Google Maps with the formatted address pre-filled, available from both Sale detail and Buyer detail screens

### Fixes
- Accessibility: icon-only buttons now carry semantic labels; touch targets meet minimum size; `CircleAvatar` buyer initials are wrapped in `Semantics`
- Category hide list no longer accumulates duplicate entries when `hideCategory` is called more than once for the same category

### Testing
- Unit tests added for `SaleGrouper`, `HeatMapService`, and `Repair` model (null-safe fields, enum fallbacks, sub-map defaults)
- `CategoryService` test fixed to use injected repositories instead of relying on constructor-time snapshots

### Architecture
- `CategoryService` now fetches the hidden-category list itself rather than accepting a caller-supplied snapshot, eliminating stale-data bugs

### Infrastructure
- `bump-and-tag` workflow now restores `firebase_options.dart` and `google-services.json` from repository secrets before building the APK

---

## [1.3.1] — 2026-06-06

### Features
- Repair detail: quick-action buttons to advance `ReturnDelivery` status without opening the edit form
- `BuyerRepository.watchBuyer(id)` stream — `BuyerDetailScreen` now reacts to remote buyer changes in real time

### Performance
- Thumbnail `Image.network` calls supply `cacheWidth`/`cacheHeight` — reduces GPU texture memory for list views
- `BuyersListScreen` ranked-view rebuild reduced from O(buyers × sales) to O(sales) — eliminates quadratic scroll jank

### Fixes
- Form and label UX hardening across multiple screens (label capitalisation, keyboard type, autofill hints)
- Nominatim geocoding errors no longer cached as misses — a server error no longer permanently suppresses map links for an address
- Unsaved-changes `PopScope` guard added to `BuyerFormScreen` and `BuyerAddressFormScreen`
- Detail screens (`SaleDetailScreen`, `BuyerDetailScreen`, `RepairDetailScreen`) now pop automatically when their stream emits `null` after deletion
- `StoreErrorWidget` with retry action wired into all store-driven screens
- `RepairDetailScreen` converted to `StatefulWidget` with stream moved to `initState` — prevents stream re-subscription on every rebuild
- All UI strings and model fields renamed from "order/encomenda" to "sale/venda" for consistency with the domain language

### Architecture
- `UrgencyReason` icon and colour mapping moved from `SaleUrgency` business logic into a UI-layer extension

---

## [1.3.0] — 2026-06-06

### Features
- **Repairs**: new feature to track repair jobs — linked to a buyer or standalone free-text contact; fields include item description, category, problem, labour cost, materials cost, payment, and return delivery; full list, detail, and edit screens
- Repair detail: quick-action buttons to advance `RepairStatus` through the workflow
- **Category maintenance**: rename, hide, and delete item categories from Settings
- **Archive analytics**: import a JSON archive and view yearly/monthly revenue trends in the Analytics screen
- **Hand delivery** added as a third delivery type alongside shipping and pickup
- **Revolut** and **PayPal** added as payment methods with brand colours
- Buyer sale picker replaced with a buyer-scoped sheet — only that buyer's existing sales are shown when linking a repair
- Master-detail split view for the Sales list on tablets (600 dp+)
- Demo tour revamped as a 7-page paged walkthrough with illustrations
- Analytics screen: `InsightsCard` and `TrendsScreen` merged into a single `AnalyticsScreen` accessed from the revenue card; standalone entry card removed
- Sort UI in the Sales filter sheet compacted; Buyers ranking metric picker moved into the tune sheet
- Search toolbars in Sales and Buyers screens collapse when scrolling down

### Performance
- `DashboardStats.compute()` 8-pass filter loop replaced with a single accumulator

### Fixes
- Global store lifecycle hardened: dispose race, `StoreLoading` deadlock, and stale auth data after sign-out resolved
- Stores no longer stuck permanently in `StoreError` after the first stream error — error is surfaced and stream continues
- Auth-revocation handling hardened; `currentUser!` force-unwraps replaced with null-guarded throws
- `fromFirestore`/`fromMap` deserialisers guarded against null fields and unknown enum strings across all models
- Crashlytics wired to store stream errors, UI write catch blocks, and navigation guards — no more silent failures
- Firebase config files (`firebase_options.dart`, `google-services.json`) removed from version control; CI restores them from repository secrets

### Architecture
- Abstract `SaleRepository` / `BuyerRepository` with factory constructors routing to Firestore or in-memory implementation based on `DemoMode`
- `SalesStore` + `BuyersStore`: shared singleton streams, one Firestore WebSocket per collection; state exposed as `StoreState<T>` sealed class

### Infrastructure
- `bump-and-tag` CI workflow: auto-detects version bump from conventional commits; creates tag and builds APK in a single run
- `flutter test` step added to the release workflow — APK build blocked if any test fails

---

## [1.2.0] — 2026-06-04

### Features
- Dashboard period control replaced with a scrollable 6-month chip row — the dashboard now operates at monthly granularity only; yearly/weekly modes are available exclusively in the AnalyticsScreen
- Dashboard action section redesigned as grouped full-width rows (coloured icon, label, count, chevron); actions split into three labelled sections: **Money** (Unpaid, Overdue, NIF required), **Production** (Assembly not ready, Pending shipment, In transit), **Planning** (Upcoming scheduled) — seven rows total, up from five
- `InsightsCard` and `TrendsScreen` merged into a single **AnalyticsScreen** accessed from an insights icon button embedded in the revenue card; the standalone entry card at the bottom of the Dashboard is removed
- Search bars unified across Sales list, Buyers list, and Unpaid Balances screens — consistent placement and behaviour

### Fixes
- Error handling audit: non-fatal Crashlytics recording wired up consistently across all repository and service layers

### Infrastructure
- Flutter upgraded to 3.44.1 (required by `image_picker` Dart SDK constraint)

## [1.1.0] — 2026-06-02

### Features
- Structured buyer addresses: street name, house number, fraction (optional), delivery notes (optional) — replaces single street blob
- Portuguese postal code auto-fill: entering a full `XXXX-XXX` code fetches city + streets from GeoAPI.pt, with 180-day local device cache; single-match auto-fills the street field, multiple matches show a picker sheet; non-PT addresses remain free text
- Address city field relabelled "Locality / Localidade" to match Portuguese postal addressing convention and the API's own field name
- Buyer detail: tabbed layout with "History" and "Addresses" tabs; buyer info card (contact details) pinned above the tab bar
- Login screen: autofill support — email and password hints let password managers fill credentials; successful sign-in triggers the OS save prompt
- Sales list: ℹ button in AppBar opens the progress path legend — replaces the unreliable hidden footer tap
- Dashboard action cards redesigned as compact full-width rows (coloured icon, label, count, chevron) — all five fit on screen without scrolling
- Demo tutorial: eighth tip added for the heat map view
- App icon: custom icon replacing Flutter default; all density buckets + adaptive icon (Android 8+)
- App display name: "Latitude Tracker" (was "latitude_tracker" in launcher)
- APK filename in GitHub Releases: `latitude-tracker.apk` (was `app-release.apk`)

### Fixes
- Crash ("Stream has already been listened to"): streams now created in `initState`, not in `build()`; affects `SaleDetailScreen`, `BuyerDetailScreen._AddressesList`, `BuyerPickerScreen`
- Crash ("Child ordering assertion"): `BuyerDetailScreen` converted to `StatefulWidget` with a stable `_buyerFuture` — prevents `FutureBuilder` reset on every parent rebuild which dismounted the inner `ListView` and corrupted render child order
- Crash ("Null check in paint"): downstream consequence of the child ordering crash; resolved by the same fix
- Postal code street lookup: API response was misread — streets are in `partes[*].Artéria`, not a top-level `Artéria`; auto-fill was silently returning empty on every lookup
- Dashboard action counts (unpaid, pending shipment, assembly not ready, NIF required, overdue) are now global (current state) rather than period-scoped — counts now match what the destination screens show
- Demo mode top gap: `MediaQuery.removePadding(removeTop: true)` applied when demo banner is active
- Shopping list cards now navigate to the respective sale detail on tap

### Testing
- 55 unit tests covering `SaleUrgency` (urgency level week boundaries, all blocker reasons, days-until-scheduled), `SaleFilter` (all 9 variants including date-sensitive overdue boundary), `Sale.deriveAssemblyStatus` (7 cases including empty-component edge case), and `BuyerStats.compute` (totals, balance, average, last purchase)
- `flutter test` step added to the GitHub Actions release workflow — APK build is blocked if any test fails

### Architecture
- `DashboardStats.compute()`: 8-pass filter loop replaced with a single accumulator — O(n) instead of O(8n)
- `NifPendingScreen`: buyers-by-id map cached in state, rebuilt only on store change
- `SaleGrouper.byWeek()`: week boundary dates hoisted out of per-sale `_weekKey()` into the outer call
- `_BuyerSalesSection`: replaced per-screen Firestore stream with `SalesStore` — eliminates one redundant WebSocket per open buyer detail screen
- `BuyersListScreen`: alphabetical, grouped, and ranked view lists pre-computed on store change
- `SaleUrgency`: converted to `extension on Sale` — `sale.urgencyLevel()` / `sale.urgencyReasons()` / `sale.daysUntilScheduled()`
- `SalesListScreen`: filter + group result cached in state; `_TimelineView` accepts pre-grouped map
- `_SaleCard`: `urgencyReasons()` computed once per build, passed to `_AttentionBadges`
- `SalesStore` + `BuyersStore`: shared singleton streams, one Firestore WebSocket per collection; state via `StoreState<T>` sealed class
- Abstract `SaleRepository` / `BuyerRepository` with factory constructors — DemoMode routing at construction time
- `Sale.deriveAssemblyStatus()` + `Sale.withUpdatedComponents()`: component auto-ready rule on the model
- Firebase Crashlytics: automatic crash reporting with email alerts

## [1.0.0] — 2026-06-01

Initial stable release.

### Features
- Sales tracking: create, edit, delete sales with items, photos, assembly status, component checklist, payment, shipment, NIF, and notes
- Buyers: profiles with addresses, purchase history, ranking metrics, unpaid balances
- Dashboard: period selector (yearly/monthly/weekly), revenue cards, action counts (unpaid, pending shipment, assembly not ready, NIF required, overdue) — each tapping to a dedicated view
- Sale card progress path: three-node Assembly → Payment → Shipment bar spanning full card width; left accent bar (red/amber) for urgency; attention badges with tap-to-sheet detail
- Shopping list: aggregated view of all unacquired components across open sales
- NIF receipts: pending AT submissions with one-tap filed/unfiled toggle
- Sales heat map: geographic view by postal code locality prefix via Nominatim geocoding
- Archive: export/import year data as JSON with photo URL preservation
- Demo mode: 255 pre-seeded sales across 18 months, tutorial bottom sheet on first entry
- Language toggle: Portuguese (default) / English, persisted across sessions
- Settings: sign out, export, import, delete year, language, app version
