From: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
Subject: [PATCH v3 0/3] usb/phy: sunxi: Assert reset before deasserting on
 init
Date: Wed, 25 Nov 2026 14:11:15 +0000
Message-Id: <20261125-usb-sunxi-reset-fix-v3-0-855c43694f78@roadbobek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NzQ7CIBAGX8VwFsNSpNaT72E88LNaNBYDLalp+
 u5CvRhjPM7m25mJRAwOI9mvJhIwueh8l6Far4hpVXdB6mxmwhmXAFDTIWoah250NGDEnp7dSC0
 oxhgIwVRD8ucjYD4v1uPpzXHQVzR9UZVF62Lvw3PJJii7/4UElFHDdS2R4U4gHIJXVnuNt43xd
 1IqiX94ePXbw7NH4BZspaRopPj2zPP8Ajai8LQUAQAA
X-Change-ID: 20261117-usb-sunxi-reset-fix-d1a0001440a9
To: Bin Liu <b-liu@ti.com>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Felipe Balbi <balbi@ti.com>, 
 Hans de Goede <hansg@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Maxime Ripard <mripard@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, 
 Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795615875; l=3498;
 i=admin@roadbobek.com; s=20261117; h=from:subject:message-id;
 bh=+B8CLcwaE8CfSA+NkGkpTmSXXtzNtTtQgGGXSeGISc8=;
 b=PVQl9NNhVlYgrt+BFNS0PQjwG3tLirodfZuRu7QGB/C+s4Xn2tBpeTy4G1/C/3Q+BnG3vXN5S
 Bn0icsaIpxzD7TVWdLGZUgePtf4KY2oyLplJbgROK28EJ4Oo0EtN0HB
X-Developer-Key: i=admin@roadbobek.com; a=ed25519;
 pk=TcWSTwITMylwCZLYbw80sv2LQx1zButqiT90TFVvhas=
X-Endpoint-Received: by B4 Relay for admin@roadbobek.com/20261117 with auth_id=1548
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a bootloader such as U-Boot (for example with
CONFIG_USB_MUSB_HOST=y) initializes USB host mode and boots Linux
without stopping USB first, both the MUSB controller and USB PHY
reset lines are already deasserted when Linux probes them.

Because reset_control_deassert() alone is a no-op on an already
deasserted reset line, stale hardware register state persists across
boot. On Allwinner A33, MUSB stays wedged in a_wait_bcon with
DevCtl=0x99, Power=0xf0, and a frozen Frame counter even across
hot-unplug and replug.

This series ensures both the MUSB controller and USB PHYs are reset
cleanly regardless of prior bootloader state, and fixes a related
PHY2 clock reference imbalance spotted during review:

- Patch 1 uses devm_reset_control_get_exclusive() and briefly asserts
  glue->rst in sunxi_musb_init().
- Patch 2 uses devm_reset_control_get_exclusive() and asserts all PHY
  resets in sun4i_usb_phy_probe() before registering the PHY provider,
  avoiding disrupting shared PHY2 on SoCs with needs_phy2_siddq.
- Patch 3 fixes a pre-existing phy2->clk2 reference imbalance in
  sun4i_usb_phy_init() on SoCs with needs_phy2_siddq.

Tested on an Allwinner A33 Q8 tablet (Laser MID-786).

Signed-off-by: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
---
Changes in v3:
- Check the return value of reset_control_assert(glue->rst) in
  sunxi_musb_init() and jump to error_clk_disable on failure
  (Philipp Zabel).
- Link to v2: https://patch.msgid.link/20261123-usb-sunxi-reset-fix-v2-0-4e51d3a64964@roadbobek.com

Changes in v2:
- Use devm_reset_control_get_exclusive() in both sunxi_musb_probe() and
  sun4i_usb_phy_probe() (Philipp Zabel).
- Move the USB PHY reset assertion from sun4i_usb_phy_init() to
  sun4i_usb_phy_probe() so initializing PHY2 on SoCs with
  needs_phy2_siddq does not reset an already active shared PHY2.
- Add Fixes tags to both reset patches.
- Add Patch 3 fixing the pre-existing phy2->clk2 clock reference
  imbalance in sun4i_usb_phy_init().
- Link to v1: https://patch.msgid.link/20261117-usb-sunxi-reset-fix-v1-0-c2b76e0e84e1@roadbobek.com

To: Bin Liu <b-liu@ti.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: Chen-Yu Tsai <wens@kernel.org>
To: Jernej Skrabec <jernej.skrabec@gmail.com>
To: Samuel Holland <samuel@sholland.org>
To: Philipp Zabel <p.zabel@pengutronix.de>
To: Felipe Balbi <balbi@ti.com>
To: Hans de Goede <hansg@kernel.org>
To: Vinod Koul <vkoul@kernel.org>
To: Neil Armstrong <neil.armstrong@linaro.org>
To: Manivannan Sadhasivam <mani@kernel.org>
To: Maxime Ripard <mripard@kernel.org>
To: Kishon Vijay Abraham I <kishon@kernel.org>
To: Andre Przywara <andre.przywara@arm.com>
Cc: linux-usb@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-sunxi@lists.linux.dev
Cc: linux-kernel@vger.kernel.org
Cc: linux-phy@lists.infradead.org

---
Bobek Brzeczyszczykiewicz (3):
      usb: musb: sunxi: Assert reset before deasserting on init
      phy: sun4i-usb: Assert PHY resets in sun4i_usb_phy_probe()
      phy: sun4i-usb: Fix phy2->clk2 reference imbalance in sun4i_usb_phy_init()

 drivers/phy/allwinner/phy-sun4i-usb.c | 23 +++++++++++++++++++++--
 drivers/usb/musb/sunxi.c              |  7 ++++++-
 2 files changed, 27 insertions(+), 3 deletions(-)
---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261117-usb-sunxi-reset-fix-d1a0001440a9

Best regards,
--  
Bobek Brzeczyszczykiewicz <admin@roadbobek.com>

