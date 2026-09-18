From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:19 +0800
Subject: [PATCH 04/21] media: i2c: it6625: drop unused bus field from
 struct it6625
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-4-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=822;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=O0b5O1RyDeNdNNk76taXPqiLok8wVKvLOP3Ji3Cxdyc=;
 b=EGOUNNXA+j2Zjowbr5YOg5d4qdmcLFrnEvC/b1AIpAh5KMffDz1tfdEryFqej662IUybmQpeX
 tTWE07/vFVbBYu8dNyNLpLbBn7rXjAgD50+xfHU1V1/D9D11fZllBL/
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct it6625::bus has no reader anywhere in the driver -- the mipi_csi2
configuration is produced fresh in it6625_get_mbus_config() and parsed
locally in it6625_parse_endpoint(), neither of which touches this field.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 42bdcc3af326ceb6c529b8da35836c49c8c43643..e18baa6e1a1933f301d9d3057c2c08411f104077 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -268,7 +268,6 @@ struct it6625 {
 	struct mutex if_state_lock;
 
 	struct v4l2_subdev sd;
-	struct v4l2_mbus_config_mipi_csi2 bus;
 	struct video_device *vdev;
 	struct media_pad pad;
 	struct v4l2_ctrl_handler hdl;

-- 
2.34.1

