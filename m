From: Michael Riesch <michael.riesch@collabora.com>
Date: Mon, 16 Feb 2026 13:28:48 +0100
Subject: [PATCH 2/2] media: synopsys: csi2rx: add missing kconfig
 dependency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-snps-csi2rx-v1-2-747bc7408f87@collabora.com>
References: <20260216-snps-csi2rx-v1-0-747bc7408f87@collabora.com>
In-Reply-To: <20260216-snps-csi2rx-v1-0-747bc7408f87@collabora.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Frank Li <Frank.Li@nxp.com>, 
 Dan Carpenter <dan.carpenter@linaro.org>
Cc: Collabora Kernel Team <kernel@collabora.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@kernel.org, Michael Riesch <michael.riesch@collabora.com>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771244928; l=1083;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=bgY+jc+2uqZDs40Q2hJUGLpFX/0F5uA7sZoal/DHrPA=;
 b=XS5jme6dD3eNof6m0qsSTKtUXpLB/FM0/lx+lwRfop0lsPEn64qyAdqK+gQJcufWjxOcdujAr
 YtMBQpFUBpwAqxw8RNOO11N41nbhmgj6JUVBnCra+AvEWstQpiUYQhE
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix "ERROR: modpost: "phy_mipi_dphy_get_default_config_for_hsclk"
[drivers/media/platform/synopsys/dw-mipi-csi2rx.ko] undefined!" by
selecting GENERIC_PHY_MIPI_DPHY in the Kconfig entry.

Fixes: 355a11004066 ("media: synopsys: add driver for the designware mipi csi-2 receiver")
Cc: stable@kernel.org
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202602130253.BZnVd4jh-lkp@intel.com/
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 drivers/media/platform/synopsys/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/media/platform/synopsys/Kconfig b/drivers/media/platform/synopsys/Kconfig
index e798ec00b189..bf2ac092fbb3 100644
--- a/drivers/media/platform/synopsys/Kconfig
+++ b/drivers/media/platform/synopsys/Kconfig
@@ -7,6 +7,7 @@ config VIDEO_DW_MIPI_CSI2RX
 	depends on VIDEO_DEV
 	depends on V4L_PLATFORM_DRIVERS
 	depends on PM && COMMON_CLK
+	select GENERIC_PHY_MIPI_DPHY
 	select MEDIA_CONTROLLER
 	select V4L2_FWNODE
 	select VIDEO_V4L2_SUBDEV_API

-- 
2.39.5

