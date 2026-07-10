From: Eugene Mavick <m@mavick.dev>
Date: Fri, 10 Jul 2026 13:30:43 +0800
Subject: [PATCH v2 5/5] MAINTAINERS: add entries for ref_trace_final_put
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-refcount-final-put-trace-v2-5-557cfce860a2@mavick.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=665; i=m@mavick.dev;
 h=from:subject:message-id; bh=qY0jw9qG8rTERqF+Mm/JywN3bXE+e644UzadbgoAM88=;
 b=owGbwMvMwCU2V/5U3e1aE3/G02pJDFkBzT1/DcKkKm17S69+OZR4JdNRoG2tTpF8UDNXWP7Mx
 Uyp9nkdpSwMYlwMsmKKLDVZCe4ZK2clGh+d1AMzh5UJZAgDF6cATCR6NcM/I6ODKmyXLLZ/eT5J
 9dAyI6OMB79Djq3a8L/smAyrtc/jXkaGdfeUHiw5E3Xwy0SZeqWnt9eVFZw1Wb+ssaP0hajyx/y
 1XAA=
X-Developer-Key: i=m@mavick.dev; a=openpgp;
 fpr=7C6A604768A99A6133C5928C9D1FCA7EDB7D344F
X-Endpoint-Received: by B4 Relay for m@mavick.dev/default with auth_id=850
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new files added in the patch series to MAINTAINERS

Signed-off-by: Eugene Mavick <m@mavick.dev>
---
v2:
This patch was added in v2
---
 MAINTAINERS | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 10e8253181d3..2dbb7441906e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -4210,7 +4210,10 @@ S:	Maintained
 F:	Documentation/atomic_*.txt
 F:	arch/*/include/asm/atomic*.h
 F:	include/*/atomic*.h
+F:	include/linux/ref_trace.h
 F:	include/linux/refcount.h
+F:	lib/ref_trace.c
+F:	lib/tests/ref_trace_kunit.c
 F:	scripts/atomic/
 F:	rust/kernel/sync/atomic.rs
 F:	rust/kernel/sync/atomic/

-- 
2.51.2

