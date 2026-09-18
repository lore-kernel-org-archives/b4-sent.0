From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:26 +0800
Subject: [PATCH 11/21] media: i2c: it6625: use unsigned int indices in EDID
 read/write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-11-78d72d7886a5@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=1460;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=NqCXYn3xhZ1IIhlAVGE1HXgnu3CsRL/n6ZRVnjAh6nw=;
 b=jOqA6KM0UKYUdWwV5r7kuGILkpP2dbium/P6VXPD81QNlemTzlveDZvPh0hKIHB27t1EEKvBG
 8vCfFbOiyCMDwmL2pH3gvOk3512qvUjzrTQObPOXpHHk4Lr6nu3i9nb
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_read_edid() and it6625_write_edid() iterate their block loop
with signed i/bank_ctrl locals holding only non-negative values; make
them unsigned int and keep err signed. Reorder the declarations to put
the pointer before the scalars while these functions are already being
touched.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index b580256d32f51465a620b639fc0134366cc6fcc1..328bd99f27cf84722caa184302cddeb9c3e667fb 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -660,8 +660,9 @@ static u64 it6625_get_pclk(struct it6625 *it6625)
 static int it6625_read_edid(struct it6625 *it6625, u8 *edid, int start_block,
 			    int num_blocks)
 {
-	int i, bank_ctrl, err = 0;
 	struct device *dev = it6625->dev;
+	unsigned int i, bank_ctrl;
+	int err = 0;
 
 	if (!edid) {
 		dev_err(dev, "edid buffer is NULL");
@@ -699,8 +700,9 @@ static int it6625_read_edid(struct it6625 *it6625, u8 *edid, int start_block,
 static int it6625_write_edid(struct it6625 *it6625, u8 *edid, int start_block,
 			     int num_blocks)
 {
-	int i, bank_ctrl, err = 0;
 	struct device *dev = it6625->dev;
+	unsigned int i, bank_ctrl;
+	int err = 0;
 
 	if (start_block < 0 || num_blocks <= 0 ||
 	    start_block > EDID_NUM_BLOCKS_MAX ||

-- 
2.34.1

