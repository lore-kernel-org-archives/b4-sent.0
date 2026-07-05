From: Eugene Mavick <m@mavick.dev>
Date: Sun, 05 Jul 2026 09:20:51 +0800
Subject: [PATCH 1/4] tracing: add ref_trace_final_put tracepoint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-refcount-final-put-trace-v1-1-0ae936edb750@mavick.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4836; i=m@mavick.dev;
 h=from:subject:message-id; bh=qHwnbzvpK9wYBzbeGmnuCtzzLwF8aY1zM3ldVu/OfqE=;
 b=owGbwMvMwCU2V/5U3e1aE3/G02pJDFmeGytvvJdkW+ErErKj6k0+85WG9YriqcYSvQejHn9Ms
 jVO00zvKGVhEONikBVTZKnJSnDPWDkr0fjopB6YOaxMIEMYuDgFYCLM0YwMHyQd7QX+uVTEReyb
 seZ+3NcZe/WkUlxNzyyccvdIR77dW0aGqWHH00Pf+12tT5go+jD06wmDUtXodzaq3R1N/ald01S
 4AA==
X-Developer-Key: i=m@mavick.dev; a=openpgp;
 fpr=7C6A604768A99A6133C5928C9D1FCA7EDB7D344F
X-Endpoint-Received: by B4 Relay for m@mavick.dev/default with auth_id=850
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ref_trace_final_put tracepoint and related core infrastructure

ref_trace_final_put fires when a reference
count reaches zero and the object enters its final release path.

The tracepoint records three fields:
- caller: function that called the refcounting
  function(refcount_sub_and_test, percpu_ref_put_many)
- fn: refcounting function(eg refcount_sub_and_test)
- obj: refcount object(struct percpu_ref, refcount_t)

Signed-off-by: Eugene Mavick <m@mavick.dev>
---
 MAINTAINERS                      |  2 ++
 include/linux/ref_trace.h        | 26 +++++++++++++++++++++++
 include/trace/events/ref_trace.h | 46 ++++++++++++++++++++++++++++++++++++++++
 lib/Makefile                     |  2 ++
 lib/ref_trace.c                  | 12 +++++++++++
 5 files changed, 88 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 10e8253181d3..8dab37726b9d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -4210,7 +4210,9 @@ S:	Maintained
 F:	Documentation/atomic_*.txt
 F:	arch/*/include/asm/atomic*.h
 F:	include/*/atomic*.h
+F:	include/linux/ref_trace.h
 F:	include/linux/refcount.h
+F:	lib/ref_trace.h
 F:	scripts/atomic/
 F:	rust/kernel/sync/atomic.rs
 F:	rust/kernel/sync/atomic/
diff --git a/include/linux/ref_trace.h b/include/linux/ref_trace.h
new file mode 100644
index 000000000000..54e9fba9e3e9
--- /dev/null
+++ b/include/linux/ref_trace.h
@@ -0,0 +1,26 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef _LINUX_REF_TRACE_H
+#define _LINUX_REF_TRACE_H
+
+#include <linux/tracepoint-defs.h>
+#include <linux/instruction_pointer.h>
+
+/* Declare the tracepoint so tracepoint_enabled() can be used */
+DECLARE_TRACEPOINT(ref_trace_final_put);
+
+#ifdef CONFIG_TRACEPOINTS
+/* Wrapper function implemented in lib/ref_trace.c */
+extern void do_ref_trace_final_put(unsigned long caller, const char *fn, const void *obj);
+
+#define trace_ref_final_put(obj)						\
+	do {									\
+		if (tracepoint_enabled(ref_trace_final_put))			\
+			do_ref_trace_final_put(_RET_IP_, __func__, obj);	\
+	} while (0)
+
+#else /* !CONFIG_TRACEPOINTS */
+static inline void do_ref_trace_final_put(unsigned long caller, const char *fn, const void *obj) { }
+#define trace_ref_final_put(obj) do { } while (0)
+#endif
+
+#endif /* _LINUX_REF_TRACE_H */
diff --git a/include/trace/events/ref_trace.h b/include/trace/events/ref_trace.h
new file mode 100644
index 000000000000..e6037a325be2
--- /dev/null
+++ b/include/trace/events/ref_trace.h
@@ -0,0 +1,46 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#undef TRACE_SYSTEM
+#define TRACE_SYSTEM ref_trace
+
+#if !defined(_TRACE_REF_TRACE_H) || defined(TRACE_HEADER_MULTI_READ)
+#define _TRACE_REF_TRACE_H
+
+#include <linux/tracepoint.h>
+
+/**
+ * ref_trace_final_put - trace when a reference count reaches zero
+ * @caller: function that called the refcounting
+ * function(refcount_sub_and_test, percpu_ref_put_many)
+ * @fn: refcounting function(eg refcount_sub_and_test)
+ * @obj: refcount object(struct percpu_ref, refcount_t)
+ *
+ * Tracepoint instrumentation can be added using the ref_trace_final_put
+ * macro defined in include/linux/ref_trace.h
+ * which uses _RET_IP_ and __func__ for caller and fn arguments respectively,
+ * thus only requiring obj arg to be supplied
+ */
+TRACE_EVENT(ref_trace_final_put,
+
+	TP_PROTO(unsigned long caller, const char *fn, const void *obj),
+
+	TP_ARGS(caller, fn, obj),
+
+	TP_STRUCT__entry(
+	__field(unsigned long, caller)
+	__string(fn, fn)
+	__field(const void *, obj)
+	),
+
+	TP_fast_assign(
+	__entry->caller = caller;
+	__assign_str(fn);
+	__entry->obj = obj;
+	),
+
+	TP_printk("caller=%pS fn=%s obj=%p", (void *)__entry->caller, __get_str(fn), __entry->obj)
+);
+
+#endif /* _TRACE_REF_TRACE_H */
+
+/* This part must be outside protection */
+#include <trace/define_trace.h>
diff --git a/lib/Makefile b/lib/Makefile
index f33a24bf1c19..41737090a95d 100644
--- a/lib/Makefile
+++ b/lib/Makefile
@@ -335,3 +335,5 @@ CONTEXT_ANALYSIS_test_context-analysis.o := y
 obj-$(CONFIG_CONTEXT_ANALYSIS_TEST) += test_context-analysis.o
 
 subdir-$(CONFIG_FORTIFY_SOURCE) += test_fortify
+
+obj-$(CONFIG_TRACEPOINTS) += ref_trace.o
diff --git a/lib/ref_trace.c b/lib/ref_trace.c
new file mode 100644
index 000000000000..25f7c17c7c47
--- /dev/null
+++ b/lib/ref_trace.c
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0
+#define CREATE_TRACE_POINTS
+#include <trace/events/ref_trace.h>
+
+//Wrapper function for functions defined entirely in header files
+void do_ref_trace_final_put(unsigned long caller, const char *fn, const void *obj)
+{
+	trace_ref_trace_final_put(caller, fn, obj);
+}
+EXPORT_SYMBOL_GPL(do_ref_trace_final_put);
+
+EXPORT_TRACEPOINT_SYMBOL_GPL(ref_trace_final_put);

-- 
2.51.2

