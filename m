From: Junye Ji <jijunye1@outlook.com>
Date: Sun, 12 Jul 2026 13:21:16 -0700
Subject: [PATCH] io_uring/kbuf: free cached iovec only after replacement
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-io-uring-kbuf-iovec-lifetime-v1-1-23028d00b6cf@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBAF0KvIrDswRlHwKqULjTP6aY0lURHEu
 zd0+TbvoqQRmqgrLop6IGENGeWjID/3YVLGmE1OXCNt6Rgr7xFh4vewW9ahnj8w3bAo12a1NL0
 M4ivKxTeq4fz3z9d9/wDEzSBTbgAAAA==
X-Change-ID: 20260712-io-uring-kbuf-iovec-lifetime-4ff406a0b0c3
To: Jens Axboe <axboe@kernel.dk>
Cc: Hao-Yu Yang <naup96721@gmail.com>, io-uring@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Junye Ji <jijunye1@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783887681; l=1694;
 i=jijunye1@outlook.com; s=junyeji-20260712; h=from:subject:message-id;
 bh=OUMgENWWWxoEYLpXsl1Dvxz32F/77rmlxtHsMQSj9/Y=;
 b=TSSzKm2z/AWaYArbGY9qOOLdCpQS9h+8be9MPINfJhHTSCbE8TshWzpdnMC5oTz/CyRHsUlhp
 DrNq9Q1YNl2D4Q6ekaJSJmmd+ZShhWihtonMqyUwggKJW4opLSwBzea
X-Developer-Key: i=jijunye1@outlook.com; a=ed25519;
 pk=aKIN8hT1V9oSVC83K2q1NNzawUnDaybDxbYJltmwvGE=
X-Endpoint-Received: by B4 Relay for jijunye1@outlook.com/junyeji-20260712 with auth_id=865
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

io_ring_buffers_peek() saves the incoming iovec array in org_iovs, then may
replace arg->iovs while expanding a provided-buffer bundle. With
KBUF_MODE_FREE set, the success path frees arg->iovs instead of org_iovs.
It either frees a replacement before the caller uses it or, when no
replacement was needed, frees the cache still owned by the request. Cleanup
later frees the same cache again.

I reproduced the stale read and double free on the no-growth and
successful-growth paths with two completions from one multishot receive.
The fixed KASAN kernel completed 100 runs of both triggers and both
liburing bundle tests without a report.

Fixes: cd053d788c3f ("io_uring: fix dangling iovec after provided-buffer bundle grow failure")
Assisted-by: Codex-Security:unspecified
Signed-off-by: Junye Ji <jijunye1@outlook.com>
---
I can send the reproducer and full trace/KASAN logs privately if needed.
---
 io_uring/kbuf.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/io_uring/kbuf.c b/io_uring/kbuf.c
index b6b969b55e12..07d81dc7cbe2 100644
--- a/io_uring/kbuf.c
+++ b/io_uring/kbuf.c
@@ -328,8 +328,8 @@ static int io_ring_buffers_peek(struct io_kiocb *req, struct buf_sel_arg *arg,
 		buf = io_ring_head_to_buf(br, ++head, bl->mask);
 	} while (--nr_iovs);
 
-	if (arg->mode & KBUF_MODE_FREE)
-		kfree(arg->iovs);
+	if ((arg->mode & KBUF_MODE_FREE) && arg->iovs != org_iovs)
+		kfree(org_iovs);
 
 	if (head == tail)
 		req->flags |= REQ_F_BL_EMPTY;

---
base-commit: 44696aa3a489d2baf58efa61b37833f100072bee
change-id: 20260712-io-uring-kbuf-iovec-lifetime-4ff406a0b0c3

Best regards,
-- 
Junye Ji <jijunye1@outlook.com>

