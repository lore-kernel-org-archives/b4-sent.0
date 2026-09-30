From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:30 +0800
Subject: [PATCH v2 12/21] media: i2c: it6625: use unaligned/units helpers
 to decode pixel clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-12-e353f887e7fa@ite.com.tw>
References: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
In-Reply-To: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=1921;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=8ZknusIer/QhqdsYanmDhev+LrXQmML7xisTSO61el8=;
 b=GdMeC9TOcWdmfDi7E9VhUmWjUFp8gWqmKpXUbro+JtkbM7j2A7UPknMNloWFc+giBQn7q+wTS
 PaEfs0pyfiEDBWHKQZt8ChCPRsXgiru8fX9GZjIieI3o27qWc1GTvfI
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_get_pclk() manually assembled a big-endian u32 from a 4-byte
buffer with a shift-and-OR sequence, and multiplied by a bare 1000.
Read the register range with sizeof(ck), decode it with
get_unaligned_be32(), and use HZ_PER_KHZ to convert the kHz register
value to the Hz value V4L2 DV timings expect. Add the linux/unaligned.h
and linux/units.h includes these need. While touching this declaration
block, reorder it per reverse fir-tree.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 16 ++++++----------
 1 file changed, 6 insertions(+), 10 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index b72b1fdc8f6b96c807bf767b82a953a89b08120a..f77eb3ed63f7695cf9da277b46d9bab4a526e065 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -18,6 +18,8 @@
 #include <linux/slab.h>
 #include <linux/time64.h>
 #include <linux/timer.h>
+#include <linux/unaligned.h>
+#include <linux/units.h>
 #include <linux/v4l2-dv-timings.h>
 #include <linux/videodev2.h>
 #include <linux/workqueue.h>
@@ -633,28 +635,22 @@ static int get_audio_sampling_rate(struct it6625 *it6625)
 
 static u64 it6625_get_pclk(struct it6625 *it6625)
 {
-	u32 pclk;
 	u8 ck[4];
+	u32 pclk;
 	int ret;
 
-	ret = it6625_read_bytes(it6625, REG_VID_PCLK, ck, 4);
+	ret = it6625_read_bytes(it6625, REG_VID_PCLK, ck, sizeof(ck));
 	if (ret < 0) {
 		dev_err(it6625->dev, "failed to read pixel clock");
 		return 0;
 	}
 
-	pclk = ck[0];
-	pclk <<= 8;
-	pclk |= ck[1];
-	pclk <<= 8;
-	pclk |= ck[2];
-	pclk <<= 8;
-	pclk |= ck[3];
+	pclk = get_unaligned_be32(ck);
 
 	v4l2_dbg(1, debug, &it6625->sd, "%s: pclk=%u (%08x)",
 		 __func__, pclk, pclk);
 
-	return (u64)pclk * 1000;
+	return (u64)pclk * HZ_PER_KHZ;
 }
 
 static int it6625_read_edid(struct it6625 *it6625, u8 *edid, int start_block,

-- 
2.34.1

