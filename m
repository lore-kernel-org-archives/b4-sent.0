From: Vishnu Razdan <vrazdan@openai.com>
Date: Tue, 11 Aug 2026 00:01:27 -0700
Subject: [PATCH] io_uring/io-wq: fix worker accounting when canceling
 creation callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-vrazdan-io-wq-b4-submit-v1-1-719ced16c921@openai.com>
X-B4-Tracking: v=1; b=H4sIAMbIemoC/yWMwQ6CMBBEf4Xs2U1aUhX8FeOhLYusgQItRSLh3
 231Nm/yZnYI5JkC3IodPK0ceHQJ5KkA22n3JOQmMZSivIhKCly9/jTaIY/4ntEoDNEMvGBta9W
 0Up2vsoK0njy1vP2e748/J/NFdsl32TA6EBqvne1y1bOLGw6aXUqEUzQ9W8wSHMcXW9QkuKgAA
 AA=
X-Change-ID: 20260810-vrazdan-io-wq-b4-submit-9c94df145718
To: axboe@kernel.dk
Cc: io-uring@vger.kernel.org, vrazdan@openai.com, 
 linux-kernel@vger.kernel.org, asml.silence@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786431705; l=2133;
 i=vrazdan@openai.com; s=io-wq-kernel-20260811; h=from:subject:message-id;
 bh=BudlQE+XkmRRoHQjFbXZv3L3ZO0exGygvlY2UfDjXFs=;
 b=4lcLmSMBawdC2cbRCMIWnW8jO7Buvnp6m/vN41G4Ry6tz6SLjDiF/C7Y6whPXEawgOZR141vw
 c8vhYriGRaFAEDOBT2Or9ASBGL71xG3wMEjxUHg1Fyzo8Bl/tGBGFLb
X-Developer-Key: i=vrazdan@openai.com; a=ed25519;
 pk=45vHW8D/KId5RtsP3Qx7zMcNpgDwEvCnL5uAw0KzuS0=
X-Endpoint-Received: by B4 Relay for vrazdan@openai.com/io-wq-kernel-20260811 with auth_id=937
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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

Fixes: 1d5f5ea7cb7d ("io-wq: remove worker to owner tw dependency")
Cc: stable@vger.kernel.org
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Vishnu Razdan <vrazdan@openai.com>
---
Prevent unreserved worker-creation callbacks from decrementing the worker count.
---
 io_uring/io-wq.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/io_uring/io-wq.c b/io_uring/io-wq.c
index 2e14880ee..fa403ed24 100644
--- a/io_uring/io-wq.c
+++ b/io_uring/io-wq.c
@@ -211,9 +211,12 @@ static void io_worker_cancel_cb(struct io_worker *worker)
 	struct io_wq *wq = worker->wq;
 
 	atomic_dec(&acct->nr_running);
-	raw_spin_lock(&acct->workers_lock);
-	acct->nr_workers--;
-	raw_spin_unlock(&acct->workers_lock);
+	/* create_worker_cb() has not reserved a worker slot yet. */
+	if (worker->create_work.func != create_worker_cb) {
+		raw_spin_lock(&acct->workers_lock);
+		acct->nr_workers--;
+		raw_spin_unlock(&acct->workers_lock);
+	}
 	io_worker_ref_put(wq);
 	clear_bit_unlock(0, &worker->create_state);
 	io_worker_release(worker);

---
base-commit: d58772d8520c7ef247c4b95c9bd76d3a25da9ff5
change-id: 20260810-vrazdan-io-wq-b4-submit-9c94df145718

Best regards,
--  
Vishnu Razdan <vrazdan@openai.com>

