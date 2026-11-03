From: Igor Velkov <iav@iav.lv>
Date: Tue, 03 Nov 2026 06:12:10 +0000
Subject: [PATCH] arm64: dts: rockchip: Enable SD UHS-I modes on ROCK Pi 4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-rockpi4-sd-uhs-v1-1-fa394d2046e1@iav.lv>
X-B4-Tracking: v=1; b=H4sIADl76WoC/x3MMQqAMAxA0auUzAZM1QpeRRykRhuEKg2KULy7x
 fEN/2dQTsIKg8mQ+BaVIxZQZcCHOW6MshSDra0jqhtMh99PaVEXvIJix448sV9d30KJzsSrPP9
 wnN73A0g3Bx1gAAAA
To: Heiko Stuebner <heiko@sntech.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2365; i=iav@iav.lv;
 h=from:subject:message-id; bh=az5m2/WqrCJ/+LWcDbyXHuHBZoPgNzj0Wuk5JL5JV+Q=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkvq61Wa6jZcBwxnsSReEeXM+R2AMdDY4XN5v1hgZP4W
 TtjJ7zqKGVhEONikBVTZJlwSONWxpKrf/09zB/AzGFlAhnCwMUpABPJ/8vwVyK5nP38C3nbF7cd
 g6OCWgqVjzNzuhZxqF6985JffvP8UEaGZqu9q/eGewl3cCT3PdWeLemz/F192n4lmduCdi93vsl
 iBwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SD I/O supply vcc_sdio (RK808 LDO4) is pinned at 3.0 V, so the
card stays in high-speed mode at 50 MHz. Let dw_mmc switch it to 1.8 V
and enable SDR12 to SDR104.

The card supply is not switchable, so after a watchdog reset or a
panic the card and vcc_sdio are still at 1.8 V. Linux and U-Boot proper
boot from the card in that state; U-Boot SPL loading from it has to set
the SD I/O domain from vcc_sdio, as it does on NanoPi 4 since U-Boot
commit 210ab4f60df8.

On ROCK Pi 4A with a SanDisk 256 GB U3 card: SDR104 at 148.5 MHz,
direct read 64-67 MB/s instead of 23.5 MB/s.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ROCK Pi 4A: v7.3.1 with this change, 3 cold boots in SDR104;
the Armbian 7.3 kernel with the same change through reboot, panic,
watchdog reset, s2idle and hibernate, SDR104 each time. Not tested on
the other boards that include rk3399-rock-pi-4.dtsi (4A+, 4B, 4B+, 4C,
4SE).

With PCIE_ROCKCHIP_HOST=y and an empty PCIe slot, tuning also needs
https://lore.kernel.org/r/20261103-rockchip-pcie-async-v1-1-4dcadb94af64@iav.lv
The SPL side for U-Boot on the SD card:
https://lore.kernel.org/r/20261103-b4-rock-pi-4-spl-iodomain-v1-1-8dfc34a5e2e2@iav.lv
---
 arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi b/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi
index 52de4a79e2f4..3de1d14529c1 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi
@@ -356,7 +356,7 @@ vcc_sdio: LDO_REG4 {
 				regulator-name = "vcc_sdio";
 				regulator-always-on;
 				regulator-boot-on;
-				regulator-min-microvolt = <3000000>;
+				regulator-min-microvolt = <1800000>;
 				regulator-max-microvolt = <3000000>;
 				regulator-state-mem {
 					regulator-on-in-suspend;
@@ -696,6 +696,11 @@ &sdmmc {
 	max-frequency = <150000000>;
 	pinctrl-names = "default";
 	pinctrl-0 = <&sdmmc_clk &sdmmc_cd &sdmmc_cmd &sdmmc_bus4>;
+	sd-uhs-sdr12;
+	sd-uhs-sdr25;
+	sd-uhs-sdr50;
+	sd-uhs-sdr104;
+	vqmmc-supply = <&vcc_sdio>;
 	status = "okay";
 };
 

---
base-commit: 2974b78ee4302390eceb5f5983c00b3d66fc3c78
change-id: 20261103-rockpi4-sd-uhs-5e61c1ecf674

Best regards,
-- 
Igor Velkov <iav@iav.lv>

