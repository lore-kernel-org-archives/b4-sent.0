From: Jihan LIN <linjh22s@gmail.com>
Date: Mon, 09 Mar 2026 12:23:05 +0000
Subject: [PATCH RFC v2 2/5] zram: Separate the lock from zcomp_strm
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-b4_zcomp_stream-v2-2-7148622326eb@gmail.com>
References: <20260309-b4_zcomp_stream-v2-0-7148622326eb@gmail.com>
In-Reply-To: <20260309-b4_zcomp_stream-v2-0-7148622326eb@gmail.com>
To: Minchan Kim <minchan@kernel.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Jens Axboe <axboe@kernel.dk>
Cc: linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773058983; l=5183;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=cVW7f7+4JOkXg2R6fUKM/sxozdCKUIpNi6O3d3HfKrI=;
 b=Dn5iWuLr2XotHC043sQvFF0aNY6lPRF1GrPLWZ8P9mNw/e+t2xHlnGV2lkGscE93QoRFSFtw9
 vhZYq8U1hnHB4T9aNGG0KQrOSfxX2sGjyIO2EHCFtoHY1TD1qAvtzgT
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently zcomp_strm has a lock for default per-CPU streams. This field
should not be part of the generic stream structure.

Remove lock from zcomp_strm, and introduce struct percpu_zstrm for
per-CPU streams. This cleans up struct zcomp_strm and separates the
stream definition from its locking policy.

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
 drivers/block/zram/zcomp.c | 44 +++++++++++++++++++++++++++++---------------
 drivers/block/zram/zcomp.h |  5 +++--
 2 files changed, 32 insertions(+), 17 deletions(-)

diff --git a/drivers/block/zram/zcomp.c b/drivers/block/zram/zcomp.c
index f2834898d3b700746db7bd2296ea9f4186e183c8..daea592f01c37106b14dca9c6d8727a2240de54b 100644
--- a/drivers/block/zram/zcomp.c
+++ b/drivers/block/zram/zcomp.c
@@ -43,17 +43,32 @@ static const struct zcomp_ops *backends[] = {
 	NULL
 };
 
-static void zcomp_strm_free_percpu(struct zcomp *comp, struct zcomp_strm *zstrm)
+struct percpu_zstrm {
+	struct zcomp_strm strm;
+	struct mutex lock;
+};
+
+static struct percpu_zstrm *zstrm_to_pcpu(struct zcomp_strm *zstrm)
+{
+	return container_of(zstrm, struct percpu_zstrm, strm);
+}
+
+static void zcomp_strm_free_percpu(struct zcomp *comp,
+				   struct percpu_zstrm *zstrm_pcpu)
 {
+	struct zcomp_strm *zstrm = &zstrm_pcpu->strm;
+
 	comp->ops->destroy_ctx(&zstrm->ctx);
 	vfree(zstrm->local_copy);
 	vfree(zstrm->buffer);
 	zstrm->buffer = NULL;
 }
 
-static int zcomp_strm_init_percpu(struct zcomp *comp, struct zcomp_strm *zstrm)
+static int zcomp_strm_init_percpu(struct zcomp *comp,
+				  struct percpu_zstrm *zstrm_pcpu)
 {
 	int ret;
+	struct zcomp_strm *zstrm = &zstrm_pcpu->strm;
 
 	ret = comp->ops->create_ctx(comp->params, &zstrm->ctx);
 	if (ret)
@@ -66,7 +81,7 @@ static int zcomp_strm_init_percpu(struct zcomp *comp, struct zcomp_strm *zstrm)
 	 */
 	zstrm->buffer = vzalloc(2 * PAGE_SIZE);
 	if (!zstrm->buffer || !zstrm->local_copy) {
-		zcomp_strm_free_percpu(comp, zstrm);
+		zcomp_strm_free_percpu(comp, zstrm_pcpu);
 		return -ENOMEM;
 	}
 	return 0;
@@ -110,7 +125,7 @@ ssize_t zcomp_available_show(const char *comp, char *buf, ssize_t at)
 struct zcomp_strm *zcomp_stream_get(struct zcomp *comp)
 {
 	for (;;) {
-		struct zcomp_strm *zstrm = raw_cpu_ptr(comp->stream);
+		struct percpu_zstrm *zstrm_pcpu = raw_cpu_ptr(comp->stream);
 
 		/*
 		 * Inspired by zswap
@@ -122,16 +137,16 @@ struct zcomp_strm *zcomp_stream_get(struct zcomp *comp)
 		 * from a CPU that has already destroyed its stream.  If
 		 * so then unlock and re-try on the current CPU.
 		 */
-		mutex_lock(&zstrm->lock);
-		if (likely(zstrm->buffer))
-			return zstrm;
-		mutex_unlock(&zstrm->lock);
+		mutex_lock(&zstrm_pcpu->lock);
+		if (likely(zstrm_pcpu->strm.buffer))
+			return &zstrm_pcpu->strm;
+		mutex_unlock(&zstrm_pcpu->lock);
 	}
 }
 
 void zcomp_stream_put(struct zcomp_strm *zstrm)
 {
-	mutex_unlock(&zstrm->lock);
+	mutex_unlock(&zstrm_to_pcpu(zstrm)->lock);
 }
 
 int zcomp_compress(struct zcomp *comp, struct zcomp_strm *zstrm,
@@ -169,7 +184,7 @@ int zcomp_decompress(struct zcomp *comp, struct zcomp_strm *zstrm,
 int zcomp_cpu_up_prepare(unsigned int cpu, struct hlist_node *node)
 {
 	struct zcomp *comp = hlist_entry(node, struct zcomp, node);
-	struct zcomp_strm *zstrm = per_cpu_ptr(comp->stream, cpu);
+	struct percpu_zstrm *zstrm = per_cpu_ptr(comp->stream, cpu);
 	int ret;
 
 	ret = zcomp_strm_init_percpu(comp, zstrm);
@@ -181,11 +196,10 @@ int zcomp_cpu_up_prepare(unsigned int cpu, struct hlist_node *node)
 int zcomp_cpu_dead(unsigned int cpu, struct hlist_node *node)
 {
 	struct zcomp *comp = hlist_entry(node, struct zcomp, node);
-	struct zcomp_strm *zstrm = per_cpu_ptr(comp->stream, cpu);
+	struct percpu_zstrm *zstrm_pcpu = per_cpu_ptr(comp->stream, cpu);
 
-	mutex_lock(&zstrm->lock);
-	zcomp_strm_free_percpu(comp, zstrm);
-	mutex_unlock(&zstrm->lock);
+	guard(mutex)(&zstrm_pcpu->lock);
+	zcomp_strm_free_percpu(comp, zstrm_pcpu);
 	return 0;
 }
 
@@ -193,7 +207,7 @@ static int zcomp_init(struct zcomp *comp, struct zcomp_params *params)
 {
 	int ret, cpu;
 
-	comp->stream = alloc_percpu(struct zcomp_strm);
+	comp->stream = alloc_percpu(struct percpu_zstrm);
 	if (!comp->stream)
 		return -ENOMEM;
 
diff --git a/drivers/block/zram/zcomp.h b/drivers/block/zram/zcomp.h
index eacfd3f7d61d9395694292713fb5da4f0023d6d7..9784bc3f432cf0e22085399b8772b8ba669071de 100644
--- a/drivers/block/zram/zcomp.h
+++ b/drivers/block/zram/zcomp.h
@@ -38,7 +38,6 @@ struct zcomp_ctx {
 };
 
 struct zcomp_strm {
-	struct mutex lock;
 	/* compression buffer */
 	void *buffer;
 	/* local copy of handle memory */
@@ -46,6 +45,8 @@ struct zcomp_strm {
 	struct zcomp_ctx ctx;
 };
 
+struct percpu_zstrm;
+
 struct zcomp_req {
 	const unsigned char *src;
 	const size_t src_len;
@@ -71,7 +72,7 @@ struct zcomp_ops {
 
 /* dynamic per-device compression frontend */
 struct zcomp {
-	struct zcomp_strm __percpu *stream;
+	struct percpu_zstrm __percpu *stream;
 	const struct zcomp_ops *ops;
 	struct zcomp_params *params;
 	struct hlist_node node;

-- 
2.51.0

