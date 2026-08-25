From: Vishnu Razdan <vrazdan@openai.com>
Date: Tue, 25 Aug 2026 09:52:03 -0700
Subject: [PATCH 6.6.y] io_uring/io-wq: fix worker accounting when canceling
 creation callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-stable-io-wq-6-6-y-v1-1-c9f890168485@openai.com>
X-B4-Tracking: v=1; b=H4sIADLIjWoC/y2MSw7CMAxEr1J5jasS1IC4CuoiMS4NQinE5VNVv
 TtOQLOap5m3gHAKLHCsFkj8ChLGqGW7qYAGFy+M4awdTGNsczAtyuT8TemI7wdazYzeGdr11JK
 hPejxnrgPnyI9ga1tPUP3w/L0V6YpC/PQO2H0yUUaMvqrCy1mWNcvDve2R6EAAAA=
X-Change-ID: 20260825-stable-io-wq-6-6-y-ba2c3fc5c2c7
To: stable@vger.kernel.org
Cc: asml.silence@gmail.com, vrazdan@openai.com, krisman@suse.de, 
 axboe@kernel.dk, io-uring@vger.kernel.org, gregkh@linuxfoundation.org
In-Reply-To: <2026082423-fineness-promotion-9ac5@gregkh>
References: <2026082423-fineness-promotion-9ac5@gregkh>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787676793; l=2337;
 i=vrazdan@openai.com; s=io-wq-kernel-20260811; h=from:subject:message-id;
 bh=VKXeGsfnMBFtjlWVBZ3PVT5X6resbdE+aaVqCUQBHaw=;
 b=cMPsI3bfyS4J/eutD9UJRVgZ7c6ppKcOg/mj1NypZn98YswYPv5cx12ROriVJTjkccI9/sHfg
 8xb7wxVT+LyAHcnstiJ0GFff2huUiw1h6vfl+7GmbHBxx4T3qJFW798
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

[ Backport: retain the existing wq->lock protecting worker accounting. ]

Fixes: 1d5f5ea7cb7d ("io-wq: remove worker to owner tw dependency")
Cc: stable@vger.kernel.org
Assisted-by: Codex:gpt-5.6-sol
Reviewed-by: Gabriel Krisman Bertazi <krisman@suse.de>
Link: https://patch.msgid.link/20260811-vrazdan-io-wq-b4-submit-v1-1-719ced16c921@openai.com
Signed-off-by: Vishnu Razdan <vrazdan@openai.com>
---
Stable backport for linux-6.6.y.
---
 io_uring/io-wq.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/io_uring/io-wq.c b/io_uring/io-wq.c
index 37725c5031b4c2..a20be1a43aafcf 100644
--- a/io_uring/io-wq.c
+++ b/io_uring/io-wq.c
@@ -193,9 +193,12 @@ static void io_worker_cancel_cb(struct io_worker *worker)
 	struct io_wq *wq = worker->wq;
 
 	atomic_dec(&acct->nr_running);
-	raw_spin_lock(&wq->lock);
-	acct->nr_workers--;
-	raw_spin_unlock(&wq->lock);
+	/* create_worker_cb() has not reserved a worker slot yet. */
+	if (worker->create_work.func != create_worker_cb) {
+		raw_spin_lock(&wq->lock);
+		acct->nr_workers--;
+		raw_spin_unlock(&wq->lock);
+	}
 	io_worker_ref_put(wq);
 	clear_bit_unlock(0, &worker->create_state);
 	io_worker_release(worker);

---
base-commit: dc6160265ffc795a1832bc1424f58291d152c7bb
change-id: 20260825-stable-io-wq-6-6-y-ba2c3fc5c2c7

Best regards,
--  
Vishnu Razdan <vrazdan@openai.com>

