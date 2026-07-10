From: Eugene Mavick <m@mavick.dev>
Date: Fri, 10 Jul 2026 13:30:40 +0800
Subject: [PATCH v2 2/5] refcount: add ref_trace_final_put tracepoint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-refcount-final-put-trace-v2-2-557cfce860a2@mavick.dev>
References: <20260710-refcount-final-put-trace-v2-0-557cfce860a2@mavick.dev>
In-Reply-To: <20260710-refcount-final-put-trace-v2-0-557cfce860a2@mavick.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1880; i=m@mavick.dev;
 h=from:subject:message-id; bh=LlgAKLvSTzT+rMKMAXMt37/mjMTpw1NXPXF0CRuqRZw=;
 b=owGbwMvMwCU2V/5U3e1aE3/G02pJDFkBzT33jpy6k7R1+kNdW73wjXUfb26Iv7hoxdSVcvOmh
 rm/cvrs2VHKwiDGxSArpshSk5XgnrFyVqLx0Uk9MHNYmUCGMHBxCsBEnKMYGVab93IpL7he/jLA
 ddYj7ctyQnPDJzFeuLVL5dQpt+0l9UUM/4NabsonXO9+eaX0QMPN2z0a//MWS3reFtgW57Lj7cd
 mBTYA
X-Developer-Key: i=m@mavick.dev; a=openpgp;
 fpr=7C6A604768A99A6133C5928C9D1FCA7EDB7D344F
X-Endpoint-Received: by B4 Relay for m@mavick.dev/default with auth_id=850
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ref_trace_final_put tracepoint to __refcount_sub_and_test() and
refcount_dec_if_one()

This tracepoint fires when a refcount_t reaches zero, capturing the caller
address, the function name, and the refcount_t address.

Signed-off-by: Eugene Mavick <m@mavick.dev>
---
v2:
-update commit message
-add tracepoint to refcount_dec_if_one(), suggested by Usuma Arif
-move MAINTAINERS file entries to new MAINTAINERS commit
-v1:https://lore.kernel.org/all/20260705-refcount-final-put-trace-v1-2-cdd0014626a9@mavick.dev/
---
 include/linux/refcount.h | 2 ++
 lib/refcount.c           | 8 +++++++-
 2 files changed, 9 insertions(+), 1 deletion(-)

diff --git a/include/linux/refcount.h b/include/linux/refcount.h
index ba7657ced281..70d07a462da1 100644
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
+		do_trace_ref_final_put(r);
 		return true;
 	}
 
diff --git a/lib/refcount.c b/lib/refcount.c
index a207a8f22b3c..cd7e32df3919 100644
--- a/lib/refcount.c
+++ b/lib/refcount.c
@@ -7,6 +7,7 @@
 #include <linux/refcount.h>
 #include <linux/spinlock.h>
 #include <linux/bug.h>
+#include <linux/ref_trace.h>
 
 #define REFCOUNT_WARN(str)	WARN_ONCE(1, "refcount_t: " str ".\n")
 
@@ -56,7 +57,12 @@ bool refcount_dec_if_one(refcount_t *r)
 {
 	int val = 1;
 
-	return atomic_try_cmpxchg_release(&r->refs, &val, 0);
+	bool ret = atomic_try_cmpxchg_release(&r->refs, &val, 0);
+
+	if (ret)
+		do_trace_ref_final_put(r);
+
+	return ret;
 }
 EXPORT_SYMBOL(refcount_dec_if_one);
 

-- 
2.51.2

