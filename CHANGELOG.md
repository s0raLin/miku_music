# Changelog

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
