From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Tue, 10 Nov 2026 01:08:53 -0600
Subject: [PATCH 2/2] usb: musb: sunxi: Unregister the extcon notifier in
 sunxi_musb_exit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-musb-sunxi-unbind-v1-2-d821584fc4a4@gmail.com>
References: <20261110-musb-sunxi-unbind-v1-0-d821584fc4a4@gmail.com>
In-Reply-To: <20261110-musb-sunxi-unbind-v1-0-d821584fc4a4@gmail.com>
To: Bin Liu <b-liu@ti.com>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: regressions@lists.linux.dev, Zijun Hu <zijun.hu@oss.qualcomm.com>, 
 linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Rajan Yadav <rajanyadav0307@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294532; l=4095;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=bZWjWO4qmuHUgam6/ZPpcz8gwogqcCZCYDKe6vCCA9A=;
 b=wKfVzErbcdvcU83jM0aWxFQUbpAvri86BapqOpv41VUu7uUe2s3QOfZlTfgzIOIHtY4aGTvN9
 fQaPbIuNbO1DVwzeAdvDg8JvZAjYrwKGdVNw7Ac2JDL2HNhsMSVU0G4
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Binding the musb-hdrc child again after it was unbound fails on v7.4-rc1
(KickPi K5C, Allwinner A133):

  # echo musb-hdrc.1.auto > /sys/bus/platform/drivers/musb-hdrc/unbind
  # echo musb-hdrc.1.auto > /sys/bus/platform/drivers/musb-hdrc/bind
  notifier callback sunxi_musb_host_notifier already registered
  WARNING: kernel/notifier.c:24 at notifier_chain_register+0x98/0xf8, CPU#1: sh/312
  ...
   notifier_chain_register+0x98/0xf8 (P)
   raw_notifier_chain_register+0x14/0x20
   extcon_register_notifier+0xa4/0xe0
   devm_extcon_register_notifier+0x64/0xe0
   sunxi_musb_init+0x170/0x280
   musb_probe+0x330/0x125c
  ...
  musb-hdrc musb-hdrc.1.auto: error -EEXIST: musb_init_controller failed
  musb-hdrc musb-hdrc.1.auto: probe with driver musb-hdrc failed with error -17

sunxi_musb_init() runs each time the child is probed, but it registers
the extcon notifier with devm_extcon_register_notifier() on the glue
device. The notifier stays registered after the child is unbound, and
the next sunxi_musb_init() registers the same notifier_block again. It
also stays registered while no musb exists, so an extcon event can
still queue glue->work after sunxi_musb_exit() cancelled it.

Commit bb1d1ce8c74e ("usb: musb: sunxi: Uses the resource-managed
extcon API when registering extcon notifier") introduced this; before
it, the notifier was unregistered in sunxi_musb_exit() and on the
sunxi_musb_init() error path. Restore that, and unregister it before
cancel_work_sync() so that the notifier cannot queue the work again.

Tested on the K5C with v7.4-rc1 and KASAN. The bind failed as above
both without and with the previous patch. With both patches, three
unbind/bind cycles of musb-hdrc bring back the UDC each time, without
warnings or KASAN reports, and unbinding the glue device afterwards is
clean as well. This patch was not tested without the previous one, and
the sunxi_musb_init() error path was not exercised.

Claude Code (Anthropic) found the cause, wrote this fix and the commit
message, and helped with the tests; I reviewed the fix and ran the
tests on the board.

Fixes: bb1d1ce8c74e ("usb: musb: sunxi: Uses the resource-managed extcon API when registering extcon notifier")
Cc: stable@vger.kernel.org
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 drivers/usb/musb/sunxi.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/musb/sunxi.c b/drivers/usb/musb/sunxi.c
index d880c3758c9..e9107ae9d34 100644
--- a/drivers/usb/musb/sunxi.c
+++ b/drivers/usb/musb/sunxi.c
@@ -246,15 +246,19 @@ static int sunxi_musb_init(struct musb *musb)
 
 	writeb(SUNXI_MUSB_VEND0_PIO_MODE, musb->mregs + SUNXI_MUSB_VEND0);
 
-	/* Register notifier before calling phy_init() */
-	ret = devm_extcon_register_notifier(glue->dev, glue->extcon,
-					EXTCON_USB_HOST, &glue->host_nb);
+	/*
+	 * Register notifier before calling phy_init(). It is unregistered in
+	 * sunxi_musb_exit(), as this runs again each time the musb-hdrc child
+	 * is bound.
+	 */
+	ret = extcon_register_notifier(glue->extcon, EXTCON_USB_HOST,
+				       &glue->host_nb);
 	if (ret)
 		goto error_reset_assert;
 
 	ret = phy_init(glue->phy);
 	if (ret)
-		goto error_reset_assert;
+		goto error_unregister_notifier;
 
 	musb->isr = sunxi_musb_interrupt;
 
@@ -263,6 +267,9 @@ static int sunxi_musb_init(struct musb *musb)
 
 	return 0;
 
+error_unregister_notifier:
+	extcon_unregister_notifier(glue->extcon, EXTCON_USB_HOST,
+				   &glue->host_nb);
 error_reset_assert:
 	if (test_bit(SUNXI_MUSB_FL_HAS_RESET, &glue->flags))
 		reset_control_assert(glue->rst);
@@ -280,6 +287,9 @@ static int sunxi_musb_exit(struct musb *musb)
 
 	pm_runtime_put(musb->controller);
 
+	/* Before cancel_work_sync(), so the notifier cannot requeue the work */
+	extcon_unregister_notifier(glue->extcon, EXTCON_USB_HOST,
+				   &glue->host_nb);
 	cancel_work_sync(&glue->work);
 	if (test_bit(SUNXI_MUSB_FL_PHY_ON, &glue->flags))
 		phy_power_off(glue->phy);

-- 
2.34.1

