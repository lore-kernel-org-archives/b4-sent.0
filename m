From: Jihan LIN <linjh22s@gmail.com>
Date: Wed, 04 Feb 2026 13:48:53 +0000
Subject: [PATCH RFC 3/3] zram: Use zcomp-managed streams for async write
 requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-b4_zcomp_stream-v1-3-35c06ce1d332@gmail.com>
References: <20260204-b4_zcomp_stream-v1-0-35c06ce1d332@gmail.com>
In-Reply-To: <20260204-b4_zcomp_stream-v1-0-35c06ce1d332@gmail.com>
To: Minchan Kim <minchan@kernel.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Jens Axboe <axboe@kernel.dk>
Cc: linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770212935; l=3979;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=n49FebibsqQERts1+tv3yx6Io3Tg7uusMwfFkfvmBE0=;
 b=5iP6q2XsN0scmSU6Ct+S9QgF8jXHJZbhYOQbAjtLTaT/vAif6+MCwR5Xhd6WJvre35Tz3Q7/K
 EdRzKxAK6D8D/uHscoEyVFhM60tKllsrv3+l1/a+wBi1wR4fG/cmVZh
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Crrent per-CPU streams limit write concurrency to the number of online
CPUs. For zcomp backends that support zcomp-managed streams, we can
utilize them for async write requests to get better parallelism.

Modify zram_write_page() to accept a flag indicating the request is
asynchronous. If the bio request is considered as non-synchronous and
the backend supports zcomp-managed streams, attempt to acquire a
zcomp-managed stream.

Although zram_write_page() currently waits for compression to complete,
making the operation appear synchronous, using zcomp-managed streams
has the potential to improve parallelism for async write requests,
provided the backend utilizes efficient streams management or
specialized implementations.

zcomp_stream_get() handles the fallback to per-CPU streams.
zram_read_page() remains using the generic per-CPU streams, since reads
are always treated as synchronous in op_is_sync().

Support multiple pages within a single bio request is deferred to keep
simple and focused.

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
 drivers/block/zram/zram_drv.c | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)

diff --git a/drivers/block/zram/zram_drv.c b/drivers/block/zram/zram_drv.c
index 2e5a1415e9034674e14e619f486052cd21098f50..655d0e141c621ca38ca1059780c1a8a00258c868 100644
--- a/drivers/block/zram/zram_drv.c
+++ b/drivers/block/zram/zram_drv.c
@@ -1966,6 +1966,7 @@ static int read_compressed_page(struct zram *zram, struct page *page, u32 index)
 	size = zram_get_obj_size(zram, index);
 	prio = zram_get_priority(zram, index);
 
+	/* Reads are treated as synchronous, see op_is_sync(). */
 	zstrm = zcomp_stream_get(zram->comps[prio], ZSTRM_DEFAULT);
 	src = zs_obj_read_begin(zram->mem_pool, handle, zstrm->local_copy);
 	dst = kmap_local_page(page);
@@ -2105,7 +2106,8 @@ static int write_incompressible_page(struct zram *zram, struct page *page,
 	return 0;
 }
 
-static int zram_write_page(struct zram *zram, struct page *page, u32 index)
+static int zram_write_page(struct zram *zram, struct page *page, u32 index,
+			   bool is_async)
 {
 	int ret = 0;
 	unsigned long handle;
@@ -2121,7 +2123,19 @@ static int zram_write_page(struct zram *zram, struct page *page, u32 index)
 	if (same_filled)
 		return write_same_filled_page(zram, element, index);
 
-	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP], ZSTRM_DEFAULT);
+	/*
+	 * Using zcomp-managed stream and waiting for compress done makes
+	 * this appear synchronous.
+	 *
+	 * At this time, zram_bio_write handles pages one by one.
+	 * However, zcomp-managed streams allow threads to submit jobs
+	 * to zcomp without the lock contention in per-cpu streams.
+	 * This might give us better parallelism than the generic per-cpu
+	 * streams could, assuming zcomp uses efficient streams management
+	 * or utilizes the specialized implementations.
+	 */
+	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP],
+				 is_async ? ZSTRM_PREFER_MGMT : ZSTRM_DEFAULT);
 	mem = kmap_local_page(page);
 	ret = zcomp_compress(zram->comps[ZRAM_PRIMARY_COMP], zstrm,
 			     mem, &comp_len);
@@ -2183,7 +2197,8 @@ static int zram_bvec_write_partial(struct zram *zram, struct bio_vec *bvec,
 	ret = zram_read_page(zram, page, index, bio);
 	if (!ret) {
 		memcpy_from_bvec(page_address(page) + offset, bvec);
-		ret = zram_write_page(zram, page, index);
+		ret = zram_write_page(zram, page, index,
+				      !op_is_sync(bio->bi_opf));
 	}
 	__free_page(page);
 	return ret;
@@ -2194,7 +2209,8 @@ static int zram_bvec_write(struct zram *zram, struct bio_vec *bvec,
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

