From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 03 Apr 2026 13:41:34 -0500
Subject: [PATCH] scsi: ufs: core: Disable timestamp for Kioxia
 THGJFJT0E25BAIP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-thgjfjt0e25baip-no-timestamp-v1-1-1ddb34225133@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBAAwK/EnlvYLCP6SnSwWmuDTFQiiP6ed
 JzLPBA5CEfoiwcCXxLldBlVWcC8GbcyypINilRLDdWYtnW3eyJWejLi0Z2Y5OCYzOGRukrZdtY
 NaYJc+MBW7r8fxvf9AJ3FIpJuAAAA
X-Change-ID: 20260403-thgjfjt0e25baip-no-timestamp-0812f6c54050
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775241715; l=1083;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=VUWuY9f9Hf6f2pny+U0MoADHfXbA8keKg9Eblgl1y5k=;
 b=RhJw/4rmpQ5Akk2QQ3JjlxqANiUNTcI3QnhkiLfcK03EJdB3bLDkejInolM+3NpMe20krQo+r
 z78hc0/WO6eAOGXdDwL93vYaGr+aZPWaCXgJWI36IW47PTXLugwZ8T7
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kioxia has another product that does not support the qTimestamp
attribute.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/ufs/core/ufshcd.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 5c3518f1f97c7f85854b66bf87c86d00b539fba6..4805e40ed4d78cd4b0c07cda0df6bb0f7e172cb1 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -315,6 +315,9 @@ static const struct ufs_dev_quirk ufs_fixups[] = {
 	{ .wmanufacturerid = UFS_VENDOR_TOSHIBA,
 	  .model = "THGLF2G9D8KBADG",
 	  .quirk = UFS_DEVICE_QUIRK_PA_TACTIVATE },
+	{ .wmanufacturerid = UFS_VENDOR_TOSHIBA,
+	  .model = "THGJFJT0E25BAIP",
+	  .quirk = UFS_DEVICE_QUIRK_NO_TIMESTAMP_SUPPORT },
 	{ .wmanufacturerid = UFS_VENDOR_TOSHIBA,
 	  .model = "THGJFJT1E45BATP",
 	  .quirk = UFS_DEVICE_QUIRK_NO_TIMESTAMP_SUPPORT },

---
base-commit: 2febe6e6ee6e34c7754eff3c4d81aa7b0dcb7979
change-id: 20260403-thgjfjt0e25baip-no-timestamp-0812f6c54050

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

