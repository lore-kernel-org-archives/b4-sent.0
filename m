From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 05 Jul 2026 23:35:37 -0500
Subject: [PATCH] scsi: ses: skip an enclosure status page shorter than its
 header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-b4-disp-e1aca452-v1-1-1dab8448608c@proton.me>
X-B4-Tracking: v=1; b=H4sIAJgwS2oC/x3MQQqAIBBA0avIrBswMbWuEi20xpqNhUIE0t2Tl
 m/xf4VCmanAJCpkurnwmRr6TsB6+LQT8tYMSiojrRwwaNy4XEi9X70eFDofyYTRSmc0tOzKFPn
 5l/Pyvh8Gzw4UYgAAAA==
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783312536; l=2791;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=MxE58RITmygpQSbsJycrFmCxluTgG75tsEkUGNlJGRI=;
 b=PH3FbW1BjN8Y+/lYFDYJ31CMtZXWgqnwWJcVGXu26VbN6CqeN/ZyyjoKUypCdGNTIHQsBQ+Uf
 aF9TRHbNd1jBQtdVh1+SDQYaYDrpZDpl8g/rK63if8MfstfJYEZ1ukL
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ses_intf_add() trusts the length an enclosure reports for its diagnostic
page 2. ses_set_page2_descriptor() clears everything past the eight-byte
status-page header; when the enclosure reports a shorter page,
page2_len - 8 underflows to a huge size_t and the clear runs off the
undersized allocation -- a heap out-of-bounds write, reached through a
sysfs component-control write, that panics the host.

Skip a page 2 too short for its header, as a page 2 whose RECEIVE
DIAGNOSTIC fails is already skipped: the enclosure still registers from
page 1, and ses_page2_supported() then reports no page 2, so the clear
is never reached. Conforming enclosures are unaffected.

Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproduced on v7.2-rc1 under KASAN (CONFIG_KASAN_INLINE=y,
kasan.fault=panic). ses_set_page2_descriptor() is static and reached only
through the sysfs component-control path, so the clear is exercised
directly by an in-kernel litmus (page2 = kzalloc(4), then
memset(page2 + 8, 0, page2_len - 8) with page2_len = 4):

  A (no guard): BUG: KASAN: out-of-bounds write of size
    18446744073709551612 at a 4-byte kmalloc-8 region; kernel panic.
  B (this patch): the short page 2 is skipped; page2 stays NULL,
    ses_page2_supported() is false, the clear is never reached. Clean.
  Control (page2_len = 64): the clear stays in-bounds. Clean.
  m32/m64: ASan negative-size-param (size = -4), 4 bytes past the region.

The guard bails before ses_dev->page2 is set, so no accessor reaches
ses_set_page2_descriptor(); every accessor is gated by
ses_page2_supported() (page2 != NULL).

This fixes only the header underflow. It does not bound the descriptor
walk against the page-1 element count -- the separate concern of commit
801ab13d50cf ("scsi: ses: Fix possible desc_ptr out-of-bounds accesses")
and its siblings. No Fixes: tag: the flaw dates to the 2008 ses ULD,
unreachable in a grafted tree, and that series set the Cc: stable@-without-

Fixes: precedent for this class.
---
 drivers/scsi/ses.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/scsi/ses.c b/drivers/scsi/ses.c
index 4c348645b04e..f77054695e12 100644
--- a/drivers/scsi/ses.c
+++ b/drivers/scsi/ses.c
@@ -766,6 +766,9 @@ static int ses_intf_add(struct device *cdev)
 		goto page2_not_supported;
 
 	len = (hdr_buf[2] << 8) + hdr_buf[3] + 4;
+	/* a status page too short for its 8-byte header carries no page 2 */
+	if (len < 8)
+		goto page2_not_supported;
 	buf = kzalloc(len, GFP_KERNEL);
 	if (!buf)
 		goto err_free;

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260705-b4-disp-e1aca452-8afe6b970864

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

