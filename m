From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 08 Dec 2025 16:13:12 +0200
Subject: [PATCH RESEND v8 20/21] media: i2c: remove MAX96717 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-gmsl2-3_serdes-v8-20-7b8d457e2e04@analog.com>
References: <20251208-gmsl2-3_serdes-v8-0-7b8d457e2e04@analog.com>
In-Reply-To: <20251208-gmsl2-3_serdes-v8-0-7b8d457e2e04@analog.com>
To: Tomi Valkeinen <tomi.valkeinen+renesas@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Julien Massot <julien.massot@collabora.com>, Rob Herring <robh@kernel.org>, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund@ragnatech.se>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-gpio@vger.kernel.org, 
 mitrutzceclan@gmail.com, Cosmin Tanislav <demonsingur@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765203192; l=2278;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=Uby6G6BvwgKOObBXcLlxO1bh2+JafLSgY3oYvgugXOs=;
 b=C7SsifaJN557+EViKCkav+E+c59VtDoptQYXCAvGND2AtQ190tO7bYnx6CfaxhBAcdmVX6Pzt
 biRWS6UP95tAuNT3uqDxNNqlz3UtdrZgDZD1V/cbXTKBJI96PXskAap
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cosmin Tanislav <demonsingur@gmail.com>

The previous MAX96717 driver has been removed and its functionality has
been moved to a MAX96717 driver which makes use of the Maxim GMSL2/3
serializer framework.

Signed-off-by: Cosmin Tanislav <demonsingur@gmail.com>
---
 MAINTAINERS                |  1 -
 drivers/media/i2c/Kconfig  | 16 ----------------
 drivers/media/i2c/Makefile |  1 -
 3 files changed, 18 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 6a6a04ce2787..ad7e28897062 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -15235,7 +15235,6 @@ M:	Julien Massot <julien.massot@collabora.com>
 L:	linux-media@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/media/i2c/maxim,max96717.yaml
-F:	drivers/media/i2c/max96717.c
 
 MAX9860 MONO AUDIO VOICE CODEC DRIVER
 M:	Peter Rosin <peda@axentia.se>
diff --git a/drivers/media/i2c/Kconfig b/drivers/media/i2c/Kconfig
index 37f86e6de969..4d3a861ee2f0 100644
--- a/drivers/media/i2c/Kconfig
+++ b/drivers/media/i2c/Kconfig
@@ -1701,22 +1701,6 @@ config VIDEO_MAX96714
 	  To compile this driver as a module, choose M here: the
 	  module will be called max96714.
 
-config VIDEO_MAX96717
-	tristate "Maxim MAX96717 GMSL2 Serializer support"
-	depends on I2C && VIDEO_DEV && COMMON_CLK
-	select I2C_MUX
-	select MEDIA_CONTROLLER
-	select GPIOLIB
-	select V4L2_CCI_I2C
-	select V4L2_FWNODE
-	select VIDEO_V4L2_SUBDEV_API
-	help
-	  Device driver for the Maxim MAX96717 GMSL2 Serializer.
-	  MAX96717 serializers convert video on a MIPI CSI-2
-	  input to a GMSL2 output.
-
-	  To compile this driver as a module, choose M here: the
-	  module will be called max96717.
 
 source "drivers/media/i2c/maxim-serdes/Kconfig"
 
diff --git a/drivers/media/i2c/Makefile b/drivers/media/i2c/Makefile
index be3200b23819..96bc49339341 100644
--- a/drivers/media/i2c/Makefile
+++ b/drivers/media/i2c/Makefile
@@ -70,7 +70,6 @@ obj-$(CONFIG_VIDEO_M52790) += m52790.o
 obj-$(CONFIG_VIDEO_MAX9271_LIB) += max9271.o
 obj-$(CONFIG_VIDEO_MAX9286) += max9286.o
 obj-$(CONFIG_VIDEO_MAX96714) += max96714.o
-obj-$(CONFIG_VIDEO_MAX96717) += max96717.o
 obj-$(CONFIG_VIDEO_MAXIM_SERDES) += maxim-serdes/
 obj-$(CONFIG_VIDEO_ML86V7667) += ml86v7667.o
 obj-$(CONFIG_VIDEO_MSP3400) += msp3400.o

-- 
2.43.0

