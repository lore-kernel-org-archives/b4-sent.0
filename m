From: Igor Velkov <iav@iav.lv>
Date: Mon, 09 Nov 2026 03:45:58 +0000
Subject: [PATCH] arm64: dts: rockchip: Enable SDR104 on the Kobol Helios64
 SD card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-helios64-sd-uhs-v1-1-ef8fc370d282@iav.lv>
X-B4-Tracking: v=1; b=H4sIAPVB8WoC/x3MQQqAIBBA0avErBtIk8iuEi1CxxwIC4cikO6et
 HyL/wsIZSaBqSmQ6WbhI1WotgEX17QRsq8G3elBqc5ipJ0PGQyKxysKWqMNhV4F60ao1Zkp8PM
 f5+V9P9MS6/thAAAA
To: Heiko Stuebner <heiko@sntech.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2313; i=iav@iav.lv;
 h=from:subject:message-id; bh=dC7wpDaNbCjkiANOAYK+QKZwUz9weOXO+ehiRLkJWy0=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkfHX9I/uZ4N0sia0uS55ILh0VNsmYbVFUmHvgnJ2pys
 NVwqu3KjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRywEM/+OEa00n7HvzzvxX
 oMBxhck7s6OEUn5dXbKXy1lfkGv/tQcM/xRfRk9cMMnGicWyffGChzM+aQk0LZ1Q6dozrYBFImv
 TfSYA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SD card I/O supply vcc_sdio_s0 can switch between 1.8 V and 3.0 V and
is already described as vqmmc-supply and as the sdmmc I/O domain supply,
but the card only runs in high speed mode.

Allow SDR104. With a SanDisk 32 GB card it runs at 148.5 MHz, and direct
read goes from 23 MB/s to 53-66 MB/s.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on Helios64 with Linux 7.3, its device tree plus this property,
and the U-Boot and .config of Armbian, PCIe host driver not loaded: 15
warm reboots and 3 cold starts, SDR104 at 148.5 MHz each time, no SD
errors in dmesg, a written file read back with the same checksum. One
card only. Writes stay at about 11 MB/s.

Armbian kernels carry this property with PCIe enabled. In their console
logs tuning sometimes fails when it coincides with the PCIe probe, as on
ROCK Pi 4, and the retry reaches SDR104 every time. The cause is not
confirmed on this board; async probe, applied as
https://lore.kernel.org/r/20261103-rockchip-pcie-async-v1-1-4dcadb94af64@iav.lv
is not tested in this combination.

A normal reboot powers the card off, but after a watchdog reset or a
panic the card stays at 1.8 V. An SPL that does not set the SD I/O domain
from vcc_sdio_s0 then fails to read the card until a power cycle. Armbian's
U-Boot does this (such resets 8 of 8, on Armbian's DTB). The board is not
in mainline U-Boot yet; v2 of
https://lore.kernel.org/r/20261021-b4-helios64-v1-1-74afe8aa6d72@iav.lv
will carry it. Kobol's U-Boot is not checked.
---
 arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index f13ea2df7a30..35153e84f206 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -781,6 +781,7 @@ &sdmmc {
 	disable-wp;
 	pinctrl-names = "default";
 	pinctrl-0 = <&sdmmc_clk &sdmmc_cmd &sdmmc_cd &sdmmc_bus4>;
+	sd-uhs-sdr104;
 	vmmc-supply = <&vcc3v0_sd>;
 	vqmmc-supply = <&vcc_sdio_s0>;
 	status = "okay";

---
base-commit: c3baae5f1a15645cddadcb2b9abddef5df291f59
change-id: 20261109-helios64-sd-uhs-9424ef31f9c8

Best regards,
-- 
Igor Velkov <iav@iav.lv>

