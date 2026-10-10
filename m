From: Igor Velkov <iav@iav.lv>
Date: Sun, 11 Oct 2026 00:52:37 +0300
Subject: [PATCH] arm64: dts: rockchip: Enable HS400 enhanced strobe on
 Kobol Helios64 eMMC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-helios64-emmc-hs400-v1-1-36951d319229@iav.lv>
X-B4-Tracking: v=1; b=H4sIAKWzymoC/x3MSQqAMAxA0atI1gZareNVxIW20QacaECE4t0tL
 t/i/whCgUmgzyIEuln4PBJ0noH107ESskuGQhW1VlrjbNDTxqfUBmnfLXoxSmFnm9YsZeVa5yD
 FV6CFn388jO/7AYMeeiVoAAAA
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1561; i=iav@iav.lv;
 h=from:subject:message-id; bh=aUbqlnQGl5qV5hXARJBMfnnwJzS8qvfPcSClzVZ69Co=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmnNq881tJuwHt9EyfLvruOpdqcDfvdVeuiflXl/ktc8
 2rFQi+DjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRbfcY/gquX/Z359py5Ymr
 5X72q/Mvij4WlXK9+NzhgFV/zoisFTnC8D9W/unuafM1JZ4u7lc8aLNuWhVnouzOq8tPqN5vvhk
 izskCAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The eMMC of Helios64 runs in HS200. Run it in HS400 enhanced strobe at
150 MHz, as on Gru. The strobe line goes straight from the SoC to the
DS pin of the eMMC with no pull-down on the board, so enable the one
in the eMMC PHY.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Schematic, sheet 14:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf

Tested on mainline with three 2 GiB write and read-back passes, no
errors. Raw reads go from 180 MB/s in HS200 to 247 MB/s. Without the
pull-down, writes dropped to about 1 MB/s with repeated
"mmc1: running CQE recovery".
---
 arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 63ad79b4c8ac..f78482c4c285 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -320,6 +320,7 @@ &cpu_l3 {
 };
 
 &emmc_phy {
+	rockchip,enable-strobe-pulldown;
 	status = "okay";
 };
 
@@ -586,8 +587,11 @@ &saradc {
 };
 
 &sdhci {
+	assigned-clock-rates = <150000000>;
 	bus-width = <8>;
 	mmc-hs200-1_8v;
+	mmc-hs400-1_8v;
+	mmc-hs400-enhanced-strobe;
 	non-removable;
 	vqmmc-supply = <&vcc1v8_sys_s0>;
 	status = "okay";

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261011-b4-helios64-emmc-hs400-9c784f35d8dd

Best regards,
-- 
Igor Velkov <iav@iav.lv>

