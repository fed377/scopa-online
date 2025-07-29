'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "0326a24d20fabb3f00816143696d6569",
"assets/AssetManifest.bin.json": "17a5ffd2d0d4817dc75ef71d74bf89d9",
"assets/AssetManifest.json": "e952186ff6a1411d44921f3ea2ce9608",
"assets/assets/0_of_clubs.png": "f0dc748d3d36f265ab670c8ce0332e3d",
"assets/assets/0_of_diamonds.png": "9588f72f2c9d6898c9af3b20bcde7c2f",
"assets/assets/0_of_hearts.png": "e8d050e1412d4866d34f9a41b0c48238",
"assets/assets/0_of_spades.png": "aebc913c5eb0ecd7859218636929c8ae",
"assets/assets/1_of_clubs.png": "07d1c180bead76a0b8cf8e488dfc2755",
"assets/assets/1_of_diamonds.png": "60b16fdaed475d30edab3bc92f4bd3c9",
"assets/assets/1_of_hearts.png": "41453bfa387b05e68828f2b0159c19d9",
"assets/assets/1_of_spades.png": "ce4f163fc9fddc4e9f173d74b2970cc2",
"assets/assets/2_of_clubs.png": "c83a7af4125e22d9733f6514295f3d4c",
"assets/assets/2_of_diamonds.png": "0b5b5249b22ada06106be8b73938be9e",
"assets/assets/2_of_hearts.png": "f97ad85b1e89af6a88c70205cdea06f6",
"assets/assets/2_of_spades.png": "2354275da56e304199f694388a8aaae6",
"assets/assets/3_of_clubs.png": "23a7a6ac76db02bbde27988e49ac5fca",
"assets/assets/3_of_diamonds.png": "b529e1c14fef2ffc07c3c4eac94c31f4",
"assets/assets/3_of_hearts.png": "1c16fe1052c3a4d1715ee1288209ebe9",
"assets/assets/3_of_spades.png": "ad02dc95b434842c3465a7a4dbaca615",
"assets/assets/4_of_clubs.png": "02deab4916f717f0b9478fad476ec40f",
"assets/assets/4_of_diamonds.png": "58bd0a6383829cbce3747c245c0b204c",
"assets/assets/4_of_hearts.png": "5ad913da63724447b7c94d1fb2d293a6",
"assets/assets/4_of_spades.png": "df185c634b2fee0418bd613524938832",
"assets/assets/5_of_clubs.png": "3781bf44a82cad8ef837e6ba281427c9",
"assets/assets/5_of_diamonds.png": "e27b4b0aadc6a28953f53cfd573e9e2d",
"assets/assets/5_of_hearts.png": "8f6a2068fd6f32c372ea8dab0cde6f40",
"assets/assets/5_of_spades.png": "aa8a072015826f2e582a59e9606e0cd3",
"assets/assets/6_of_clubs.png": "9c2fdf6a8916a2b3daea26a7974eed28",
"assets/assets/6_of_diamonds.png": "ee5053d458469b151ef1f4503b5ab12f",
"assets/assets/6_of_hearts.png": "9cd2258c8c8c175ead46f94800741891",
"assets/assets/6_of_spades.png": "5d221b2a958bb6b66b4e57de437c0906",
"assets/assets/7_of_clubs.png": "112be1dfa65edf2cabf9122b2c49eb22",
"assets/assets/7_of_diamonds.png": "df3e8e93d277f2b73d2c5ddf348c065c",
"assets/assets/7_of_hearts.png": "a9afa10fcea89a4227bb4b81f49a35e8",
"assets/assets/7_of_spades.png": "c0f5e5f9013f1d24eccd395ab9312766",
"assets/assets/8_of_clubs.png": "d96ecf4f3c246b8c781f82d1bb2bd1dc",
"assets/assets/8_of_diamonds.png": "c936f66eb6ca786d62a2c49876367017",
"assets/assets/8_of_hearts.png": "9be659a7f009932fe8f49a213c22e439",
"assets/assets/8_of_spades.png": "d77ce402c3977e303abeed8ec5bb35a5",
"assets/assets/9_of_clubs.png": "fd943099b2abeb6cf01bebb4dc66cbbe",
"assets/assets/9_of_diamonds.png": "f91b8d276604290828523a097fd4af26",
"assets/assets/9_of_hearts.png": "8065dc2a89d1be1e9908343fb99d82cc",
"assets/assets/9_of_spades.png": "445df3cf193554d44a50f43d4597c324",
"assets/assets/back.png": "1062d94a6e700d587fbeb7704350fea1",
"assets/assets/back_card.pdn": "c0e38308a10f65d6a06d5e8d2743b495",
"assets/assets/back_card.png": "f053098e367e1b3d78813c8351e4e50f",
"assets/assets/Club.png": "bc8bacf6ed1f5b2a19f71ecb0440722b",
"assets/assets/Club_black.png": "5cb5a35bd2b80b33fd50d12ac9407cd7",
"assets/assets/Club_red.png": "df70985c51c91fe83cf252ecc551c714",
"assets/assets/Diamond_black.png": "0aa5cd251057bb774407c2046f33ff7a",
"assets/assets/Diamond_red.png": "7a7e3db1356648537532f43d8f49f524",
"assets/assets/Heart_black.png": "adde0e0d66fbfd6ea3f09cf00185025b",
"assets/assets/Heart_red.png": "1d709101f9dedc2c09187e6ad0c51f90",
"assets/assets/Spade.png": "df70985c51c91fe83cf252ecc551c714",
"assets/assets/Spade_black.png": "f4833f9e66ed184cb520792ae6f02663",
"assets/assets/Spade_red.png": "9fc68c62036d6626080160f4e6302c67",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "19807cd6e62e0201427559ba2de61531",
"assets/NOTICES": "2c02f5e1f4e56023a9b7ca6832b31e8e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"flutter_bootstrap.js": "13d2bf7ceff21545b525a5d96ae7e27f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "01fb881374e4a98d23b5907beb5ef2eb",
"/": "01fb881374e4a98d23b5907beb5ef2eb",
"main.dart.js": "3f1feef21475dfafdcecb4dc4a12b979",
"manifest.json": "cebc37d03e8fe58df65bae5da14dbbea",
"version.json": "bcc546eaa902a6191fd3d10f6c37be73"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
