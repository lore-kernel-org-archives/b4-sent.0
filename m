From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 08 Feb 2024 01:19:22 +0800
Subject: [PATCH v2 3/3] usb: ehci: Make usage of
 generic_{setup,shutdown}_phy_bulk() helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240208-ehci-v2-3-6bf084b7ffac@outlook.com>
References: <20240208-ehci-v2-0-6bf084b7ffac@outlook.com>
In-Reply-To: <20240208-ehci-v2-0-6bf084b7ffac@outlook.com>
To: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707326360; l=1440;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=/ZXy+/JFQl5w+CVuHs0t22RB2/75bzpwupaCW19x1fw=;
 b=T0VGMv/rvxKay1BaPdI+fbid9E5WCGCyPOwpFMwM7O/uU+078PWnIop8x7HnkzKh9ocSaA/K8
 zug2MCKYLb4AcZn//LMD0/7jbcAqcsFIN85vZCNsda8lJ6JMoYF+DER
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace generic_setup_phy() and generic_shutdown_phy() by respectively
generic_setup_phy_bulk() and generic_shutdown_phy_bulk().

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/usb/host/ehci-generic.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/host/ehci-generic.c b/drivers/usb/host/ehci-generic.c
index 936e30438d..e109d84d73 100644
--- a/drivers/usb/host/ehci-generic.c
+++ b/drivers/usb/host/ehci-generic.c
@@ -25,7 +25,7 @@ struct generic_ehci {
 	struct ehci_ctrl ctrl;
 	struct clk_bulk clocks;
 	struct reset_ctl_bulk resets;
-	struct phy phy;
+	struct phy_bulk phys;
 	struct udevice *vbus_supply;
 };
 
@@ -95,7 +95,7 @@ static int ehci_usb_probe(struct udevice *dev)
 	if (err)
 		goto reset_err;
 
-	err = generic_setup_phy(dev, &priv->phy, 0);
+	err = generic_setup_phy_bulk(dev, &priv->phys);
 	if (err)
 		goto regulator_err;
 
@@ -110,7 +110,7 @@ static int ehci_usb_probe(struct udevice *dev)
 	return 0;
 
 phy_err:
-	ret = generic_shutdown_phy(&priv->phy);
+	ret = generic_shutdown_phy_bulk(&priv->phys);
 	if (ret)
 		dev_err(dev, "failed to shutdown usb phy (ret=%d)\n", ret);
 
@@ -140,7 +140,7 @@ static int ehci_usb_remove(struct udevice *dev)
 	if (ret)
 		return ret;
 
-	ret = generic_shutdown_phy(&priv->phy);
+	ret = generic_shutdown_phy_bulk(&priv->phys);
 	if (ret)
 		return ret;
 

-- 
2.43.0

