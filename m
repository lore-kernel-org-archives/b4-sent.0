From: Igor Velkov <iav@iav.lv>
Date: Sun, 18 Oct 2026 07:55:00 +0300
Subject: [PATCH 2/2] arm64: dts: rockchip: Label the fans on Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-helios64-fan-label-v1-2-69a3f96d4efa@iav.lv>
References: <20261018-helios64-fan-label-v1-0-69a3f96d4efa@iav.lv>
In-Reply-To: <20261018-helios64-fan-label-v1-0-69a3f96d4efa@iav.lv>
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1083; i=iav@iav.lv;
 h=from:subject:message-id; bh=8aw4Q5PUDH6ZuJvAmunt0x+2TojvBEPQhOMZdMQFsu4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlXAnWNvvozNJcwG/2IF53P377q+jN24+aDyi9OWF76Y
 VjwYd2DjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjARpxUM/9Q0si8d+u9uvkTq
 fGi3Y591yt/ohHMNGo0+tbafjjhqcDMybBVtdBKLYUk2kte+/jTVbEHY7alm522eTNvJp8i+KnE
 iMwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Name each fan after the header it plugs into, so that userspace can
tell the two apart through the hwmon label attribute.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 63ad79b4c8ac..a206827903e9 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -70,8 +70,8 @@ clkin_gmac: external-gmac-clock {
 	};
 
 	fan1 {
-		/* fan connected to P7 */
 		compatible = "pwm-fan";
+		label = "P7";
 		pwms = <&pwm0 0 40000 0>;
 		cooling-levels = <0 80 170 255>;
 		interrupt-parent = <&gpio4>;
@@ -81,8 +81,8 @@ fan1 {
 	};
 
 	fan2 {
-		/* fan connected to P6 */
 		compatible = "pwm-fan";
+		label = "P6";
 		pwms = <&pwm1 0 40000 0>;
 		cooling-levels = <0 80 170 255>;
 		interrupt-parent = <&gpio4>;

-- 
2.43.0

