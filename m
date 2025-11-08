From: Dang Huynh <dang.huynh@mainlining.org>
Date: Sat, 08 Nov 2025 12:37:59 +0700
Subject: [PATCH v6 03/12] video: rockchip: dw_mipi_dsi: Proceed when
 external PHY is not defined
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251108-vop2-pt2-v6-3-d04c699262fb@mainlining.org>
References: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
In-Reply-To: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
To: u-boot@lists.denx.de
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Simon Glass <sjg@chromium.org>, Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Tom Rini <trini@konsulko.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Alexander Graf <agraf@csgraf.de>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Ion Agorria <ion@agorria.com>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 Dragan Simic <dsimic@manjaro.org>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Piotr Zalewski <pZ010001011111@proton.me>, 
 Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=905;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=9gpiuhGhHfrCxw0TDWhTuoGDRsbhqUw0wLwjeTCRv1w=;
 b=0CDyuVwl2cVmYV0u9ea1prK2/zD2L7e8D2AFHl0S2KuDPiZFuaFfK4vqC1U4Cez+BIJNHPJD+
 8uEb5KFwAm3CldKb4t9bo5sOkgK8qaEbf6eLFJaYCVckZJF1skvPA3V
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ondrej Jirman <megi@xff.cz>

In this case the DM returns ENOENT, not ENODATA.

Signed-off-by: Ondrej Jirman <megi@xff.cz>
Reviewed-by: Svyatoslav Ryhel <clamor95@gmail.com>
Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 drivers/video/rockchip/dw_mipi_dsi_rockchip.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
index c47992dfb13..95e825eb3d6 100644
--- a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
+++ b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
@@ -839,7 +839,7 @@ static int dw_mipi_dsi_rockchip_probe(struct udevice *dev)
 	 * NULL if it's not initialized.
 	 */
 	ret = generic_phy_get_by_name(dev, "dphy", &priv->phy);
-	if (ret && ret != -ENODATA) {
+	if (ret && ret != -ENOENT) {
 		dev_err(dev, "failed to get mipi dphy: %d\n", ret);
 		return ret;
 	}

-- 
2.51.2

