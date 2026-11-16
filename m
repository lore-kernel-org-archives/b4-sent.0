From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:05 +0000
Subject: [PATCH v2 6/8] dt-bindings: rtc: Add linux,wakeup-states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-6-b2c69721e489@iav.lv>
References: <20261116-b4-alarmtimer-rtc-priority-v2-0-b2c69721e489@iav.lv>
In-Reply-To: <20261116-b4-alarmtimer-rtc-priority-v2-0-b2c69721e489@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3061; i=iav@iav.lv;
 h=from:subject:message-id; bh=jiWwGKeX8J95JaxaQWkNTzGvuFoNUgKE+31aH14O6+k=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fJM+HbRbzvOrcLN3Z3bohrn176QZAn96i7190bszJ
 9IldGF7RykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZhIjwTD/7z5Xad3PvXKsfZq
 2XV+acvpA6bqq77kFk7lX/5uM2fSf3WGv7LRzD55rDquroK32mX+n5qncENr0u8wQ1GmttgnrUI
 z+QA=
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

Add linux,wakeup-states to describe this per RTC: the suspend states an
alarm of the RTC wakes the system from, named as in /sys/power/mem_sleep,
or none for an RTC whose alarm wakes the system from no suspend state.

List it in nxp,pcf8563.yaml and amlogic,meson-vrtc.yaml, which do not
allow unlisted properties.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 .../devicetree/bindings/rtc/amlogic,meson-vrtc.yaml     |  2 ++
 Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml  |  2 ++
 Documentation/devicetree/bindings/rtc/rtc.yaml          | 17 +++++++++++++++++
 3 files changed, 21 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml b/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml
index a89865fa676a..51cce4b2a7ff 100644
--- a/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml
+++ b/Documentation/devicetree/bindings/rtc/amlogic,meson-vrtc.yaml
@@ -30,6 +30,8 @@ properties:
   reg:
     maxItems: 1
 
+  linux,wakeup-states: true
+
 required:
   - compatible
   - reg
diff --git a/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml b/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml
index 22909a96123e..e464432e4690 100644
--- a/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml
+++ b/Documentation/devicetree/bindings/rtc/nxp,pcf8563.yaml
@@ -32,6 +32,8 @@ properties:
   interrupts:
     maxItems: 1
 
+  linux,wakeup-states: true
+
   start-year: true
   wakeup-source: true
 
diff --git a/Documentation/devicetree/bindings/rtc/rtc.yaml b/Documentation/devicetree/bindings/rtc/rtc.yaml
index e46d50b1063e..54f41858dda4 100644
--- a/Documentation/devicetree/bindings/rtc/rtc.yaml
+++ b/Documentation/devicetree/bindings/rtc/rtc.yaml
@@ -26,6 +26,23 @@ properties:
       0: not chargeable
       1: chargeable
 
+  linux,wakeup-states:
+    $ref: /schemas/types.yaml#/definitions/string-array
+    description:
+      Suspend states an alarm of this RTC wakes the system from, given
+      the board and its firmware, named as in /sys/power/mem_sleep. none,
+      given alone, means the alarm wakes the system from no suspend
+      state. An RTC without this property is taken to wake the system
+      from every suspend state.
+    oneOf:
+      - items:
+          enum:
+            - s2idle
+            - shallow
+            - deep
+      - items:
+          - const: none
+
   quartz-load-femtofarads:
     description:
       The capacitive load of the quartz(x-tal), expressed in femto

-- 
2.43.0

