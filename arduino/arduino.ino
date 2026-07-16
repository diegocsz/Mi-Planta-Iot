#include <DHT.h>

#define DHTPIN 2
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(9600);
  dht.begin();
}

void loop() {
  delay(3000);

  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    return;
  }

  // Buffers para almacenar el formato (3,1) -> Ej: "25.5" (4 caracteres incluyendo el punto)
  char tempBuffer[6];
  char humBuffer[6];

  // Convertimos a string con formato: (valor, ancho_total, decimales, buffer)
  dtostrf(t, 4, 1, tempBuffer);
  dtostrf(h, 4, 1, humBuffer);

  // Enviamos los datos limpiando espacios iniciales si es necesario
  Serial.print(tempBuffer);
  Serial.print(",");
  Serial.println(humBuffer);
}