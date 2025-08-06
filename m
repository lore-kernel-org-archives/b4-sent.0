From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 06 Aug 2025 11:13:16 +0800
Subject: [PATCH] scsi: hpsa: fix incorrect comment format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250806-scsi_typo-v1-1-ec353a303b31@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAEvIkmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCwMz3eLk4sz4ksqCfN00k+SU5NRkY2ODZGMloPqCotS0zAqwWdGxtbU
 Awh2GSVsAAAA=
X-Change-ID: 20250806-scsi_typo-f4cdcec330c3
To: Don Brace <don.brace@microchip.com>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: storagedev@microchip.com, linux-scsi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, wangyuli@uniontech.com, zhanjun@uniontech.com, 
 guanwentao@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754450003; l=908;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=3UMfS7qpU8IFgDaZz/llRfgTL2TQCQqfwbCh0auXswU=;
 b=t0BXVHA8W7v/uTiulr+eQUoGrooCc5YrZ9Jky3Vn+AQOPtQopjXntJJRezHHnQGJSQtpDBsz8
 u+p9dDnL4TDAw86Gq0f/sN0tnB3BIK0rRAyU6aRLbNwL5yjlVBkgEaU
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Comments should not have a leading plus sign.

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 drivers/scsi/hpsa.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/scsi/hpsa.c b/drivers/scsi/hpsa.c
index c73a71ac3c2901393826e86c0a53c58600fa86ae..3bb7a1d9af53a9a535b4bfa34c0d1d13b5918643 100644
--- a/drivers/scsi/hpsa.c
+++ b/drivers/scsi/hpsa.c
@@ -7632,8 +7632,8 @@ static void hpsa_free_cfgtables(struct ctlr_info *h)
 }
 
 /* Find and map CISS config table and transfer table
-+ * several items must be unmapped (freed) later
-+ * */
+ * several items must be unmapped (freed) later
+ */
 static int hpsa_find_cfgtables(struct ctlr_info *h)
 {
 	u64 cfg_offset;

---
base-commit: 6bcdbd62bd56e6d7383f9e06d9d148935b3c9b73
change-id: 20250806-scsi_typo-f4cdcec330c3

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

