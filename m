From: Moe Mahhouk <moe@flashbots.net>
Date: Thu, 22 Oct 2026 16:31:42 +0000
Subject: [PATCH v2 2/2] virt: tdx-guest: Poll Quote status with exponential
 backoff
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-tdx-guest-quote-poll-v2-2-7543c6eb2d36@flashbots.net>
References: <20261022-tdx-guest-quote-poll-v2-0-7543c6eb2d36@flashbots.net>
In-Reply-To: <20261022-tdx-guest-quote-poll-v2-0-7543c6eb2d36@flashbots.net>
To: Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Erdem Aktas <erdemaktas@google.com>, Tom Lendacky <thomas.lendacky@amd.com>, 
 Dan Williams <djbw@kernel.org>
Cc: Jun Miao <jun.miao@intel.com>, 
 Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>, 
 x86@kernel.org, linux-coco@lists.linux.dev, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Moe Mahhouk <moe@flashbots.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792686704; l=2835;
 i=moe@flashbots.net; s=20261021; h=from:subject:message-id;
 bh=qSVE+hw1y6dS8lKhF55oe4BwZY0z5PC+umOVM8RdJVs=;
 b=Rd5lKcb7G0lbmQa+sbSVtrW/ii30WTcmvTRyosbGzigOVfjWjbpLDhs7VwADVmo74iAgjyxUd
 J2wjHqerY0ICEdFvlU7hYMFOKlbDVIxSdYtTzxAu0VamilZEO7JzAwT
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
QGS), back-to-back Quote requests through configfs-tsm took 1021-1024 ms
each; with this change they take 6-12 ms at HZ=250. Since quote_lock
serializes requests, the one-second floor also caps a TD at about one
Quote per second, which hurts users that bind a fresh Quote to every
connection, such as attested TLS.

Poll with an exponential backoff instead: sleep 1 ms first and double
the interval up to 100 ms, so that a fast Quote is noticed within a few
milliseconds while a slow one costs at most ten wakeups per second. The
sleep stays interruptible, and the timeout becomes a deadline in
jiffies.

Signed-off-by: Moe Mahhouk <moe@flashbots.net>
---
 drivers/virt/coco/tdx-guest/tdx-guest.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/drivers/virt/coco/tdx-guest/tdx-guest.c b/drivers/virt/coco/tdx-guest/tdx-guest.c
index a5a53174f9d9..000fff4ef6f5 100644
--- a/drivers/virt/coco/tdx-guest/tdx-guest.c
+++ b/drivers/virt/coco/tdx-guest/tdx-guest.c
@@ -16,6 +16,7 @@
 #include <linux/set_memory.h>
 #include <linux/io.h>
 #include <linux/delay.h>
+#include <linux/jiffies.h>
 #include <linux/sockptr.h>
 #include <linux/tsm.h>
 #include <linux/tsm-mr.h>
@@ -271,18 +272,24 @@ static struct tdx_quote_buf *alloc_quote_buf(void)
  */
 static int wait_for_quote_completion(struct tdx_quote_buf *buf, u32 timeout)
 {
-	int i = 0;
+	unsigned long deadline = jiffies + secs_to_jiffies(timeout);
+	unsigned int sleep_ms = 1;
 
 	/*
-	 * Quote requests usually take a few seconds to complete, so waking up
-	 * once per second to recheck the status is fine for this use case.
+	 * A local Quote Generation Service usually completes the request
+	 * within a few milliseconds. Poll with an exponential backoff, from
+	 * 1 ms up to 100 ms, so that a fast Quote is noticed promptly while
+	 * a slow one costs at most ten wakeups per second.
 	 */
-	while (buf->status == GET_QUOTE_IN_FLIGHT && i++ < timeout) {
-		if (msleep_interruptible(MSEC_PER_SEC))
+	while (READ_ONCE(buf->status) == GET_QUOTE_IN_FLIGHT) {
+		if (time_after(jiffies, deadline))
+			return -ETIMEDOUT;
+		if (msleep_interruptible(sleep_ms))
 			return -EINTR;
+		sleep_ms = min(2 * sleep_ms, 100U);
 	}
 
-	return (buf->status == GET_QUOTE_IN_FLIGHT) ? -ETIMEDOUT : 0;
+	return 0;
 }
 
 static int tdx_report_new_locked(struct tsm_report *report)

-- 
2.34.1

