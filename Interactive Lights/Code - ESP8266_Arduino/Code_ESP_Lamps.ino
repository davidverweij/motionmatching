/* UDP connection with Processing Sketch (running on laptop / raspberry PI). IP adress should be known of the PI */

#include <ESP8266WiFi.h>
#include <Adafruit_NeoPixel.h>
#include <WiFiUdp.h>

const char* ssid     = "SSID";
const char* password = "PASS";
unsigned int localUdpPort = 8266;
char udpInPacket[480];
int lamp = 2;  // 0 = walllight; 1 = standing light; 2 = ceiling light

String replyPacket[3] = {"WallLight Heartbeat!", "StandingLight Heartbeat!", "CeilingLight Heartbeat!"};      // not using at the moment
String hostName[] = {"ESP_Wall", "ESP_Stand", "ESP_Ceiling"};
WiFiUDP Udp;              // UDP client

#define NeoPixelPIN 14
int nrLEDS[] = {60, 40, 40};
Adafruit_NeoPixel strip = Adafruit_NeoPixel(nrLEDS[lamp], NeoPixelPIN, NEO_RGBW + NEO_KHZ800);
 //
int brightness = 0;   // 0 - 100%
long last_message = 0;

void WIFI_Connect() {
  // We start by connecting to a WiFi network
  // set light on red as status
  for (uint16_t i = 0; i < strip.numPixels(); i++) {
    strip.setPixelColor(i, strip.Color(0, 10, 0, 0));
  }
  strip.show();

  WiFi.disconnect();
  delay(200);
  WiFi.begin(ssid, password);

  WiFi.hostname(hostName[lamp]);

  Serial.println();
  Serial.println();
  Serial.print("Wait for WiFi... ");

  while (WiFi.status() != WL_CONNECTED) {
    //Serial.print(".");
    delay(500);
  }

  last_message = millis();

  delay(500);
}

void setup() {
  Serial.begin(115200);

  strip.begin();
  strip.show(); // Initialize all pixels to 'off'

  delay(10);

  WiFi.mode(WIFI_STA);

  WIFI_Connect();

  Udp.begin(localUdpPort);


}


void loop() {

  if (WiFi.status() != WL_CONNECTED)
  {
    WIFI_Connect();
  }

  checkUDP();

  if (millis() - last_message > 1500) {                            // if we did not get a message in the last 1,5 seconds, we fading blink blue
    float timert = map((float)(millis() % 6000), 0, 6000, 0, 510); //timer for 4 second fade
    int bright = (int)timert;
    if (bright > 255) bright = 510 - bright;
    bright = bright * bright / 255;
    for (uint16_t i = 0; i < strip.numPixels(); i++) {
      strip.setPixelColor(i, strip.Color(0, 0 , (int)bright / 4, 0));
    }
    strip.show();

    if (millis() - last_message > 60000) {
      WIFI_Connect();
      Udp.begin(localUdpPort);
    }

  }


}

void checkUDP() {
  int packetSize = Udp.parsePacket();

  if (packetSize)       // if we receive instructions, just bluntly set the colours as instructed
  {
    //Serial.printf("Received %d bytes from %s, port %d\n", packetSize, Udp.remoteIP().toString().c_str(), Udp.remotePort());
    int len = Udp.read(udpInPacket, sizeof(udpInPacket));
    //Serial.print("/");

    // Set color command
    if (udpInPacket[0] == 0x01)
    {
      last_message = millis();
      // [1] reply required (1 = yes, 0 = no) --> not using at the moment
      // [2] mode (0 = idle/selectable, 1 = no motion, 2 = menu)
      // [3] menu (depends on the lights)
      // [4] brightness (0-100)
      // [5] target 1 position (in degrees) (at the time of sending)
      // [6] if target selected, give number (99 is none)

      for (int i = 0; i < nrLEDS[lamp]; i++)
      {
        strip.setPixelColor(i, strip.Color((int)udpInPacket[2 + i * 4 + 1], (int)udpInPacket[2 + i * 4 + 0], (int)udpInPacket[2 + i * 4 + 2], (int)udpInPacket[2 + i * 4 + 3]));    // set the LED's to their instructed colours
      }
      strip.show();
    }
  }

}

