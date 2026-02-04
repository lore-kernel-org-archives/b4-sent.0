From: Jihan LIN <linjh22s@gmail.com>
Date: Wed, 04 Feb 2026 13:48:52 +0000
Subject: [PATCH RFC 2/3] zram: Introduce zcomp-managed streams
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-b4_zcomp_stream-v1-2-35c06ce1d332@gmail.com>
References: <20260204-b4_zcomp_stream-v1-0-35c06ce1d332@gmail.com>
In-Reply-To: <20260204-b4_zcomp_stream-v1-0-35c06ce1d332@gmail.com>
To: Minchan Kim <minchan@kernel.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Jens Axboe <axboe@kernel.dk>
Cc: linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770212935; l=7328;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=oRqOL0lUgKYsttjly5TdUBB6Rs+XQ4mL1OOAVXXVKqE=;
 b=V+sc5XZD9jWoqC8CA66r/Etd/EIr/XtSX168KZoSdlx3XsC5Jf7z6EsdAD/MeyblZ8LJJ2Qfu
 nVZNvn5Sy0PA4gRdwvLEJeGHOzCCAvQRkZpVjTRf4jXXABzK0v7XwN7
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, zcomp uses a per-CPU stream model. This design is restrictive
for hardware-accelerated or batched zcomp backends. These backends often
need to manage their own resources rather than relying on a generic
mutex-protected per-CPU stream for batched operations.

This patch introduces a hybrid model, allowing backends to optionally
manage their own streams while generic per-CPU streams still remain
allocated as a complementary mechanism.

Introduce zstrm_mgmt flag to struct zcomp_params. Backends set this flag
during zcomp_ops->setup_params() to advertise their capability to manage
streams.
Add zcomp_ops->{get, put}_stream() to allow zcomp backends to implement
their own stream strategies.
Modify zcomp_stream_get() to accept a new parameter indicating
zcomp-managed streams are preferred, and update zcomp_stream_put() to
route a zcomp-managed stream to the backend. If the backends advertise
their capability and the caller prefers managed streams, try to get the
stream from the backends; otherwise, fall back to the generic per-CPU
stream.

All existing call sites request the default per-CPU stream to preserve
the original behavior.

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
 drivers/block/zram/zcomp.c    | 27 +++++++++++++++++++++++++--
 drivers/block/zram/zcomp.h    | 23 +++++++++++++++++++++--
 drivers/block/zram/zram_drv.c |  6 +++---
 3 files changed, 49 insertions(+), 7 deletions(-)

diff --git a/drivers/block/zram/zcomp.c b/drivers/block/zram/zcomp.c
index 1614340e81dd2bebb29373411c9d180446f78f4c..86ff6ecb0293d7b95ef4fa822122568cedf78f6e 100644
--- a/drivers/block/zram/zcomp.c
+++ b/drivers/block/zram/zcomp.c
@@ -69,6 +69,7 @@ static int zcomp_strm_init_percpu(struct zcomp *comp, struct zcomp_strm *zstrm)
 		zcomp_strm_free_percpu(comp, zstrm);
 		return -ENOMEM;
 	}
+	zstrm->zcomp_managed = false;
 	return 0;
 }
 
@@ -107,8 +108,18 @@ ssize_t zcomp_available_show(const char *comp, char *buf, ssize_t at)
 	return at;
 }
 
-struct zcomp_strm *zcomp_stream_get(struct zcomp *comp)
+struct zcomp_strm *zcomp_stream_get(struct zcomp *comp, enum zstrm_pref pref)
 {
+	if (comp->params->zstrm_mgmt && pref == ZSTRM_PREFER_MGMT) {
+		struct zcomp_strm *zcomp_strm =
+			comp->ops->get_stream(comp->params);
+
+		if (zcomp_strm) {
+			zcomp_strm->comp = comp;
+			return zcomp_strm;
+		}
+	}
+
 	for (;;) {
 		struct zcomp_strm *zstrm = raw_cpu_ptr(comp->stream);
 
@@ -131,7 +142,11 @@ struct zcomp_strm *zcomp_stream_get(struct zcomp *comp)
 
 void zcomp_stream_put(struct zcomp_strm *zstrm)
 {
-	mutex_unlock(&zstrm->lock);
+	if (zstrm->zcomp_managed) {
+		zstrm->comp->ops->put_stream(zstrm->comp->params, zstrm);
+	} else {
+		mutex_unlock(&zstrm->lock);
+	}
 }
 
 int zcomp_compress(struct zcomp *comp, struct zcomp_strm *zstrm,
@@ -197,11 +212,19 @@ static int zcomp_init(struct zcomp *comp, struct zcomp_params *params)
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
index eacfd3f7d61d9395694292713fb5da4f0023d6d7..cbe8842ea5352eed4e73e3d45fe6c12221ab9f64 100644
--- a/drivers/block/zram/zcomp.h
+++ b/drivers/block/zram/zcomp.h
@@ -24,6 +24,7 @@ struct zcomp_params {
 	union {
 		struct deflate_params deflate;
 	};
+	bool zstrm_mgmt;
 
 	void *drv_data;
 };
@@ -31,14 +32,18 @@ struct zcomp_params {
 /*
  * Run-time driver context - scratch buffers, etc. It is modified during
  * request execution (compression/decompression), cannot be shared, so
- * it's in per-CPU area.
+ * it's in per-CPU area or management by backend.
  */
 struct zcomp_ctx {
 	void *context;
 };
 
 struct zcomp_strm {
+	bool zcomp_managed;
+	/* lock used only for per-cpu streams */
 	struct mutex lock;
+	/* pointer to zcomp valid only for zcomp-managed streams */
+	struct zcomp *comp;
 	/* compression buffer */
 	void *buffer;
 	/* local copy of handle memory */
@@ -54,6 +59,11 @@ struct zcomp_req {
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
@@ -66,6 +76,15 @@ struct zcomp_ops {
 	int (*setup_params)(struct zcomp_params *params);
 	void (*release_params)(struct zcomp_params *params);
 
+	/*
+	 * get_stream() needs to prepare zstrm->ctx, and backend must ensure
+	 * returned stream sets zcomp_managed and match the per-cpu stream
+	 * sizing: local_copy >= PAGE_SIZE, buffer >= 2 * PAGE_SIZE.
+	 */
+	struct zcomp_strm *(*get_stream)(struct zcomp_params *params);
+	void (*put_stream)(struct zcomp_params *params,
+			   struct zcomp_strm *zstrm);
+
 	const char *name;
 };
 
@@ -85,7 +104,7 @@ bool zcomp_available_algorithm(const char *comp);
 struct zcomp *zcomp_create(const char *alg, struct zcomp_params *params);
 void zcomp_destroy(struct zcomp *comp);
 
-struct zcomp_strm *zcomp_stream_get(struct zcomp *comp);
+struct zcomp_strm *zcomp_stream_get(struct zcomp *comp, enum zstrm_pref pref);
 void zcomp_stream_put(struct zcomp_strm *zstrm);
 
 int zcomp_compress(struct zcomp *comp, struct zcomp_strm *zstrm,
diff --git a/drivers/block/zram/zram_drv.c b/drivers/block/zram/zram_drv.c
index 5759823d631488904189168326fd133549c76141..2e5a1415e9034674e14e619f486052cd21098f50 100644
--- a/drivers/block/zram/zram_drv.c
+++ b/drivers/block/zram/zram_drv.c
@@ -1966,7 +1966,7 @@ static int read_compressed_page(struct zram *zram, struct page *page, u32 index)
 	size = zram_get_obj_size(zram, index);
 	prio = zram_get_priority(zram, index);
 
-	zstrm = zcomp_stream_get(zram->comps[prio]);
+	zstrm = zcomp_stream_get(zram->comps[prio], ZSTRM_DEFAULT);
 	src = zs_obj_read_begin(zram->mem_pool, handle, zstrm->local_copy);
 	dst = kmap_local_page(page);
 	ret = zcomp_decompress(zram->comps[prio], zstrm, src, size, dst);
@@ -2121,7 +2121,7 @@ static int zram_write_page(struct zram *zram, struct page *page, u32 index)
 	if (same_filled)
 		return write_same_filled_page(zram, element, index);
 
-	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP]);
+	zstrm = zcomp_stream_get(zram->comps[ZRAM_PRIMARY_COMP], ZSTRM_DEFAULT);
 	mem = kmap_local_page(page);
 	ret = zcomp_compress(zram->comps[ZRAM_PRIMARY_COMP], zstrm,
 			     mem, &comp_len);
@@ -2303,7 +2303,7 @@ static int recompress_slot(struct zram *zram, u32 index, struct page *page,
 		if (!zram->comps[prio])
 			continue;
 
-		zstrm = zcomp_stream_get(zram->comps[prio]);
+		zstrm = zcomp_stream_get(zram->comps[prio], ZSTRM_DEFAULT);
 		src = kmap_local_page(page);
 		ret = zcomp_compress(zram->comps[prio], zstrm,
 				     src, &comp_len_new);

-- 
2.51.0

