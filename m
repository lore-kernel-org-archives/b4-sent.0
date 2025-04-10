From: Michael Riesch <michael.riesch@collabora.com>
Date: Thu, 10 Apr 2025 21:41:32 +0200
Subject: [PATCH 3/3] media: dt-bindings: sony,imx415: update maintainer
 e-mail address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-maintainer-mriesch-v1-3-cdc5c6c68238@collabora.com>
References: <20250410-maintainer-mriesch-v1-0-cdc5c6c68238@collabora.com>
In-Reply-To: <20250410-maintainer-mriesch-v1-0-cdc5c6c68238@collabora.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Sascha Hauer <s.hauer@pengutronix.de>, Shawn Guo <shawnguo@kernel.org>, 
 Fabio Estevam <festevam@gmail.com>
Cc: Collabora Kernel Team <kernel@collabora.com>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, imx@lists.linux.dev, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744314122; l=1515;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=xr1ihcFoc0yPTwxBHQ/xwE7MT3EXhuIWkXBlu34zX7Y=;
 b=Or2MDjLm15qmFgm2NdavJqYIiJs0q4ObG6CAZMRqnCXmyh3ZVWR9zx4ry92uishm80J5AC2Ym
 8cMzmp9bw/uCtk99fkkoYmlX7FyXhjmDdcL4DhWaCx4GMuKG8M91VWD
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I recently left WolfVision but would like to continue to maintain the
Sony IMX415 image sensor driver. Update my e-mail address.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 Documentation/devicetree/bindings/media/i2c/sony,imx415.yaml | 2 +-
 MAINTAINERS                                                  | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/sony,imx415.yaml b/Documentation/devicetree/bindings/media/i2c/sony,imx415.yaml
index 34962c5c7006..7c11e871dca6 100644
--- a/Documentation/devicetree/bindings/media/i2c/sony,imx415.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/sony,imx415.yaml
@@ -7,7 +7,7 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 title: Sony IMX415 CMOS Image Sensor
 
 maintainers:
-  - Michael Riesch <michael.riesch@wolfvision.net>
+  - Michael Riesch <michael.riesch@collabora.com>
 
 description: |-
   The Sony IMX415 is a diagonal 6.4 mm (Type 1/2.8) CMOS active pixel type
diff --git a/MAINTAINERS b/MAINTAINERS
index c87b26eada7b..f02a895e5cb5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -22563,7 +22563,7 @@ F:	Documentation/devicetree/bindings/media/i2c/sony,imx412.yaml
 F:	drivers/media/i2c/imx412.c
 
 SONY IMX415 SENSOR DRIVER
-M:	Michael Riesch <michael.riesch@wolfvision.net>
+M:	Michael Riesch <michael.riesch@collabora.com>
 L:	linux-media@vger.kernel.org
 S:	Maintained
 T:	git git://linuxtv.org/media.git

-- 
2.39.5

