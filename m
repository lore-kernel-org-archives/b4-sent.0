From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 22 Jan 2024 22:33:20 +0800
Subject: [PATCH v3 1/5] net: hifemac_mdio: use log_msg_ret() correctly,
 report error by dev_err()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240122-net-v3-1-f1e80564725b@outlook.com>
References: <20240122-net-v3-0-f1e80564725b@outlook.com>
In-Reply-To: <20240122-net-v3-0-f1e80564725b@outlook.com>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705934004; l=1755;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=hQDPCsolPbXnTnIjMDCaSwJsmF0AaJNRipJEFZgsKnM=;
 b=6mc0ozN9x91P278dghQxAg1ckXpaRzX9opyD7/kuKyTB/NfmQul9j/4uvo7ZJv9G8ADV6pA4a
 WA/XTvvND5HAisAsRZeJQYLbWsM1XWUcMoEnFYIQ5Q/hOLNs++wS7br
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The initial commit used log_msg_ret() wrongly. Fix that by moving error
report to a separate dev_err() call and shrink the first argument of
log_msg_ret() to no more than 4 chars.

Fixes: 6b5c8d98e204 ("net: add hifemac_mdio MDIO bus driver for HiSilicon platform")

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/hifemac_mdio.c | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/drivers/net/hifemac_mdio.c b/drivers/net/hifemac_mdio.c
index 343c5f3a38..0b59d06091 100644
--- a/drivers/net/hifemac_mdio.c
+++ b/drivers/net/hifemac_mdio.c
@@ -8,6 +8,7 @@
 #include <dm.h>
 #include <clk.h>
 #include <miiphy.h>
+#include <dm/device_compat.h>
 #include <linux/io.h>
 #include <linux/iopoll.h>
 
@@ -74,7 +75,8 @@ static int hisi_femac_mdio_of_to_plat(struct udevice *dev)
 	data->membase = dev_remap_addr(dev);
 	if (IS_ERR(data->membase)) {
 		ret = PTR_ERR(data->membase);
-		return log_msg_ret("Failed to remap base addr", ret);
+		dev_err(dev, "Failed to remap base addr %d\n", ret);
+		return log_msg_ret("mdio", ret);
 	}
 
 	// clk is optional
@@ -89,8 +91,10 @@ static int hisi_femac_mdio_probe(struct udevice *dev)
 	int ret;
 
 	ret = clk_prepare_enable(data->clk);
-	if (ret)
-		return log_msg_ret("Failed to enable clk", ret);
+	if (ret) {
+		dev_err(dev, "Failed to enable clock: %d\n", ret);
+		return log_msg_ret("clk", ret);
+	}
 
 	return 0;
 }
@@ -112,5 +116,6 @@ U_BOOT_DRIVER(hisi_femac_mdio_driver) = {
 	.of_to_plat = hisi_femac_mdio_of_to_plat,
 	.probe = hisi_femac_mdio_probe,
 	.ops = &hisi_femac_mdio_ops,
+	.plat_auto = sizeof(struct mdio_perdev_priv),
 	.priv_auto = sizeof(struct hisi_femac_mdio_data),
 };

-- 
2.43.0

