From: Michael Riesch <michael.riesch@collabora.com>
Date: Thu, 10 Apr 2025 21:41:30 +0200
Subject: [PATCH 1/3] MAINTAINERS: add exclude for dt-bindings to imx entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-maintainer-mriesch-v1-1-cdc5c6c68238@collabora.com>
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
 devicetree@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744314121; l=1038;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=X1CVfLOeLPqWSee4KPG6jhbZlQYBoSFynMcMXTp5Z9o=;
 b=Zh/AQQfAuatrmJO0rGGXk/rTSqdO5Z4z+h9vttZOMHXxS93ra3H+h6dDtc4iWNBL9La9/+5i6
 kFrTAb9AP5FDFZ3PKwUkXvRkyklkaZvzcbXHu9TXUs3fBzzZGADR6IC
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the IMX (as in i.MX, the NXP SoCs) MAINTAINERS entry claims
everything that contains the name "imx", hanges to device tree
bindings for any Sony IMX image sensor are likely to be sent to the
maintainers listed therein. Add the missing exclude to fix that.

Fixes: da8b7f0fb02b ("MAINTAINERS: add all files matching "imx" and "mxs" to the IMX entry")
Suggested-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 MAINTAINERS | 1 +
 1 file changed, 1 insertion(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 96b827049501..c87b26eada7b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2519,6 +2519,7 @@ T:	git git://git.kernel.org/pub/scm/linux/kernel/git/shawnguo/linux.git
 F:	arch/arm/boot/dts/nxp/imx/
 F:	arch/arm/boot/dts/nxp/mxs/
 F:	arch/arm64/boot/dts/freescale/
+X:	Documentation/devicetree/bindings/media/i2c/
 X:	arch/arm64/boot/dts/freescale/fsl-*
 X:	arch/arm64/boot/dts/freescale/qoriq-*
 X:	drivers/media/i2c/

-- 
2.39.5

