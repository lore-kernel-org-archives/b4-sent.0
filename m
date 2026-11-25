From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:46 +0100
Subject: [PATCH RFC v4 04/15] net: pcs: xpcs: allow a PCS to opt out of
 soft reset and EEE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-4-3bfe0589be8d@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=2142;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=XscJymCuOoPX6VkV4O1nIKYSBnUzCtjWiHRRdPqdbMk=;
 b=iE2FYHKkZBcU6n24n7zNpgnccWxNcvMAikDlY+jLN6198179BHbRw1XeT2teHMY9FSK6wFUv8
 dIL2U1KySspC9q2iEtKQHhV1fidG8GKop8Oba4PFSWj7J2idWFs6aFx
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a quirks mask to struct dw_xpcs_desc, with two flags:

 - DW_XPCS_QUIRK_NO_SOFT_RESET: no soft reset in pcs_pre_config(). When
   the XPCS shares its PMA with another controller, the reset belongs
   to a bring-up sequence owned by the platform.

 - DW_XPCS_QUIRK_NO_EEE: VR_MII_EEE_MCTRL0/1 are not implemented and
   must not be written.

No entry sets a quirk yet, so there is no functional change.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/pcs/pcs-xpcs.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/drivers/net/pcs/pcs-xpcs.c b/drivers/net/pcs/pcs-xpcs.c
index 6466e0ff2a98..442c64a731b7 100644
--- a/drivers/net/pcs/pcs-xpcs.c
+++ b/drivers/net/pcs/pcs-xpcs.c
@@ -158,10 +158,20 @@ struct dw_xpcs_compat {
 	int (*pma_config)(struct dw_xpcs *xpcs);
 };
 
+/*
+ * The integration owns the PCS reset sequence: skip the soft reset in
+ * pcs_pre_config(). Only for PCS without Clause 73, whose fault recovery
+ * still resets.
+ */
+#define DW_XPCS_QUIRK_NO_SOFT_RESET	BIT(0)
+/* VR_MII_EEE_MCTRL0/1 are not implemented */
+#define DW_XPCS_QUIRK_NO_EEE		BIT(1)
+
 struct dw_xpcs_desc {
 	u32 id;
 	u32 mask;
 	const struct dw_xpcs_compat *compat;
+	unsigned int quirks;
 };
 
 static const struct dw_xpcs_compat *
@@ -729,6 +739,9 @@ static void xpcs_pre_config(struct phylink_pcs *pcs, phy_interface_t interface)
 		dev_err(&xpcs->mdiodev->dev, "switch interface failed: %pe\n",
 			ERR_PTR(ret));
 
+	if (xpcs->desc->quirks & DW_XPCS_QUIRK_NO_SOFT_RESET)
+		xpcs->need_reset = false;
+
 	if (!xpcs->need_reset)
 		return;
 
@@ -1318,6 +1331,9 @@ static void xpcs_disable_eee(struct phylink_pcs *pcs)
 {
 	struct dw_xpcs *xpcs = phylink_pcs_to_xpcs(pcs);
 
+	if (xpcs->desc->quirks & DW_XPCS_QUIRK_NO_EEE)
+		return;
+
 	xpcs_config_eee(xpcs, false);
 }
 
@@ -1325,6 +1341,9 @@ static void xpcs_enable_eee(struct phylink_pcs *pcs)
 {
 	struct dw_xpcs *xpcs = phylink_pcs_to_xpcs(pcs);
 
+	if (xpcs->desc->quirks & DW_XPCS_QUIRK_NO_EEE)
+		return;
+
 	xpcs_config_eee(xpcs, true);
 }
 

-- 
2.55.0

