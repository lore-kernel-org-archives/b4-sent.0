From: Soufiane <soufianeda@tutanota.com>
Date: Tue, 10 Feb 2026 16:26:31 +0100
Subject: [PATCH] staging: atomisp: fix heap buffer overflow in framebuffer
 conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260210-atomisp-fix-v1-1-024429cbff31@tutanota.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDI0MD3cSS/NzM4gLdtMwKXYtUAwvjNHNTYzMLCyWgjoKiVKAw2LTo2Np
 aAMjY+oRdAAAA
X-Change-ID: 20260210-atomisp-fix-8e083f753688
To: sakari.ailus@linux.intel.com
Cc: linux-staging@lists.linux.dev, Soufiane <soufianeda@tutanota.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770737197; l=983;
 i=soufianeda@tutanota.com; s=20260210; h=from:subject:message-id;
 bh=02IOA1nCQPUgzJT/I1vQUUz6XZjDT1WpNqtxpsjfooI=;
 b=geFPqNN/T0BVfo4OYMZ3MxEJxzvH3LvSlXY88thCyVGuI7tvc2LId+BvyPTkgPJjyQvEs6WAZ
 9lUhugeSwnkDGY4aDnOrRTV5EnLI7RB8i//RlTqAZTPWVG+PNOuL8xi
X-Developer-Key: i=soufianeda@tutanota.com; a=ed25519;
 pk=UzU2pI3/kdLVX1NbSuU4LzRt28OBKkEmk+xBRMw7P+Q=
X-Endpoint-Received: by B4 Relay for soufianeda@tutanota.com/20260210 with auth_id=631
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Validate sizeimage against the allocated frame buffer size before
hmm_store() to prevent out-of-bounds write.

Signed-off-by: Soufiane <soufianeda@tutanota.com>
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

