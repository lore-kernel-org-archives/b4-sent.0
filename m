From: Moe Mahhouk <moe@flashbots.net>
Date: Sat, 24 Oct 2026 19:17:13 +0000
Subject: [PATCH v3 2/2] virt: tdx-guest: Poll Quote status with exponential
 backoff
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-tdx-guest-quote-poll-v3-2-6a83bb767314@flashbots.net>
References: <20261024-tdx-guest-quote-poll-v3-0-6a83bb767314@flashbots.net>
In-Reply-To: <20261024-tdx-guest-quote-poll-v3-0-6a83bb767314@flashbots.net>
To: Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Erdem Aktas <erdemaktas@google.com>, Tom Lendacky <thomas.lendacky@amd.com>, 
 Dan Williams <djbw@kernel.org>, 
 Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>
Cc: Jun Miao <jun.miao@intel.com>, x86@kernel.org, 
 linux-coco@lists.linux.dev, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Moe Mahhouk <moe@flashbots.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792869441; l=3161;
 i=moe@flashbots.net; s=20261021; h=from:subject:message-id;
 bh=9wLrH7YqqH84MzZMatdM4i6m5nN1ejaqoVcq375fEBE=;
 b=eLxTF7RjCr/NlBZDcr2wIPJaLyGbKqnr+6cYoqZXkprSmTHNs7XnnNu4EuYvkREcOKAz0DYte
 ctdRoi0YC4aBRkWIqLWL+tED/gTHUk63Yw+afTF5T9sQN8VdaISjYxf
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

Poll with an exponential backoff instead: double the sleep from 1 ms up
to 100 ms, so that a fast Quote is noticed within a few milliseconds
while a slow one costs at most ten wakeups per second.
msleep_interruptible() rounds up to whole jiffies, so at HZ=250 the 1, 2
and 4 ms steps are one 4 ms tick each. The sleep stays interruptible,
and the timeout becomes a deadline in jiffies.

Reviewed-by: Kiryl Shutsemau (Meta) <kas@kernel.org>
Reviewed-by: Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>
Signed-off-by: Moe Mahhouk <moe@flashbots.net>
---
 drivers/virt/coco/tdx-guest/tdx-guest.c | 20 ++++++++++++++------
 1 file changed, 14 insertions(+), 6 deletions(-)

diff --git a/drivers/virt/coco/tdx-guest/tdx-guest.c b/drivers/virt/coco/tdx-guest/tdx-guest.c
index a5a53174f9d9..d58c8eccb26b 100644
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
@@ -271,18 +272,25 @@ static struct tdx_quote_buf *alloc_quote_buf(void)
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
+	 * within a few milliseconds. Poll with an exponential backoff of up
+	 * to 100 ms, so that a fast Quote is noticed promptly while a slow
+	 * one costs at most ten wakeups per second. msleep_interruptible()
+	 * rounds up to whole jiffies, so the shortest steps take one tick.
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

