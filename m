From: Soufiane <soufianeda@tutanota.com>
Date: Tue, 10 Feb 2026 16:35:27 +0100
Subject: [PATCH v2] staging: atomisp: fix heap buffer overflow in
 framebuffer conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260210-atomisp-fix-v2-1-2e1e15f1b774@tutanota.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22MQQ7CIBAAv9LsWQwstWJP/sP0gAh2D4UGkGga/
 i727HEmmdkg2Ug2wdhtEG2hRME3wEMHZtb+aRk9GgNyHDgKznQOC6WVOXozZbmS7nySg1LQijX
 apvfbbWo8U8ohfvZ5ET/7/1MEE4xj3+PF3J2T4ppfWfuQ9dGEBaZa6xfRn5UsqQAAAA==
X-Change-ID: 20260210-atomisp-fix-8e083f753688
To: andy@kernel.org, hansg@kernel.org, mchehab@kernel.org, 
 sakari.ailus@linux.intel.com
Cc: gregkh@linuxfoundation.org, linux-media@vger.kernel.org, 
 linux-staging@lists.linux.dev, Soufiane <soufianeda@tutanota.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770737743; l=1170;
 i=soufianeda@tutanota.com; s=20260210; h=from:subject:message-id;
 bh=LIUHpU74WY0uQyqdYbvaZ7O7xKufBT6aHUwY0/k5w9k=;
 b=rvOtB6aPKYanBXLUZDLJTTwFiLVGt8ns4rKokbVb1Lmbrgf+UW2zv3H2/mRt0aiN2A0mwC7u9
 HtRzFBEMl6OBe36d9HpHylgcNkZE13kZ8DnBzwKoo+xO/LcjfOHqODQ
X-Developer-Key: i=soufianeda@tutanota.com; a=ed25519;
 pk=UzU2pI3/kdLVX1NbSuU4LzRt28OBKkEmk+xBRMw7P+Q=
X-Endpoint-Received: by B4 Relay for soufianeda@tutanota.com/20260210 with auth_id=631
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Validate sizeimage against the allocated frame buffer size before
hmm_store() to prevent out-of-bounds write.

Signed-off-by: Soufiane <soufianeda@tutanota.com>
---
Changes in v2:
- Resend with all recipients (v1 only reached sakari and linux-staging)
- Link to v1: https://lore.kernel.org/r/20260210-atomisp-fix-v1-1-024429cbff31@tutanota.com
---
 drivers/staging/media/atomisp/pci/atomisp_cmd.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/staging/media/atomisp/pci/atomisp_cmd.c b/drivers/staging/media/atomisp/pci/atomisp_cmd.c
index 3a4eb4f6d3be..ca7ffc7855ac 100644
--- a/drivers/staging/media/atomisp/pci/atomisp_cmd.c
+++ b/drivers/staging/media/atomisp/pci/atomisp_cmd.c
@@ -3326,6 +3326,11 @@ atomisp_v4l2_framebuffer_to_css_frame(const struct v4l2_framebuffer *arg,
 		goto err;
 	}
 
+	if (arg->fmt.sizeimage > res->data_bytes) {
+		ret = -EINVAL;
+		goto err;
+	}
+
 	tmp_buf = vmalloc(arg->fmt.sizeimage);
 	if (!tmp_buf) {
 		ret = -ENOMEM;

---
base-commit: 72c395024dac5e215136cbff793455f065603b06
change-id: 20260210-atomisp-fix-8e083f753688

Best regards,
-- 
Soufiane <soufianeda@tutanota.com>

