From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 11 Oct 2026 21:35:45 +0200
Subject: [PATCH v2 3/9] video: dw_mipi_dsi: sync LP command and clock lane
 handling with Linux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-pinephone-pro-defconfig-v2-3-6b7be35fbee7@protonmail.com>
References: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
In-Reply-To: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Ondrej Jirman <megi@xff.cz>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Lukasz Majewski <lukma@denx.de>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791747347; l=3331;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=6U3A16Eh7TIqRpAkW4FUKZxONalMrKI8Ls2Fpm0hs50=;
 b=b6aQScNsLBCPpJoveMBfxFAmPmVPhqI28C7Anr4GOqXpjTYWYIBhpT+mfann8jay6VzMltGX1
 Vg30HTyqvbtDLizbPRlkR75tvypHhLbPxRwQpf2MfcxDDA93mamNfaR
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Program DPI_LP_CMD_TIM when configuring a message, switch the
low-power command bit in VID_MODE_CFG instead of gating the clock
lane per message and set the clock lane control in set_mode()
for both command and video mode.

Based on megi's 0711c54e94c ("video: dw-mipi-dsi: Sync-up with
Linux driver"), https://codeberg.org/megi/u-boot

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/video/dw_mipi_dsi.c | 33 +++++++++++++++++++++++----------
 1 file changed, 23 insertions(+), 10 deletions(-)

diff --git a/drivers/video/dw_mipi_dsi.c b/drivers/video/dw_mipi_dsi.c
index c74fe678d12..fa22ee82b7e 100644
--- a/drivers/video/dw_mipi_dsi.c
+++ b/drivers/video/dw_mipi_dsi.c
@@ -85,6 +85,7 @@
 #define VID_MODE_TYPE_NON_BURST_SYNC_EVENTS	0x1
 #define VID_MODE_TYPE_BURST			0x2
 #define VID_MODE_TYPE_MASK			0x3
+#define ENABLE_LOW_POWER_CMD		BIT(15)
 
 #define DSI_VID_PKT_SIZE		0x3c
 #define VID_PKT_SIZE(p)			((p) & 0x3fff)
@@ -293,13 +294,28 @@ static void dw_mipi_message_config(struct dw_mipi_dsi *dsi,
 	bool lpm = msg->flags & MIPI_DSI_MSG_USE_LPM;
 	u32 val = 0;
 
+	/*
+	 * TODO dw drv improvements
+	 * largest packet sizes during hfp or during vsa/vpb/vfp
+	 * should be computed according to byte lane, lane number and only
+	 * if sending lp cmds in high speed is enable (PHY_TXREQUESTCLKHS)
+	 */
+	dsi_write(dsi, DSI_DPI_LP_CMD_TIM, OUTVACT_LPCMD_TIME(16)
+		  | INVACT_LPCMD_TIME(4));
+
 	if (msg->flags & MIPI_DSI_MSG_REQ_ACK)
 		val |= ACK_RQST_EN;
 	if (lpm)
 		val |= CMD_MODE_ALL_LP;
 
-	dsi_write(dsi, DSI_LPCLK_CTRL, lpm ? 0 : PHY_TXREQUESTCLKHS);
 	dsi_write(dsi, DSI_CMD_MODE_CFG, val);
+
+	val = dsi_read(dsi, DSI_VID_MODE_CFG);
+	if (lpm)
+		val |= ENABLE_LOW_POWER_CMD;
+	else
+		val &= ~ENABLE_LOW_POWER_CMD;
+	dsi_write(dsi, DSI_VID_MODE_CFG, val);
 }
 
 static int dw_mipi_dsi_gen_pkt_hdr_write(struct dw_mipi_dsi *dsi, u32 hdr_val)
@@ -463,17 +479,22 @@ static void dw_mipi_dsi_set_mode(struct dw_mipi_dsi *dsi,
 				 unsigned long mode_flags)
 {
 	const struct mipi_dsi_phy_ops *phy_ops = dsi->phy_ops;
+	u32 val;
 
 	dsi_write(dsi, DSI_PWR_UP, RESET);
 
 	if (mode_flags & MIPI_DSI_MODE_VIDEO) {
 		dsi_write(dsi, DSI_MODE_CFG, ENABLE_VIDEO_MODE);
 		dw_mipi_dsi_video_mode_config(dsi);
-		dsi_write(dsi, DSI_LPCLK_CTRL, PHY_TXREQUESTCLKHS);
 	} else {
 		dsi_write(dsi, DSI_MODE_CFG, ENABLE_CMD_MODE);
 	}
 
+	val = PHY_TXREQUESTCLKHS;
+	if (mode_flags & MIPI_DSI_CLOCK_NON_CONTINUOUS)
+		val |= AUTO_CLKLANE_CTRL;
+	dsi_write(dsi, DSI_LPCLK_CTRL, val);
+
 	if (phy_ops->post_set_mode)
 		phy_ops->post_set_mode(dsi->device, mode_flags);
 
@@ -544,14 +565,6 @@ static void dw_mipi_dsi_dpi_config(struct dw_mipi_dsi *dsi,
 	dsi_write(dsi, DSI_DPI_VCID, DPI_VCID(dsi->channel));
 	dsi_write(dsi, DSI_DPI_COLOR_CODING, color);
 	dsi_write(dsi, DSI_DPI_CFG_POL, val);
-	/*
-	 * TODO dw drv improvements
-	 * largest packet sizes during hfp or during vsa/vpb/vfp
-	 * should be computed according to byte lane, lane number and only
-	 * if sending lp cmds in high speed is enable (PHY_TXREQUESTCLKHS)
-	 */
-	dsi_write(dsi, DSI_DPI_LP_CMD_TIM, OUTVACT_LPCMD_TIME(4)
-		  | INVACT_LPCMD_TIME(4));
 }
 
 static void dw_mipi_dsi_packet_handler_config(struct dw_mipi_dsi *dsi)

-- 
2.55.0

