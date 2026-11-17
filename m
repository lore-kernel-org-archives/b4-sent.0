From: Roadbobek <admin@roadbobek.com>
Date: Tue, 17 Nov 2026 13:00:43 +0000
Subject: [PATCH 2/2] phy: sun4i-usb: Assert reset before deasserting in phy
 init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-usb-sunxi-reset-fix-v1-2-c2b76e0e84e1@roadbobek.com>
References: <20261117-usb-sunxi-reset-fix-v1-0-c2b76e0e84e1@roadbobek.com>
In-Reply-To: <20261117-usb-sunxi-reset-fix-v1-0-c2b76e0e84e1@roadbobek.com>
To: Bin Liu <b-liu@ti.com>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, Roadbobek <admin@roadbobek.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920443; l=1163;
 i=admin@roadbobek.com; s=20261117; h=from:subject:message-id;
 bh=OVg8qc9Dvbt0DpBBY/dML99s9283yAaJeOiCsaXqahQ=;
 b=5z7gVCV2tubzbMgwKmN+aLOEQ1vWqqKL1z+6YQv0bljLTSE+qxlA1SMTklz+ncPdxMcuB/qF0
 WYOLvj2KjZKCI6wo/koiAq3H3sn2WkQP5ZJ+dadlnl7RRIt2cdEXYw2
X-Developer-Key: i=admin@roadbobek.com; a=ed25519;
 pk=TcWSTwITMylwCZLYbw80sv2LQx1zButqiT90TFVvhas=
X-Endpoint-Received: by B4 Relay for admin@roadbobek.com/20261117 with auth_id=1548
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a bootloader initializes USB before booting Linux without
first tearing down the controller, phy->reset may already be
deasserted when sun4i_usb_phy_init() runs.

Because reset_control_deassert() alone is a no-op on an
already deasserted reset line, stale USB PHY state can
persist across the bootloader-to-kernel handoff.

Assert phy->reset briefly before deasserting it in
sun4i_usb_phy_init() so the PHY starts cleanly regardless of
prior bootloader USB usage. Tested on an Allwinner A33 Q8
tablet (Laser MID-786).

Signed-off-by: Roadbobek <admin@roadbobek.com>
---
 drivers/phy/allwinner/phy-sun4i-usb.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/phy/allwinner/phy-sun4i-usb.c b/drivers/phy/allwinner/phy-sun4i-usb.c
index f26eed0db17e..05e6dcf035a1 100644
--- a/drivers/phy/allwinner/phy-sun4i-usb.c
+++ b/drivers/phy/allwinner/phy-sun4i-usb.c
@@ -270,6 +270,8 @@ static int sun4i_usb_phy_init(struct phy *_phy)
 		return ret;
 	}
 
+	reset_control_assert(phy->reset);
+	usleep_range(10, 20);
 	ret = reset_control_deassert(phy->reset);
 	if (ret) {
 		clk_disable_unprepare(phy->clk2);

-- 
2.53.0

