From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Wed, 31 Aug 2022 17:34:49 -0400
Subject: [PATCH RESEND v7 4/4] arm64: dts: allwinner: beelink-gs1: Enable GPU OPP
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v7-4-4f04b9e94ea1@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v7-0-4f04b9e94ea1@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v7-0-4f04b9e94ea1@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-3b344
X-Developer-Signature: v=1; a=openpgp-sha256; l=885;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=gGf/982jiMg3/fzMo6cAgv3/WJ/79H5Y3MSHSUh8eTo=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJL5L/8JNBHZIC+wQiiv1W32pY91Pb7/rta5Bu7q3/L1V0DA
 wnNGHaUsDGJcDLJiiixl+2I3BRU+9JBL7zGFmcPKBDKEgYtTACbyo4qR4Y3SRY1Zp5WuGmTURTRvku
 pfWpm5NbQ6X8mh7mXZkT1N3xkZutMs/02bFL45RZ5HsvSxTgOznP9LdpsbS2Vsj23KOD6FFQA=
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
b4 0.10.0-dev-3b344
