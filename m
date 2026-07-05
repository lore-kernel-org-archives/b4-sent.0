From: Eugene Mavick <m@mavick.dev>
Date: Sun, 05 Jul 2026 09:20:52 +0800
Subject: [PATCH 2/4] refcount: add ref_trace_final_put tracepoint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-refcount-final-put-trace-v1-2-0ae936edb750@mavick.dev>
References: <20260705-refcount-final-put-trace-v1-0-0ae936edb750@mavick.dev>
In-Reply-To: <20260705-refcount-final-put-trace-v1-0-0ae936edb750@mavick.dev>
To: Will Deacon <will@kernel.org>, Peter Zijlstra <peterz@infradead.org>, 
 Boqun Feng <boqun@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Gary Guo <gary@garyguo.net>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Dennis Zhou <dennis@kernel.org>, 
 Tejun Heo <tj@kernel.org>, Christoph Lameter <cl@gentwo.org>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Eugene Mavick <m@mavick.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=878; i=m@mavick.dev;
 h=from:subject:message-id; bh=oxdQX1dkebrHkQOKFGbMe1L7jn1KmiWYDIa5MeosIJI=;
 b=owGbwMvMwCU2V/5U3e1aE3/G02pJDFmeGyv/807KiA0NbPXYPkn7mHjaVUmpXYse5O2/nPh50
 8XpL0UudJSyMIhxMciKKbLUZCW4Z6yclWh8dFIPzBxWJpAhDFycAjCRI7WMDA/MrTK8W0pXGvLM
 14mQLjER/Vx4pUtRfGNCYHGoZ7NZMyPDgq+JyszX12/Ufi2bXiGsJ/xxrXn5lo5M4zYNvpwAwxk
 MAA==
X-Developer-Key: i=m@mavick.dev; a=openpgp;
 fpr=7C6A604768A99A6133C5928C9D1FCA7EDB7D344F
X-Endpoint-Received: by B4 Relay for m@mavick.dev/default with auth_id=850
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ref_trace_final_put tracepoint to __refcount_sub_and_test().
This fires when a refcount_t reaches zero, capturing the caller
address, the function name, and the refcount_t address.

Signed-off-by: Eugene Mavick <m@mavick.dev>
---
 include/linux/refcount.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/include/linux/refcount.h b/include/linux/refcount.h
index ba7657ced281..7b1fbf326a21 100644
--- a/include/linux/refcount.h
+++ b/include/linux/refcount.h
@@ -107,6 +107,7 @@
 #include <linux/limits.h>
 #include <linux/refcount_types.h>
 #include <linux/spinlock_types.h>
+#include <linux/ref_trace.h>
 
 struct mutex;
 
@@ -393,6 +394,7 @@ bool __refcount_sub_and_test(int i, refcount_t *r, int *oldp)
 
 	if (old > 0 && old == i) {
 		smp_acquire__after_ctrl_dep();
+		trace_ref_final_put(r);
 		return true;
 	}
 

-- 
2.51.2

