From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Mon, 28 Oct 2024 21:24:58 +0100
Subject: [PATCH v4 16/16] net: stmmac: dwmac-s32: Read PTP clock rate when
 ready
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241028-upstream_s32cc_gmac-v4-16-03618f10e3e2@oss.nxp.com>
References: <20241028-upstream_s32cc_gmac-v4-0-03618f10e3e2@oss.nxp.com>
In-Reply-To: <20241028-upstream_s32cc_gmac-v4-0-03618f10e3e2@oss.nxp.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <joabreu@synopsys.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Vinod Koul <vkoul@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Emil Renner Berthing <kernel@esmil.dk>, 
 Minda Chen <minda.chen@starfivetech.com>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>, 
 Iyappan Subramanian <iyappan@os.amperecomputing.com>, 
 Keyur Chudgar <keyur@os.amperecomputing.com>, 
 Quan Nguyen <quan@os.amperecomputing.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>
Cc: linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, linux-arm-msm@vger.kernel.org, imx@lists.linux.dev, 
 devicetree@vger.kernel.org, NXP S32 Linux Team <s32@nxp.com>, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 Andrei Botila <andrei.botila@nxp.org>, 
 Jacob Keller <jacob.e.keller@intel.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730147124; l=1605;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=LsZsEsLk0S5TfmlHZCV6HTyBWNimPqjm1epTUQoYEEY=;
 b=UQ0dGVjkzm5GF1d8SPLrApbJm5eP1wcEFzCOmIZsO2S6Axeju/ihEdVNgR5Ymfi+y/1JYAjtu
 8gaokdVXYkrAPmWNLUbafaETbKpSQPUHkt0TuYOSgaxtqsEpslpq/0U
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PTP clock is read by stmmac_platform during DT parse.
On S32G/R the clock is not ready and returns 0. Postpone
reading of the clock on PTP init.

Co-developed-by: Andrei Botila <andrei.botila@nxp.org>
Signed-off-by: Andrei Botila <andrei.botila@nxp.org>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
Reviewed-by: Jacob Keller <jacob.e.keller@intel.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c
index fba221c37594..da2cdcfd0529 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c
@@ -140,6 +140,18 @@ static void s32_fix_mac_speed(void *priv, unsigned int speed, unsigned int mode)
 		dev_err(gmac->dev, "Can't set tx clock\n");
 }
 
+static void s32_dwmac_ptp_clk_freq_config(struct stmmac_priv *priv)
+{
+	struct plat_stmmacenet_data *plat = priv->plat;
+
+	if (!plat->clk_ptp_ref)
+		return;
+
+	plat->clk_ptp_rate = clk_get_rate(plat->clk_ptp_ref);
+
+	netdev_dbg(priv->dev, "PTP rate %lu\n", plat->clk_ptp_rate);
+}
+
 static int s32_dwmac_probe(struct platform_device *pdev)
 {
 	struct plat_stmmacenet_data *plat;
@@ -195,6 +207,7 @@ static int s32_dwmac_probe(struct platform_device *pdev)
 	plat->init = s32_gmac_init;
 	plat->exit = s32_gmac_exit;
 	plat->fix_mac_speed = s32_fix_mac_speed;
+	plat->ptp_clk_freq_config = s32_dwmac_ptp_clk_freq_config;
 
 	plat->bsp_priv = gmac;
 

-- 
2.46.0

