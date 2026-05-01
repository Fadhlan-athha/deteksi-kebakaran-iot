# Cloud Functions FCM Alerts

Contoh ini menunjukkan pola backend untuk mengirim FCM saat:

`/monitoring/device_1/kondisi`

berubah menjadi `WASPADA`, `DARURAT`, atau kembali `AMAN`.

Flutter sudah subscribe ke topic:

`device_1_alerts`

> Catatan: file ini contoh implementasi. Pasang di project Firebase Functions jika backend belum ada.

```js
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendDeviceAlert = functions.database
  .ref("/monitoring/device_1/kondisi")
  .onUpdate(async (change) => {
    const before = String(change.before.val() || "").toUpperCase();
    const after = String(change.after.val() || "").toUpperCase();

    if (before === after) {
      return null;
    }

    const topic = "device_1_alerts";
    let title = "";
    let body = "";

    if (after === "WASPADA") {
      title = "Peringatan Waspada";
      body = "Kondisi sensor menunjukkan status WASPADA. Segera periksa lokasi.";
    } else if (after === "DARURAT") {
      title = "DARURAT Kebakaran";
      body = "Kondisi DARURAT terdeteksi! Segera lakukan tindakan.";
    } else if (after === "AMAN") {
      title = "Kondisi Aman";
      body = "Status perangkat kembali AMAN.";
    } else {
      return null;
    }

    return admin.messaging().send({
      topic,
      data: {
        kondisi: after,
        deviceId: "device_1",
        title,
        body,
      },
      // Kirim data-only message supaya Flutter menampilkan local notification
      // dengan channel, suara, dan pola getar yang sudah dibuat di aplikasi.
      // Jika memakai payload "notification" juga, hindari menampilkan local
      // notification kedua agar tidak dobel.
      android: {
        priority: "high",
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            contentAvailable: true,
            sound: "default",
          },
        },
      },
    });
  });
```

Untuk menghindari notifikasi berulang, fungsi di atas hanya mengirim jika nilai `kondisi` berubah.
