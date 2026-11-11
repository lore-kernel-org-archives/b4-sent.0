From: Mizuno Miotsuki <founder@crepuse.com>
To: heiko@sntech.de
Cc: broonie@kernel.org, conor+dt@kernel.org, devicetree@vger.kernel.org, 
 krzk+dt@kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-sound@vger.kernel.org, luca.ceresoli@bootlin.com, robh@kernel.org
Subject: [PATCH v2 RESEND 1/1] arm64: dts: rockchip: Enable audio on
 DFRobot UNIHIKER M10 V1.2
Date: Wed, 11 Nov 2026 12:14:34 +0000
Message-ID: <179439927464.86676.4421939132317972846.audio-v2-resend-1@crepuse.com>
In-Reply-To: <179439927463.86676.9537625579963969157.audio-v2-resend-0@crepuse.com>
References: <179439927463.86676.9537625579963969157.audio-v2-resend-0@crepuse.com>
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
Content-Type: text/plain; charset="utf-8"
X-Developer-Signature: v=1; a=openpgp-sha256; l=2172; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=xlzLLRAxNlPSYq2hZGjl4gVBzWPQJrF0KJ1HKORoHvI=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFlfYrRWp7M7Bbz8FX1Y9Of1eUeDDNKyq5buPKV+jX9p7
 JnaaXvtOyayMIhxMViKKbLMFmUvP9S84trcCU12MHNYmUCGSIs0MAABCwNfbmJeqZGOkZ6ptqGe
 oZGOgY4xAxenAEx17ilGhoaAyctLXF/v3VAs3eeY+vlTd+meF4lN3RWzBPtijPNOCDMynHNq3fH
 8fZt/hvKOJstrk5jOrvrZbz2tXCLzxImQiTWyHAA=
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mizuno Miotsuki <founder@crepuse.com>

Enable the internal RK3308 codec and its I2S2 interface, and add a
simple-audio-card. Route the onboard microphone to MIC1 and supply it
from MICBIAS1, with the bias set to 85 percent of AVDD as used during
board bring-up.

The board does not expose a speaker interface, so no speaker routing
is added.

The board uses codec revision B. Support has been accepted in the ASoC
for-7.4 branch as commit 157f7cba77a9 ("ASoC: codecs: rk3308: add support
for codec revision B"). This is a runtime dependency; the DTS uses the
existing codec compatible and bindings.

Signed-off-by: Mizuno Miotsuki <founder@crepuse.com>
---
 .../dts/rockchip/rk3308-unihiker-m10-v1.2.dts | 30 +++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts b/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
index 270ea970c95a..7adef454ea89 100644
--- a/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
@@ -54,6 +54,26 @@ sdio_pwrseq: sdio-pwrseq {
 		reset-gpios = <&gpio0 RK_PA2 GPIO_ACTIVE_LOW>;
 	};
 
+	sound {
+		compatible = "simple-audio-card";
+		simple-audio-card,name = "UNIHIKER M10 RK3308 codec";
+		simple-audio-card,format = "i2s";
+		simple-audio-card,mclk-fs = <256>;
+		simple-audio-card,widgets =
+			"Microphone", "Internal Microphone";
+		simple-audio-card,routing =
+			"Internal Microphone", "MICBIAS1",
+			"MIC1", "Internal Microphone";
+
+		simple-audio-card,cpu {
+			sound-dai = <&i2s_8ch_2>;
+		};
+
+		simple-audio-card,codec {
+			sound-dai = <&codec>;
+		};
+	};
+
 	vcc_1v8: regulator-vcc-1v8 {
 		compatible = "regulator-fixed";
 		regulator-name = "vcc_1v8";
@@ -117,6 +137,11 @@ vdd_core: regulator-vdd-core {
 	};
 };
 
+&codec {
+	rockchip,micbias-avdd-percent = <85>;
+	status = "okay";
+};
+
 &cpu0 {
 	cpu-supply = <&vdd_core>;
 };
@@ -131,6 +156,11 @@ &emmc {
 	status = "okay";
 };
 
+&i2s_8ch_2 {
+	#sound-dai-cells = <0>;
+	status = "okay";
+};
+
 &io_domains {
 	vccio0-supply = <&vcc_io>;
 	vccio1-supply = <&vcc_io>;
-- 
2.56.0

