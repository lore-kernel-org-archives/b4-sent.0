From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Feb 2023 12:54:17 -0600
Subject: [PATCH v2 01/19] powerpc/rtas: handle extended delays safely in
 early boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-1-9aa6bd058063@linux.ibm.com>
References: <20230125-b4-powerpc-rtas-queue-v2-0-9aa6bd058063@linux.ibm.com>
In-Reply-To: <20230125-b4-powerpc-rtas-queue-v2-0-9aa6bd058063@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Kajol Jain <kjain@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Andrew Donnellan <ajd@linux.ibm.com>, Nick Child <nnac123@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=3779;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=pLkh3/obNWVA07fMBbNuF95oFvgPYtA8yiTJ8EjahUk=;
 b=s+khifzqEVF1RwfURHFHOqye8hBqeNSzTN5qy++G9PFN1j17oMOQlNhAkHMtp6F5KrgqUJPdl
 wgOaYZOOwMLDzuvlIOMLOLBddAFzLSLzxdzSfkUF8GW7VNPCJSgtXnB
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Some code that runs early in boot calls RTAS functions that can return
-2 or 990x statuses, which mean the caller should retry. An example is
pSeries_cmo_feature_init(), which invokes ibm,get-system-parameter but
treats these benign statuses as errors instead of retrying.

pSeries_cmo_feature_init() and similar code should be made to retry
until they succeed or receive a real error, using the usual pattern:

	do {
		rc = rtas_call(token, etc...);
	} while (rtas_busy_delay(rc));

But rtas_busy_delay() will perform a timed sleep on any 990x
status. This isn't safe so early in boot, before the CPU scheduler and
timer subsystem have initialized.

The -2 RTAS status is much more likely to occur during single-threaded
boot than 990x in practice, at least on PowerVM. This is because -2
usually means that RTAS made progress but exhausted its self-imposed
timeslice, while 990x is associated with concurrent requests from the
OS causing internal contention. Regardless, according to the language
in PAPR, the OS should be prepared to handle either type of status at
any time.

Add a fallback path to rtas_busy_delay() to handle this as safely as
possible, performing a small delay on 990x. Include a counter to
detect retry loops that aren't making progress and bail out.

This was found by inspection and I'm not aware of any real
failures. However, the implementation of rtas_busy_delay() before
commit 38f7b7067dae ("powerpc/rtas: rtas_busy_delay() improvements")
was not susceptible to this problem, so let's treat this as a
regression.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: 38f7b7067dae ("powerpc/rtas: rtas_busy_delay() improvements")
---
 arch/powerpc/kernel/rtas.c | 48 +++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 47 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 795225d7f138..ec2df09a70cf 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -606,6 +606,46 @@ unsigned int rtas_busy_delay_time(int status)
 	return ms;
 }
 
+/*
+ * Early boot fallback for rtas_busy_delay().
+ */
+static bool __init rtas_busy_delay_early(int status)
+{
+	static size_t successive_ext_delays __initdata;
+	bool ret;
+
+	switch (status) {
+	case RTAS_EXTENDED_DELAY_MIN...RTAS_EXTENDED_DELAY_MAX:
+		/*
+		 * In the unlikely case that we receive an extended
+		 * delay status in early boot, the OS is probably not
+		 * the cause, and there's nothing we can do to clear
+		 * the condition. Best we can do is delay for a bit
+		 * and hope it's transient. Lie to the caller if it
+		 * seems like we're stuck in a retry loop.
+		 */
+		mdelay(1);
+		ret = true;
+		successive_ext_delays += 1;
+		if (successive_ext_delays > 1000) {
+			pr_err("too many extended delays, giving up\n");
+			dump_stack();
+			ret = false;
+		}
+		break;
+	case RTAS_BUSY:
+		ret = true;
+		successive_ext_delays = 0;
+		break;
+	default:
+		ret = false;
+		successive_ext_delays = 0;
+		break;
+	}
+
+	return ret;
+}
+
 /**
  * rtas_busy_delay() - helper for RTAS busy and extended delay statuses
  *
@@ -624,11 +664,17 @@ unsigned int rtas_busy_delay_time(int status)
  * * false - @status is not @RTAS_BUSY nor an extended delay hint. The
  *           caller is responsible for handling @status.
  */
-bool rtas_busy_delay(int status)
+bool __ref rtas_busy_delay(int status)
 {
 	unsigned int ms;
 	bool ret;
 
+	/*
+	 * Can't do timed sleeps before timekeeping is up.
+	 */
+	if (system_state < SYSTEM_SCHEDULING)
+		return rtas_busy_delay_early(status);
+
 	switch (status) {
 	case RTAS_EXTENDED_DELAY_MIN...RTAS_EXTENDED_DELAY_MAX:
 		ret = true;

-- 
2.39.1

