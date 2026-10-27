From: Igor Velkov <iav@iav.lv>
Date: Tue, 27 Oct 2026 02:20:40 +0200
Subject: [PATCH] arm64: dts: rockchip: Add the watchdog reset to RK3399
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-rk3399-wdt-reset-v1-1-de9615abb0ec@iav.lv>
X-B4-Tracking: v=1; b=H4sIAFfu32oC/x3MSwqAMAwA0atI1gaaFj/1KuJCbNQgqKSignh3i
 8u3mHkgsgpHaLIHlE+Jsq0JlGcwzP06MUpIBmtsScZWqItz3uMVDlSOfOBQ1MESUWl8gJTtyqP
 c/7Lt3vcDe+b2R2IAAAA=
To: Heiko Stuebner <heiko@sntech.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Artem Shimko <a.shimko.dev@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1530; i=iav@iav.lv;
 h=from:subject:message-id; bh=YfZXV/pwUDuzE4RfqVS8zgmubems4bbmhrrE9YcpAwk=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFn330We1c2qfCG7W7WJIXnL8s+XeMrZffpP7bbrWNY0u
 6tuYqhfRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZhI9kyGv8K3etbdMbWcum1V
 8P8zlvO3iarF3nyiIG22Q626KPLUd2eG/6UXO0sXHZkaOKPcrEHV3oWv98XP52uvr7+wyvlWyyr
 ZTwwA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3399 watchdog at 0xff848000 is reset by SRST_P_WDT0 (bit 5 of
CRU_SOFTRST_CON20), but its node has no resets property. Its clock is
gated from SECURE_GRF_SOC_CON3[8], out of reach for Linux, so without
the reset dw_wdt_stop() can only set WDOG_HW_RUNNING and the watchdog
keeps counting through s2idle: on a Kobol Helios64 and a ROCK Pi 4A,
s2idle longer than the watchdog timeout ends in a watchdog reset.

With the reset line dw_wdt_stop() can stop the watchdog, and with
"watchdog: dw_wdt: manage reset line during system suspend/resume" the
driver holds it in reset while the system sleeps.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
The dw_wdt side is applied in the watchdog tree:
https://lore.kernel.org/r/20261024140854.25664-3-a.shimko.dev@gmail.com
---
 arch/arm64/boot/dts/rockchip/rk3399-base.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3399-base.dtsi
index c46e58d4af0d..7b71b24c1f51 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3399-base.dtsi
@@ -1748,6 +1748,7 @@ watchdog@ff848000 {
 		reg = <0x0 0xff848000 0x0 0x100>;
 		clocks = <&cru PCLK_WDT>;
 		interrupts = <GIC_SPI 120 IRQ_TYPE_LEVEL_HIGH 0>;
+		resets = <&cru SRST_P_WDT0>;
 	};
 
 	rktimer: rktimer@ff850000 {

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261027-rk3399-wdt-reset-c58d2111609d

Best regards,
-- 
Igor Velkov <iav@iav.lv>

