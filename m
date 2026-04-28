From: Christian DREHER <christian.dreher@nanoxplore.com>
Date: Tue, 28 Apr 2026 20:04:07 +0200
Subject: [PATCH 3/4] net: macb: do not set user_io when it does not exist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-net-macb-support-for-feature-lite-instances-v1-3-480e4cecac01@nanoxplore.com>
References: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
In-Reply-To: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
To: u-boot@lists.denx.de
Cc: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>, 
 Christian DREHER <christian.dreher@nanoxplore.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777399485; l=3683;
 i=christian.dreher@nanoxplore.com; s=20260428; h=from:subject:message-id;
 bh=azfemyGZY4URq8jSKvMACBdrUxtdTLkpvC20Z3LnAS4=;
 b=3XnWTuEJnfLwpj/f0+sHJTsXq0+k8Anw9xnbR4N9uvZGXSIyIp+2ksxRLnNO7AJ42frj4sBjx
 1nNnix1yrvtCzn3kTZmRZlN/2CNS1nbRsR5/cj2SBIGi6kqP4ZJ5wxS
X-Developer-Key: i=christian.dreher@nanoxplore.com; a=ed25519;
 pk=id7EcKmXLV2xNgNiCIcsPjkoMQHM/qxTYqEqMhidSAU=
X-Endpoint-Received: by B4 Relay for christian.dreher@nanoxplore.com/20260428 with auth_id=760
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cadence Ethernet MAC has a feature named user_io, which provides
some input and some output signals for arbitrary purpose in the SoC.
From the driver code, I understand that, on Atmel SoC, it is used to
drive the PHY mode.

At least on Cadence IP7014 r1p12, this feature is optional, and I am
working on a SoC that does not instantiate it. The presence of this
feature is advertised in DCFG1, this patch merely disables the access
to the user_io register based on this information.

I did not apply this change to the non-gigabit capable versions of
the IP, as I do not have documentation for them, and a new non-gigabit
instance is unlikely to appear. I prefer avoiding regressions on old
systems.

Signed-off-by: Christian DREHER <christian.dreher@nanoxplore.com>
---
 drivers/net/macb.c | 51 ++++++++++++++++++++++++++++++++-------------------
 drivers/net/macb.h |  2 ++
 2 files changed, 34 insertions(+), 19 deletions(-)

diff --git a/drivers/net/macb.c b/drivers/net/macb.c
index 807a038e071..5cc29ecb214 100644
--- a/drivers/net/macb.c
+++ b/drivers/net/macb.c
@@ -927,26 +927,39 @@ static int _macb_init(struct udevice *dev, const char *name)
 		/* Check the multi queue and initialize the queue for tx */
 		gmac_init_multi_queues(macb);
 
-		/*
-		 * When the GMAC IP with GE feature, this bit is used to
-		 * select interface between RGMII and GMII.
-		 * When the GMAC IP without GE feature, this bit is used
-		 * to select interface between RMII and MII.
+		/* This driver uses the user I/O to select the PHY features,
+		 * but some GEM instances come with a fixed configuration and
+		 * no USERIO.
 		 */
-		if (macb->phy_interface == PHY_INTERFACE_MODE_RGMII ||
-		    macb->phy_interface == PHY_INTERFACE_MODE_RGMII_ID ||
-		    macb->phy_interface == PHY_INTERFACE_MODE_RGMII_RXID ||
-		    macb->phy_interface == PHY_INTERFACE_MODE_RGMII_TXID)
-			val = macb->config->usrio->rgmii;
-		else if (macb->phy_interface == PHY_INTERFACE_MODE_RMII)
-			val = macb->config->usrio->rmii;
-		else if (macb->phy_interface == PHY_INTERFACE_MODE_MII)
-			val = macb->config->usrio->mii;
-
-		if (macb->config->caps & MACB_CAPS_USRIO_HAS_CLKEN)
-			val |= macb->config->usrio->clken;
-
-		gem_writel(macb, USRIO, val);
+		if (gem_readl(macb, DCFG1) & GEM_BIT(USERIO)) {
+			/*
+			 * When the GMAC IP with GE feature, this bit is used to
+			 * select interface between RGMII and GMII.
+			 * When he GMAC IP without GE feature, this bit is used
+			 * to select interface between RMII and MII.
+			 */
+			switch (macb->phy_interface) {
+			case PHY_INTERFACE_MODE_RGMII:
+			case PHY_INTERFACE_MODE_RGMII_ID:
+			case PHY_INTERFACE_MODE_RGMII_RXID:
+			case PHY_INTERFACE_MODE_RGMII_TXID:
+				val = macb->config->usrio->rgmii;
+				break;
+			case PHY_INTERFACE_MODE_RMII:
+				val = macb->config->usrio->rmii;
+				break;
+			case PHY_INTERFACE_MODE_MII:
+				val = macb->config->usrio->mii;
+				break;
+			default:
+				break;
+			}
+
+			if (macb->config->caps & MACB_CAPS_USRIO_HAS_CLKEN)
+				val |= macb->config->usrio->clken;
+
+			gem_writel(macb, USRIO, val);
+		}
 
 		if (macb->phy_interface == PHY_INTERFACE_MODE_SGMII) {
 			unsigned int ncfgr = macb_readl(macb, NCFGR);
diff --git a/drivers/net/macb.h b/drivers/net/macb.h
index 0eb90574618..002d5bd31b2 100644
--- a/drivers/net/macb.h
+++ b/drivers/net/macb.h
@@ -443,6 +443,8 @@
 #define MACB_REV_SIZE				16
 
 /* Bitfields in DCFG1. */
+#define GEM_USERIO_OFFSET			9
+#define GEM_USERIO_SIZE				1
 #define GEM_IRQCOR_OFFSET			23
 #define GEM_IRQCOR_SIZE				1
 #define GEM_DBWDEF_OFFSET			25

-- 
2.47.3

