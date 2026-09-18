From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:30 +0800
Subject: [PATCH 15/21] media: i2c: it6625: use early returns in
 it6625_update_timings_if_changed()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-15-78d72d7886a5@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=1398;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=nhYLeOnWUfOr4p9kaFWjpJjBGZeXmu4xl/oIvvdqeOc=;
 b=pVtstrPUw4pFLakci5deW/zW81qVnHiqawNZYO6gByOeaIpB71m9q3FtnfSZy60RhvEFlEMfG
 kWtmxo6iHePDMlPA3aGscJHYw318ej/jcBQn1cJx6XgSJfcSljadHgO
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert the if/else if/else chain that only ever assigns a single
ret value to early returns. guard(mutex)(...) is scoped to the whole
function body, so an early return still unlocks correctly.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 21 +++++++++------------
 1 file changed, 9 insertions(+), 12 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 882eda8b836d655585ba45b0a33d1c068bb3a8ee..db962bc100cad9f4d71fa4156b10ff5b4c952a7c 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -1431,20 +1431,17 @@ static int
 it6625_update_timings_if_changed(struct it6625 *it6625,
 				 const struct v4l2_dv_timings *timings)
 {
-	int ret;
-
 	guard(mutex)(&it6625->it6625_lock);
-	if (v4l2_match_dv_timings(&it6625->timings, timings, 0, false)) {
-		ret = 0;
-	} else if (!v4l2_valid_dv_timings(timings, it6625_get_timings_cap(it6625),
-					  NULL, NULL)) {
-		ret = -ERANGE;
-	} else {
-		it6625->timings = *timings;
-		ret = 1;
-	}
 
-	return ret;
+	if (v4l2_match_dv_timings(&it6625->timings, timings, 0, false))
+		return 0;
+
+	if (!v4l2_valid_dv_timings(timings, it6625_get_timings_cap(it6625), NULL, NULL))
+		return -ERANGE;
+
+	it6625->timings = *timings;
+
+	return 1;
 }
 
 static int it6625_enum_dv_timings(struct v4l2_subdev *sd,

-- 
2.34.1

