From: Igor Velkov <iav@iav.lv>
Date: Mon, 19 Oct 2026 21:52:01 +0000
Subject: [PATCH] arm64: dts: amlogic: meson-sm1-odroid-hc4: wire the RTC
 alarm interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-hc4-rtc-alarm-irq-v1-1-078fc79e596f@iav.lv>
X-B4-Tracking: v=1; b=H4sIAACR1moC/x3MTQqAIBBA4avErBtQsYiuEi3Uphrod4wIwrsnL
 b/Fey9EEqYIbfGC0M2R9y1DlwWE2W0TIQ/ZYJSptTIK52BRroBucbIiy4ne+CbUzVDZsYLcHUI
 jP/+z61P6ALS5vPZjAAAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1527; i=iav@iav.lv;
 h=from:subject:message-id; bh=gqWYjjz0xRwzUadDg123AIW6B3N3BYaR8H5aIi6Ymss=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnXJjIKXTE26pG/dCvY67j7dRmrhfs/i4TzbTrct3yua
 I/1ioTnHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiAacYGRq+7Jc36d0uJfho
 TvPjvC/5dvMu+lTmaF/KDVVmvfH3z0SG//Vbzm33EYqv7Dlr5Tq91WXqRR6WnFnvZqzkf9swc51
 4CDMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PCF8563 on the OLED/RTC add-on board drives its interrupt output
to GPIOX_5, pin 4 of the P1 header, but the rtc node does not describe
it. The alarm interrupt is therefore never delivered and cannot wake
the board.

Describe the line as a level-low interrupt of the GPIO interrupt
controller.

Tested on ODROID-HC4: the alarm interrupt fires and wakes the board
from s2idle.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
This needs commit 5831f5fef100 ("rtc: pcf8563: pass the driver data to
the alarm interrupt handler") in the rtc tree: without it the first
alarm oopses. Waking from s2idle also needs commit 5b6e2a46b80d
("irqchip/meson-gpio: Allow the GPIO interrupts to wake the system")
in tip irq/drivers.
---
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
index 5f15c2299509..25a8a60e152c 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
@@ -105,6 +105,8 @@ rtc: rtc@51 {
 		status = "okay";
 		compatible = "nxp,pcf8563";
 		reg = <0x51>;
+		interrupt-parent = <&gpio_intc>;
+		interrupts = <IRQID_GPIOX_5 IRQ_TYPE_LEVEL_LOW>;
 		wakeup-source;
 	};
 };

---
base-commit: b44e2be772f866985cafdf90355285069ea68495
change-id: 20261020-hc4-rtc-alarm-irq-b2b8c68d54f5

Best regards,
-- 
Igor Velkov <iav@iav.lv>

