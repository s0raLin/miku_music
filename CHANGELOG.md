# Changelog

## [1.23.0](https://github.com/s0raLin/miku_music/compare/v1.22.0...v1.23.0) (2026-05-24)


### Features

* **ui:** add volume control card to music dashboard ([269b632](https://github.com/s0raLin/miku_music/commit/269b632d9fa698ca580a011fec2d9404b4b5abc3))

## [1.22.0](https://github.com/s0raLin/miku_music/compare/v1.21.0...v1.22.0) (2026-05-24)


### Features

* **audio:** add LRC lyric parsing functionality ([255d697](https://github.com/s0raLin/miku_music/commit/255d69772e803644c2c6e5db07ffd45972006a1f))
* **playlist:** integrate music library for song selection ([f164abd](https://github.com/s0raLin/miku_music/commit/f164abd5848276ee7e3b01d6e4759073ab80e197))

## [1.21.0](https://github.com/s0raLin/miku_music/compare/v1.20.0...v1.21.0) (2026-05-24)


### Features

* **music:** implement audio database management via Rust ([03dd62a](https://github.com/s0raLin/miku_music/commit/03dd62a5f1cd4c5a6aa900c1ee5748952bb4fc31))
* **ui:** display playlist description in detail view ([84ef311](https://github.com/s0raLin/miku_music/commit/84ef311d242a3375c180779ae942a107c1ffd0d4))
* **ui:** implement data-driven drawer and update playlist routing ([5363dbe](https://github.com/s0raLin/miku_music/commit/5363dbe6500684cef43580c948499b92e4940742))
* **ui:** implement desktop window controls and custom header component ([ccb623a](https://github.com/s0raLin/miku_music/commit/ccb623a822bfd1e4a46d68d9c7d9b1ff4f124b54))


### Bug Fixes

* **music:** use metadata for title instead of file path ([b838643](https://github.com/s0raLin/miku_music/commit/b8386430fbb73a6f79af3b3f5b7c896443c7c273))


### Performance Improvements

* **music:** optimize library rendering and memory usage ([1412fa1](https://github.com/s0raLin/miku_music/commit/1412fa11e301745f0b5b5e9f4753017009b90182))

## [1.20.0](https://github.com/s0raLin/miku_music/compare/v1.19.0...v1.20.0) (2026-05-23)


### Features

* **music:** implement parallel audio scanning via Rust ([ab328ee](https://github.com/s0raLin/miku_music/commit/ab328ee354d1d26cb9d3853238813ee00d020ac1))


### Bug Fixes

* **music:** map album metadata in MusicService ([cf3afd0](https://github.com/s0raLin/miku_music/commit/cf3afd03ac892336b8fbd45936eec8d2f30954b1))

## [1.19.0](https://github.com/s0raLin/miku_music/compare/v1.18.1...v1.19.0) (2026-05-22)


### Features

* **music:** restructure music library and simplify navigation ([a365e03](https://github.com/s0raLin/miku_music/commit/a365e03d01973ff59804d8b6113220d2e56b3ed2))
* **ui:** implement responsive action menu for playlist details ([5f5544f](https://github.com/s0raLin/miku_music/commit/5f5544f237727e497d9bd266718528384e4a08c5))

## [1.18.1](https://github.com/s0raLin/miku_music/compare/v1.18.0...v1.18.1) (2026-05-18)


### Bug Fixes

* **music:** simplify playback control and queue selection logic ([96f3061](https://github.com/s0raLin/miku_music/commit/96f30613290c214f4dff83c0e89e4022ef8d6151))
* **music:** update library tab playback logic ([1556226](https://github.com/s0raLin/miku_music/commit/15562267816dd1ceddd35bd67616e56bd39690ab))

## [1.18.0](https://github.com/s0raLin/miku_music/compare/v1.17.0...v1.18.0) (2026-05-18)


### Features

* **music:** enhance library playback controls and UI feedback ([2f029ec](https://github.com/s0raLin/miku_music/commit/2f029ec6b79f1fc8cfc59144e98bce17b5d9562e))
* **music:** pass music data via router extra to detail page ([2b33458](https://github.com/s0raLin/miku_music/commit/2b33458789aa0e495dbebd8f9020c78faf33f135))

## [1.17.0](https://github.com/s0raLin/miku_music/compare/v1.16.0...v1.17.0) (2026-05-17)


### Features

* **audio:** implement background audio playback service ([9da65f8](https://github.com/s0raLin/miku_music/commit/9da65f80553048589675dac94e55065b16767cf7))
* **audio:** implement local file caching for album art ([0959671](https://github.com/s0raLin/miku_music/commit/09596719c3fb8ae424f476dba62ed02d2de968a3))
* **ui:** enhance navigation and refactor initialization logic ([deff4ec](https://github.com/s0raLin/miku_music/commit/deff4ecac3a5520a66ee893fd4d758b432e00006))


### Bug Fixes

* **audio:** include file URI as artUri in MediaItem ([a34374d](https://github.com/s0raLin/miku_music/commit/a34374dac728fc91ecfbe3cc1d22f37c9e60f241))
* **audio:** update notification controls and playback behavior ([d9ef344](https://github.com/s0raLin/miku_music/commit/d9ef344a9b9eff3adfb5192e441e00b69c7c3836))

## [1.16.0](https://github.com/s0raLin/miku_music/compare/v1.15.0...v1.16.0) (2026-05-15)


### Features

* **ui:** add navigation tap interaction to NowPlayingBar ([e5d7f76](https://github.com/s0raLin/miku_music/commit/e5d7f7649f21adfba0af647a277253fc419519de))

## [1.15.0](https://github.com/s0raLin/miku_music/compare/v1.14.0...v1.15.0) (2026-05-15)


### Features

* **api:** integrate lrclib for lyrics retrieval ([521dce4](https://github.com/s0raLin/miku_music/commit/521dce499d0e497b1d1888bdf3d29fb9e7e2ab39))
* **music:** add local persistence for lyrics ([eb762b8](https://github.com/s0raLin/miku_music/commit/eb762b812f10d1cb1e8bd9e5e4bcf5eb8049869a))
* **ui:** implement native Android toast support ([9399116](https://github.com/s0raLin/miku_music/commit/9399116ce759fddb2bb5df5743d621f871a58dbf))

## [1.14.0](https://github.com/s0raLin/miku_music/compare/v1.13.0...v1.14.0) (2026-05-15)


### Features

* **ui:** add navigation to music detail from NowPlaying components ([84444ba](https://github.com/s0raLin/miku_music/commit/84444ba2eee8e88a9e4082e23e4a816722f0436f))
* **ui:** integrate AppToast for user feedback across views ([6745fd4](https://github.com/s0raLin/miku_music/commit/6745fd42fbfdc48907558ef85be58a2a310100aa))
* **ui:** replace NowPlayingBar with new NowPlaying component ([43b6ebe](https://github.com/s0raLin/miku_music/commit/43b6ebe0b75c83e48ce4c7f37a065d39b167fe03))
* **ui:** update NowPlayingMiniFab interaction logic ([bd31bdf](https://github.com/s0raLin/miku_music/commit/bd31bdf131c5c257b57288808fb38be899d52e8b))

## [1.13.0](https://github.com/s0raLin/miku_music/compare/v1.12.0...v1.13.0) (2026-05-14)


### Features

* **ui:** add AppToast component and refactor snackbars ([c158669](https://github.com/s0raLin/miku_music/commit/c158669442d8b2b50303c142c9584a47d2f63e4f))

## [1.12.0](https://github.com/s0raLin/miku_music/compare/v1.11.2...v1.12.0) (2026-05-12)


### Features

* **ui:** add bio field and improve edit profile layout ([54fc6e0](https://github.com/s0raLin/miku_music/commit/54fc6e04e5a14d47014c05a1d4cb3a2dd33c8eac))
* **ui:** replace M3UserCard with custom _UserCard in user profile ([5fd5dc8](https://github.com/s0raLin/miku_music/commit/5fd5dc893d6da3df8c3be6a57e3ac5f4c990a397))

## [1.11.2](https://github.com/s0raLin/miku_music/compare/v1.11.1...v1.11.2) (2026-05-11)


### Bug Fixes

* **app:** wrap dotenv loading in try-catch block ([c90686a](https://github.com/s0raLin/miku_music/commit/c90686a26fc6305ed533ad863479d07923801cb3))

## [1.11.1](https://github.com/s0raLin/miku_music/compare/v1.11.0...v1.11.1) (2026-05-11)


### Bug Fixes

* **macos:** add placeholder .env file to prevent build failure ([8a7f522](https://github.com/s0raLin/miku_music/commit/8a7f52214a7ca58e5efc139822076e440a194eb6))

## [1.11.0](https://github.com/s0raLin/miku_music/compare/v1.10.0...v1.11.0) (2026-05-11)


### Features

* **auth:** add setup wizard for first-time users ([c713466](https://github.com/s0raLin/miku_music/commit/c71346635a0cfa6e23bbdd06f6fa78a23d21e973))
* **music:** implement initial music library scanning on startup ([4be4b9a](https://github.com/s0raLin/miku_music/commit/4be4b9ab92397f6e401ad68095ea4da398086887))
* **music:** implement NetEase Cloud Music integration and playlist management ([2ef0746](https://github.com/s0raLin/miku_music/commit/2ef07461ffa98d6f6b5ea72febf3ce7ae85d2030))
* **ui:** add window management and system tray support ([6dda5d2](https://github.com/s0raLin/miku_music/commit/6dda5d23bc9c59cad433ce02bf78cd9d1a181b48))


### Bug Fixes

* **music:** improve Android storage permissions and scanning logic ([832c516](https://github.com/s0raLin/miku_music/commit/832c516634410a116d519d9152cb52f70c04a2d1))
* **ui:** integrate setup wizard flow into splash screen ([d3e2ee8](https://github.com/s0raLin/miku_music/commit/d3e2ee8042eee2a54f4ece71b72b4a866476ef0b))

## [1.10.0](https://github.com/s0raLin/miku_music/compare/v1.9.0...v1.10.0) (2026-05-08)


### Features

* **music:** implement CoverFlow and enhance music playback UI ([1be5a30](https://github.com/s0raLin/miku_music/commit/1be5a30d78934b0443d3131ee3576de5f26cf3f1))

## [1.9.0](https://github.com/s0raLin/miku_music/compare/v1.8.0...v1.9.0) (2026-05-08)


### Features

* **ui:** implement music dashboard and refactor home carousel ([22c51c0](https://github.com/s0raLin/miku_music/commit/22c51c05465b91eb4c98b925ec5a29772ef44b3d))
* **ui:** update home layout and navigation ([9f6a476](https://github.com/s0raLin/miku_music/commit/9f6a4762ca3a424a8dd004e30595ded689eef857))
* **user:** add profile editing functionality ([3d6801b](https://github.com/s0raLin/miku_music/commit/3d6801b77e87c9f3a2fa5b511e3e1f8be1a90481))

## [1.8.0](https://github.com/s0raLin/miku_music/compare/v1.7.0...v1.8.0) (2026-05-06)


### Features

* **music:** add playback state synchronization and equalizer animation ([4eb658f](https://github.com/s0raLin/miku_music/commit/4eb658fba6f29d1e54c2c4a2a5f96f167172d0bf))
* **nav:** implement NavProvider for centralized navigation management ([4d83645](https://github.com/s0raLin/miku_music/commit/4d83645321b3c4d02fd39eebc3189e2bfe370a6c))
* **settings:** implement comprehensive user preferences and initialization service ([2144b34](https://github.com/s0raLin/miku_music/commit/2144b34aff73abaf8b2328b1dfa765cc98e36133))
* **ui:** add header to main page content area ([8b2c086](https://github.com/s0raLin/miku_music/commit/8b2c0864961da71145e9779a49614296cbc07a3c))
* **ui:** implement custom playback icons and album grid view ([c9295ba](https://github.com/s0raLin/miku_music/commit/c9295ba413bf12380a43cc25ec428190ed5b2fed))


### Performance Improvements

* **files:** implement incremental grouping for music metadata ([d1f2bfc](https://github.com/s0raLin/miku_music/commit/d1f2bfc57b59810eaa726a960cddd8226b24b32b))

## [1.7.0](https://github.com/s0raLin/miku_music/compare/v1.6.0...v1.7.0) (2026-05-04)


### Features

* **music:** replace on_audio_query with photo_manager ([acb8e51](https://github.com/s0raLin/miku_music/commit/acb8e5182194953614f27fe8d7638d195f88845d))
* **ui:** implement playback queue and app versioning ([f1e98e8](https://github.com/s0raLin/miku_music/commit/f1e98e8f5036e89396d1423437d0766b03894c6c))

## [1.6.0](https://github.com/s0raLin/miku_music/compare/v1.5.0...v1.6.0) (2026-05-02)


### Features

* **api:** implement playlist support and bulk music upload ([89bf0d2](https://github.com/s0raLin/miku_music/commit/89bf0d29972412fd88300ba98bf3906f6e081bc5))
* **api:** modularize client API and add music endpoints ([760426c](https://github.com/s0raLin/miku_music/commit/760426cd17055c78dc7e1b6bfdbc0ab5fe6e90a3))
* **auth:** integrate jwt token into user model and provider ([6f4b3d8](https://github.com/s0raLin/miku_music/commit/6f4b3d81f45b678ece0eb35e44acfa9485f3bbcb))
* **auth:** unify login and registration into a single tabbed view ([1d7def6](https://github.com/s0raLin/miku_music/commit/1d7def61a64d54f29a7db10374b32feceb3721d4))
* **music:** add music listing endpoint and cleanup ui code ([6c85004](https://github.com/s0raLin/miku_music/commit/6c85004b90c30881836c0a27fd4edc5ac57fbe3b))
* **music:** implement nested scroll view for music library ([859aef6](https://github.com/s0raLin/miku_music/commit/859aef6dec5c3bc785a4e7f3da48727fd9ac74f7))
* **music:** implement playlist management system ([d9dd3cf](https://github.com/s0raLin/miku_music/commit/d9dd3cf23505258635d8f495e60f0522e6b2e5ef))
* **music:** support metadata extraction and cover art upload ([29e1815](https://github.com/s0raLin/miku_music/commit/29e181562d9e1b1f5f05807009548db2c1f8ffe1))
* **nav:** add user profile route and update drawer destinations ([42a86dd](https://github.com/s0raLin/miku_music/commit/42a86dd1a98f18faee585cb3930d6542789d191f))
* **ui:** enhance playback controls and user profile styling ([7e2e23f](https://github.com/s0raLin/miku_music/commit/7e2e23f9538fdbe302239474ac9d28bc0c4f8240))
* **ui:** enhance theme provider and refine settings UI ([ff20915](https://github.com/s0raLin/miku_music/commit/ff209154a6fe0234c1814223fd14f8a77eeaf65d))
* **ui:** implement about page and enhance drawer navigation ([151bf91](https://github.com/s0raLin/miku_music/commit/151bf915e62b300a5d3420c2ae4d7633c4b776aa))
* **ui:** implement reactive user state in drawer ([c7fcdfc](https://github.com/s0raLin/miku_music/commit/c7fcdfcaaba98f69052b458bb52fdcf8b4772f58))
* **ui:** implement responsive navigation layout and settings access ([fa65225](https://github.com/s0raLin/miku_music/commit/fa652259beca28c07b2c151d2325a19c5efbe085))
* **user:** add quick access category cards to profile view ([3ed8029](https://github.com/s0raLin/miku_music/commit/3ed8029aa0e232cdbca762b0931625a6ea5ccf68))


### Bug Fixes

* **music:** correct cover art file extension and remove unused import ([b93190d](https://github.com/s0raLin/miku_music/commit/b93190df2565a3748bdb5af0cc47e1f3f563c5de))
* **ui:** manage selected index state in NavigationDrawer ([4683167](https://github.com/s0raLin/miku_music/commit/46831676de7d2a3b87ffd11a0e6f371dc8b5409e))

## [1.5.0](https://github.com/s0raLin/miku_music/compare/v1.4.0...v1.5.0) (2026-04-27)


### Features

* **api:** add backend and api layer ([ebbaec9](https://github.com/s0raLin/miku_music/commit/ebbaec925212bdc6dab690f779e25472aa6cd642))
* **auth:** add jwt authentication middleware and utility ([bd0dc47](https://github.com/s0raLin/miku_music/commit/bd0dc47977c49242956435b6095de159cb3b5ac4))
* **auth:** expand user profile data in authentication response ([6b26559](https://github.com/s0raLin/miku_music/commit/6b26559096c50d382dc9cd374279493d7ff0f94b))
* **auth:** implement login functionality and client-side integration ([032cf3c](https://github.com/s0raLin/miku_music/commit/032cf3c0a8947e0ecdc91e551288f0e4bbbda98f))
* **auth:** implement user avatar upload during registration ([a3291ff](https://github.com/s0raLin/miku_music/commit/a3291ff745284ecff1868d3540cb161c867907de))
* **auth:** implement user registration with avatar upload ([6eb12d7](https://github.com/s0raLin/miku_music/commit/6eb12d7d2334bbe0b8840c60926fb9dc3b536733))
* **backend:** implement music upload to OSS and add email to user model ([da030ef](https://github.com/s0raLin/miku_music/commit/da030ef3e0ee2fd193454a87ff23d5d0c0e95d72))
* **backend:** upgrade OSS SDK to v2 and implement UUID-based file naming ([7b70e20](https://github.com/s0raLin/miku_music/commit/7b70e20350abebbb8be77a0a967c5d7a797edf73))
* **client:** add secure token storage and user state management ([6ba21e1](https://github.com/s0raLin/miku_music/commit/6ba21e1aebe733c7774e931b06ae88a13f372e5c))
* **ui:** implement user profile page and navigation ([433b946](https://github.com/s0raLin/miku_music/commit/433b946feb468df15f4f61c5a74b56d3f6cc6091))


### Bug Fixes

* **auth:** improve login validation and error handling ([0fc107f](https://github.com/s0raLin/miku_music/commit/0fc107f2bc9ed1caa9c91343681ce8b68a39d42a))
* **ui:** improve lyrics scrolling logic and index calculation ([4e504aa](https://github.com/s0raLin/miku_music/commit/4e504aa571692628aa358ef8a26e28f442985899))

## [1.4.0](https://github.com/s0raLin/miku_music/compare/v1.3.0...v1.4.0) (2026-04-25)


### Features

* **music:** add real-time lyric synchronization ([1c36d3b](https://github.com/s0raLin/miku_music/commit/1c36d3beb104aec6a4d7f83486044d549ed36fa7))
* **music:** add seek functionality to lyric lines ([d2be4ba](https://github.com/s0raLin/miku_music/commit/d2be4ba569e1b8c2d08882c4dd7fee1d5b270fad))
* **music:** implement lrc file parsing and external lyric loading ([e7a234e](https://github.com/s0raLin/miku_music/commit/e7a234eecd130355957f564437b08250169872eb))

## [1.3.0](https://github.com/s0raLin/miku_music/compare/v1.2.0...v1.3.0) (2026-04-21)


### Features

* **ui:** implement functional playback queue menu in NowPlayingBar ([4a43b64](https://github.com/s0raLin/miku_music/commit/4a43b648c75cb5d2e6291c497b656bf72f99dc68))

## [1.2.0](https://github.com/s0raLin/miku_music/compare/v1.1.0...v1.2.0) (2026-04-20)


### Features

* **ui:** replace NavigationRail with NavigationDrawer and implement responsive carousel ([2aa3364](https://github.com/s0raLin/miku_music/commit/2aa3364d9afc30d58f6f78aa051fa64b2058fef0))
* **ui:** restructure navigation and enhance component styling ([1aac0c2](https://github.com/s0raLin/miku_music/commit/1aac0c23939cf5e68af516d289859666e4e77b67))


### Bug Fixes

* use linguist-ignored for HTML files ([fbe960e](https://github.com/s0raLin/miku_music/commit/fbe960ea5be6ea74fe957b7be62de60ef318faa7))

## [1.1.0](https://github.com/s0raLin/miku_music/compare/v1.0.0...v1.1.0) (2026-04-17)


### Features

* **ui:** migrate to native CarouselView and add background assets ([592cee3](https://github.com/s0raLin/miku_music/commit/592cee3bb969e831ac1f591d5e2b455a05e8b551))

## 1.0.0 (2026-04-17)


### ⚠ BREAKING CHANGES

* **music:** None.
* **router:** old /contants/Routes has been deleted and navigation now relies on the new AppNavItem structure.
* **router:** RouterCtx extension removed; Header no longer uses context.read<GoRouter>()

### Features

* **components:** add now playing bar component and integrate into main page ([135eb91](https://github.com/s0raLin/miku_music/commit/135eb918e00b97dde76bbb8415461df0ece06446))
* **files:** add audio file picker and metadata extraction ([5f1ad88](https://github.com/s0raLin/miku_music/commit/5f1ad88b02bbc4b06724f038fbe93ce9b5b38baa))
* **files:** add files page with music scanning and metadata extraction ([893ee7c](https://github.com/s0raLin/miku_music/commit/893ee7c10b833ae243f56dfeed1285d998ac15af))
* **files:** add files page with music scanning, provider integration and navigation overhaul ([4b2bfc6](https://github.com/s0raLin/miku_music/commit/4b2bfc6cec2a53db50cb7f5916ef86ae94c101b2))
* **files:** add Files page with music scanning, provider integration and navigation overhaul ([49ac9e9](https://github.com/s0raLin/miku_music/commit/49ac9e9f7704e88dacb822e5fd0f5eed15fb1fcc))
* **files:** add multi‑directory music scanning and persistent storage ([a00ef14](https://github.com/s0raLin/miku_music/commit/a00ef1485144300c136c47242d3280f88531c04b))
* **files:** add scan progress updates to MusicService and UI ([7f127b1](https://github.com/s0raLin/miku_music/commit/7f127b1c72887428e08a5f6c028d09b7cf397d00))
* **music:** add favorite list support and UI updates ([268e9c7](https://github.com/s0raLin/miku_music/commit/268e9c71902f56017096a5ab1905da0bcaebdd28))
* **music:** add favorite list, navigation, and refactor detail page ([500b0c5](https://github.com/s0raLin/miku_music/commit/500b0c5e36b602f2594dde4091c0c6f639b7ac60))
* **music:** add ListTileTheme for track selection ([085e96e](https://github.com/s0raLin/miku_music/commit/085e96e9491c3a76d9ecea13a1266519fe423be4))
* **music:** add persistent playback history support ([c51db2a](https://github.com/s0raLin/miku_music/commit/c51db2aab970f60f598eb674bc7abb8fc0af11dc))
* **resources:** integrate permission_handler and add drawable assets ([3f4458e](https://github.com/s0raLin/miku_music/commit/3f4458eaad49e85f72e5626e78bd857f37d84f08))
* **router:** add NotFound page and error handling to routing ([19783da](https://github.com/s0raLin/miku_music/commit/19783da5c1771738642f77245d957c888912499c))
* **ui:** add Files page and refactor navigation ([d98b3d9](https://github.com/s0raLin/miku_music/commit/d98b3d95ea5cd32480f2585fc3690f23826b3dc6))
* **ui:** add files page and update navigation ([c883329](https://github.com/s0raLin/miku_music/commit/c8833292dfd280d69018d1b325861c1002629a88))
* **ui:** add Files page with music scanning, Google Fonts and navigation overhaul ([d11cc20](https://github.com/s0raLin/miku_music/commit/d11cc20ae3c4d3379e4694ad0b2ddb9f2cad6c76))
* **ui:** adopt ThemeProvider and refactor navigation UI ([52d1cf1](https://github.com/s0raLin/miku_music/commit/52d1cf194220773eb2e9a0dd715336c88bcbd29c))


### Code Refactoring

* **router:** improve navigation stack and theme defaults ([2997a7f](https://github.com/s0raLin/miku_music/commit/2997a7f4cc6f1bb490bcf6c1aa4ead9e980a6960))
* **router:** overhaul navigation, theme and component integration ([74cf551](https://github.com/s0raLin/miku_music/commit/74cf55186154eb93857d26167171d3c5c183087d))
