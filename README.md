# IoT Remote Control & Monitor Suhu (MQTT)

Aplikasi Flutter untuk kontrol remote IoT dan monitoring suhu real-time menggunakan protokol MQTT.

## 🚀 Fitur Utama

1. **Page 1: Kontrol Relay 4 Modul**
   - Mengendalikan 4 channel relay secara terpisah (`Relay 1`, `Relay 2`, `Relay 3`, `Relay 4`).
   - Fitur **Master Saklar**: "Nyalakan Semua" dan "Matikan Semua" dalam 1 kali klik.
   - Status visual real-time (Indikator warna, ikon dinamis, label aktif/mati).
   - Penamaan relay kustom (bisa ubah nama per modul, misal: *Lampu Ruang Tamu*, *Kipas Angin*, *Pompa Air*).
   - Opsi format payload: Angka biner (`"1"` / `"0"`) atau teks (`"ON"` / `"OFF"`).
   - Log aktivitas MQTT real-time untuk memantau pesan yang terkirim.

2. **Page 2: Monitor Data Suhu**
   - Menerima dan menampilkan data suhu secara real-time dari sensor (misal DHT11, DHT22, DS18B20).
   - Indikator suhu visual dinamis (warna berubah sesuai temperatur: Sejuk, Normal, Hangat, Panas).
   - Tampilan pembacaan kelembapan (humidity) jika dikirimkan oleh mikrokontroler.
   - Timestamp waktu penerimaan data terakhir.
   - Riwayat data suhu (History list) lengkap dengan raw payload.
   - Fitur **Simulasi Data**: tombol untuk menguji pengiriman data suhu langsung di aplikasi tanpa harus menunggu perangkat fisik.

3. **Pengaturan Broker & Topik MQTT**
   - Broker bawaan: `broker.emqx.io` (port `1883`) atau bisa diganti ke broker lain (HiveMQ, Mosquitto lokal, dsb).
   - Client ID otomatis / kustom.
   - Dukungan autentikasi (Username & Password).
   - Kustomisasi prefix topik relay (default: `iot/relay/`) dan topik suhu (default: `iot/sensor/suhu`).
   - Dilengkapi contoh kode ESP32 / Arduino lengkap di dalam aplikasi.

---

## 📡 Konfigurasi Topik MQTT

| Fungsi | Topik Default | Payload | Keterangan |
| :--- | :--- | :--- | :--- |
| **Relay 1** | `iot/relay/1` | `"1"` / `"0"` | Menghidupkan / Mematikan Relay 1 |
| **Relay 2** | `iot/relay/2` | `"1"` / `"0"` | Menghidupkan / Mematikan Relay 2 |
| **Relay 3** | `iot/relay/3` | `"1"` / `"0"` | Menghidupkan / Mematikan Relay 3 |
| **Relay 4** | `iot/relay/4` | `"1"` / `"0"` | Menghidupkan / Mematikan Relay 4 |
| **Sensor Suhu** | `iot/sensor/suhu` | `"28.5"` atau `{"suhu": 28.5, "humidity": 65}` | Format angka biasa atau format JSON didukung |

---

## 💻 Contoh Kode ESP32 / Arduino (PubSubClient)

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include "DHT.h"

const char* ssid = "NAMA_WIFI_ANDA";
const char* password = "PASSWORD_WIFI";
const char* mqtt_server = "broker.emqx.io";

WiFiClient espClient;
PubSubClient client(espClient);

// Pin Relay 4 Channel
const int relayPins[4] = {26, 27, 14, 12};

// Pin Sensor DHT11 / DHT22
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

unsigned long lastTempSend = 0;

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  // Cek pesan untuk relay 1 s/d 4
  for (int i = 0; i < 4; i++) {
    String expectedTopic = "iot/relay/" + String(i + 1);
    if (String(topic) == expectedTopic) {
      if (message == "1" || message == "ON") {
        digitalWrite(relayPins[i], HIGH);
      } else {
        digitalWrite(relayPins[i], LOW);
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  dht.begin();

  for (int i = 0; i < 4; i++) {
    pinMode(relayPins[i], OUTPUT);
    digitalWrite(relayPins[i], LOW);
  }

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }

  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    while (!client.connected()) {
      if (client.connect("ESP32_Client_IoT")) {
        for (int i = 1; i <= 4; i++) {
          client.subscribe(("iot/relay/" + String(i)).c_str());
        }
      } else {
        delay(3000);
      }
    }
  }
  client.loop();

  // Kirim data suhu setiap 5 detik
  if (millis() - lastTempSend > 5000) {
    lastTempSend = millis();
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    if (!isnan(t)) {
      String json = "{\"suhu\":" + String(t, 1) + ",\"humidity\":" + String(h, 1) + "}";
      client.publish("iot/sensor/suhu", json.c_str());
    }
  }
}
```

---

## 📱 Cara Menjalankan Aplikasi

1. Pastikan dependensi sudah terunduh:
   ```bash
   flutter pub get
   ```
2. Jalankan aplikasi di perangkat emulator, web, atau HP Android:
   ```bash
   flutter run
   ```
