From: Vishnu Razdan <vrazdan@openai.com>
Date: Tue, 25 Aug 2026 09:54:10 -0700
Subject: [PATCH 5.15.y] io_uring/io-wq: fix worker accounting when
 canceling creation callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-stable-io-wq-5-15-y-v1-1-a37209dc29ed@openai.com>
X-B4-Tracking: v=1; b=H4sIALHIjWoC/y2Myw6CMBBFf4XM2iG0yVjirxgX0zpKjSnawQch/
 LsFXJ6Te88EKjmKwqGaIMs7auxTAbOrIHScroLxXBhsY/dNawl1YH8vtsfPEwkN4YjsHFPLwTo
 iKM9Hlkv8rtUjUG2oHuG0eX35m4RhSS5LzyroM6fQLeofX+3Whnn+AdtsDWWkAAAA
X-Change-ID: 20260825-stable-io-wq-5-15-y-a77a58ac2755
To: stable@vger.kernel.org
Cc: io-uring@vger.kernel.org, vrazdan@openai.com, asml.silence@gmail.com, 
 axboe@kernel.dk, krisman@suse.de, gregkh@linuxfoundation.org
In-Reply-To: <2026082424-reflux-strut-f1e1@gregkh>
References: <2026082424-reflux-strut-f1e1@gregkh>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787676852; l=2384;
 i=vrazdan@openai.com; s=io-wq-kernel-20260811; h=from:subject:message-id;
 bh=Tl/OzY3FNyX7xHdZQwqDkXPChdqaGTeIOqQGm/x/EIA=;
 b=0rivWzHQH5EB0zgdQXfXfJw4rzcv1hvXzZaCw62QHak+jai5mTckSbMfDl9K691WBYrVe6X15
 HdrDk8KXUubAR4HCsI/RhJ1y+FSXNHI0doARSgDVETVENRHhNhZJRe3
X-Developer-Key: i=vrazdan@openai.com; a=ed25519;
 pk=45vHW8D/KId5RtsP3Qx7zMcNpgDwEvCnL5uAw0KzuS0=
X-Endpoint-Received: by B4 Relay for vrazdan@openai.com/io-wq-kernel-20260811 with auth_id=937
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

commit 297b5ccea4acacaa47c150f043bce695202afbf1 upstream.

create_worker_cb() reserves an io-wq worker slot only after its
task-work callback runs. If the callback is canceled before then,
io_worker_cancel_cb() still decrements acct->nr_workers. When an
existing worker retires with its creation callback pending, that
worker has already decremented the same account's worker count.

The resulting undercount permits worker creation beyond the account's
configured limit. On an AST2600 OpenBMC system, an unchanged sensor
daemon reached 4,291 threads with the original kernel. With an
equivalent downstream fix, 25 passive samples under its normal
workload showed 6-9 threads.

Decrement nr_workers only when the canceled callback is not
create_worker_cb(). Continuation callbacks still release their reserved
slot, and both callback types retain the existing running-count,
reference-count, and create-state cleanup.

[ Backport: retain the existing worker->wqe->lock protecting worker
  accounting. ]

Fixes: 1d5f5ea7cb7d ("io-wq: remove worker to owner tw dependency")
Cc: stable@vger.kernel.org
Assisted-by: Codex:gpt-5.6-sol
Reviewed-by: Gabriel Krisman Bertazi <krisman@suse.de>
Link: https://patch.msgid.link/20260811-vrazdan-io-wq-b4-submit-v1-1-719ced16c921@openai.com
Signed-off-by: Vishnu Razdan <vrazdan@openai.com>
---
Stable backport for linux-5.15.y.
---
 io_uring/io-wq.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/io_uring/io-wq.c b/io_uring/io-wq.c
index edcb5af514b53e..f57743d911b4cd 100644
--- a/io_uring/io-wq.c
+++ b/io_uring/io-wq.c
@@ -195,9 +195,12 @@ static void io_worker_cancel_cb(struct io_worker *worker)
 	struct io_wq *wq = wqe->wq;
 
 	atomic_dec(&acct->nr_running);
-	raw_spin_lock(&worker->wqe->lock);
-	acct->nr_workers--;
-	raw_spin_unlock(&worker->wqe->lock);
+	/* create_worker_cb() has not reserved a worker slot yet. */
+	if (worker->create_work.func != create_worker_cb) {
+		raw_spin_lock(&worker->wqe->lock);
+		acct->nr_workers--;
+		raw_spin_unlock(&worker->wqe->lock);
+	}
 	io_worker_ref_put(wq);
 	clear_bit_unlock(0, &worker->create_state);
 	io_worker_release(worker);

---
base-commit: 945fa863f02cf8b1638546907f72dd0fc4d6ba85
change-id: 20260825-stable-io-wq-5-15-y-a77a58ac2755

Best regards,
--  
Vishnu Razdan <vrazdan@openai.com>

