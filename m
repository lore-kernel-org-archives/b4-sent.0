From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:50:48 +0000
Subject: [PATCH] media: v4l2-mem2mem: Don't leave the context aborted when
 STREAMOFF fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-m2m-streamoff-abort-v1-1-03d069fd446d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ7CMAxA0atUnrFUp6UDV0EMSeOAkdIgOyCkq
 ncnpeMb/l/BWIUNLt0Kyh8xKUsDnTqYH365M0psBte7iYhGDCNml9Gqss8lJfShaMUYaYhTz34
 4E7T4pZzk+x9fb4ftHZ481/0G2/YDxOVqXnoAAAA=
X-Change-ID: 20261114-b4-m2m-streamoff-abort-dd13d60ea351
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794732647; l=2190;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=BuQkZRj7ByvS1NUQNOI5Oe3+pEoeToFjAE2b+Y7gZv0=;
 b=31LFjhg6raOEK+/4BmBo3P4wFiBpFI5mErQ8Jc9DyB7SPwYS9ky2pWUvv859FlNhLz4yBQOMO
 /kXF0tOLV54BKZxtRYH4WWfVnytW+2qGaFOlkKqR9k41bxERHfdtlIt
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v4l2_m2m_streamoff() sets TRANS_ABORT before vb2_streamoff(). If that
fails, e.g. for a single-planar type on a multi-planar device, the flag
stays and no job of the context runs until a successful STREAMOFF.

Reject a type the queue doesn't have before cancelling, and if vb2 still
fails, clear TRANS_ABORT and reschedule the context.

Fixes: 2ad5389b3412 ("[media] v4l2-mem2mem: Don't schedule the context if abort job is called")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S): after a wrong-type STREAMOFF on an
RGA context, the next job ran only with this patch.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed it.
---
 drivers/media/v4l2-core/v4l2-mem2mem.c | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/drivers/media/v4l2-core/v4l2-mem2mem.c b/drivers/media/v4l2-core/v4l2-mem2mem.c
index a65cbb124cfe..03d9f492fbe9 100644
--- a/drivers/media/v4l2-core/v4l2-mem2mem.c
+++ b/drivers/media/v4l2-core/v4l2-mem2mem.c
@@ -874,15 +874,24 @@ int v4l2_m2m_streamoff(struct file *file, struct v4l2_m2m_ctx *m2m_ctx,
 	unsigned long flags_job, flags;
 	int ret;
 
+	q_ctx = get_queue_ctx(m2m_ctx, type);
+	m2m_dev = m2m_ctx->m2m_dev;
+
+	if (type != q_ctx->q.type)
+		return -EINVAL;
+
 	/* wait until the current context is dequeued from job_queue */
 	v4l2_m2m_cancel_job(m2m_ctx);
 
-	q_ctx = get_queue_ctx(m2m_ctx, type);
 	ret = vb2_streamoff(&q_ctx->q, type);
-	if (ret)
+	if (ret) {
+		spin_lock_irqsave(&m2m_dev->job_spinlock, flags_job);
+		m2m_ctx->job_flags &= ~TRANS_ABORT;
+		spin_unlock_irqrestore(&m2m_dev->job_spinlock, flags_job);
+		v4l2_m2m_try_schedule(m2m_ctx);
 		return ret;
+	}
 
-	m2m_dev = m2m_ctx->m2m_dev;
 	spin_lock_irqsave(&m2m_dev->job_spinlock, flags_job);
 	/* We should not be scheduled anymore, since we're dropping a queue. */
 	if (m2m_ctx->job_flags & TRANS_QUEUED)

---
base-commit: 48fe5a7834cc10081887d7bcd9ff0a4cadc3fa8c
change-id: 20261114-b4-m2m-streamoff-abort-dd13d60ea351

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

