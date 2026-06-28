importScripts(
  'https://www.gstatic.com/firebasejs/11.10.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/11.10.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyAjXbkhrPPgq9hwlhdKB21dG2VfvatAXTI',
  authDomain: 'shield-zabnix.firebaseapp.com',
  projectId: 'shield-zabnix',
  storageBucket: 'shield-zabnix.firebasestorage.app',
  messagingSenderId: '1086152719549',
  appId: '1:1086152719549:web:199b8c17ac57081cda0bd4',
  measurementId: 'G-358541Z4LN',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle =
    payload.notification?.title ?? 'SHIELD notification';
  const notificationOptions = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
    data: payload.data ?? {},
  };

  self.registration.showNotification(
    notificationTitle,
    notificationOptions,
  );
});
