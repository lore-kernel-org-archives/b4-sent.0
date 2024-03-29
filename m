From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Fri, 29 Mar 2024 17:17:15 +0800
Subject: [PATCH 3/3] arm64: dts: amlogic: add reset controller for Amlogic
 T7 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240329-t7-reset-v1-3-4c6e2e68359e@amlogic.com>
References: <20240329-t7-reset-v1-0-4c6e2e68359e@amlogic.com>
In-Reply-To: <20240329-t7-reset-v1-0-4c6e2e68359e@amlogic.com>
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zelong Dong <zelong.dong@amlogic.com>, 
 Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711703853; l=1108;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=nQ6i4onLrotYFoJPFCF0uK2+BCj3hGBC1C42Lz/v9h4=;
 b=Jaw99hNZQkkHxQBjC35M3u7xduE2mi1d6p+mbAr75eUopJQwluSwKkTVhFrdm2MgKnxJglndn
 fc86fr2K0poCv4GnbrE3ablxTtxcKSl1DfbTwZmXw38Wpr62LNNX5tb
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zelong Dong <zelong.dong@amlogic.com>

Add the reset controller device of Amlogic T7 SoC family

Signed-off-by: Zelong Dong <zelong.dong@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index 5248bdf824ea..e94bb85b5292 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -5,6 +5,7 @@
 
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/power/amlogic,t7-pwrc.h>
+#include <dt-bindings/reset/amlogic,t7-reset.h>
 
 / {
 	interrupt-parent = <&gic>;
@@ -149,6 +150,12 @@ apb4: bus@fe000000 {
 			#size-cells = <2>;
 			ranges = <0x0 0x0 0x0 0xfe000000 0x0 0x480000>;
 
+			reset: reset-controller@2000 {
+				compatible = "amlogic,t7-reset";
+				reg = <0x0 0x2000 0x0 0x98>;
+				#reset-cells = <1>;
+			};
+
 			watchdog@2100 {
 				compatible = "amlogic,t7-wdt";
 				reg = <0x0 0x2100 0x0 0x10>;

-- 
2.37.1

