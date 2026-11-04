From: =?utf-8?q?Orkun_Emin_Sar=C4=B1?= <sariorkunemin@gmail.com>
Date: Wed, 04 Nov 2026 19:51:42 +0300
Subject: [PATCH v2] io_uring: only wait for in-flight requests if the
 closing task uses the ring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261104-io-uring-wait-inflight-v2-1-f38f29fe8018@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNSw6CMBRFt0I69pm28lFG7sMwqOW1PAOtaQtqC
 HsXcAEOT3LuuTOLGAgjq7OZBZwokncryEPGdKecRaB2ZSa5LIXgOZCHMZCz8FKUgJzpyXYJCmO
 qs6p0qduCreNnQEPvPXxrfhzH+wN12mqb0VFMPnz250ls3t+TSYCA/FQKxS+8QMmvdlDUH7UfW
 LMsyxdeRv3zzgAAAA==
X-Change-ID: 20261104-io-uring-wait-inflight-5ff78a7c6cd5
To: Jens Axboe <axboe@kernel.dk>
Cc: io-uring@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Orkun_Emin_Sar=C4=B1?= <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793811101; l=1703;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=2zAkFtlRAbKoTeetYy4EAFWZ/r67JeI0vLajPk/pxyc=;
 b=RtbouLjW9ofs3DQvgitpYlDXkyFY8PtA5hoa0+z1rlR9uW0kpvA51MXzujS+yCgydwx0R3FEt
 5LxnsoqxBh3DvSp1QBiEehpF1vnVQ2C4db2GpQZYtTyqTBgIzMfcT7X
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 13d3783a55b7 ("io_uring: wait for in-flight requests on
ring release"), the task dropping the last reference to a ring waits
for every request on it to complete. A process that only received the
ring fd, e.g. over a UNIX socket, can then block in close(2) on
requests owned by other tasks, such as a read from an unresponsive
FUSE server.

Skip the wait for tasks that never attached to the ring and leave those
requests to io_ring_exit_work(), as before.

Fixes: 13d3783a55b7 ("io_uring: wait for in-flight requests on ring release")
Signed-off-by: Orkun Emin Sarı <sariorkunemin@gmail.com>
---
Changes in v2:
- Shorten the commit message and the code comment
- Use real name in Signed-off-by
- Link to v1: https://patch.msgid.link/20261104-io-uring-wait-inflight-v1-1-4361a0905e20@gmail.com
---
 io_uring/io_uring.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/io_uring/io_uring.c b/io_uring/io_uring.c
index 03724419c4..5db57bf675 100644
--- a/io_uring/io_uring.c
+++ b/io_uring/io_uring.c
@@ -2547,7 +2547,10 @@ static __cold void io_ring_ctx_wait_inflight(struct io_ring_ctx *ctx)
 
 	if (current->flags & (PF_KTHREAD | PF_EXITING))
 		return;
-	if (tctx && atomic_read(&tctx->in_cancel))
+	/* Only wait if this task has attached to the ring */
+	if (!tctx || !xa_load(&tctx->xa, (unsigned long)ctx))
+		return;
+	if (atomic_read(&tctx->in_cancel))
 		return;
 
 	while (io_ring_ctx_inflight(ctx) && !fatal_signal_pending(current)) {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-io-uring-wait-inflight-5ff78a7c6cd5

Best regards,
--  
Orkun Emin Sarı <sariorkunemin@gmail.com>

