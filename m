From: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
Date: Mon, 23 Nov 2026 06:54:07 +0000
Subject: [PATCH v2 1/3] usb: musb: sunxi: Assert reset before deasserting
 on init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-usb-sunxi-reset-fix-v2-1-4e51d3a64964@roadbobek.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795416949; l=2005;
 i=admin@roadbobek.com; s=20261117; h=from:subject:message-id;
 bh=4U8ofcJ5CaE3LjdH1VHfvFhhqtxQkjH9SyoARmkLRfM=;
 b=fsb4YhStcZrL24l9lIdisnCkVahY3Uch2BAXtPeUtkG0+AyVTcJv286JSJ3tnvBbfEerDKshU
 U8beRALeh26CoXmaqZtmU2Yv1jNwVek4mRLcGTpA7vS38jcbYYHzssS
X-Developer-Key: i=admin@roadbobek.com; a=ed25519;
 pk=TcWSTwITMylwCZLYbw80sv2LQx1zButqiT90TFVvhas=
X-Endpoint-Received: by B4 Relay for admin@roadbobek.com/20261117 with auth_id=1548
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a bootloader such as U-Boot (for example with
CONFIG_USB_MUSB_HOST=y) initializes MUSB and boots Linux without
stopping USB first, the controller reset line is already deasserted at
probe time.

In that case reset_control_deassert() in sunxi_musb_init() is a no-op
and stale MUSB register state persists across boot. On Allwinner A33,
MUSB stays wedged in a_wait_bcon with DevCtl=0x99, Power=0xf0, and a
frozen Frame counter even across hot-unplug and replug.

Request exclusive reset control via devm_reset_control_get_exclusive()
and assert glue->rst briefly before deasserting it when
SUNXI_MUSB_FL_HAS_RESET is set so MUSB starts cleanly.

Tested on an Allwinner A33 Q8 tablet (Laser MID-786).

Fixes: 132e23775779 ("usb: musb: sunxi: Add support for musb controller in A31 SoC")
Signed-off-by: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
---
 drivers/usb/musb/sunxi.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/musb/sunxi.c b/drivers/usb/musb/sunxi.c
index a17b1c150626..5f63d519237b 100644
--- a/drivers/usb/musb/sunxi.c
+++ b/drivers/usb/musb/sunxi.c
@@ -9,6 +9,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/delay.h>
 #include <linux/err.h>
 #include <linux/extcon.h>
 #include <linux/io.h>
@@ -239,6 +240,8 @@ static int sunxi_musb_init(struct musb *musb)
 		goto error_sram_release;
 
 	if (test_bit(SUNXI_MUSB_FL_HAS_RESET, &glue->flags)) {
+		reset_control_assert(glue->rst);
+		usleep_range(10, 20);
 		ret = reset_control_deassert(glue->rst);
 		if (ret)
 			goto error_clk_disable;
@@ -745,7 +748,7 @@ static int sunxi_musb_probe(struct platform_device *pdev)
 	}
 
 	if (test_bit(SUNXI_MUSB_FL_HAS_RESET, &glue->flags)) {
-		glue->rst = devm_reset_control_get(&pdev->dev, NULL);
+		glue->rst = devm_reset_control_get_exclusive(&pdev->dev, NULL);
 		if (IS_ERR(glue->rst))
 			return dev_err_probe(&pdev->dev, PTR_ERR(glue->rst),
 					     "Error getting reset\n");

-- 
2.53.0

