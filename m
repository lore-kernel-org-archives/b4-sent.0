From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 03 Nov 2026 11:05:08 +0800
Subject: [PATCH v2 5/5] media: i2c: it6625: lower the minimum pixel clock
 to 25 MHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-upstream-it6625-dv-timings-fix-v2-5-127b879da6d3@ite.com.tw>
References: <20261103-upstream-it6625-dv-timings-fix-v2-0-127b879da6d3@ite.com.tw>
In-Reply-To: <20261103-upstream-it6625-dv-timings-fix-v2-0-127b879da6d3@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793675109; l=1934;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=LZ+01dAE5B+ehttmwPegWfW9eW+Lb7d1dAXHvLm5fuE=;
 b=63CfZnhcww7zjaxEPbL+R5JhzqZWoK6olMDG+FZBwr1E63OWqTbvVrwUHAZtSxazpekbJ4QFi
 sSdctpogeudCS+Vuj6y6/RX70xgFZTCE3x5rsigM2NdoIovbSaPOjph
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 27 MHz minimum pixel clock rejected 640x480p59.94 and 640x480p60
(25.175 and 25.2 MHz), the lowest CEA-861 format, both in
QUERY_DV_TIMINGS and in S_DV_TIMINGS. A 27 MHz format whose measured
pixel clock comes out slightly below nominal can be rejected as well.

Use 25 MHz as the minimum. This admits the 640x480 formats but still
keeps out the 13.5 MHz 480i/576i presets.

Change both timings caps. The minimum doesn't depend on the CSI-2 PHY
configuration; the three-trio C-PHY cap only raises the maximum.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 75bcb8304c02c7c0c5feeb02af6c93378fcfa5d7..561e5b5f75d887da01755fa292d6c04e4fb22c16 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -342,7 +342,7 @@ static const struct v4l2_dv_timings_cap it6625_timings_cap = {
 	/* keep this initialization for compatibility with GCC < 4.4.6 */
 	.reserved = { 0 },
 
-	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 27000000, 300000000,
+	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 25000000, 300000000,
 			     V4L2_DV_BT_STD_CEA861 | V4L2_DV_BT_STD_DMT |
 			     V4L2_DV_BT_STD_GTF | V4L2_DV_BT_STD_CVT,
 			     V4L2_DV_BT_CAP_PROGRESSIVE | V4L2_DV_BT_CAP_INTERLACED |
@@ -357,7 +357,7 @@ static const struct v4l2_dv_timings_cap it6626_cphy_3trio_timings_cap = {
 	.type = V4L2_DV_BT_656_1120,
 	.reserved = { 0 },
 
-	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 27000000, 594000000,
+	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 25000000, 594000000,
 			     V4L2_DV_BT_STD_CEA861 | V4L2_DV_BT_STD_DMT |
 			     V4L2_DV_BT_STD_GTF | V4L2_DV_BT_STD_CVT,
 			     V4L2_DV_BT_CAP_PROGRESSIVE | V4L2_DV_BT_CAP_INTERLACED |

-- 
2.34.1

