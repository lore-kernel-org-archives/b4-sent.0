From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 25 Jun 2026 01:10:01 -0500
Subject: [PATCH] udmabuf: serialize the sg_table cache under the
 reservation lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-b4-disp-67d1f3db-v1-1-a47fb9edab9e@proton.me>
X-B4-Tracking: v=1; b=H4sIADjGPGoC/x3MTQqAIBBA4avErBtQS/u5SrRIZ6zZVChEEN09a
 fkt3nsgcxLOMFYPJL4ky7EX6LqCsC37yihUDEYZp5yx6FskySe6jnRsyKNSvRl0Hyl4CyU7E0e
 5/+U0v+8HHB1aSGIAAAA=
To: =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Gerd Hoffmann <kraxel@redhat.com>, 
 Vivek Kasireddy <vivek.kasireddy@intel.com>, 
 Sumit Semwal <sumit.semwal@linaro.org>
Cc: Gurchetan Singh <gurchetansingh@chromium.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linaro-mm-sig@lists.linaro.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782367800; l=4089;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=tbMBMPicpQt1QqKD+RCY9Vxm4yTDKoprdEZEpVOUo3g=;
 b=uTiRAaRRHN6K0aI7q5dY+Tx2srEy2QVFrHcunyVvDItOWdzlQAjI1XbWnYa3eMlrrVP6xoXuC
 3E3POaKKHdQChLdG3ck/9dbM/iaN/Clc8utwzYJADtY3DzS+gnDIOUU
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

begin_cpu_udmabuf() builds and caches ubuf->sg with an unserialised
check-then-set, and end_cpu_udmabuf() reads the same field unlocked. The
core invokes both cpu-access hooks without holding the reservation lock and
DMA_BUF_IOCTL_SYNC is unlocked, so concurrent SYNC ioctls on a shared
udmabuf fd race on ubuf->sg: two begins can both observe NULL and both call
get_sg_table(), and the later store orphans the earlier table and its DMA
mapping, which release_udmabuf() never frees. Each won race permanently
leaks an sg_table and an unbalanced DMA mapping.

Serialize both hooks under the buffer's reservation lock, as panfrost and
panthor do. dma_buf_begin/end_cpu_access() already annotate might_lock() on
that lock, so taking it here matches the documented contract.
Single-threaded callers are unaffected.

Fixes: 284562e1f348 ("udmabuf: implement begin_cpu_access/end_cpu_access hooks")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Same leak-with-dangling-pointer class as CVE-2024-56712 (export_udmabuf()
error path) -- a distinct site the 2024 fix does not cover.

udmabuf is the only exporter that lazily builds its sg_table cache inside the
cpu-access hook without serialising the check-then-set. The exporters that do
comparable in-hook cache work all take a lock first: panfrost and panthor
dma_resv_lock() (both hooks), omapdrm omap_obj->lock around its lazy page-get,
the dma-heaps buffer->lock, and the TTM/GEM exporters (amdgpu, i915, xe) their
object's reservation lock. tegra and videobuf2 take no lock here because they
only sync an sg_table built earlier, so there is nothing to serialise.

Confirmed with an out-of-tree A/B exercising the begin/begin race: this driver
built as a module with get_sg_table()/put_sg_table() counting allocations
against frees, driven by a userspace racer that creates 3000 udmabufs and fires
DMA_BUF_IOCTL_SYNC(SYNC_START) from N threads on each shared fd.

  arm                            leaked sg_tables (of 3000 buffers)
  vulnerable, 4 threads          4761
  control, 1 thread              0
  patched (resv lock), 4 threads 0

One sg_table and its DMA mapping leak per won race; the single-thread control
does not leak, isolating the race; with the lock the lazy-init runs once per
buffer (3000 allocations, zero leaked). end_cpu_udmabuf() is locked for the
same field too: an unlocked end could otherwise observe the transient IS_ERR
store begin makes before resetting ubuf->sg to NULL, and dereference it. In a
tighter 5000-iteration loop the unpatched leak runs around 15-20 MB/s of slab.
---
 drivers/dma-buf/udmabuf.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/drivers/dma-buf/udmabuf.c b/drivers/dma-buf/udmabuf.c
index bced421c0d65..702ae13b97d1 100644
--- a/drivers/dma-buf/udmabuf.c
+++ b/drivers/dma-buf/udmabuf.c
@@ -226,6 +226,8 @@ static int begin_cpu_udmabuf(struct dma_buf *buf,
 	struct device *dev = ubuf->device->this_device;
 	int ret = 0;
 
+	dma_resv_lock(buf->resv, NULL);
+
 	if (!ubuf->sg) {
 		ubuf->sg = get_sg_table(dev, buf, direction);
 		if (IS_ERR(ubuf->sg)) {
@@ -238,6 +240,8 @@ static int begin_cpu_udmabuf(struct dma_buf *buf,
 		dma_sync_sgtable_for_cpu(dev, ubuf->sg, direction);
 	}
 
+	dma_resv_unlock(buf->resv);
+
 	return ret;
 }
 
@@ -246,12 +250,18 @@ static int end_cpu_udmabuf(struct dma_buf *buf,
 {
 	struct udmabuf *ubuf = buf->priv;
 	struct device *dev = ubuf->device->this_device;
+	int ret = 0;
+
+	dma_resv_lock(buf->resv, NULL);
 
 	if (!ubuf->sg)
-		return -EINVAL;
+		ret = -EINVAL;
+	else
+		dma_sync_sgtable_for_device(dev, ubuf->sg, direction);
 
-	dma_sync_sgtable_for_device(dev, ubuf->sg, direction);
-	return 0;
+	dma_resv_unlock(buf->resv);
+
+	return ret;
 }
 
 static const struct dma_buf_ops udmabuf_ops = {

---
base-commit: 7eed1fb17959e721031555e5b5654083fe6a7d02
change-id: 20260625-b4-disp-67d1f3db-0082918fdcb5

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

