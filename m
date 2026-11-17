From: Roadbobek <admin@roadbobek.com>
Date: Tue, 17 Nov 2026 13:00:42 +0000
Subject: [PATCH 1/2] usb: musb: sunxi: Assert reset before deasserting on
 init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-usb-sunxi-reset-fix-v1-1-c2b76e0e84e1@roadbobek.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920443; l=1415;
 i=admin@roadbobek.com; s=20261117; h=from:subject:message-id;
 bh=Bzs+Bok/1pte1PfClsczqYfF32Y1BbstMmHy95Q44ZE=;
 b=GOV2+10kg10zXZLyEVlNPyFWyN0C0AkEP8WNKSt6LllGHLiceFrMahB5XGAYKIGjzf9fDi7Hb
 wKyzVEx/4L3ADlOwuALD5iDSg9VA/RdFlZP7/1m9wFIqj+LdxSDSac6
X-Developer-Key: i=admin@roadbobek.com; a=ed25519;
 pk=TcWSTwITMylwCZLYbw80sv2LQx1zButqiT90TFVvhas=
X-Endpoint-Received: by B4 Relay for admin@roadbobek.com/20261117 with auth_id=1548
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a bootloader such as U-Boot (for example with
CONFIG_USB_MUSB_HOST=y) initializes MUSB and boots Linux
without stopping USB first, the controller reset line is
already deasserted at probe time.

In that case reset_control_deassert() in sunxi_musb_init()
is a no-op and stale MUSB register state persists across boot.
On Allwinner A33, MUSB stays wedged in a_wait_bcon with
DevCtl=0x99, Power=0xf0, and a frozen Frame counter even
across hot-unplug and replug.

Assert glue->rst briefly before deasserting it when
SUNXI_MUSB_FL_HAS_RESET is set so MUSB starts cleanly.
Tested on an Allwinner A33 Q8 tablet (Laser MID-786).

Signed-off-by: Roadbobek <admin@roadbobek.com>
---
 drivers/usb/musb/sunxi.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/musb/sunxi.c b/drivers/usb/musb/sunxi.c
index a17b1c150626..3d16049e53b5 100644
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

-- 
2.53.0

