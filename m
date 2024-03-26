From: Folker Schwesinger <dev@folker-schwesinger.de>
Date: Tue, 26 Mar 2024 19:54:35 +0100
Subject: [PATCH 1/3] phy: rockchip: emmc: Enable pulldown for strobe line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240326-rk-default-enable-strobe-pulldown-v1-1-f410c71605c0@folker-schwesinger.de>
References: <20240326-rk-default-enable-strobe-pulldown-v1-0-f410c71605c0@folker-schwesinger.de>
In-Reply-To: <20240326-rk-default-enable-strobe-pulldown-v1-0-f410c71605c0@folker-schwesinger.de>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Chris Ruehl <chris.ruehl@gtsys.com.hk>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Christopher Obbard <chris.obbard@collabora.com>, 
 Alban Browaeys <alban.browaeys@gmail.com>, 
 Doug Anderson <dianders@chromium.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Jensen Huang <jensenhuang@friendlyarm.com>, linux-phy@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Folker Schwesinger <dev@folker-schwesinger.de>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2253;
 i=dev@folker-schwesinger.de; h=from:subject:message-id;
 bh=vn1WaogVqkovnF++lKXXa6btFkOAZlcxkgTSF4vHKKI=;
 b=owGbwMvMwCXG5FBoZNu1u5bxtFoSQxqz1ESGm1xxESWPdL0nBP77tEF529PKYs66r0ez70y8w
 2eS2Tm5o5SFQYyLQVZMkYU1L2MLc2b5Uuuun69h5rAygQ3h4hSAibCEMfwVOiHs8frNmQnzo1mu
 GdVGya19sFMoZ+G78y36Xp3W6h5fGRnaD1XFVlhoO08onHh787XvZ+ad11Ko0L/3/tkVv8uFT66
 zAQA=
X-Developer-Key: i=dev@folker-schwesinger.de; a=openpgp;
 fpr=056E68B4036977A53B8AF9EB024071323D8ABB7D
X-Endpoint-Received: by B4 Relay for dev@folker-schwesinger.de/default with auth_id=144
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Restore the behavior of the Rockchip kernel that undconditionally
enables the internal strobe pulldown.
As the DT property rockchip,enable-strobe-pulldown is obsolete now,
replace it with a property to disable the internal pulldown.

This fixes I/O errors observed on various Rock Pi 4 and NanoPi4 series
boards with some eMMC modules. Other boards may also be affected.

An example of these errors is as follows:

[  290.060817] mmc1: running CQE recovery
[  290.061337] blk_update_request: I/O error, dev mmcblk1, sector 1411072 op 0x1:(WRITE) flags 0x800 phys_seg 36 prio class 0
[  290.061370] EXT4-fs warning (device mmcblk1p1): ext4_end_bio:348: I/O error 10 writing to inode 29547 starting block 176466)
[  290.061484] Buffer I/O error on device mmcblk1p1, logical block 172288

Fixes: 8b5c2b45b8f0 ("phy: rockchip: set pulldown for strobe line in dts")
Signed-off-by: Folker Schwesinger <dev@folker-schwesinger.de>
---
 drivers/phy/rockchip/phy-rockchip-emmc.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-emmc.c b/drivers/phy/rockchip/phy-rockchip-emmc.c
index 20023f6eb994..6e637f3e1b19 100644
--- a/drivers/phy/rockchip/phy-rockchip-emmc.c
+++ b/drivers/phy/rockchip/phy-rockchip-emmc.c
@@ -376,14 +376,14 @@ static int rockchip_emmc_phy_probe(struct platform_device *pdev)
 	rk_phy->reg_offset = reg_offset;
 	rk_phy->reg_base = grf;
 	rk_phy->drive_impedance = PHYCTRL_DR_50OHM;
-	rk_phy->enable_strobe_pulldown = PHYCTRL_REN_STRB_DISABLE;
+	rk_phy->enable_strobe_pulldown = PHYCTRL_REN_STRB_ENABLE;
 	rk_phy->output_tapdelay_select = PHYCTRL_OTAPDLYSEL_DEFAULT;
 
 	if (!of_property_read_u32(dev->of_node, "drive-impedance-ohm", &val))
 		rk_phy->drive_impedance = convert_drive_impedance_ohm(pdev, val);
 
-	if (of_property_read_bool(dev->of_node, "rockchip,enable-strobe-pulldown"))
-		rk_phy->enable_strobe_pulldown = PHYCTRL_REN_STRB_ENABLE;
+	if (of_property_read_bool(dev->of_node, "rockchip,disable-strobe-pulldown"))
+		rk_phy->enable_strobe_pulldown = PHYCTRL_REN_STRB_DISABLE;
 
 	if (!of_property_read_u32(dev->of_node, "rockchip,output-tapdelay-select", &val)) {
 		if (val <= PHYCTRL_OTAPDLYSEL_MAXVALUE)

-- 
2.44.0

