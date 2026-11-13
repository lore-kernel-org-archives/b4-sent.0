From: Igor Velkov <iav@iav.lv>
Date: Fri, 13 Nov 2026 21:20:52 +0000
Subject: [PATCH v2] arm64: dts: rockchip: Enable SDR104 on the ODROID-M1 SD
 card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-odroid-m1-sdr104-v2-1-1a1611fc4cbf@iav.lv>
X-B4-Tracking: v=1; b=H4sIADN/92oC/32NQQrCMBBFr1Jm7Uim2qCuvId0ETMTO6CNJBKUk
 rsbewCX78F/f4EsSSXDqVsgSdGscW7Qbzrwk5tvgsqNoTe9JSKDkVNUxgdh5kRmj8GK2TnjB+e
 P0GbPJEHfa/IyNp40v2L6rA+FfvZPrBASHoS95cHTNdizurK9FxhrrV/+6JtbrQAAAA==
To: Heiko Stuebner <heiko@sntech.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1891; i=iav@iav.lv;
 h=from:subject:message-id; bh=bk0BmaYleLaidbW/Gg6PAAPuKLMUdjp+ycVXNHy1qDY=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnf661D3W8Knv7y4OkXxgllDB5KF5w5Nfe8Ut/syHut+
 tCmqSf+dpSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJXN3OyPBk1Q+t2JRfh3+l
 Z8RObd12tfDEFo59BT9Z/rJc9796zXU+w2/Wxy2bNu3jbbPr8WuYL7hqifq3Y3ZOscFLth86IjQ
 n2Z0PAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SD card already switches to 1.8 V, but only SDR50 is described, and
clk_sdmmc0 on RK3568 is a mux without a divider: dw_mmc-rockchip asks
it for twice the card clock, 200 MHz for SDR50, the mux rounds down to
the 100 MHz parent and the card runs at 50 MHz.

Describe SDR104 as well. With the 150 MHz max-frequency from
rk356x-base.dtsi the clock comes from the 300 MHz parent and the card
runs at 150 MHz. Hardkernel's vendor kernel already uses sd-uhs-sdr104
on this board. With a SanDisk 128 GB card, direct read goes from
22 MB/s to 58-64 MB/s and direct write from 20 MB/s to 47-50 MB/s.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested with an Armbian 7.3.3 kernel (rockchip64), the property added to
the DTB with fdtput: reboot, sysrq-b, watchdog reset, poweroff, s2idle,
deep, hibernate, hybrid-sleep and suspend-then-hibernate; the card
re-tuned and came back in SDR104 at 150 MHz in all 29 runs.
---
Changes in v2:
- keep sd-uhs-sdr50 next to sd-uhs-sdr104 (Heiko)
- rebased on for-next
- Link to v1: https://lore.kernel.org/r/20261110-odroid-m1-sdr104-v1-1-8edc6d5c1bf6@iav.lv
---
 arch/arm64/boot/dts/rockchip/rk3568-odroid-m1.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-odroid-m1.dts b/arch/arm64/boot/dts/rockchip/rk3568-odroid-m1.dts
index ec43dee18094..27793d3970d2 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-odroid-m1.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3568-odroid-m1.dts
@@ -611,6 +611,7 @@ &sdmmc0 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&sdmmc0_bus4 &sdmmc0_clk &sdmmc0_cmd &sdmmc0_det>;
 	sd-uhs-sdr50;
+	sd-uhs-sdr104;
 	vmmc-supply = <&vcc3v3_sd>;
 	vqmmc-supply = <&vccio_sd>;
 	status = "okay";

---
base-commit: a9d78db32fe78bdbe7c66ba77cb7dbb729b885de
change-id: 20261110-odroid-m1-sdr104-f6e03a0c5ac9

Best regards,
-- 
Igor Velkov <iav@iav.lv>

