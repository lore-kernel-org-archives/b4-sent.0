From: Junrui Luo <moonafterrain@outlook.com>
Date: Thu, 13 Aug 2026 20:47:16 +0800
Subject: [PATCH 1/2] coresight: etm-perf: don't leak the AUX handle on
 failed resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-coresight-fixes-v1-1-7411a73cd496@outlook.com>
References: <20260813-coresight-fixes-v1-0-7411a73cd496@outlook.com>
In-Reply-To: <20260813-coresight-fixes-v1-0-7411a73cd496@outlook.com>
To: Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@arm.com>, James Clark <james.clark@linaro.org>, 
 Leo Yan <leo.yan@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2150;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=yzAo1y/oAIoZDkd9ZQ7K7NSoBvEh92PgMNscnk7BIUA=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrNo9V+NKtQ37yzf+WmV9qneb7rEYSe/27bWH6rlyn
 yRK6apfN+ooZWEQ42KQFVNkOV5w6ZuF7xbdLT5bkmHmsDKBDGHg4hSAiTAcYmS4MtHziTrfiqXJ
 ly/X6ufezZidyXvyp0Y1V+WLORfWMHlcYvin/6D4RNsBvon8Txn9bvx0Fl9S+nZidJHdL/OudTW
 8Ic3MAMzmS7I=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

etm_event_start() shares one error label between the initial start and
the PERF_EF_RESUME path. On the initial start, reaching 'fail' means
perf_aux_output_begin() has not succeeded, so marking the event
PERF_HES_STOPPED is correct. On resume, an AUX transaction opened by the
earlier successful start is still outstanding, and 'goto fail' jumps past
fail_end_stop, which would have ended it.

The following etm_event_stop() returns early on PERF_HES_STOPPED, ahead
of perf_aux_output_end(), coresight_disable_source() and
coresight_disable_path(). This leaks the AUX ring buffer reference and
leaves the sink, the remaining path elements and the trace ID held, so no
later session can use them. ctxt->event_data is cleared just above that
early return, so the leak is silent.

Make resume infallible as pt_event_start() does: leave hw.state alone so
the regular stop path still runs the full teardown. etm_event_resume()
already logs the failure.

Fixes: abffe22e93d7 ("coresight: perf: Support AUX trace pause and resume")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/hwtracing/coresight/coresight-etm-perf.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/hwtracing/coresight/coresight-etm-perf.c b/drivers/hwtracing/coresight/coresight-etm-perf.c
index 09b21a711a87..af0295eab143 100644
--- a/drivers/hwtracing/coresight/coresight-etm-perf.c
+++ b/drivers/hwtracing/coresight/coresight-etm-perf.c
@@ -548,8 +548,13 @@ static void etm_event_start(struct perf_event *event, int flags)
 
 	if (flags & PERF_EF_RESUME) {
 		path = etm_event_get_ctxt_path(ctxt);
-		if (etm_event_resume(path) < 0)
-			goto fail;
+		/*
+		 * Don't mark the event stopped on failure: the AUX transaction
+		 * from the initial start is still live and etm_event_stop()
+		 * bails out early on PERF_HES_STOPPED, leaking it and the path.
+		 * etm_event_resume() already reports the error.
+		 */
+		etm_event_resume(path);
 		return;
 	}
 

-- 
2.51.2

