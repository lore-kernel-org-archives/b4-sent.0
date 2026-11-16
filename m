From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:07 +0000
Subject: [PATCH v2 8/8] arm64: dts: amlogic: meson-sm1-odroid-hc4: Describe
 which RTC wakes the board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-8-b2c69721e489@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1310; i=iav@iav.lv;
 h=from:subject:message-id; bh=KnLlIIqoXkwEM5qIksoDafpdgl/wvWdUGl1vKeB191k=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fJN3R1f0LWlIi57vYrn7w16ulSkcvV9/cn9QcnUpM
 T22/k9MRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZjISWVGhsbZ1QIZGz4v53wr
 ctYsqTN2+dxcjsc85+fyxR1JeiW2NYLhv9/c8r1Huha838rk+vvh47pz1+8ziB5+vq7p1/P44L4
 TSXwA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The board has two RTCs with an alarm. The pcf8563 interrupt line goes
to GPIOX_5, so once that interrupt is described [1], its alarm wakes the
board from s2idle. meson-vrtc is a register the SoC firmware reads when
the application processors suspend, so it wakes the board from deep
sleep only, and only with a BL301 that handles its alarm.

List the states per RTC, so that alarmtimer programs the pcf8563 for
s2idle and meson-vrtc for deep sleep.

Link: https://lore.kernel.org/r/20261019-hc4-rtc-alarm-irq-v1-1-078fc79e596f@iav.lv [1]
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
index 5f15c2299509..0dd9cd2d8245 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
@@ -106,6 +106,7 @@ rtc: rtc@51 {
 		compatible = "nxp,pcf8563";
 		reg = <0x51>;
 		wakeup-source;
+		linux,wakeup-states = "s2idle";
 	};
 };
 
@@ -142,3 +143,7 @@ &usb {
 	phys = <&usb2_phy0>, <&usb2_phy1>;
 	phy-names = "usb2-phy0", "usb2-phy1";
 };
+
+&vrtc {
+	linux,wakeup-states = "deep";
+};

-- 
2.43.0

