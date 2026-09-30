From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:23 +0800
Subject: [PATCH v2 05/21] media: i2c: it6625: drop stale GCC < 4.4.6
 workaround
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-5-e353f887e7fa@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=1310;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=V9bwEAyagMxudYN4xHUy2bQH/gYjrOpBukYLroS2Zxg=;
 b=MeNAGj4SzHM3hYJ/Ckl0R+DJp7ecCkMfb4tC4uUK5MPwF06n6DbCR/196J4lQWuquHy6zdnW8
 rlWpw4XnAToCaLNDFZlDqhRtB9ovwiPGau/bvBev3JWdvXzZvWx05kb
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kernel-wide minimum GCC version is 8.1 (scripts/min-tool-version.sh),
so the explicit .reserved = { 0 } initializer kept for GCC < 4.4.6 is no
longer needed in either v4l2_dv_timings_cap initializer.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index b09b331b20364a8e169429bb309d1112ec83d919..b747c08e092c7b35994cb36bb5bf7b99495282cb 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -331,8 +331,6 @@ static const s64 it6625_link_freq[] = {
  */
 static const struct v4l2_dv_timings_cap it6625_timings_cap = {
 	.type = V4L2_DV_BT_656_1120,
-	/* keep this initialization for compatibility with GCC < 4.4.6 */
-	.reserved = { 0 },
 
 	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 27000000, 300000000,
 			     V4L2_DV_BT_STD_CEA861 | V4L2_DV_BT_STD_DMT |
@@ -347,7 +345,6 @@ static const struct v4l2_dv_timings_cap it6625_timings_cap = {
  */
 static const struct v4l2_dv_timings_cap it6626_cphy_3trio_timings_cap = {
 	.type = V4L2_DV_BT_656_1120,
-	.reserved = { 0 },
 
 	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 27000000, 594000000,
 			     V4L2_DV_BT_STD_CEA861 | V4L2_DV_BT_STD_DMT |

-- 
2.34.1

