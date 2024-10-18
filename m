From: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
Date: Fri, 18 Oct 2024 14:45:56 +0300
Subject: [PATCH v2 2/2] common: buffer access out-of-bounds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241018-errors_fixes-v2-2-7f49d5a0087b@gmail.com>
References: <20241018-errors_fixes-v2-0-7f49d5a0087b@gmail.com>
In-Reply-To: <20241018-errors_fixes-v2-0-7f49d5a0087b@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729251992; l=1246;
 i=abdelrahmanyossef12@gmail.com; s=20241017; h=from:subject:message-id;
 bh=ZQGlteveeYHhMUHGwjTXIUeYQOG4oblMLEUZ2E18yDo=;
 b=ZU+Uk/HSWvwitMEyW/8+oyd2HafLdUKHvIBaI8s/UWgdrbHTASe4MC/WrPbHNSxcUxpZgSG08
 gTY9m96DrQ1B3V+l7Xrn6uiOoFTGnCMHkUf6UUjErn9Ow9Uys0BOBG0
X-Developer-Key: i=abdelrahmanyossef12@gmail.com; a=ed25519;
 pk=ayjFVDSRo1qKm+PGih8rsNvcMQvJ4ROQWuZWrYU8ujc=
X-Endpoint-Received: by B4 Relay for abdelrahmanyossef12@gmail.com/20241017 with auth_id=251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

in file_detect_type() to detect file of type socfpga_xload you need at least
68 bytes bytes, so we need to check if we have enough bufsize.
So I moved it after checking if `bufsize >= 256`.

Signed-off-by: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
---
 common/filetype.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/common/filetype.c b/common/filetype.c
index 3690d4ae07..3f74871d7f 100644
--- a/common/filetype.c
+++ b/common/filetype.c
@@ -374,9 +374,6 @@ enum filetype file_detect_type(const void *_buf, size_t bufsize)
 	if (le32_to_cpu(buf[5]) == 0x504d5453)
 		return filetype_mxs_bootstream;
 
-	if (buf[16] == 0x31305341)
-		return filetype_socfpga_xload;
-
 	if (is_barebox_arm_head(_buf))
 		return filetype_arm_barebox;
 	if (buf[9] == 0x016f2818 || buf[9] == 0x18286f01)
@@ -388,7 +385,10 @@ enum filetype file_detect_type(const void *_buf, size_t bufsize)
 	if (bufsize < 256)
 		return filetype_unknown;
 
-	if (strncmp(buf8, "STM\x32", 4) == 0) {
+	if (buf[16] == 0x31305341)
+		return filetype_socfpga_xload;
+
+    if (strncmp(buf8, "STM\x32", 4) == 0) {
 		if (buf8[74] == 0x01) {
 			switch(le32_to_cpu(buf[63])) {
 			case 0x00000000:

-- 
2.43.0

