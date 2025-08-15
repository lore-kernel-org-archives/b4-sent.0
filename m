From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 15 Aug 2025 16:37:33 +0800
Subject: [PATCH 07/13] ARM: dts: amlogic: Unify the compatible property for
 clk-measure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-add-more-socs-to-support-clk_measure-v1-7-59f04ba67457@amlogic.com>
References: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
In-Reply-To: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755247057; l=1245;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=ogLhza13Z3+sRdNuog3wi18IBAswOBl0lnCwSfN1OrY=;
 b=I/pWu4T97rWRApNMfafG00zPnjp6BitC2JwcExuQmhW9xDCyeJcyQ2yhM37tCrDcoUd2rnXUb
 fGhA362SrvHB/Xc4jqb9tkx1TFny57iIjqx6o3+bwhiHTlcLanyy9i6
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clk-measure IPs across Amlogic SoCs have minimal differences, so
they can be managed with a unified compatible property.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 arch/arm/boot/dts/amlogic/meson8.dtsi  | 2 +-
 arch/arm/boot/dts/amlogic/meson8b.dtsi | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm/boot/dts/amlogic/meson8.dtsi b/arch/arm/boot/dts/amlogic/meson8.dtsi
index 2f9ecd2eb4cf..db47e1de0b20 100644
--- a/arch/arm/boot/dts/amlogic/meson8.dtsi
+++ b/arch/arm/boot/dts/amlogic/meson8.dtsi
@@ -460,7 +460,7 @@ pwm_ef: pwm@86c0 {
 	};
 
 	clock-measure@8758 {
-		compatible = "amlogic,meson8-clk-measure";
+		compatible = "amlogic,clk-measure";
 		reg = <0x8758 0x1c>;
 		clkmsr-indices = <0>,
 				 <1>,
diff --git a/arch/arm/boot/dts/amlogic/meson8b.dtsi b/arch/arm/boot/dts/amlogic/meson8b.dtsi
index 74fd000569a2..3b1d2d2ad7a2 100644
--- a/arch/arm/boot/dts/amlogic/meson8b.dtsi
+++ b/arch/arm/boot/dts/amlogic/meson8b.dtsi
@@ -414,7 +414,7 @@ pwm_ef: pwm@86c0 {
 	};
 
 	clock-measure@8758 {
-		compatible = "amlogic,meson8b-clk-measure";
+		compatible = "amlogic,clk-measure";
 		reg = <0x8758 0x1c>;
 		clkmsr-indices = <0>,
 				 <1>,

-- 
2.42.0

