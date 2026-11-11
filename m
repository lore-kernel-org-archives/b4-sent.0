From: Mike Bazov <mikeba@sentinelone.com>
Date: Wed, 11 Nov 2026 21:39:49 +0200
Subject: [PATCH bpf-next v2 3/5] bpf: Check recursion per task for programs
 on syscall tracepoints
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-bpf-preempt-v2-r2-v2-3-9d8f6b952ad2@sentinelone.com>
References: <20261111-bpf-preempt-v2-r2-v2-0-9d8f6b952ad2@sentinelone.com>
In-Reply-To: <20261111-bpf-preempt-v2-r2-v2-0-9d8f6b952ad2@sentinelone.com>
To: bpf@vger.kernel.org, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>
Cc: Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 JP Kobryn <jp.kobryn@linux.dev>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mike Bazov <mikeba@sentinelone.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794425986; l=1799;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=+dOmL4KrsoZoGHMSIZ+zYy2Dw+1c2bQCDaNaqZIz4eA=;
 b=ngIG6k9K+uC7fNwJvhNNFFAP1Zl9aFx8bASTNwTXbce+1J8lGwXGxG46cfCbaib1vgWx79Exj
 xE72nTL1eCtAN9dQwGBYhjy6qK9EFAWpDItR5KxcGI13NbnwahyXCNE
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 57918341dd19 ("bpf: Add sleepable support for classic
tracepoint programs"), classic tracepoint programs on syscall
tracepoints run before perf disables preemption, through
trace_call_bpf_faultable() and bpf_prog_run_array_sleepable(). That
runner still checks recursion with the per-CPU counter, so a task
preempted inside such a program blocks every other task on the same
CPU, and their runs are dropped as recursion misses. A sleepable
program that faults keeps the counter raised for the whole sleep.

Use the per-task check from the previous patch. The runner publishes one
frame for the whole program array, so the program is recorded in it per
item and cleared before the next one.

Fixes: 57918341dd19 ("bpf: Add sleepable support for classic tracepoint programs")
Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 include/linux/bpf.h | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/include/linux/bpf.h b/include/linux/bpf.h
index 52e29b374b4a..649ff2950fd6 100644
--- a/include/linux/bpf.h
+++ b/include/linux/bpf.h
@@ -3549,9 +3549,9 @@ bpf_prog_run_array_sleepable(const struct bpf_prog_array *array,
 			continue;
 		}
 
-		if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+		if (unlikely(!bpf_prog_enter_recur_ctx(prog, &run_ctx.run_ctx))) {
 			bpf_prog_inc_misses_counter(prog);
-			bpf_prog_put_recursion_context(prog);
+			bpf_prog_exit_recur_ctx(prog, &run_ctx.run_ctx);
 			item++;
 			continue;
 		}
@@ -3565,7 +3565,7 @@ bpf_prog_run_array_sleepable(const struct bpf_prog_array *array,
 			ret &= run_prog(prog, ctx);
 		}
 
-		bpf_prog_put_recursion_context(prog);
+		bpf_prog_exit_recur_ctx(prog, &run_ctx.run_ctx);
 		item++;
 	}
 	bpf_reset_run_ctx(old_run_ctx);

-- 
2.43.0

