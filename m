From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:49 +0100
Subject: [PATCH RFC v4 07/15] net: pcs: xpcs: wait for SGMII AN to complete
 in-band
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-7-3bfe0589be8d@oss.nxp.com>
References: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
In-Reply-To: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
To: Vincent Guittot <vincent.guittot@linaro.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=2657;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=/xyLv2QCrquyhEtexeBz8mg+SBUqNG1P5gZP4XIM2r4=;
 b=erl2TTTSecbJtEkEGUMEMricIBexirLTsD7OwLnWEjO8pXSKjC8hxqv0KmBe/qhRnG4Ip/J7k
 DsP0e/gxl52Acql2yks2XJ/rpswNxCSV2gIa1tzkf6Pa5k+FLFiszGP
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With in-band SGMII, the S32G XPCS keeps the previous SGMII link word in
VR_MII_AN_INTR_STS until the next negotiation completes, so phylink can
latch a stale speed after the link partner changes speed.

Add DW_XPCS_QUIRK_SGMII_WAIT_AN: with in-band negotiation enabled,
report the link down until BMSR reports AN complete. Set it for S32G
only.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/pcs/pcs-xpcs.c | 21 +++++++++++++++++++--
 1 file changed, 19 insertions(+), 2 deletions(-)

diff --git a/drivers/net/pcs/pcs-xpcs.c b/drivers/net/pcs/pcs-xpcs.c
index 71e5882f4b0b..65597c2d7a89 100644
--- a/drivers/net/pcs/pcs-xpcs.c
+++ b/drivers/net/pcs/pcs-xpcs.c
@@ -166,6 +166,11 @@ struct dw_xpcs_compat {
 #define DW_XPCS_QUIRK_NO_SOFT_RESET	BIT(0)
 /* VR_MII_EEE_MCTRL0/1 are not implemented */
 #define DW_XPCS_QUIRK_NO_EEE		BIT(1)
+/*
+ * With in-band SGMII, VR_MII_AN_INTR_STS keeps the previous SGMII word until
+ * the next negotiation completes; only trust it once BMSR reports AN complete
+ */
+#define DW_XPCS_QUIRK_SGMII_WAIT_AN	BIT(2)
 
 struct dw_xpcs_desc {
 	u32 id;
@@ -1081,6 +1086,7 @@ static int xpcs_get_state_c73(struct dw_xpcs *xpcs,
 }
 
 static int xpcs_get_state_c37_sgmii(struct dw_xpcs *xpcs,
+				    unsigned int neg_mode,
 				    struct phylink_link_state *state)
 {
 	int ret;
@@ -1092,6 +1098,16 @@ static int xpcs_get_state_c37_sgmii(struct dw_xpcs *xpcs,
 	state->duplex = DUPLEX_UNKNOWN;
 	state->pause = 0;
 
+	if (xpcs->desc->quirks & DW_XPCS_QUIRK_SGMII_WAIT_AN &&
+	    neg_mode == PHYLINK_PCS_NEG_INBAND_ENABLED) {
+		ret = xpcs_read(xpcs, MDIO_MMD_VEND2, MII_BMSR);
+		if (ret < 0)
+			return ret;
+
+		if (!(ret & BMSR_ANEGCOMPLETE))
+			return 0;
+	}
+
 	/* For C37 SGMII mode, we check DW_VR_MII_AN_INTR_STS for link
 	 * status, speed and duplex.
 	 */
@@ -1218,7 +1234,7 @@ static void xpcs_get_state(struct phylink_pcs *pcs, unsigned int neg_mode,
 				"xpcs_get_state_c73", ERR_PTR(ret));
 		break;
 	case DW_AN_C37_SGMII:
-		ret = xpcs_get_state_c37_sgmii(xpcs, state);
+		ret = xpcs_get_state_c37_sgmii(xpcs, neg_mode, state);
 		if (ret)
 			dev_err(&xpcs->mdiodev->dev, "%s returned %pe\n",
 				"xpcs_get_state_c37_sgmii", ERR_PTR(ret));
@@ -1535,7 +1551,8 @@ static const struct dw_xpcs_desc xpcs_desc_list[] = {
 		.mask = DW_XPCS_ID_MASK,
 		.pma = NXP_S32G_XPCS_PMA_ID,
 		.compat = nxp_s32g_xpcs_compat,
-		.quirks = DW_XPCS_QUIRK_NO_SOFT_RESET | DW_XPCS_QUIRK_NO_EEE,
+		.quirks = DW_XPCS_QUIRK_NO_SOFT_RESET | DW_XPCS_QUIRK_NO_EEE |
+			  DW_XPCS_QUIRK_SGMII_WAIT_AN,
 	},
 };
 

-- 
2.55.0

