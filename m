From: Eugene Mavick <m@mavick.dev>
Subject: [PATCH 0/4] tracing: add ref_trace_final_put tracing
Date: Sun, 05 Jul 2026 09:20:50 +0800
Message-Id: <20260705-refcount-final-put-trace-v1-0-0ae936edb750@mavick.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHKxSWoC/53NTQ7CIBAF4Ks0rMUApdC68h6mC8qPJSptgBJN0
 7tLqxs3mriZ5E1mvjeDoL3VARyKGXidbLCDywHvCiB74c4aWpUzIIgwxAiFXhs5TC5CY524wnG
 KMHohNaRNp7gs86wEyO9jvrT3jT61Ofc2xME/tqaE1+0L5egLmjBEsKM1p0wJbAg/3kSy8rJXO
 q0lb6H6IUilEMKUESaa/wRBsSqNQrpmH0K7LMsT7EtDCEUBAAA=
X-Change-ID: 20260624-refcount-final-put-trace-49bd7c39bd5a
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1625; i=m@mavick.dev;
 h=from:subject:message-id; bh=VAHi+PBb8b+++SWfPayXCtK/lkvsgLLw/50K5jGemuU=;
 b=owGbwMvMwCU2V/5U3e1aE3/G02pJDFmeGyslgz5sbDXY/cjNem4Q8wlzhtnsPpu3/pN6mzPJ9
 kbg9qpnHaUsDGJcDLJiiiw1WQnuGStnJRofndQDM4eVCWQIAxenAEzE1Jnhn84GqSPPEpdu+mpT
 JLou4bdi7f9Dedbc/6Z+zhCceWVKfTDD/8AVk68+Uta2fjT/vh3L0aXHcrvqXyRrJDKfZ5Bv8a0
 QYgYA
X-Developer-Key: i=m@mavick.dev; a=openpgp;
 fpr=7C6A604768A99A6133C5928C9D1FCA7EDB7D344F
X-Endpoint-Received: by B4 Relay for m@mavick.dev/default with auth_id=850
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When debugging use-after-free(UAF) bugs, knowing when the object reaches
0 references and enters final release can significantly aide the
debugging process.

There is currently no universal way to trace this information.

This patches traces the final puts in the most widely used refcounting
implementations, refcount_t(and thus kref which uses it), and
percpu-ref.

The tracepoint records three fields:
- caller: function that called the refcounting
  function(refcount_sub_and_test, percpu_ref_put_many)
- fn: refcounting function(eg refcount_sub_and_test)
- obj: refcount object(struct percpu_ref, refcount_t) 

Signed-off-by: Eugene Mavick <m@mavick.dev>
---
Eugene Mavick (4):
      tracing: add ref_trace_final_put tracepoint
      refcount: add ref_trace_final_put tracepoint
      percpu-refcount: add ref_trace_final_put trace
      kunit: add test for ref_trace_final_put

 MAINTAINERS                      |   3 +
 include/linux/percpu-refcount.h  |   5 +-
 include/linux/ref_trace.h        |  26 ++++++++
 include/linux/refcount.h         |   2 +
 include/trace/events/ref_trace.h |  46 +++++++++++++
 lib/Kconfig                      |  10 +++
 lib/Makefile                     |   2 +
 lib/ref_trace.c                  |  12 ++++
 lib/tests/Makefile               |   1 +
 lib/tests/ref_trace_kunit.c      | 138 +++++++++++++++++++++++++++++++++++++++
 10 files changed, 244 insertions(+), 1 deletion(-)
---
base-commit: df685633c3dbc67441cc86f1c3fee58de4652ba2
change-id: 20260624-refcount-final-put-trace-49bd7c39bd5a

Best regards,
-- 
Eugene Mavick <m@mavick.dev>

