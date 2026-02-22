importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCjI-LFvVTF2WPHRMiVVS4ClbnSixG1bR4",
  authDomain: "momit-1.firebaseapp.com",
  projectId: "momit-1",
  storageBucket: "momit-1.firebasestorage.app",
  messagingSenderId: "459220254220",
  appId: "1:459220254220:web:1b2ae6f7c99fff14fff829",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || "MOMIT";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    dir: "rtl",
    lang: "he",
    data: payload.data,
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener("notificationclick", function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then(function(clientList) {
      if (clientList.length > 0) {
        return clientList[0].focus();
      }
      return clients.openWindow("/");
    })
  );
});
