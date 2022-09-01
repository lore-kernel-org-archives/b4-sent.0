From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:41:43 -0400
Subject: [PATCH RESEND v7 4/4] arm64: dts: allwinner: beelink-gs1: Enable GPU OPP
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v7-4-43f6566c433f@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v7-0-43f6566c433f@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v7-0-43f6566c433f@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=885;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=+4PeqXvmiQMAgNX0YMY7tdA6RYPPnuoh6fGFpKEiMII=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIFuX7t4dqZz//mwuLVTKc/tapxf2JVXHbws2WD259Pbg63
 7IwdO0pZGMS4GGTFFFnK9sVuCip86CGX3mMKM4eVCWQIAxenAEzkUhvDP+PKnJhQ+U0vuvtvvjUqeq
 Jwrm/F07qpZ+ViSi6dnjxzvyIjw/LXTw96Pt23+ssj60qHqKIZFjwaVRriT3InMe0Pn1pZyAIA
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
b4 0.10.0-dev-03aea
