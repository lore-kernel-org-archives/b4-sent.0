From: Dang Huynh <dang.huynh@mainlining.org>
Date: Sat, 08 Nov 2025 12:37:57 +0700
Subject: [PATCH v6 01/12] video: rockchip: dw-mipi-dsi: Depend on
 CONFIG_VIDEO_BRIDGE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251108-vop2-pt2-v6-1-d04c699262fb@mainlining.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=809;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=dF+S2vGhhZ3xeqXcRD+CelND3VvzktGZx/+nq+lUz0A=;
 b=/U/Vk4XXAZB3NukDkAaQUl3HDv9AcJmQ8LMt48Rioi7CHiTzYhJVY6iincsq8r53Irs5uaR81
 K01XKESvYVyDrX+AlSqqwKon51tpCMwkoYjfTwnJGth8Adp/uSuRJdv
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver is in video bridge class, so we must depend on it or
the driver will fail to init.

Reviewed-by: Svyatoslav Ryhel <clamor95@gmail.com>
Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 drivers/video/rockchip/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/video/rockchip/Kconfig b/drivers/video/rockchip/Kconfig
index 0f4550a29e3..dfd08f1e5d1 100644
--- a/drivers/video/rockchip/Kconfig
+++ b/drivers/video/rockchip/Kconfig
@@ -72,7 +72,7 @@ config DISPLAY_ROCKCHIP_MIPI
 
 config DISPLAY_ROCKCHIP_DW_MIPI
 	bool "Rockchip Designware MIPI"
-	depends on VIDEO_ROCKCHIP
+	depends on VIDEO_ROCKCHIP && VIDEO_BRIDGE
 	select VIDEO_DW_MIPI_DSI
 	help
 	  Select the Designware MIPI DSI controller in use on some Rockchip

-- 
2.51.2

