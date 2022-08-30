From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Tue, 30 Aug 2022 09:31:29 -0400
Subject: [PATCH RESEND v3 4/4] arm64: dts: allwinner: beelink-gs1: Enable GPU OPP
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v3-4-736c986dd55c@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v3-0-736c986dd55c@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v3-0-736c986dd55c@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-bfc54
X-Developer-Signature: v=1; a=openpgp-sha256; l=885;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=xkdZAo9EUXpwkS8ZmWG+ExWrVSGxyOFYAdb09oPGkjU=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJL5BPVeui52tMi0C2T5/PBh3WO/R0d3fLvyXvvU1axpe+tm
 3ZqyuKOUhUGMi0FWTJGlbF/spqDChx5y6T2mMHNYmUCGMHBxCsBEGnIZGW4Us5x+k1kj6tJgPrurmP
 tX9b/5rNLymzsPsAg8szp89RLD/8j9rs9rZCeynrP63LBiUZTIHea4ax6q13aEuTtP3JY1lR0A
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
b4 0.10.0-dev-bfc54
