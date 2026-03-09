From: Jihan LIN <linjh22s@gmail.com>
Date: Mon, 09 Mar 2026 12:23:07 +0000
Subject: [PATCH RFC v2 4/5] zram: Use zcomp-managed streams for async write
 requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-b4_zcomp_stream-v2-4-7148622326eb@gmail.com>
References: <20260309-b4_zcomp_stream-v2-0-7148622326eb@gmail.com>
In-Reply-To: <20260309-b4_zcomp_stream-v2-0-7148622326eb@gmail.com>
To: Minchan Kim <minchan@kernel.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Jens Axboe <axboe@kernel.dk>
Cc: linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773058983; l=3798;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=v0DGgSS+E5bgvt8cBKnXuZ6r8eM9BVP7bcdiMehO2N4=;
 b=zwljVfG1zncWfD57mFttrzMqxef6yb2k6deJ19Qm8qYfJy3u8QDJK3byb+yduxIK6Tvk0LF7w
 N5PKY/tv4cBAJG1Rg5GthxCscul2Qk0o6fzkDouOpzjWoEkEIh/GK1/
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current per-CPU streams limit write concurrency to the number of online
CPUs. Hardware accelerators with deep submission queues can handle far
more concurrent requests. Use zcomp-managed streams for async write
requests to take advantage of this.

Modify zram_write_page() to accept a flag indicating the request is
asynchronous. If the bio request is considered non-synchronous and the
backend supports zcomp-managed streams, attempt to acquire one.
zcomp_stream_get() handles the fallback to per-CPU streams.

Sync writes block waiting for completion (e.g., blk_wait_io() in
submit_bio_wait() from callers), and remain on per-CPU streams for
per-request latency. Reads are unchanged since they are treated as
synchronous operations. Recompression also remains unchanged as it
prioritizes compression ratio.

Although zram_write_page() currently waits for compression to complete,
using zcomp-managed streams allows write concurrency to exceed the
number of CPUs.

Supporting multiple pages within a single bio request is deferred to
keep it simple and focused.

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
 drivers/block/zram/zram_drv.c | 21 +++++++++++++++++----
 1 file changed, 17 insertions(+), 4 deletions(-)

diff --git a/drivers/block/zram/zram_drv.c b/drivers/block/zram/zram_drv.c
index 7be88cfb56adb12fcc1edc6b4d42271044ef71b5..3db4579776f758c16006fd3108b4f778b84fea30 100644
--- a/drivers/block/zram/zram_drv.c
+++ b/drivers/block/zram/zram_drv.c
@@ -2083,6 +2083,7 @@ static int read_compressed_page(struct zram *zram, struct page *page, u32 index)
 	size = get_slot_size(zram, index);
 	prio = get_slot_comp_priority(zram, index);
 
+	/* Reads are treated as synchronous, see op_is_sync(). */
 	zstrm = zcomp_stream_get(zram->comps[prio], ZSTRM_DEFAULT);
 	src = zs_obj_read_begin(zram->mem_pool, handle, size,
 				zstrm->local_copy);
@@ -2249,7 +2250,8 @@ static int write_incompressible_page(struct zram *zram, struct page *page,
 	return 0;
 }
 
-static int zram_write_page(struct zram *zram, struct page *page, u32 index)
+static int zram_write_page(struct zram *zram, struct page *page, u32 index,
+			   bool is_async)
 {
 	int ret = 0;
 	unsigned long handle;
@@ -2265,7 +2267,16 @@ static int zram_write_page(struct zram *zram, struct page *page, u32 index)
 	if (same_filled)
 		return write_same_filled_page(zram, element, index);
 
-	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP], ZSTRM_DEFAULT);
+	/*
+	 * Using a zcomp-managed stream and waiting for compression makes this
+	 * appear synchronous.
+	 *
+	 * At this time, zram_bio_write handles pages one by one.
+	 * However, preferring zcomp-managed streams allows backends to utilize
+	 * their own resources.
+	 */
+	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP],
+				 is_async ? ZSTRM_PREFER_MGMT : ZSTRM_DEFAULT);
 	mem = kmap_local_page(page);
 	ret = zcomp_compress(zram->comps[ZRAM_PRIMARY_COMP], zstrm,
 			     mem, &comp_len);
@@ -2327,7 +2338,8 @@ static int zram_bvec_write_partial(struct zram *zram, struct bio_vec *bvec,
 	ret = zram_read_page(zram, page, index, bio);
 	if (!ret) {
 		memcpy_from_bvec(page_address(page) + offset, bvec);
-		ret = zram_write_page(zram, page, index);
+		ret = zram_write_page(zram, page, index,
+				      !op_is_sync(bio->bi_opf));
 	}
 	__free_page(page);
 	return ret;
@@ -2338,7 +2350,8 @@ static int zram_bvec_write(struct zram *zram, struct bio_vec *bvec,
 {
 	if (is_partial_io(bvec))
 		return zram_bvec_write_partial(zram, bvec, index, offset, bio);
-	return zram_write_page(zram, bvec->bv_page, index);
+	return zram_write_page(zram, bvec->bv_page, index,
+			       !op_is_sync(bio->bi_opf));
 }
 
 #ifdef CONFIG_ZRAM_MULTI_COMP

-- 
2.51.0

