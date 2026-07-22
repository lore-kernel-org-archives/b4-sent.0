From: Nathan Lynch <nathan.lynch@amd.com>
Date: Wed, 22 Jul 2026 10:47:48 -0500
Subject: [PATCH 3/4] dmaengine: dmatest: Terminate channel before freeing
 threads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-dmatest-fixes-and-fatal-errors-v1-3-8287709987ea@amd.com>
References: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
In-Reply-To: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Tycho Andersen <tycho@kernel.org>, Wei Huang <wei.huang2@amd.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784735280; l=1679;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=/0q1Z1d1+2oGXvP2+BrsGqvG+5+zUlAtwDMzMF2C+Mk=;
 b=SOqPziyDMTrFeN9HfcYkh2T22cJ2YzcJccaRSZ37T2mP4Avx/UTiYyZLTAnE1Z9zXcUil87Gn
 G0T4wtcdJ9cBXiwf9qUbWWcvewEaFtHhSk5o1kgJZg8+SbY7IHAEjpR
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a channel shared by multiple threads, the completion callbacks run from
one tasklet, and dmaengine_terminate_sync() flushes it. Freeing a thread
before that flush can leave a pending callback pointing at freed memory
(dmatest_callback() reads thread->done).

Stop all channel threads and then flush the channel before freeing the
threads.

Fixes: 6f6a23a213be ("dmaengine: dmatest: move callback wait queue to thread context")
Assisted-by: Claude:claude-opus-4-8 [Claude-Code]
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/dmatest.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/dma/dmatest.c b/drivers/dma/dmatest.c
index 3267c7e86f5d..0d7752c2451a 100644
--- a/drivers/dma/dmatest.c
+++ b/drivers/dma/dmatest.c
@@ -959,18 +959,23 @@ static void dmatest_cleanup_channel(struct dmatest_chan *dtc)
 	struct dmatest_thread	*_thread;
 	int			ret;
 
-	list_for_each_entry_safe(thread, _thread, &dtc->threads, node) {
+	/* stop all threads first */
+	list_for_each_entry(thread, &dtc->threads, node) {
 		ret = kthread_stop(thread->task);
 		pr_debug("thread %s exited with status %d\n",
 			 thread->task->comm, ret);
+	}
+
+	/* flush the channel (e.g. vchan_synchronize() -> tasklet_kill()) */
+	dmaengine_terminate_sync(dtc->chan);
+
+	/* now it is safe to free the thread memory */
+	list_for_each_entry_safe(thread, _thread, &dtc->threads, node) {
 		list_del(&thread->node);
 		put_task_struct(thread->task);
 		kfree(thread);
 	}
 
-	/* terminate all transfers on specified channels */
-	dmaengine_terminate_sync(dtc->chan);
-
 	kfree(dtc);
 }
 

-- 
2.54.0

