From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 22 Jan 2024 05:02:06 +0800
Subject: [PATCH v2 3/4] net: hifemac: register MDIO bus device for subnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240122-net-v2-3-78a368896f62@outlook.com>
References: <20240122-net-v2-0-78a368896f62@outlook.com>
In-Reply-To: <20240122-net-v2-0-78a368896f62@outlook.com>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705870930; l=1700;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=NCJcSa/cOcfklo9ByKOIk+8yiytHK/pmWUU7P4ZbEz8=;
 b=zP/278dnFb6/4BqS7ogZuRVjMH7w5DlOS4kf5J87ETf1OeLtyLnOH991uWxA3J8efKj6ozc1b
 12d+6QdWG3rBhx3ifuHhwVrAaqDAH5POq4K1NANam6foQELiTUhvh17
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

