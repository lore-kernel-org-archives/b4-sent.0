From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:21 +0800
Subject: [PATCH 06/21] media: i2c: it6625: use unsigned int loop indices in
 table lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-6-78d72d7886a5@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=1788;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=5Ctpnc+LLcR3m3GriRx3vFNF83f7OL4HJpZpnaEfXgE=;
 b=Bf3iH9gI31vUxKhbt9d5/ViXQWrtvJGccq+I5WKsqNl+vOvtGdr0McRq9Wgs0HCsKqqJ7tfkx
 cUfShiyMpY2CI6wzGZ8ZdtFmGp+8g+O/uiNhWqFcG4MfT9FupUEHBE1
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_csi_format_idx(), it6625_csi_mbus_code_idx(), and
it6625_regdump_print() iterate with a plain-signed loop index against
an unsigned bound. Declare the index as unsigned int directly in the
for() statement instead.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 12 +++---------
 1 file changed, 3 insertions(+), 9 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 97780c3d2d8fd3567ef18b3d2fc46b4e1f0758d7..9077f66187c647f85e41e571ff0d52e5e2ffdfdf 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -375,9 +375,7 @@ static const struct it6625_format_info {
 
 static inline int it6625_csi_format_idx(u8 csi_format)
 {
-	int i;
-
-	for (i = 0; i < ARRAY_SIZE(it6625_formats); i++) {
+	for (unsigned int i = 0; i < ARRAY_SIZE(it6625_formats); i++) {
 		if (it6625_formats[i].csi_format == csi_format)
 			return i;
 	}
@@ -387,9 +385,7 @@ static inline int it6625_csi_format_idx(u8 csi_format)
 
 static inline int it6625_csi_mbus_code_idx(u32 mbus_fmt_code)
 {
-	int i;
-
-	for (i = 0; i < ARRAY_SIZE(it6625_formats); i++) {
+	for (unsigned int i = 0; i < ARRAY_SIZE(it6625_formats); i++) {
 		if (it6625_formats[i].mbus_fmt_code == mbus_fmt_code)
 			return i;
 	}
@@ -1878,11 +1874,9 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 
 static void it6625_regdump_print(struct seq_file *s, const u8 *reg_buf)
 {
-	int i;
-
 	seq_puts(s, "     0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0A 0x0B 0x0C 0x0D 0x0E 0x0F\n");
 
-	for (i = 0; i < 256; i++) {
+	for (unsigned int i = 0; i < 256; i++) {
 		if (i % 16 == 0)
 			seq_printf(s, "[%02X] ", i & 0xF0);
 		seq_printf(s, "0x%02X ", reg_buf[i]);

-- 
2.34.1

