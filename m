From: Igor Velkov <iav@iav.lv>
Date: Tue, 06 Oct 2026 07:48:58 +0300
Subject: [PATCH] arm64: dts: rockchip: Add the fan tachometers to Kobol
 Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-helios64-fan-tach-v1-1-1c87e72d42b2@iav.lv>
X-B4-Tracking: v=1; b=H4sIALl9xGoC/x3MQQqAIBBA0avErBvQyVx0lWihNeZAWGhEEN09a
 fkW/z9QOAsXGJoHMl9SZE8Vum1gji6tjLJUAymyWimLkTfZizUYXMLTzRFp8WS87kirHmp3ZA5
 y/89xet8PxiNwOmMAAAA=
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2185; i=iav@iav.lv;
 h=from:subject:message-id; bh=UqldmxTMEF3J34R8VW6EVq9SH4TMYUR5K/t8pdza0BQ=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlHanenbA14+VvTLSX709oLufKqi4QL2zzLT2+9INujO
 XPmyZezO0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEuMQY/oqYdqsrn5zZyfWU
 +afFrQKxgtd/fevNxdIzeGrWMihqqDH8Zo9YYGChJHJtnVGn6ozQxDmVIQ8PLrH99l9nwtK5Jy0
 jWQE=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The tachometer outputs of both fan connectors reach the SoC through
open-drain buffers, on GPIO4_C5 for P7 and GPIO4_C7 for P6, but the fan
nodes do not describe them. pwm-fan therefore registers no fan1_input.

Describe each line as the fan's interrupt. The board pulls both lines
up, so configure the pins without internal bias.

Tested on 7.3-rc6: fan1_input reads 0 with the fans stopped and rises
with the duty cycle, to about 3500 rpm at full speed on both fans.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Schematic, sheets 30 and 36:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf
---
 arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index d146e5075b4f..63ad79b4c8ac 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -74,6 +74,10 @@ fan1 {
 		compatible = "pwm-fan";
 		pwms = <&pwm0 0 40000 0>;
 		cooling-levels = <0 80 170 255>;
+		interrupt-parent = <&gpio4>;
+		interrupts = <RK_PC5 IRQ_TYPE_EDGE_FALLING>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&fan1_sense>;
 	};
 
 	fan2 {
@@ -81,6 +85,10 @@ fan2 {
 		compatible = "pwm-fan";
 		pwms = <&pwm1 0 40000 0>;
 		cooling-levels = <0 80 170 255>;
+		interrupt-parent = <&gpio4>;
+		interrupts = <RK_PC7 IRQ_TYPE_EDGE_FALLING>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&fan2_sense>;
 	};
 
 	gpio-keys {
@@ -493,6 +501,16 @@ user1_btn: user1-btn {
 		};
 	};
 
+	fan {
+		fan1_sense: fan1-sense {
+			rockchip,pins = <4 RK_PC5 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		fan2_sense: fan2-sense {
+			rockchip,pins = <4 RK_PC7 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
 	gmac {
 		gphy_reset: gphy-reset {
 			rockchip,pins = <3 RK_PB7 RK_FUNC_GPIO &pcfg_output_low>;

---
base-commit: 1892b1ccccb9d546903ad6a61ffb9e388acdec80
change-id: 20261006-helios64-fan-tach-2db24b132105

Best regards,
-- 
Igor Velkov <iav@iav.lv>

