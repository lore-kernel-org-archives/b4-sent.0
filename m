From: Christian DREHER <christian.dreher@nanoxplore.com>
Date: Tue, 28 Apr 2026 20:04:08 +0200
Subject: [PATCH 4/4] net: macb: add gigabit implementation for fixed-link
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-net-macb-support-for-feature-lite-instances-v1-4-480e4cecac01@nanoxplore.com>
References: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
In-Reply-To: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
To: u-boot@lists.denx.de
Cc: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>, 
 Christian DREHER <christian.dreher@nanoxplore.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777399485; l=2337;
 i=christian.dreher@nanoxplore.com; s=20260428; h=from:subject:message-id;
 bh=C5Nzv11Bwryz9D8hZGO5arZ3cYSEIEx4tJZcH1tjt9k=;
 b=jktcw76AUqrFYKKOIov1SKJ23gxal8xRE0YBkgG50FZIBR4mdRJZsK8jjIR2cQPFCWoh3Y3BN
 o5eaMDjjG9MDcqWV8tqYZEfo2cSU8lloghIB16pmZDz/Ik3W1TktCsG
X-Developer-Key: i=christian.dreher@nanoxplore.com; a=ed25519;
 pk=id7EcKmXLV2xNgNiCIcsPjkoMQHM/qxTYqEqMhidSAU=
X-Endpoint-Received: by B4 Relay for christian.dreher@nanoxplore.com/20260428 with auth_id=760
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A fixed gigabit link on a non-gigabit controller is only rejected
during PHY init (even though there is no PHY to init), because, on
device-tree parsing, the controller is not probed, and it is still
unknown whether it is gigabit-capable.

This code was only tested on emulator with a full-duplex RGMII
interface, but is expected to work in GMII or half-duplex as well.

Signed-off-by: Christian DREHER <christian.dreher@nanoxplore.com>
---
 drivers/net/macb.c | 32 ++++++++++++++++++++++++++++----
 1 file changed, 28 insertions(+), 4 deletions(-)

diff --git a/drivers/net/macb.c b/drivers/net/macb.c
index 5cc29ecb214..bea1dfed892 100644
--- a/drivers/net/macb.c
+++ b/drivers/net/macb.c
@@ -772,18 +772,40 @@ static int macb_phy_init(struct udevice *dev, const char *name)
 			lpa);
 	} else {
 		/* if macb port is a fixed link */
-		/* TODO : manage gigabit capable processors */
+		const char *human_readable_speed;
+
 		speed = macb->speed;
 		duplex = macb->duplex;
+		switch (speed) {
+		case 2:
+			human_readable_speed = "1000";
+			break;
+		case 1:
+			human_readable_speed = "100";
+			break;
+		case 0:
+			human_readable_speed = "10";
+			break;
+		default:
+			printf("%s: speed %d not supported\n", name, speed);
+			return -EINVAL;
+		}
 		printf("%s: link up, %sMbps %s-duplex\n",
 			name,
-			speed ? "100" : "10",
+			human_readable_speed,
 			duplex ? "full" : "half");
 	}
 
 	ncfgr = macb_readl(macb, NCFGR);
 	ncfgr &= ~(MACB_BIT(SPD) | MACB_BIT(FD) | GEM_BIT(GBE));
-	if (speed) {
+	if (speed == 2) {
+		if (!gem_is_gigabit_capable(macb)) {
+			printf("%s: is not gigabit Ethernet capable\n", name);
+			return -EINVAL;
+		}
+		ncfgr |= GEM_BIT(GBE);
+		ret = macb_linkspd_cb(dev, _1000BASET);
+	} else if (speed == 1) {
 		ncfgr |= MACB_BIT(SPD);
 		ret = macb_linkspd_cb(dev, _100BASET);
 	} else {
@@ -1329,7 +1351,9 @@ static int macb_eth_of_to_plat(struct udevice *dev)
 		macb->phy_addr = PHY_MAX_ADDR + 1;
 		macb->duplex = fdtdec_get_bool(blob, fl_node, "full-duplex");
 		speed_fdt = fdtdec_get_int(blob, fl_node, "speed", 0);
-		if (speed_fdt == 100) {
+		if (speed_fdt == 1000) {
+			macb->speed = 2;
+		} else if (speed_fdt == 100) {
 			macb->speed = 1;
 		} else if (speed_fdt == 10) {
 			macb->speed = 0;

-- 
2.47.3

