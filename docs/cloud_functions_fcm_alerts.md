# Cloud Functions FCM Alerts

Contoh ini mengirim FCM saat nilai Realtime Database berubah di:

`/monitoring/device_1/kondisi`

Nilai dari ESP32 tetap dipakai apa adanya:

- `AMAN`
- `WASPADA`
- `DARURAT`

Flutter sudah subscribe ke topic:

`device_1_alerts`

## Batasan Android

- Jika HP benar-benar power off, tidak ada aplikasi yang bisa menerima notifikasi karena sistem operasi tidak berjalan.
- Jika aplikasi di-force stop dari Settings Android, FCM/background handler bisa diblokir sampai aplikasi dibuka lagi.
- Jika aplikasi di-uninstall, notifikasi tidak bisa diterima.
- Battery optimization ekstrem dari beberapa vendor bisa menunda atau memblokir background delivery.
- Audio loop dan getar loop terus-menerus di background tidak dijamin oleh Android.
- Untuk foreground, aplikasi memakai `AlarmService` dengan audio loop dan getar loop.
- Untuk background, layar terkunci, layar mati, atau app tidak dibuka, solusi utama adalah FCM + notification channel dengan suara dan getar custom.

## Contoh Functions

Pasang kode ini di Firebase Functions jika backend belum ada. Fungsi ini hanya mengirim FCM jika kondisi berubah, jadi nilai yang sama tidak dikirim berulang.

```js
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

const TOPIC = "device_1_alerts";
const DEVICE_ID = "device_1";

function normalizeCondition(value) {
  return String(value || "").trim().toUpperCase();
}

function buildAlertPayload(condition) {
  if (condition === "WASPADA") {
    return {
      title: "Peringatan Waspada",
      body: "Kondisi sensor menunjukkan status WASPADA. Segera periksa lokasi.",
      channelId: "fire_warning_channel",
    };
  }

  if (condition === "DARURAT") {
    return {
      title: "DARURAT Kebakaran",
      body: "Kondisi DARURAT terdeteksi! Segera lakukan tindakan.",
      channelId: "fire_emergency_channel",
    };
  }

  if (condition === "AMAN") {
    return {
      title: "Kondisi Aman",
      body: "Status perangkat kembali AMAN.",
      channelId: "fire_safe_channel",
    };
  }

  return null;
}

exports.sendDeviceAlert = functions.database
  .ref("/monitoring/device_1/kondisi")
  .onWrite(async (change) => {
    const before = normalizeCondition(change.before.val());
    const after = normalizeCondition(change.after.val());

    if (before === after) {
      return null;
    }

    const alert = buildAlertPayload(after);

    if (!alert) {
      return null;
    }

    return admin.messaging().send({
      topic: TOPIC,
      data: {
        condition: after,
        deviceId: DEVICE_ID,
        title: alert.title,
        body: alert.body,
        channelId: alert.channelId,
      },
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

Kode di atas mengirim data-only message agar Flutter menampilkan local notification memakai channel Android `fire_warning_channel` atau `fire_emergency_channel`. Jangan menambahkan payload `notification` jika local notification juga ditampilkan oleh aplikasi, supaya tidak muncul notifikasi dobel.
