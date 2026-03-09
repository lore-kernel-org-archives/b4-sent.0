From: Jihan LIN <linjh22s@gmail.com>
Date: Mon, 09 Mar 2026 12:23:06 +0000
Subject: [PATCH RFC v2 3/5] zram: Introduce zcomp-managed streams
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-b4_zcomp_stream-v2-3-7148622326eb@gmail.com>
References: <20260309-b4_zcomp_stream-v2-0-7148622326eb@gmail.com>
In-Reply-To: <20260309-b4_zcomp_stream-v2-0-7148622326eb@gmail.com>
To: Minchan Kim <minchan@kernel.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Jens Axboe <axboe@kernel.dk>
Cc: linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773058983; l=9074;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=+EUQ9ObG8GprpcXAW94+J5dWVRBMsH3iSu9ywZbjB8A=;
 b=RYN+QUVIiYfbGA/89v4IYc5R0SkiW5pSAzbUHrHwQ8Oh8rDq8EQfTUVM4amOSzEAKdit1nbwE
 NeacQzNmTrMAOKym0JHkV+eubY6iffUCtQdffl5Fx7cIOfPdHbJessn
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, zcomp uses a per-CPU stream model. This design is restrictive
for hardware-accelerated or batched zcomp backends. These backends often
need to manage their own resources rather than relying on a generic
mutex-protected per-CPU stream for batched operations.

Extend the zcomp interface to allow backends to optionally manage their
own streams while generic per-CPU streams still remain allocated as a
complementary mechanism.

Introduce zstrm_mgmt flag to struct zcomp_params. Backends set this flag
during zcomp_ops->setup_params() to advertise their capability to manage
streams.
Add zcomp_ops->{get, put}_stream() to allow zcomp backends to implement
their own stream strategies.
Modify zcomp_stream_get() to accept a new parameter indicating
zcomp-managed streams are preferred, and update zcomp_stream_put() to
route a zcomp-managed stream to the backend. If the backends advertise
their capability and the caller prefers managed streams, try to get a
stream from the backends; otherwise, fall back to the generic per-CPU
stream.

All existing call sites request the default per-CPU stream to preserve
the original behavior.

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
 drivers/block/zram/zcomp.c    | 41 +++++++++++++++++++++++++++++++++++++++--
 drivers/block/zram/zcomp.h    | 30 ++++++++++++++++++++++++++++--
 drivers/block/zram/zram_drv.c | 10 +++++-----
 3 files changed, 72 insertions(+), 9 deletions(-)

diff --git a/drivers/block/zram/zcomp.c b/drivers/block/zram/zcomp.c
index daea592f01c37106b14dca9c6d8727a2240de54b..1b5c8e8f6c6cb78a812320334da0b61391bb38f0 100644
--- a/drivers/block/zram/zcomp.c
+++ b/drivers/block/zram/zcomp.c
@@ -84,6 +84,7 @@ static int zcomp_strm_init_percpu(struct zcomp *comp,
 		zcomp_strm_free_percpu(comp, zstrm_pcpu);
 		return -ENOMEM;
 	}
+	zstrm->zcomp_managed = false;
 	return 0;
 }
 
@@ -122,7 +123,7 @@ ssize_t zcomp_available_show(const char *comp, char *buf, ssize_t at)
 	return at;
 }
 
-struct zcomp_strm *zcomp_stream_get(struct zcomp *comp)
+static inline struct zcomp_strm *zcomp_stream_pcpu_get(struct zcomp *comp)
 {
 	for (;;) {
 		struct percpu_zstrm *zstrm_pcpu = raw_cpu_ptr(comp->stream);
@@ -144,9 +145,37 @@ struct zcomp_strm *zcomp_stream_get(struct zcomp *comp)
 	}
 }
 
+struct zcomp_strm *zcomp_stream_get(struct zcomp *comp, enum zstrm_pref pref)
+{
+	if (comp->params->zstrm_mgmt && pref == ZSTRM_PREFER_MGMT) {
+		struct managed_zstrm *zstrm_managed =
+			comp->ops->get_stream(comp->params);
+
+		if (zstrm_managed) {
+			zstrm_managed->comp = comp;
+			return &zstrm_managed->strm;
+		}
+	}
+
+	return zcomp_stream_pcpu_get(comp);
+}
+
+static inline void zcomp_stream_pcpu_put(struct percpu_zstrm *zstrm)
+{
+	mutex_unlock(&zstrm->lock);
+}
+
 void zcomp_stream_put(struct zcomp_strm *zstrm)
 {
-	mutex_unlock(&zstrm_to_pcpu(zstrm)->lock);
+	if (zstrm->zcomp_managed) {
+		struct managed_zstrm *zstrm_managed =
+			zstrm_to_managed(zstrm);
+
+		zstrm_managed->comp->ops->put_stream(
+			zstrm_managed->comp->params, zstrm_managed);
+	} else {
+		zcomp_stream_pcpu_put(zstrm_to_pcpu(zstrm));
+	}
 }
 
 int zcomp_compress(struct zcomp *comp, struct zcomp_strm *zstrm,
@@ -211,11 +240,19 @@ static int zcomp_init(struct zcomp *comp, struct zcomp_params *params)
 	if (!comp->stream)
 		return -ENOMEM;
 
+	params->zstrm_mgmt = false;
 	comp->params = params;
 	ret = comp->ops->setup_params(comp->params);
 	if (ret)
 		goto cleanup;
 
+	if (params->zstrm_mgmt &&
+	    !(comp->ops->get_stream && comp->ops->put_stream)) {
+		params->zstrm_mgmt = false;
+		pr_warn("Missing managed stream ops in %s, managed stream disabled\n",
+			comp->ops->name);
+	}
+
 	for_each_possible_cpu(cpu)
 		mutex_init(&per_cpu_ptr(comp->stream, cpu)->lock);
 
diff --git a/drivers/block/zram/zcomp.h b/drivers/block/zram/zcomp.h
index 9784bc3f432cf0e22085399b8772b8ba669071de..3543e7e4d2b3b1344bb191b321bcdd69f67031f6 100644
--- a/drivers/block/zram/zcomp.h
+++ b/drivers/block/zram/zcomp.h
@@ -24,6 +24,7 @@ struct zcomp_params {
 	union {
 		struct deflate_params deflate;
 	};
+	bool zstrm_mgmt;
 
 	void *drv_data;
 };
@@ -31,13 +32,14 @@ struct zcomp_params {
 /*
  * Run-time driver context - scratch buffers, etc. It is modified during
  * request execution (compression/decompression), cannot be shared, so
- * it's in per-CPU area.
+ * it's in per-CPU area or managed by the backend.
  */
 struct zcomp_ctx {
 	void *context;
 };
 
 struct zcomp_strm {
+	bool zcomp_managed;
 	/* compression buffer */
 	void *buffer;
 	/* local copy of handle memory */
@@ -47,6 +49,11 @@ struct zcomp_strm {
 
 struct percpu_zstrm;
 
+struct managed_zstrm {
+	struct zcomp *comp;
+	struct zcomp_strm strm;
+};
+
 struct zcomp_req {
 	const unsigned char *src;
 	const size_t src_len;
@@ -55,6 +62,11 @@ struct zcomp_req {
 	size_t dst_len;
 };
 
+enum zstrm_pref {
+	ZSTRM_DEFAULT, /* always use the generic per-CPU stream */
+	ZSTRM_PREFER_MGMT, /* try managed stream; fallback to per-CPU */
+};
+
 struct zcomp_ops {
 	int (*compress)(struct zcomp_params *params, struct zcomp_ctx *ctx,
 			struct zcomp_req *req);
@@ -67,6 +79,15 @@ struct zcomp_ops {
 	int (*setup_params)(struct zcomp_params *params);
 	void (*release_params)(struct zcomp_params *params);
 
+	/*
+	 * get_stream() needs to prepare zstrm->ctx. The backend must ensure
+	 * returned stream has zcomp_managed set and matches the per-cpu
+	 * stream sizing: local_copy >= PAGE_SIZE, buffer >= 2 * PAGE_SIZE.
+	 */
+	struct managed_zstrm *(*get_stream)(struct zcomp_params *params);
+	void (*put_stream)(struct zcomp_params *params,
+			   struct managed_zstrm *zstrm);
+
 	const char *name;
 };
 
@@ -86,7 +107,7 @@ bool zcomp_available_algorithm(const char *comp);
 struct zcomp *zcomp_create(const char *alg, struct zcomp_params *params);
 void zcomp_destroy(struct zcomp *comp);
 
-struct zcomp_strm *zcomp_stream_get(struct zcomp *comp);
+struct zcomp_strm *zcomp_stream_get(struct zcomp *comp, enum zstrm_pref pref);
 void zcomp_stream_put(struct zcomp_strm *zstrm);
 
 int zcomp_compress(struct zcomp *comp, struct zcomp_strm *zstrm,
@@ -94,4 +115,9 @@ int zcomp_compress(struct zcomp *comp, struct zcomp_strm *zstrm,
 int zcomp_decompress(struct zcomp *comp, struct zcomp_strm *zstrm,
 		     const void *src, unsigned int src_len, void *dst);
 
+static inline struct managed_zstrm *zstrm_to_managed(struct zcomp_strm *zstrm)
+{
+	return container_of(zstrm, struct managed_zstrm, strm);
+}
+
 #endif /* _ZCOMP_H_ */
diff --git a/drivers/block/zram/zram_drv.c b/drivers/block/zram/zram_drv.c
index bca33403fc8bf872569c63e65af0fe143287eaaf..7be88cfb56adb12fcc1edc6b4d42271044ef71b5 100644
--- a/drivers/block/zram/zram_drv.c
+++ b/drivers/block/zram/zram_drv.c
@@ -1377,7 +1377,7 @@ static int decompress_bdev_page(struct zram *zram, struct page *page, u32 index)
 	size = get_slot_size(zram, index);
 	prio = get_slot_comp_priority(zram, index);
 
-	zstrm = zcomp_stream_get(zram->comps[prio]);
+	zstrm = zcomp_stream_get(zram->comps[prio], ZSTRM_DEFAULT);
 	src = kmap_local_page(page);
 	ret = zcomp_decompress(zram->comps[prio], zstrm, src, size,
 			       zstrm->local_copy);
@@ -2083,7 +2083,7 @@ static int read_compressed_page(struct zram *zram, struct page *page, u32 index)
 	size = get_slot_size(zram, index);
 	prio = get_slot_comp_priority(zram, index);
 
-	zstrm = zcomp_stream_get(zram->comps[prio]);
+	zstrm = zcomp_stream_get(zram->comps[prio], ZSTRM_DEFAULT);
 	src = zs_obj_read_begin(zram->mem_pool, handle, size,
 				zstrm->local_copy);
 	dst = kmap_local_page(page);
@@ -2111,7 +2111,7 @@ static int read_from_zspool_raw(struct zram *zram, struct page *page, u32 index)
 	 * case if object spans two physical pages. No decompression
 	 * takes place here, as we read raw compressed data.
 	 */
-	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP]);
+	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP], ZSTRM_DEFAULT);
 	src = zs_obj_read_begin(zram->mem_pool, handle, size,
 				zstrm->local_copy);
 	memcpy_to_page(page, 0, src, size);
@@ -2265,7 +2265,7 @@ static int zram_write_page(struct zram *zram, struct page *page, u32 index)
 	if (same_filled)
 		return write_same_filled_page(zram, element, index);
 
-	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP]);
+	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP], ZSTRM_DEFAULT);
 	mem = kmap_local_page(page);
 	ret = zcomp_compress(zram->comps[ZRAM_PRIMARY_COMP], zstrm,
 			     mem, &comp_len);
@@ -2447,7 +2447,7 @@ static int recompress_slot(struct zram *zram, u32 index, struct page *page,
 		if (!zram->comps[prio])
 			continue;
 
-		zstrm = zcomp_stream_get(zram->comps[prio]);
+		zstrm = zcomp_stream_get(zram->comps[prio], ZSTRM_DEFAULT);
 		src = kmap_local_page(page);
 		ret = zcomp_compress(zram->comps[prio], zstrm,
 				     src, &comp_len_new);

-- 
2.51.0

