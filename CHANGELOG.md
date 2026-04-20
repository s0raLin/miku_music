# Changelog

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
