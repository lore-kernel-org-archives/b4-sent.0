From: Janne Grunau <j@jannau.net>
Date: Tue, 03 Dec 2024 08:57:57 +0100
Subject: [PATCH v2 1/5] arm64: dts: apple: t8103: Fix spi4 power domain
 sort order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-asahi-spi-dt-v2-1-cd68bfaf0c84@jannau.net>
References: <20241203-asahi-spi-dt-v2-0-cd68bfaf0c84@jannau.net>
In-Reply-To: <20241203-asahi-spi-dt-v2-0-cd68bfaf0c84@jannau.net>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1498; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=9ueUveKszfxawJ0HmIK5r7NU/tiqsgQwLWeRgQUwJgA=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnS/XVzVerG/X+kfvlZww+imQce2syrbvpnIbtvpz56tZ
 vDJ+VB0RykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIlYSDIyHPl49dl3Zm+x2wZi
 F805WX4WfJtdxqR3LNIvlq1wkur2JEaGc9fKjx5hnDRx69rqxinMh1dsCmZbx+YgNvU3u8+FXav
 /sgEA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Neal Gompa <neal@gompa.dev>
---
 arch/arm64/boot/dts/apple/t8103-pmgr.dtsi | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi b/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
index 9645861a858c1a7c46c25a614c2cc4b03083bf46..c41c57d63997a59a9fe3c88de31fddb31781398e 100644
--- a/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
@@ -387,6 +387,15 @@ ps_spi3: power-controller@258 {
 		power-domains = <&ps_sio>, <&ps_spi_p>;
 	};
 
+	ps_spi4: power-controller@260 {
+		compatible = "apple,t8103-pmgr-pwrstate", "apple,pmgr-pwrstate";
+		reg = <0x260 4>;
+		#power-domain-cells = <0>;
+		#reset-cells = <0>;
+		label = "spi4";
+		power-domains = <&ps_sio>, <&ps_spi_p>;
+	};
+
 	ps_uart_n: power-controller@268 {
 		compatible = "apple,t8103-pmgr-pwrstate", "apple,pmgr-pwrstate";
 		reg = <0x268 4>;
@@ -558,15 +567,6 @@ ps_mcc: power-controller@2f8 {
 		apple,always-on; /* Memory controller */
 	};
 
-	ps_spi4: power-controller@260 {
-		compatible = "apple,t8103-pmgr-pwrstate", "apple,pmgr-pwrstate";
-		reg = <0x260 4>;
-		#power-domain-cells = <0>;
-		#reset-cells = <0>;
-		label = "spi4";
-		power-domains = <&ps_sio>, <&ps_spi_p>;
-	};
-
 	ps_dcs0: power-controller@300 {
 		compatible = "apple,t8103-pmgr-pwrstate", "apple,pmgr-pwrstate";
 		reg = <0x300 4>;

-- 
2.47.0

