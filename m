From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sun, 13 Sep 2026 10:30:37 +0000
Subject: [PATCH] io_uring/io-wq: stop a single cancel after one running
 match
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-b4-send-io-wq-cancel-v1-1-dcfe47275c6e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEx7pmoC/yXMSQ6DMAxA0asgr7EUQhjKVRALCKZ1VYUSM0mIu
 5OW5Vv8f4CQZxKoogM8rSw8uoAkjsC+Wvck5D4YtNK5eiQpdgaFXI884jahbZ2lD2aqMGU5FFq
 bDEL69TTw/t/WzW1ZujfZ+feC87wAE6bFqngAAAA=
X-Change-ID: 20260913-b4-send-io-wq-cancel-507488f72245
To: Jens Axboe <axboe@kernel.dk>, io-uring@vger.kernel.org
Cc: Max Kellermann <max.kellermann@ionos.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789295453; l=2320;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=zEcwHR2kQSy3dfsGCzpbxbgI9eHTSwWnoSfY7BAfcpo=;
 b=cCFKWrKxZT+Dh8OtKAXY4k/2l3YdVhb71iiGjzuYVQ9LKbof4yktciTuZx2U9gHVXvhO3lDU9
 STu8WUmIXhsBt/s4D4MzUGqqf3hCDE6n/6P/TQ3Nbk07bwwO6mZasv2
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

io_wq_worker_cancel() asks io_acct_for_each_worker() to stop after one
match when cancel_all is clear.  io_acct_cancel_running_work() discards
that result, so io_wq_cancel_running_work() continues into the other
worker account with nr_running already set.

If the first worker there also matches, one non-ALL cancel signals a
request in both the bounded and unbounded accounts.

Return the iterator result and stop scanning accounts after a match.
IORING_ASYNC_CANCEL_ALL is unchanged because its callback does not stop
the iteration.

A test runs a blocking open in the bounded account and a blocking
pipe-to-pipe splice in the unbounded account with the same user_data.
Before this change both operations are interrupted by one cancel.  After
the change only the open is interrupted, and the splice completes when
input is supplied.

Fixes: 751eedc4b4b7 ("io_uring/io-wq: move worker lists to struct io_wq_acct")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 io_uring/io-wq.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/io_uring/io-wq.c b/io_uring/io-wq.c
index 2ca223e47d..9f9039e3d3 100644
--- a/io_uring/io-wq.c
+++ b/io_uring/io-wq.c
@@ -1181,12 +1181,15 @@ static void io_wq_cancel_pending_work(struct io_wq *wq,
 	}
 }
 
-static void io_acct_cancel_running_work(struct io_wq_acct *acct,
+static bool io_acct_cancel_running_work(struct io_wq_acct *acct,
 					struct io_cb_cancel_data *match)
 {
+	bool ret;
+
 	raw_spin_lock(&acct->workers_lock);
-	io_acct_for_each_worker(acct, io_wq_worker_cancel, match);
+	ret = io_acct_for_each_worker(acct, io_wq_worker_cancel, match);
 	raw_spin_unlock(&acct->workers_lock);
+	return ret;
 }
 
 static void io_wq_cancel_running_work(struct io_wq *wq,
@@ -1195,7 +1198,8 @@ static void io_wq_cancel_running_work(struct io_wq *wq,
 	rcu_read_lock();
 
 	for (int i = 0; i < IO_WQ_ACCT_NR; i++)
-		io_acct_cancel_running_work(&wq->acct[i], match);
+		if (io_acct_cancel_running_work(&wq->acct[i], match))
+			break;
 
 	rcu_read_unlock();
 }

---
base-commit: 11773ae6da9c9d92f5d1def78f7e70a9f1fa7b1c
change-id: 20260913-b4-send-io-wq-cancel-507488f72245

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

