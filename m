From: Moe Mahhouk <moe@flashbots.net>
Date: Wed, 21 Oct 2026 17:16:32 +0000
Subject: [PATCH] virt: tdx-guest: Poll Quote status with exponential
 backoff
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-tdx-guest-quote-poll-v1-1-919a87812ecb@flashbots.net>
X-B4-Tracking: v=1; b=H4sIAG/z2GoC/yXMQQqDMBBA0avIrDswCbRir1K6aOJEp4ixmaQI4
 t2b6vIt/t9AOQkr3JsNEn9FJc4V5tKAH1/zwCh9NViyN0PWYO5XHAprxk+JmXGJ04QUWhf8teu
 IHNR0SRxkPbaP52kt7s0+/1+w7z+kcMDgeAAAAA==
X-Change-ID: 20261021-tdx-guest-quote-poll-0f7bfc59900b
To: Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>
Cc: x86@kernel.org, linux-coco@lists.linux.dev, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Moe Mahhouk <moe@flashbots.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792602996; l=3676;
 i=moe@flashbots.net; s=20261021; h=from:subject:message-id;
 bh=ovLjrwfOdsN8YV/HwtnnZX45Tn33AdVlaLj2iyiZxOg=;
 b=NerAd036wmkMOdNkDJm5yKzKT8DYx11lgGw4sGyYs33FluB7iBSKnw0ovprvbNvjeyeRTOoib
 Chgkf+bdwTWAe2iY3uOW0Za4az4NHjcAknw5+o6DNLQwK+5cV3GQbYR
X-Developer-Key: i=moe@flashbots.net; a=ed25519;
 pk=hJTKfjLno/YESrpxMIKDJk34GM+/8Tol+24XK2b4xf0=
X-Endpoint-Received: by B4 Relay for moe@flashbots.net/20261021 with auth_id=1259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wait_for_quote_completion() sleeps for a full second before it first
checks whether the VMM has completed a GetQuote request, and then
rechecks once per second. Every Quote request therefore takes at least
one second, however quickly the host answers.

With a local Quote Generation Service the VMM completes the request in
a few milliseconds. On an Emerald Rapids host (KVM, QEMU 11.1, Intel
QGS), 40 back-to-back Quote requests through configfs-tsm took
1021-1024 ms each; with this change they take 2-3 ms. Since quote_lock
serializes requests, the one-second floor also caps a TD at about one
Quote per second, which hurts users that bind a fresh Quote to every
connection, such as attested TLS.

Poll with an exponential backoff instead: start at 100 us and double the
interval up to 100 ms. A fast Quote is noticed within a few milliseconds,
a slow one costs at most ten wakeups per second. The timeout is
unchanged, and a pending signal still aborts the wait with -EINTR.

The latency was found while measuring TD boot and attestation times.
The code and this changelog were written with an AI coding assistant,
Claude (Claude Code, model Claude Opus 5.5), which also ran the tests.
Tested on mainline a804c5742 in a TDX guest (KVM host v7.0, QEMU 11.1.2,
TDX module 1.5.34, Intel QGS) with 40 Quote requests per kernel; builds
with W=1 and passes checkpatch.pl.

Signed-off-by: Moe Mahhouk <moe@flashbots.net>
---
The GHCI SetupEventNotifyInterrupt mechanism would avoid polling
altogether, but it relies on the VMM implementing that service. This
patch keeps the existing polling model, which works with any VMM, and
only removes the fixed one-second floor.
---
 drivers/virt/coco/tdx-guest/tdx-guest.c | 21 +++++++++++++++------
 1 file changed, 15 insertions(+), 6 deletions(-)

diff --git a/drivers/virt/coco/tdx-guest/tdx-guest.c b/drivers/virt/coco/tdx-guest/tdx-guest.c
index 11d741da3..5cb7365b2 100644
--- a/drivers/virt/coco/tdx-guest/tdx-guest.c
+++ b/drivers/virt/coco/tdx-guest/tdx-guest.c
@@ -16,6 +16,8 @@
 #include <linux/set_memory.h>
 #include <linux/io.h>
 #include <linux/delay.h>
+#include <linux/jiffies.h>
+#include <linux/sched/signal.h>
 #include <linux/sockptr.h>
 #include <linux/tsm.h>
 #include <linux/tsm-mr.h>
@@ -271,18 +273,25 @@ static struct tdx_quote_buf *alloc_quote_buf(void)
  */
 static int wait_for_quote_completion(struct tdx_quote_buf *buf, u32 timeout)
 {
-	int i = 0;
+	unsigned long deadline = jiffies + timeout * HZ;
+	unsigned int sleep_us = 100;
 
 	/*
-	 * Quote requests usually take a few seconds to complete, so waking up
-	 * once per second to recheck the status is fine for this use case.
+	 * A local Quote Generation Service usually completes the request
+	 * within a few milliseconds. Poll with an exponential backoff, from
+	 * 100 us up to 100 ms, so that a fast Quote is noticed promptly while
+	 * a slow one costs at most ten wakeups per second.
 	 */
-	while (buf->status == GET_QUOTE_IN_FLIGHT && i++ < timeout) {
-		if (msleep_interruptible(MSEC_PER_SEC))
+	while (READ_ONCE(buf->status) == GET_QUOTE_IN_FLIGHT) {
+		if (time_after(jiffies, deadline))
+			return -ETIMEDOUT;
+		if (signal_pending(current))
 			return -EINTR;
+		usleep_range(sleep_us, 2 * sleep_us);
+		sleep_us = min(2 * sleep_us, 100 * USEC_PER_MSEC);
 	}
 
-	return (i == timeout) ? -ETIMEDOUT : 0;
+	return 0;
 }
 
 static int tdx_report_new_locked(struct tsm_report *report)

---
base-commit: a804c5742bff224d4cb4d25dd383554d598be32b
change-id: 20261021-tdx-guest-quote-poll-0f7bfc59900b

Best regards,
--  
Moe Mahhouk <moe@flashbots.net>

