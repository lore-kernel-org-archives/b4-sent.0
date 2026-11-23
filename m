From: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
Date: Mon, 23 Nov 2026 06:54:09 +0000
Subject: [PATCH v2 3/3] phy: sun4i-usb: Fix phy2->clk2 reference imbalance
 in sun4i_usb_phy_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-usb-sunxi-reset-fix-v2-3-4e51d3a64964@roadbobek.com>
References: <20261123-usb-sunxi-reset-fix-v2-0-4e51d3a64964@roadbobek.com>
In-Reply-To: <20261123-usb-sunxi-reset-fix-v2-0-4e51d3a64964@roadbobek.com>
To: Bin Liu <b-liu@ti.com>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Hans de Goede <hansg@kernel.org>, 
 Felipe Balbi <balbi@ti.com>, Kishon Vijay Abraham I <kishon@kernel.org>, 
 Maxime Ripard <mripard@kernel.org>, Andre Przywara <andre.przywara@arm.com>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, 
 Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795416949; l=1149;
 i=admin@roadbobek.com; s=20261117; h=from:subject:message-id;
 bh=2/RvSPv9KdaGKCqwuU1CPvhUhe3Y2XomCyvU8DfERlY=;
 b=8SadnOA0k7DAxtcHP3w9+5kmioUG393Aa8KvOxAQQwynz3lISKa3QefO2RtF2O3grc23Erh+Q
 ViQsz6Rgd5LAHTW+luPwAwI0GVW+8O+ncw5k4rigTo+hWItwpJOYBNG
X-Developer-Key: i=admin@roadbobek.com; a=ed25519;
 pk=TcWSTwITMylwCZLYbw80sv2LQx1zButqiT90TFVvhas=
X-Endpoint-Received: by B4 Relay for admin@roadbobek.com/20261117 with auth_id=1548
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In sun4i_usb_phy_init(), the needs_phy2_siddq path enables phy2->clk2
to access the REG_HCI_PHY_CTL PMU register for PHY2, but then disables
phy->clk2 instead of phy2->clk2.

This leaks a prepare/enable reference on phy2->clk2 while prematurely
disabling phy->clk2, causing a clock disable/unprepare underflow when
sun4i_usb_phy_exit() later runs.

Disable and unprepare phy2->clk2 instead of phy->clk2.

Fixes: b45c6d80325b ("phy: sun4i-usb: Introduce port2 SIDDQ quirk")
Signed-off-by: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
---
 drivers/phy/allwinner/phy-sun4i-usb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/phy/allwinner/phy-sun4i-usb.c b/drivers/phy/allwinner/phy-sun4i-usb.c
index a62558124d2d..6e35eb77c879 100644
--- a/drivers/phy/allwinner/phy-sun4i-usb.c
+++ b/drivers/phy/allwinner/phy-sun4i-usb.c
@@ -318,7 +318,7 @@ static int sun4i_usb_phy_init(struct phy *_phy)
 			writel(val, phy2->pmu + REG_HCI_PHY_CTL);
 		}
 
-		clk_disable_unprepare(phy->clk2);
+		clk_disable_unprepare(phy2->clk2);
 	}
 
 	if (phy->pmu && data->cfg->hci_phy_ctl_clear) {

-- 
2.53.0

