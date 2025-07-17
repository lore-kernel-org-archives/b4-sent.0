From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 17 Jul 2025 17:38:38 +0800
Subject: [PATCH 2/2] arm64: dts: amlogic: C3: Add RTC controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250717-rtc-c3-node-v1-2-4f9ae059b8e6@amlogic.com>
References: <20250717-rtc-c3-node-v1-0-4f9ae059b8e6@amlogic.com>
In-Reply-To: <20250717-rtc-c3-node-v1-0-4f9ae059b8e6@amlogic.com>
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752745121; l=1224;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=oDscrQnwBWleM1lKXYkem+gVGQrkocRvej4i/VO/Lqk=;
 b=7H03TvHXdNylCWXWrMbEeTI+1PGuh2L1B8KhKOjjIqk3FuLzkDI3KcY81WNs5ECGqlqxiWdfV
 +2Dzk3/7U5AD+mOxUE1rQSUSR9ra0skTfhMbvFoRVyJMmhsKAMqGKaL
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the RTC controller node for C3 SoC family.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
index cb9ea3ca6ee0..b81bffac7732 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
@@ -53,6 +53,13 @@ xtal: xtal-clk {
 		#clock-cells = <0>;
 	};
 
+	xtal_32k: xtal-clk-32k {
+		compatible = "fixed-clock";
+		clock-frequency = <32768>;
+		clock-output-names = "xtal_32k";
+		#clock-cells = <0>;
+	};
+
 	sm: secure-monitor {
 		compatible = "amlogic,meson-gxbb-sm";
 
@@ -967,6 +974,15 @@ nand: nand-controller@8d000 {
 				clock-names = "core", "device";
 				status = "disabled";
 			};
+
+			rtc@9a000 {
+				compatible = "amlogic,c3-rtc",
+					     "amlogic,a5-rtc";
+				reg = <0x0 0x9a000 0x0 0x38>;
+				interrupts = <GIC_SPI 131 IRQ_TYPE_EDGE_RISING>;
+				clocks = <&xtal_32k>, <&clkc_periphs CLKID_SYS_RTC>;
+				clock-names = "osc", "sys";
+			};
 		};
 
 		ethmac: ethernet@fdc00000 {

-- 
2.37.1

