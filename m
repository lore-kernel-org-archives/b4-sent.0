From: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
Date: Fri, 18 Oct 2024 19:24:43 +0300
Subject: [PATCH v4] common: buffer access out-of-bounds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241018-overflow-v4-1-b0aed7711dc6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMqLEmcC/23MSwqDMBSF4a3IHTclL1rtyH0UByG50QtqSlLSi
 mTvpo47/A+Hb4eEkTDBo9khYqZEYa2hLw3YyawjMnK1QXKpBRctCxmjn8OHOaulQ39H7W9Q76+
 Inr4n9RxqT5TeIW6nnNVv/YNkxQRT3Nmu9dgpbvpxMTRfbVhgKKUc9tmesqAAAAA=
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729268684; l=1598;
 i=abdelrahmanyossef12@gmail.com; s=20241017; h=from:subject:message-id;
 bh=QWTUuGk9RwnfJAMjCAGxegxXtgyypiWYdpNK77oXhZk=;
 b=KaI5JXvxeLwgryzpnRRi4dhL+K5uR2AGbJTXgkS0koCNEXaHCBxBVzuHbzAEipFKi4fZyoQzX
 Cee7oD41pjHBbb2TgbMFfWO5ey8S8sDj0Q9zjLLkrdDb8GQTFe1FS3t
X-Developer-Key: i=abdelrahmanyossef12@gmail.com; a=ed25519;
 pk=ayjFVDSRo1qKm+PGih8rsNvcMQvJ4ROQWuZWrYU8ujc=
X-Endpoint-Received: by B4 Relay for abdelrahmanyossef12@gmail.com/20241017 with auth_id=251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

in file_detect_type() to detect file of type socfpga_xload you need at least
68 bytes bytes, so we need to check if we have enough bufsize.
So I moved it after checking if `bufsize >= 256`.

Signed-off-by: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
---
This patch is a replacement of the last one because there were some issues with it
---
To: Sascha Hauer <s.hauer@pengutronix.de>
To: open list:BAREBOX <barebox@lists.infradead.org>
Signed-off-by: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
---
 common/filetype.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/common/filetype.c b/common/filetype.c
index 3690d4ae07..67ae4916d1 100644
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
@@ -388,6 +385,9 @@ enum filetype file_detect_type(const void *_buf, size_t bufsize)
 	if (bufsize < 256)
 		return filetype_unknown;
 
+	if (buf[16] == 0x31305341)
+		return filetype_socfpga_xload;
+
 	if (strncmp(buf8, "STM\x32", 4) == 0) {
 		if (buf8[74] == 0x01) {
 			switch(le32_to_cpu(buf[63])) {

---
base-commit: 9d47ff66c3892c5a6ddd4704993365a797fbeb68
change-id: 20241018-overflow-dc42def7e4f6

Best regards,
-- 
Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>

