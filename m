From: Igor Velkov <iav@iav.lv>
Date: Wed, 04 Nov 2026 05:54:37 +0000
Subject: [PATCH RFC 1/3] dt-bindings: rtc: Add linux,wakeup-states and
 linux,alarmtimer-priority
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-alarmtimer-rtc-priority-v1-1-e996681b8086@iav.lv>
References: <20261104-b4-alarmtimer-rtc-priority-v1-0-e996681b8086@iav.lv>
In-Reply-To: <20261104-b4-alarmtimer-rtc-priority-v1-0-e996681b8086@iav.lv>
To: John Stultz <jstultz@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>
Cc: Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3808; i=iav@iav.lv;
 h=from:subject:message-id; bh=03lyxM4SQ2zx0WHWIjnOxBbyYZuv2oiIWhQvdfHX1RY=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmvTsz7PYtLJGfuw7h/x3gefC637LKTrvZlvP/gWsTcs
 82zHvIe7yhlYRDjYpAVU2SZcEjjVsaSq3/9PcwfwMxhZQIZwsDFKQATMYtm+MV8XeKmxqIldz/n
 6Qos2pOWzFUzL0iuYi2vyfUMTqlWtQuMDKe0zi11av/rZ3z210otX7mVS2STfe/M3X5qUfq3/O+
 l/3gA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A board can have more than one RTC with an alarm that wakes the system,
for example an I2C RTC next to an RTC in the PMIC or the SoC firmware.
Which of them wakes the system depends on the sleep state and on the
board's firmware: amlogic,meson-vrtc is a register the firmware reads
when the application processors suspend, so it wakes the system from
deep sleep only, and whether an I2C RTC wakes the system from deep
sleep depends on the firmware handling its interrupt line.

Add two properties to describe this per RTC. linux,wakeup-states lists
the sleep states an alarm of the RTC wakes the system from, named as in
/sys/power/mem_sleep, plus hibernate and off, or none for an RTC whose
alarm wakes the system from no state. linux,alarmtimer-priority weights
the RTC among those that wake the system from the target state.

List both in nxp,pcf8563.yaml and amlogic,meson-vrtc.yaml, which do not
allow unlisted properties.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 .../bindings/rtc/amlogic,meson-vrtc.yaml           |  3 +++
 .../devicetree/bindings/rtc/nxp,pcf8563.yaml       |  3 +++
 Documentation/devicetree/bindings/rtc/rtc.yaml     | 29 ++++++++++++++++++++++
 3 files changed, 35 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml b/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml
index a89865fa676a..bc4a1916f600 100644
--- a/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml
+++ b/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml
@@ -30,6 +30,9 @@ properties:
   reg:
     maxItems: 1
 
+  linux,alarmtimer-priority: true
+  linux,wakeup-states: true
+
 required:
   - compatible
   - reg
diff --git a/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml b/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml
index 22909a96123e..5aabeb074c82 100644
--- a/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml
+++ b/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml
@@ -32,6 +32,9 @@ properties:
   interrupts:
     maxItems: 1
 
+  linux,alarmtimer-priority: true
+  linux,wakeup-states: true
+
   start-year: true
   wakeup-source: true
 
diff --git a/Documentation/devicetree/bindings/rtc/rtc.yaml b/Documentation/devicetree/bindings/rtc/rtc.yaml
index efb66df82782..3b4b8ff90ada 100644
--- a/Documentation/devicetree/bindings/rtc/rtc.yaml
+++ b/Documentation/devicetree/bindings/rtc/rtc.yaml
@@ -26,6 +26,35 @@ properties:
       0: not chargeable
       1: chargeable
 
+  linux,alarmtimer-priority:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Weight of this RTC for waking the system on alarmtimer alarms.
+      Among the RTCs that can wake the system from the target sleep
+      state, the one with the highest value is used; on a tie, the
+      operating system decides. An RTC without this property has
+      priority 0.
+
+  linux,wakeup-states:
+    $ref: /schemas/types.yaml#/definitions/string-array
+    description:
+      System sleep states an alarm of this RTC wakes the system from,
+      given the board and its firmware. s2idle, shallow and deep are the
+      states of /sys/power/mem_sleep, hibernate is suspend-to-disk and
+      off is the powered-off system, and none, given alone, means the
+      alarm wakes the system from no state. An RTC without this property
+      is taken to wake the system from every state.
+    oneOf:
+      - items:
+          enum:
+            - s2idle
+            - shallow
+            - deep
+            - hibernate
+            - "off"
+      - items:
+          - const: none
+
   quartz-load-femtofarads:
     description:
       The capacitive load of the quartz(x-tal), expressed in femto

-- 
2.43.0

