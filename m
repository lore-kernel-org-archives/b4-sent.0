From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 10:31:33 -0400
Subject: [PATCH RESEND v7 4/4] arm64: dts: allwinner: beelink-gs1: Enable GPU OPP
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v7-4-821f03d2f76c@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v7-0-821f03d2f76c@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v7-0-821f03d2f76c@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-b62e0
X-Developer-Signature: v=1; a=openpgp-sha256; l=885;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=xoQ5vRXmVepjeENUuT622GH8vKmciFxGq7L4yk8xHKo=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIFDjmxcVjNE8tR3O1wU3HlrMk2+xtnKJh+qdzQEGPFcbLm
 yN4bHaUsDGJcDLJiiixl+2I3BRU+9JBL7zGFmcPKBDKEgYtTACZiE8/IsO4iy5V0RuGF5sHbBAU2NC
 1SNFjd5n8vWmNmpW/ohjOzdBj+V7fXuV05bC3MxOZ6IvICt+bsy+tPrXLmLFksov7Z/+p+JgA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Clément Péron <peron.clem@gmail.com>

Enable GPU OPP table for Beelink GS1

Signed-off-by: Clément Péron <peron.clem@gmail.com>
Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h6-beelink-gs1.dts b/arch/arm64/boot/dts/allwinner/sun50i-h6-beelink-gs1.dts
index 6249e9e02928..20fc0584d1c6 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h6-beelink-gs1.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h6-beelink-gs1.dts
@@ -5,6 +5,7 @@
 
 #include "sun50i-h6.dtsi"
 #include "sun50i-h6-cpu-opp.dtsi"
+#include "sun50i-h6-gpu-opp.dtsi"
 
 #include <dt-bindings/gpio/gpio.h>
 
@@ -261,6 +262,7 @@ reg_dcdca: dcdca {
 			};
 
 			reg_dcdcc: dcdcc {
+				regulator-always-on;
 				regulator-enable-ramp-delay = <32000>;
 				regulator-min-microvolt = <810000>;
 				regulator-max-microvolt = <1080000>;

-- 
b4 0.10.0-dev-b62e0
