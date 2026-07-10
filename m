From: Eugene Mavick <m@mavick.dev>
Subject: [PATCH v2 0/5] tracing: add ref_trace_final_put tracing
Date: Fri, 10 Jul 2026 13:30:38 +0800
Message-Id: <20260710-refcount-final-put-trace-v2-0-557cfce860a2@mavick.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH6DUGoC/53NPQ7CMAwF4KugzAQ5aZpQJu6BGNzYhQhoq7REI
 NS7E34GJpBYLD3L/t5NDBwDD2I1u4nIKQyha3PQ85nwe2x3LAPlLDRoC1YbGbnx3bkdZRNaPMr
 +PMoxomdpqpqcL/IsUeT3Pl+Gy5PebHPeh2Hs4vXZlNRj+0IdfEGTkiBrs3TGEqpGu/UJU/CHB
 XF6lLyF8ofgiQCUsdpi9Z+ARlHREPDS/ikAclVYptqV8Clsp2m6A/C+Nx2HAQAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2130; i=m@mavick.dev;
 h=from:subject:message-id; bh=F+56U6C6KuvEh/81ka3tRtqh4dyvZl3JiYsBpnaflyE=;
 b=owGbwMvMwCU2V/5U3e1aE3/G02pJDFkBzT2nTffvL220YFjqU5G9671GPtP7pTwnHPj665sea
 V+MthXqKGVhEONikBVTZKnJSnDPWDkr0fjopB6YOaxMIEMYuDgFYCKc+xn+qQh1Rf5p+KvZv67d
 RjgjT/Hwv0U3T1fafTyl9LhojQvrNkaGB9U7Lx3R8z05//qev8/ZJ76TZp7dJnnJ4vNylqXXXls
 HcwAA
X-Developer-Key: i=m@mavick.dev; a=openpgp;
 fpr=7C6A604768A99A6133C5928C9D1FCA7EDB7D344F
X-Endpoint-Received: by B4 Relay for m@mavick.dev/default with auth_id=850
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When debugging use-after-free(UAF) bugs, knowing when the object reaches
0 references and enters final release can significantly aid the
debugging process.

There is currently no universal way to trace this information.

This patch series implements tracing of the final puts in the
most widely used refcounting implementations,
refcount_t(and thus kref which uses it), and percpu-ref.

The tracepoint records three fields:
- caller: function that called the refcounting
  function(refcount_sub_and_test, percpu_ref_put_many)
- fn: refcounting function(eg refcount_sub_and_test)
- obj: refcount object(struct percpu_ref, refcount_t) 

Signed-off-by: Eugene Mavick <m@mavick.dev>
---
Changes in v2:
-include/linux/ref_trace.h: change macro name, use direct tracepoint
 call in macro to avoid double check
-add tracepoint to refcount_dec_if_one
-kunit: make significant improvements to design, fix critical bug, add test case for
 refcount_dec_if_one()
-Link to v1: https://lore.kernel.org/r/20260705-refcount-final-put-trace-v1-0-0ae936edb750@mavick.dev

---
Eugene Mavick (5):
      tracing: add ref_trace_final_put tracepoint
      refcount: add ref_trace_final_put tracepoint
      percpu-refcount: add ref_trace_final_put trace
      kunit: add test for ref_trace_final_put
      MAINTAINERS: add entries for ref_trace_final_put

 MAINTAINERS                      |   3 +
 include/linux/percpu-refcount.h  |   5 +-
 include/linux/ref_trace.h        |  26 ++++++++
 include/linux/refcount.h         |   2 +
 include/trace/events/ref_trace.h |  46 +++++++++++++
 lib/Kconfig                      |  10 +++
 lib/Makefile                     |   2 +
 lib/ref_trace.c                  |  12 ++++
 lib/refcount.c                   |   8 ++-
 lib/tests/Makefile               |   1 +
 lib/tests/ref_trace_kunit.c      | 136 +++++++++++++++++++++++++++++++++++++++
 11 files changed, 249 insertions(+), 2 deletions(-)
---
base-commit: df685633c3dbc67441cc86f1c3fee58de4652ba2
change-id: 20260624-refcount-final-put-trace-49bd7c39bd5a

Best regards,
-- 
Eugene Mavick <m@mavick.dev>

