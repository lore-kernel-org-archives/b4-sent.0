From: Sam Day <me@samcday.com>
Date: Thu, 08 Jan 2026 08:30:21 +1000
Subject: [PATCH 2/2] usb: gadget: f_fs: fix DMA-BUF OUT queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-ffs-dmabuf-ioctl-fix-v1-2-e51633891a81@samcday.com>
References: <20260108-ffs-dmabuf-ioctl-fix-v1-0-e51633891a81@samcday.com>
In-Reply-To: <20260108-ffs-dmabuf-ioctl-fix-v1-0-e51633891a81@samcday.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sam Day <me@samcday.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767825022; l=2158;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=azguOzfXRNk8xkQSYbcIA+Axl0/kG7ysuSZ9qR/g6jg=;
 b=hauXppLXpTgJQeqrpzIRTyDFVd8M4vidOI0TYfgI3z8TBGtDvEGdl04J5eSKScUJ6Mwd/f3NI
 EvgVUJWO5PoCe8/PodkUd4mGnMQCn3ZubQtm/SkP7V7wZslejsbi2GN
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, DMA_FROM_DEVICE is used when attaching DMABUFs to IN
endpoints and DMA_TO_DEVICE for OUT endpoints. This is inverted from
how it should be.

The result is IOMMU read-only mappings placed on OUT queues,
triggering arm-smmu write faults.

Put differently, OUT endpoints flow data from host -> gadget, meaning
the UDC peripheral needs to have write access to the buffer to fill it
with the incoming data.

This commit flips the directions and updates the implicit-sync helpers
so IN endpoints act as readers and OUT endpoints as writers.

Signed-off-by: Sam Day <me@samcday.com>
Tested-by: David Heidelberg <david@ixit.cz>  # OnePlus 6T on sdm845-next-20251119
---
 drivers/usb/gadget/function/f_fs.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/usb/gadget/function/f_fs.c b/drivers/usb/gadget/function/f_fs.c
index 9ea1445bec97531f9c2bed678268bd6f76199bfb..a738d835f61e3d6b31363ccb6dda563336996b0e 100644
--- a/drivers/usb/gadget/function/f_fs.c
+++ b/drivers/usb/gadget/function/f_fs.c
@@ -1513,7 +1513,7 @@ static int ffs_dmabuf_attach(struct file *file, int fd)
 		goto err_dmabuf_detach;
 	}
 
-	dir = epfile->in ? DMA_FROM_DEVICE : DMA_TO_DEVICE;
+	dir = epfile->in ? DMA_TO_DEVICE : DMA_FROM_DEVICE;
 
 	err = ffs_dma_resv_lock(dmabuf, nonblock);
 	if (err)
@@ -1643,7 +1643,7 @@ static int ffs_dmabuf_transfer(struct file *file,
 	/* Make sure we don't have writers */
 	timeout = nonblock ? 0 : msecs_to_jiffies(DMABUF_ENQUEUE_TIMEOUT_MS);
 	retl = dma_resv_wait_timeout(dmabuf->resv,
-				     dma_resv_usage_rw(epfile->in),
+				     dma_resv_usage_rw(!epfile->in),
 				     true, timeout);
 	if (retl == 0)
 		retl = -EBUSY;
@@ -1688,7 +1688,7 @@ static int ffs_dmabuf_transfer(struct file *file,
 	dma_fence_init(&fence->base, &ffs_dmabuf_fence_ops,
 		       &priv->lock, priv->context, seqno);
 
-	resv_dir = epfile->in ? DMA_RESV_USAGE_WRITE : DMA_RESV_USAGE_READ;
+	resv_dir = epfile->in ? DMA_RESV_USAGE_READ : DMA_RESV_USAGE_WRITE;
 
 	dma_resv_add_fence(dmabuf->resv, &fence->base, resv_dir);
 	dma_resv_unlock(dmabuf->resv);

-- 
2.52.0

