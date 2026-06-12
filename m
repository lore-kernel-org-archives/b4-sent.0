From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 12 Jun 2026 15:57:57 +0100
Subject: [PATCH] usb: gadget: f_fs: Fix fence cleanup in
 ffs_dmabuf_transfer() error paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260612-fix-f_fs-fence-cleanup-v1-1-79f489b0efe9@analog.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7bsEWrOgrEWG61kJYKEUQ/T3pO
 DAzD2ROwhl69UDiS7LssUBdKXCrjQuj+MJAmhrd1IRBbgxTyBg4Oka3sY3nga3tNPmZjNEWSnw
 kLuY/Hsb3/QAXluEHaAAAAA==
X-Change-ID: 20260612-fix-f_fs-fence-cleanup-7a802db2550a
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Simona Vetter <simona.vetter@ffwll.ch>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Paul Cercueil <paul@crapouillou.net>
Cc: linux-usb@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781276421; l=1859;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=BOlKoX2q6H6KtLn6NlDIY91aGSPjYvKunR5y99ZooVc=;
 b=vKY+TxEfbZripG/059i4l2KhTtY+qMtIswZq2uT69H1t5tfWc2sCBRhfwnPIG3994jtv9p0ul
 HCkY80dWVJfBnlY75/cUL46MDfw164GHmw+6OBWbmFlzn9U4VjpqwwJ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The error paths for endpoint-disabled (ESHUTDOWN) and request-allocation
failure (ENOMEM) in ffs_dmabuf_transfer() jump to err_fence_put which
calls dma_fence_put() on the fence. However, at that point the fence has
only been kmalloc'd — dma_fence_init() has not been called yet, so the
refcount and the fence ops are uninitialized. Calling dma_fence_put() on
such an object leads to undefined behavior.

Use kfree() instead, since the fence is just a plain allocation at this
stage, and rename the label to err_fence_free to reflect the actual
cleanup action.

Fixes: 7b07a2a7ca02 ("usb: gadget: functionfs: Add DMABUF import interface")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/usb/gadget/function/f_fs.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/gadget/function/f_fs.c b/drivers/usb/gadget/function/f_fs.c
index 75912ce6ab556..ac8c53789ec20 100644
--- a/drivers/usb/gadget/function/f_fs.c
+++ b/drivers/usb/gadget/function/f_fs.c
@@ -1682,13 +1682,13 @@ static int ffs_dmabuf_transfer(struct file *file,
 	/* In the meantime, endpoint got disabled or changed. */
 	if (epfile->ep != ep) {
 		ret = -ESHUTDOWN;
-		goto err_fence_put;
+		goto err_fence_free;
 	}
 
 	usb_req = usb_ep_alloc_request(ep->ep, GFP_ATOMIC);
 	if (!usb_req) {
 		ret = -ENOMEM;
-		goto err_fence_put;
+		goto err_fence_free;
 	}
 
 	/*
@@ -1736,9 +1736,9 @@ static int ffs_dmabuf_transfer(struct file *file,
 
 	return ret;
 
-err_fence_put:
+err_fence_free:
 	spin_unlock_irq(&epfile->ffs->eps_lock);
-	dma_fence_put(&fence->base);
+	kfree(fence);
 err_resv_unlock:
 	dma_resv_unlock(dmabuf->resv);
 err_attachment_put:

---
base-commit: f176a7c3e44f80b4493d22aa12d02673243ec7d8
change-id: 20260612-fix-f_fs-fence-cleanup-7a802db2550a
--

Thanks!
- Nuno Sá

