From: Gabriel Prostitis <prostitisgabriel@gmail.com>
Date: Sun, 31 May 2026 23:04:41 +0200
Subject: [PATCH 2/2] USB: gadget: inode: fix mm lifetime handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-mm-uaf-fix-v1-2-91571cc6ca46@gmail.com>
References: <20260531-mm-uaf-fix-v1-0-91571cc6ca46@gmail.com>
In-Reply-To: <20260531-mm-uaf-fix-v1-0-91571cc6ca46@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Gabriel Prostitis <prostitisgabriel@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780261550; l=2138;
 i=prostitisgabriel@gmail.com; s=20260530; h=from:subject:message-id;
 bh=vEsZ4QwqvYlH70rsOhB9QVTgchod8aGQd1KQsxPk2MY=;
 b=CBMq6EY2jYW4/qQuk4vuyeWMbY/35Da4Bx0LXIeCPcDKA4uhhbwz2m2t2EByNaQw3putwapkH
 cfOA3ye99+DB0OWBbu0xy8d5KHCejS5yQQp21HaO4GpBjo0xSlsf4lI
X-Developer-Key: i=prostitisgabriel@gmail.com; a=ed25519;
 pk=FwuU+O6ZnvvnFVA45nfqkGlhSmC1P64HLtxRgBebOuY=
X-Endpoint-Received: by B4 Relay for prostitisgabriel@gmail.com/20260530 with auth_id=800
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

priv stores a pointer to the submitting task's mm_struct,
but does not currently hold a reference to it while async
requests are pending.

This can result in a use-after-free if the task exits before
completion handling finishes.

Take a reference with mmgrab() when queuing the read request
and release it with mmdrop() on request completion.

Signed-off-by: Gabriel Prostitis <prostitisgabriel@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 17 +++++++++++++----
 1 file changed, 13 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index d87a8ab51510..f9b7199afc9e 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -471,11 +471,17 @@ static void ep_user_copy_worker(struct work_struct *work)
 	struct kiocb *iocb = priv->iocb;
 	size_t ret;
 
-	kthread_use_mm(mm);
-	ret = copy_to_iter(priv->buf, priv->actual, &priv->to);
-	kthread_unuse_mm(mm);
-	if (!ret)
+	if (mmget_not_zero(mm)) {
+		kthread_use_mm(mm);
+		ret = copy_to_iter(priv->buf, priv->actual, &priv->to);
+		kthread_unuse_mm(mm);
+		mmput(mm);
+		if (!ret)
+			ret = -EFAULT;
+	} else {
 		ret = -EFAULT;
+	}
+	mmdrop(mm);
 
 	/* completing the iocb can drop the ctx and mm, don't touch mm after */
 	iocb->ki_complete(iocb, ret);
@@ -501,6 +507,7 @@ static void ep_aio_complete(struct usb_ep *ep, struct usb_request *req)
 	 * complete the aio request immediately.
 	 */
 	if (priv->to_free == NULL || unlikely(req->actual == 0)) {
+		mmdrop(priv->mm);
 		kfree(req->buf);
 		kfree(priv->to_free);
 		kfree(priv);
@@ -540,6 +547,7 @@ static ssize_t ep_aio(struct kiocb *iocb,
 	get_ep(epdata);
 	priv->epdata = epdata;
 	priv->actual = 0;
+	mmgrab(priv->mm);
 	priv->mm = current->mm; /* mm teardown waits for iocbs in exit_aio() */
 
 	/* each kiocb is coupled to one usb_request, but we can't
@@ -570,6 +578,7 @@ static ssize_t ep_aio(struct kiocb *iocb,
 
 fail:
 	spin_unlock_irq(&epdata->dev->lock);
+	mmdrop(priv->mm);
 	kfree(priv->to_free);
 	kfree(priv);
 	put_ep(epdata);

-- 
2.54.0

