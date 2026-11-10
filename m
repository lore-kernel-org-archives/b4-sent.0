From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Tue, 10 Nov 2026 01:08:52 -0600
Subject: [PATCH 1/2] usb: musb: sunxi: Unregister the generic PHY after
 dropping its reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-musb-sunxi-unbind-v1-1-d821584fc4a4@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294532; l=4698;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=eUHfUOy8mHnS4tm+sNyfT5FtNME+N65p3UiFyU70Ldc=;
 b=93/spdKuFn6nPrVDmAMIQZKoYK4cgQR8a2VXwb5WXdpzGlWQ7Ic5L36HW8mRwYr7mHCUJlTpe
 XWCZLNN04/MDY8OWQbFG6WWtp4QHLUP1IkMGhO0PMTBIbCjSrZC4O2H
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unbinding musb-sunxi oopses on v7.4-rc1 (KickPi K5C, Allwinner A133,
KASAN enabled, no out-of-tree modules):

  # echo 5100000.usb > /sys/bus/platform/drivers/musb-sunxi/unbind
  BUG: KASAN: slab-use-after-free in devm_usb_phy_release+0x2c/0x68
  Read of size 8 at addr ffff0000057ef080 by task sh/329
  ...
  Allocated by task 48:
   ...
   devm_kmalloc+0x5c/0x140
   usb_phy_generic_probe+0x30/0x184
   ...
   usb_phy_generic_register+0x9c/0xd8
   sunxi_musb_probe+0x310/0x5c8
  ...
  Freed by task 329:
   ...
   platform_device_unregister+0x24/0x40
   usb_phy_generic_unregister+0x10/0x1c
   sunxi_musb_remove+0x44/0x54
   ...
  Unable to handle kernel NULL pointer dereference at virtual address 0000000000000010
  ...
  pc : devm_usb_phy_release+0x44/0x68

sunxi_musb_remove() unregisters the usb_phy_generic device. That unbinds
its driver, which frees the struct usb_phy_generic holding the struct
usb_phy. The reference that sunxi_musb_probe() took with
devm_usb_get_phy() is only dropped after that, when devres runs, and
usb_put_phy() then reads x->dev->driver->owner from the freed PHY with
dev->driver already NULL. The probe error paths unregister the generic
PHY with the devres reference still held in the same way.

Commit 6ed05c68cbca ("usb: musb: sunxi: Explicitly release USB PHY on
exit") fixed this oops in 2017 by calling devm_usb_put_phy() in
sunxi_musb_exit(). Commit 498dbd9aea20 ("usb: musb: sunxi: Fix
accessing an released usb phy") removed that call again, because
sunxi_musb_exit() also runs when only the musb-hdrc child is unbound,
and the PHY must stay valid for the next bind. That brought the oops
back.

Keep the reference for the lifetime of the glue device, as 498dbd9aea20
intended, and let devres unregister the generic PHY device as well. The
action is added before devm_usb_get_phy(), so devres drops the
reference first, on unbind and on the probe error paths.

Tested on the K5C with v7.4-rc1 and KASAN: unbinding musb-sunxi gives
no KASAN report and no oops, the generic PHY device, musb-hdrc and the
UDC are removed and come back on bind, and 11 unbind/bind cycles stayed
clean. The probe error paths were not exercised, and no USB gadget
traffic was tested (no data connection to a host).

Claude Code (Anthropic) found the cause from the oops, wrote this fix
and the commit message, and helped with the tests; I reviewed the fix
and ran the tests on the board.

Fixes: 498dbd9aea20 ("usb: musb: sunxi: Fix accessing an released usb phy")
Cc: stable@vger.kernel.org
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 drivers/usb/musb/sunxi.c | 25 +++++++++++++++++--------
 1 file changed, 17 insertions(+), 8 deletions(-)

diff --git a/drivers/usb/musb/sunxi.c b/drivers/usb/musb/sunxi.c
index a6bd3e968cc..d880c3758c9 100644
--- a/drivers/usb/musb/sunxi.c
+++ b/drivers/usb/musb/sunxi.c
@@ -674,6 +674,11 @@ static const struct musb_hdrc_config sunxi_musb_hdrc_config_4eps = {
 	.ram_bits	= SUNXI_MUSB_RAM_BITS,
 };
 
+static void sunxi_musb_unregister_usb_phy(void *usb_phy)
+{
+	usb_phy_generic_unregister(usb_phy);
+}
+
 static int sunxi_musb_probe(struct platform_device *pdev)
 {
 	struct musb_hdrc_platform_data	pdata;
@@ -768,11 +773,21 @@ static int sunxi_musb_probe(struct platform_device *pdev)
 		return PTR_ERR(glue->usb_phy);
 	}
 
+	/*
+	 * Registered before devm_usb_get_phy(), so that devres drops the
+	 * reference to the PHY before the PHY device is unregistered.
+	 */
+	ret = devm_add_action_or_reset(&pdev->dev,
+				       sunxi_musb_unregister_usb_phy,
+				       glue->usb_phy);
+	if (ret)
+		return ret;
+
 	glue->xceiv = devm_usb_get_phy(&pdev->dev, USB_PHY_TYPE_USB2);
 	if (IS_ERR(glue->xceiv)) {
 		ret = PTR_ERR(glue->xceiv);
 		dev_err(&pdev->dev, "Error getting usb-phy %d\n", ret);
-		goto err_unregister_usb_phy;
+		return ret;
 	}
 
 	platform_set_drvdata(pdev, glue);
@@ -792,23 +807,17 @@ static int sunxi_musb_probe(struct platform_device *pdev)
 	if (IS_ERR(glue->musb_pdev)) {
 		ret = PTR_ERR(glue->musb_pdev);
 		dev_err(&pdev->dev, "Error registering musb dev: %d\n", ret);
-		goto err_unregister_usb_phy;
+		return ret;
 	}
 
 	return 0;
-
-err_unregister_usb_phy:
-	usb_phy_generic_unregister(glue->usb_phy);
-	return ret;
 }
 
 static void sunxi_musb_remove(struct platform_device *pdev)
 {
 	struct sunxi_glue *glue = platform_get_drvdata(pdev);
-	struct platform_device *usb_phy = glue->usb_phy;
 
 	platform_device_unregister(glue->musb_pdev);
-	usb_phy_generic_unregister(usb_phy);
 }
 
 static const struct sunxi_musb_cfg sun4i_a10_musb_cfg = {

-- 
2.34.1

