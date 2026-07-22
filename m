From: Nathan Lynch <nathan.lynch@amd.com>
Date: Wed, 22 Jul 2026 10:47:49 -0500
Subject: [PATCH 4/4] dmaengine: dmatest: Optionally make test errors fatal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-dmatest-fixes-and-fatal-errors-v1-4-8287709987ea@amd.com>
References: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
In-Reply-To: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Tycho Andersen <tycho@kernel.org>, Wei Huang <wei.huang2@amd.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784735280; l=5353;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=r1oLdav/T8y/iZ+lMH1y1LszIWGqEDNjroTj5YnSY/4=;
 b=OOwqmJqiFUGXTYHXFgESLpyGa7lUqTmyJjMfbbR3vznkOSnvTfOdXf9mbAyyi7YQOWiKEpExS
 U17QLqCOaLVC5eww7va6h+oYHPDL0A/tt5R5r/BtrX1yI9Rn7g5PPxi
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For automated testing it is useful to have dmatest halt the machine when
errors occur rather than logging them and continuing, so that the system
state at the point of failure can be captured instead of allowing the run
to carry on.

Add a 'fatal_errors' module parameter, defaulting to 0. When set to a
non-zero value N, panic the kernel once N test errors have accumulated in
a run; the count is reset at the start of each run. The panic is triggered
after the existing result() line is logged, so the specific error (data
mismatch, mapping/prep/submit error, timeout, or bad completion status) is
recorded before the crash.

Assisted-by: Claude:claude-opus-4-8 [Claude-Code]
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/dmatest.c | 36 +++++++++++++++++++++++++++++++++++-
 1 file changed, 35 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/dmatest.c b/drivers/dma/dmatest.c
index 0d7752c2451a..a070ce6f2fa9 100644
--- a/drivers/dma/dmatest.c
+++ b/drivers/dma/dmatest.c
@@ -7,6 +7,7 @@
  */
 #define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
 
+#include <linux/atomic.h>
 #include <linux/err.h>
 #include <linux/delay.h>
 #include <linux/dma-mapping.h>
@@ -92,6 +93,11 @@ static bool polled;
 module_param(polled, bool, 0644);
 MODULE_PARM_DESC(polled, "Use polling for completion instead of interrupts");
 
+static unsigned int fatal_errors;
+module_param(fatal_errors, uint, 0644);
+MODULE_PARM_DESC(fatal_errors,
+		"Panic after this many test errors in a run; 0 = never (default: 0)");
+
 /**
  * struct dmatest_params - test parameters.
  * @nobounce:		prevent using swiotlb buffer
@@ -109,6 +115,7 @@ MODULE_PARM_DESC(polled, "Use polling for completion instead of interrupts");
  * @alignment:		custom data address alignment taken as 2^alignment
  * @transfer_size:	custom transfer size in bytes
  * @polled:		use polling for completion instead of interrupts
+ * @fatal_errors:	panic after this many test errors in a run (0 = never)
  */
 struct dmatest_params {
 	bool		nobounce;
@@ -126,6 +133,7 @@ struct dmatest_params {
 	int		alignment;
 	unsigned int	transfer_size;
 	bool		polled;
+	unsigned int	fatal_errors;
 };
 
 /**
@@ -133,6 +141,7 @@ struct dmatest_params {
  * @params:		test parameters
  * @channels:		channels under test
  * @nr_channels:	number of channels under test
+ * @error_count:	test errors in the current run (for fatal_errors)
  * @lock:		access protection to the fields of this structure
  * @did_init:		module has been initialized completely
  * @last_error:		test has faced configuration issues
@@ -144,6 +153,7 @@ struct dmatest_info {
 	/* Internal state */
 	struct list_head	channels;
 	unsigned int		nr_channels;
+	atomic_t		error_count;
 	int			last_error;
 	struct mutex		lock;
 	bool			did_init;
@@ -487,6 +497,24 @@ static void dbg_result(const char *err, unsigned int n, unsigned int src_off,
 		dbg_result(err, n, src_off, dst_off, len, data);\
 })
 
+/*
+ * Record a test error whose details were just logged via result(). When
+ * fatal_errors is set, panic once that many errors have accumulated in the
+ * current run.
+ */
+static void dmatest_note_error(struct dmatest_info *info)
+{
+	unsigned int errors;
+
+	if (!info->params.fatal_errors)
+		return;
+
+	errors = atomic_inc_return(&info->error_count);
+	if (errors >= info->params.fatal_errors)
+		panic("dmatest: fatal_errors=%u and %u error(s) encountered\n",
+		      info->params.fatal_errors, errors);
+}
+
 static unsigned long long dmatest_persec(s64 runtime, unsigned int val)
 {
 	unsigned long long per_sec = 1000000;
@@ -583,7 +611,7 @@ static int dmatest_func(void *data)
 	struct dma_device	*dev;
 	struct device		*dma_dev;
 	unsigned int		error_count;
-	unsigned int		failed_tests = 0;
+	unsigned int		failed_tests = 0;	/* for this thread */
 	unsigned int		total_tests = 0;
 	dma_cookie_t		cookie;
 	enum dma_status		status;
@@ -755,6 +783,7 @@ static int dmatest_func(void *data)
 			failed_tests++;
 			result("unmap data NULL", total_tests,
 			       src->off, dst->off, len, ret);
+			dmatest_note_error(info);
 			continue;
 		}
 
@@ -910,6 +939,7 @@ static int dmatest_func(void *data)
 			result("data error", total_tests, src->off, dst->off,
 			       len, error_count);
 			failed_tests++;
+			dmatest_note_error(info);
 		} else {
 			verbose_result("test passed", total_tests, src->off,
 				       dst->off, len, 0);
@@ -920,6 +950,7 @@ static int dmatest_func(void *data)
 error_unmap_continue:
 		dmaengine_unmap_put(um);
 		failed_tests++;
+		dmatest_note_error(info);
 	}
 	ktime = ktime_sub(ktime_get(), ktime);
 	ktime = ktime_sub(ktime, comparetime);
@@ -1135,6 +1166,7 @@ static void add_threaded_test(struct dmatest_info *info)
 	params->alignment = alignment;
 	params->transfer_size = transfer_size;
 	params->polled = polled;
+	params->fatal_errors = fatal_errors;
 
 	request_channels(info, DMA_MEMCPY);
 	request_channels(info, DMA_MEMSET);
@@ -1147,6 +1179,8 @@ static void run_pending_tests(struct dmatest_info *info)
 	struct dmatest_chan *dtc;
 	unsigned int thread_count = 0;
 
+	atomic_set(&info->error_count, 0);
+
 	list_for_each_entry(dtc, &info->channels, node) {
 		struct dmatest_thread *thread;
 

-- 
2.54.0

