From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Sat, 29 Aug 2026 16:06:33 +0300
Subject: [PATCH v2 1/2] media: i2c: imx258: Add wait after enabling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-imx258-add-reset-gpio-patch-v2-1-bfd27891e225@mainlining.org>
References: <20260829-imx258-add-reset-gpio-patch-v2-0-bfd27891e225@mainlining.org>
In-Reply-To: <20260829-imx258-add-reset-gpio-patch-v2-0-bfd27891e225@mainlining.org>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: git@luigi311.com, pavel@ucw.cz, tomm.merciai@gmail.com, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 =?utf-8?q?Ond=C5=99ej_Jirman?= <megi@xff.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788008809; l=852;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=6gFgGcWn8XWMZgFcAqImtkE7Mtn0Fv/loz0A+OqkWoQ=;
 b=uDYz4J8Nixs5xOqxBYgf/sToUz4lEo/oxloyl5W/XX50cB3pCXI9ryVqXDpD2cvMOCYz4mBB5
 gDjt0HwAdhpDyOM1OGRks8jJLKAZGPyV9NUsTA31ue5+WUOQEMa7t6Z
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After enabling the device, a delay is required before the sensor is
ready for CCI access. 0.4ms delay needed between enabling and
reading the ID register over CCI.

Link: https://lore.kernel.org/phone-devel/apF5oxsCf7MJt1lk@kekkonen.localdomain/T/#md6a0411e81a2e3a563c935348f2fb4f3d52df64f
Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 drivers/media/i2c/imx258.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/media/i2c/imx258.c b/drivers/media/i2c/imx258.c
index bc9ee449a87c..9c3a6579df0d 100644
--- a/drivers/media/i2c/imx258.c
+++ b/drivers/media/i2c/imx258.c
@@ -1129,6 +1129,7 @@ static int imx258_power_on(struct device *dev)
 		dev_err(dev, "failed to enable clock\n");
 		regulator_bulk_disable(IMX258_NUM_SUPPLIES, imx258->supplies);
 	}
+	fsleep(400);
 
 	return ret;
 }

-- 
2.54.0

