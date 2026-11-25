From: Moe Mahhouk <moe@flashbots.net>
Date: Wed, 25 Nov 2026 14:11:51 +0000
Subject: [PATCH v4 2/2] virt: tdx-guest: Poll Quote status every 10 ms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-tdx-guest-quote-poll-v4-2-d89f26854b88@flashbots.net>
References: <20261125-tdx-guest-quote-poll-v4-0-d89f26854b88@flashbots.net>
In-Reply-To: <20261125-tdx-guest-quote-poll-v4-0-d89f26854b88@flashbots.net>
To: Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Erdem Aktas <erdemaktas@google.com>, Tom Lendacky <thomas.lendacky@amd.com>, 
 Dan Williams <djbw@kernel.org>, 
 Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>, 
 Xiaoyao Li <xiaoyao.li@intel.com>
Cc: Jun Miao <jun.miao@intel.com>, x86@kernel.org, 
 linux-coco@lists.linux.dev, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Moe Mahhouk <moe@flashbots.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795615914; l=2710;
 i=moe@flashbots.net; s=20261021; h=from:subject:message-id;
 bh=ZJ2AKpTdfk8nnjvMdjII9JPQIlMg0qVyJ6/cNAQLTWE=;
 b=wI2fSczMhX/mxKYtl2J1z8aeVnGsBDgKSZSGKGgAeWbkOWb9jePYRrpaFb3+vuATW/qQdCI/E
 94ZvL/SDmvrDOuBjUzTO+Dvc5VZdEya49VfgPXeLfK1a8AAFjyftNnW
X-Developer-Key: i=moe@flashbots.net; a=ed25519;
 pk=hJTKfjLno/YESrpxMIKDJk34GM+/8Tol+24XK2b4xf0=
X-Endpoint-Received: by B4 Relay for moe@flashbots.net/20261021 with auth_id=1259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wait_for_quote_completion() checks the status of a GetQuote request
once and then sleeps for a full second before each further check. The
VMM has rarely completed the request at the first check, so every Quote
request takes at least one second, however quickly the host answers.

With a local Quote Generation Service the VMM completes the request in
a few milliseconds. On an Emerald Rapids host (KVM, QEMU 11.1, Intel
QGS), back-to-back Quote requests through configfs-tsm took 1021-1024 ms
each; with this change they take 14-21 ms (median 16 ms) at HZ=250.
Since quote_lock serializes requests, the one-second floor also caps a
TD at about one Quote per second, which hurts users that bind a fresh
Quote to every connection, such as attested TLS.

Recheck the status every 10 ms instead. msleep_interruptible() rounds
up to whole jiffies and adds one, so at HZ=250 a step takes 16 ms. The
sleep stays interruptible, and the timeout becomes a deadline in
jiffies.

Suggested-by: Rick Edgecombe <rick.p.edgecombe@intel.com>
Signed-off-by: Moe Mahhouk <moe@flashbots.net>
---
 drivers/virt/coco/tdx-guest/tdx-guest.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)

diff --git a/drivers/virt/coco/tdx-guest/tdx-guest.c b/drivers/virt/coco/tdx-guest/tdx-guest.c
index a5a53174f9d9..25fa2a875c44 100644
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
@@ -271,18 +272,21 @@ static struct tdx_quote_buf *alloc_quote_buf(void)
  */
 static int wait_for_quote_completion(struct tdx_quote_buf *buf, u32 timeout)
 {
-	int i = 0;
+	unsigned long deadline = jiffies + secs_to_jiffies(timeout);
 
 	/*
-	 * Quote requests usually take a few seconds to complete, so waking up
-	 * once per second to recheck the status is fine for this use case.
+	 * A local Quote Generation Service usually completes the request
+	 * within a few milliseconds, so recheck the status every 10 ms.
+	 * msleep_interruptible() rounds up to whole jiffies.
 	 */
-	while (buf->status == GET_QUOTE_IN_FLIGHT && i++ < timeout) {
-		if (msleep_interruptible(MSEC_PER_SEC))
+	while (READ_ONCE(buf->status) == GET_QUOTE_IN_FLIGHT) {
+		if (time_after(jiffies, deadline))
+			return -ETIMEDOUT;
+		if (msleep_interruptible(10))
 			return -EINTR;
 	}
 
-	return (buf->status == GET_QUOTE_IN_FLIGHT) ? -ETIMEDOUT : 0;
+	return 0;
 }
 
 static int tdx_report_new_locked(struct tsm_report *report)

-- 
2.34.1

