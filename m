From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 19 Jan 2024 19:44:30 +0800
Subject: [PATCH 3/3] net: hifemac: register MDIO bus device for subnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240119-net-v1-3-d1feb8e16ac6@outlook.com>
References: <20240119-net-v1-0-d1feb8e16ac6@outlook.com>
In-Reply-To: <20240119-net-v1-0-d1feb8e16ac6@outlook.com>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705664668; l=1700;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=NCJcSa/cOcfklo9ByKOIk+8yiytHK/pmWUU7P4ZbEz8=;
 b=rND95nDtP/9KqbaXnMyNzdr5maqnmP/r5Ct482hfEGeJQBM1OCC6U8S7H0TN9KJjp2u+oiQ7c
 VUD2q2vTjSSBsjJvaWqFHCViM8mHbZgtlR4IW+XqJsGL2JciIfD6jUp
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

register internal MDIO bus device if it is a subnode.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/hifemac.c | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/drivers/net/hifemac.c b/drivers/net/hifemac.c
index 1088f3eca3..39c0233b62 100644
--- a/drivers/net/hifemac.c
+++ b/drivers/net/hifemac.c
@@ -15,6 +15,7 @@
 #include <wait_bit.h>
 #include <asm/io.h>
 #include <dm/device_compat.h>
+#include <dm/lists.h>
 #include <linux/delay.h>
 #include <linux/kernel.h>
 
@@ -337,6 +338,8 @@ int hisi_femac_of_to_plat(struct udevice *dev)
 {
 	int ret, i;
 	struct hisi_femac_priv *priv = dev_get_priv(dev);
+	ofnode mdio_node;
+	bool mdio_registered = false;
 	static const char * const clk_strs[] = {
 		[CLK_MAC] = "mac",
 		[CLK_BUS] = "bus",
@@ -388,6 +391,31 @@ int hisi_femac_of_to_plat(struct udevice *dev)
 						     MAC_RESET_DELAY_PROPERTY,
 						     MAC_RESET_ASSERT_PERIOD);
 
+	/* Create MDIO bus */
+	ofnode_for_each_subnode(mdio_node, dev_ofnode(dev)) {
+		const char *subnode_name = ofnode_get_name(mdio_node);
+		struct udevice *mdiodev;
+
+		// Skip subnodes not starting with "mdio"
+		if (strncmp(subnode_name, "mdio", 4))
+			continue;
+
+		ret = device_bind_driver_to_node(dev, "hisi-femac-mdio",
+						 subnode_name, mdio_node, &mdiodev);
+		if (ret) {
+			dev_err(dev, "Failed to register MDIO bus device %d\n", ret);
+			return log_msg_ret("net", ret);
+		}
+
+		mdio_registered = true;
+		break;
+	}
+
+	if (!mdio_registered) {
+		dev_err(dev, "No MDIO subnode is found!\n");
+		return log_msg_ret("mdio", -ENODATA);
+	}
+
 	return 0;
 }
 

-- 
2.43.0

