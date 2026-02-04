From: Jihan LIN <linjh22s@gmail.com>
Date: Wed, 04 Feb 2026 13:48:51 +0000
Subject: [PATCH RFC 1/3] zram: Rename zcomp_strm_{init, free}()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-b4_zcomp_stream-v1-1-35c06ce1d332@gmail.com>
References: <20260204-b4_zcomp_stream-v1-0-35c06ce1d332@gmail.com>
In-Reply-To: <20260204-b4_zcomp_stream-v1-0-35c06ce1d332@gmail.com>
To: Minchan Kim <minchan@kernel.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Jens Axboe <axboe@kernel.dk>
Cc: linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770212935; l=2361;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=IFvoK5U+khkiAvwSnFIAQSJIRT0dcUrOwkW93SNRf6w=;
 b=PRv9qw5rfie6P+3wgDGa1Y91Sk+MwawKplgOLzT2zxS5CbI3eCVz/gR2pCSaq3p8C69gRoKHx
 bPeCX0RrFuJBRrmFtPfiOF+2E2LldwSB5WxN7ZXMx3Eh2i8nLEekB1v
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, zcomp uses a preemptive per-CPU stream model where streams
are allocated for each online CPUs and guarded by mutexes. The existing
names zcomp_strm_{init, free}() are too generic to explicitly indicate
they handle per-CPU streams.

Rename them to zcomp_strm_{init, free}_percpu(). This helps distinguish
them from future streams that may not be per-CPU based. No functional
changes are intended.

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
 drivers/block/zram/zcomp.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/block/zram/zcomp.c b/drivers/block/zram/zcomp.c
index b1bd1daa0060a5b437d947d504d9ee6b4a9ac152..1614340e81dd2bebb29373411c9d180446f78f4c 100644
--- a/drivers/block/zram/zcomp.c
+++ b/drivers/block/zram/zcomp.c
@@ -43,7 +43,7 @@ static const struct zcomp_ops *backends[] = {
 	NULL
 };
 
-static void zcomp_strm_free(struct zcomp *comp, struct zcomp_strm *zstrm)
+static void zcomp_strm_free_percpu(struct zcomp *comp, struct zcomp_strm *zstrm)
 {
 	comp->ops->destroy_ctx(&zstrm->ctx);
 	vfree(zstrm->local_copy);
@@ -51,7 +51,7 @@ static void zcomp_strm_free(struct zcomp *comp, struct zcomp_strm *zstrm)
 	zstrm->buffer = NULL;
 }
 
-static int zcomp_strm_init(struct zcomp *comp, struct zcomp_strm *zstrm)
+static int zcomp_strm_init_percpu(struct zcomp *comp, struct zcomp_strm *zstrm)
 {
 	int ret;
 
@@ -66,7 +66,7 @@ static int zcomp_strm_init(struct zcomp *comp, struct zcomp_strm *zstrm)
 	 */
 	zstrm->buffer = vzalloc(2 * PAGE_SIZE);
 	if (!zstrm->buffer || !zstrm->local_copy) {
-		zcomp_strm_free(comp, zstrm);
+		zcomp_strm_free_percpu(comp, zstrm);
 		return -ENOMEM;
 	}
 	return 0;
@@ -172,7 +172,7 @@ int zcomp_cpu_up_prepare(unsigned int cpu, struct hlist_node *node)
 	struct zcomp_strm *zstrm = per_cpu_ptr(comp->stream, cpu);
 	int ret;
 
-	ret = zcomp_strm_init(comp, zstrm);
+	ret = zcomp_strm_init_percpu(comp, zstrm);
 	if (ret)
 		pr_err("Can't allocate a compression stream\n");
 	return ret;
@@ -184,7 +184,7 @@ int zcomp_cpu_dead(unsigned int cpu, struct hlist_node *node)
 	struct zcomp_strm *zstrm = per_cpu_ptr(comp->stream, cpu);
 
 	mutex_lock(&zstrm->lock);
-	zcomp_strm_free(comp, zstrm);
+	zcomp_strm_free_percpu(comp, zstrm);
 	mutex_unlock(&zstrm->lock);
 	return 0;
 }

-- 
2.51.0

