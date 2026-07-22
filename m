From: Nathan Lynch <nathan.lynch@amd.com>
Date: Wed, 22 Jul 2026 10:47:47 -0500
Subject: [PATCH 2/4] dmaengine: dmatest: Suppress bogus failures when
 stopping a run
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260722-dmatest-fixes-and-fatal-errors-v1-2-8287709987ea@amd.com>
References: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
In-Reply-To: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Tycho Andersen <tycho@kernel.org>, Wei Huang <wei.huang2@amd.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784735280; l=2864;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=74Mzvk0OhTQ8oeyoxuGyU/WEbTMbhAo7r3eZp+EdkGI=;
 b=4g8nxKx42X48tlx8QmGzW5nnhlhEjili4Eu6/6VS627E/LbA8IYnyI7XWp6Wd8d2koduhYE93
 C6SWXdM1dfcDP+Rm7nexzpCfha/avFLMxRCSURU2SzP3kdH3QQJHtt1
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing 0 to the module 'run' attribute stops the test threads with
kthread_stop(), waking threads out of wait_event_freezable_timeout()
before the last transfer's completion callback has run. The stopping
thread samples the transfer status and then checks done->done at two
different instants, so the last transaction gets misreported two ways:

- "test timed out": the wait returns early with done->done still clear
  even though the transfer is simply still finishing — not a real
  timeout.

- "completion busy status": status is read as DMA_IN_PROGRESS a moment
  before the transfer completes and latches done->done, so the stale
  status is reported as a failure against a transfer that actually
  succeeded.

This is not a recent regression: the threads have used an interruptible,
freezable timeout wait since long before the wait queue was moved into
thread context by commit 6f6a23a213be ("dmaengine: dmatest: move callback
wait queue to thread context"), so a stop has always been able to wake
the wait before the final callback runs.

When kthread_should_stop() returns true, use dma_sync_wait() to settle
the pending transaction. Real errors still yield DMA_ERROR.

Assisted-by: Claude:claude-opus-4-8 [Claude-Code]
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/dmatest.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/dma/dmatest.c b/drivers/dma/dmatest.c
index 60bc448f42ee..3267c7e86f5d 100644
--- a/drivers/dma/dmatest.c
+++ b/drivers/dma/dmatest.c
@@ -702,6 +702,7 @@ static int dmatest_func(void *data)
 		struct dmaengine_unmap_data *um;
 		dma_addr_t *dsts;
 		unsigned int len;
+		bool stopping;
 
 		total_tests++;
 
@@ -839,6 +840,7 @@ static int dmatest_func(void *data)
 			status = dma_sync_wait(chan, cookie);
 			if (status == DMA_COMPLETE)
 				done->done = true;
+			stopping = kthread_should_stop();
 		} else {
 			dma_async_issue_pending(chan);
 
@@ -846,14 +848,19 @@ static int dmatest_func(void *data)
 					done->done,
 					msecs_to_jiffies(params->timeout));
 
-			status = dma_async_is_tx_complete(chan, cookie, NULL,
-							  NULL);
+			stopping = kthread_should_stop();
+			status = stopping ?
+				dma_sync_wait(chan, cookie) :
+				dma_async_is_tx_complete(chan, cookie, NULL, NULL);
 		}
 
 		if (!done->done) {
-			result("test timed out", total_tests, src->off, dst->off,
-			       len, 0);
-			goto error_unmap_continue;
+			/* stopping: dma_sync_wait() let the transfer finish, not a timeout */
+			if (!stopping) {
+				result("test timed out", total_tests, src->off,
+				       dst->off, len, 0);
+				goto error_unmap_continue;
+			}
 		} else if (status != DMA_COMPLETE &&
 			   !(dma_has_cap(DMA_COMPLETION_NO_ORDER,
 					 dev->cap_mask) &&

-- 
2.54.0

