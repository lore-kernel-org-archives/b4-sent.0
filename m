From: Ivan Pfarher <ipfarher@gmail.com>
Date: Fri, 20 Nov 2026 12:40:45 +0100
Subject: [PATCH 1/4] arm64: dts: allwinner: h5: orangepi-zero-plus2: Add
 LPO clock for AP6212
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-orangepi-zero-plus2-fixes-v1-1-ecd792189f27@gmail.com>
References: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
In-Reply-To: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, Ivan Pfarher <ipfarher@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174845; l=2115;
 i=ipfarher@gmail.com; s=20261120; h=from:subject:message-id;
 bh=7KEtdKj9IY+64J+dCjZb1N3Us47orLdmi9i9eYZWsuM=;
 b=SOxTVC1DYhuLVEV7n+Im/3RiM9ou+VEHmEJgGfO8FSkz+Qz6pLswSgdzCSEG8p+bdVtsJUhhg
 We9IBq70qemCUoxa7CgvszjvEU/6ECL/sz79h+0mCFhVGJuWuuwmOTt
X-Developer-Key: i=ipfarher@gmail.com; a=ed25519;
 pk=3DMYyz/xl+KRAx2TNGJpheG+5QUm7lqHhKXFqVu2TmY=
X-Endpoint-Received: by B4 Relay for ipfarher@gmail.com/20261120 with auth_id=1582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AP6212 WiFi/BT module needs a 32.768 kHz low power oscillator (LPO)
clock, which on this board comes from the RTC clock output (osc32k-out).
Nothing in the device tree references that clock, so it is disabled as
unused during late boot.

WiFi keeps working without it, but the Bluetooth core does not: with the
LPO gated, the BCM43430A1 ROM answers HCI_Reset and nothing else (no
Read Local Version, no firmware download), so the controller can never
be brought up. Turning the clock output on by hand (RTC LOSC_OUT_GATING)
makes the controller answer normally.

Reference the clock from the WiFi power sequence, as other boards using
the same module do (e.g. sun8i-h2-plus-bananapi-m2-zero.dts).

Tested on an Orange Pi Zero Plus2 (H5) running Linux 6.6.160 with this
change applied: osc32k-out stays enabled and the Bluetooth controller
answers HCI commands. Build-tested only against current mainline.

This problem was investigated, and the patch drafted, in an interactive
session with an AI coding assistant (Claude by Anthropic). The submitter
reviewed the change and ran the tests described above.

Fixes: cf8e19e1ec15 ("arm64: dts: orange-pi-zero-plus2: enable AP6212a WiFi/BT combo")
Signed-off-by: Ivan Pfarher <ipfarher@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
index 3eb986c35..34d6c1468 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
@@ -5,6 +5,7 @@
 
 #include "sun50i-h5.dtsi"
 
+#include <dt-bindings/clock/sun6i-rtc.h>
 #include <dt-bindings/gpio/gpio.h>
 
 / {
@@ -54,6 +55,8 @@
 
 	wifi_pwrseq: pwrseq {
 		compatible = "mmc-pwrseq-simple";
+		clocks = <&rtc CLK_OSC32K_FANOUT>;
+		clock-names = "ext_clock";
 		reset-gpios = <&pio 0 9 GPIO_ACTIVE_LOW>; /* PA9 */
 		post-power-on-delay-ms = <200>;
 	};

-- 
2.43.0

