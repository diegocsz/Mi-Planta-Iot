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

  char tempBuffer[6];
  char humBuffer[6];

  dtostrf(t, 4, 1, tempBuffer);
  dtostrf(h, 4, 1, humBuffer);

  Serial.print(tempBuffer);
  Serial.print(",");
  Serial.println(humBuffer);
}