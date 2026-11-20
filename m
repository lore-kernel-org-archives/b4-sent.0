From: Mike Bazov <mike.bazov@gmail.com>
Date: Fri, 20 Nov 2026 12:59:11 +0200
Subject: [PATCH bpf-next v3 1/3] bpf: Don't WARN when
 bpf_perf_event_output() nests too deep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-bpf-raw-tp-regs-preempt-v3-1-ec109009a5d2@gmail.com>
References: <20261120-bpf-raw-tp-regs-preempt-v3-0-ec109009a5d2@gmail.com>
In-Reply-To: <20261120-bpf-raw-tp-regs-preempt-v3-0-ec109009a5d2@gmail.com>
To: Song Liu <song@kernel.org>, Jiri Olsa <jolsa@kernel.org>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Andrii Nakryiko <andrii@kernel.org>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 Emil Tsalapatis <emil@etsalapatis.com>, KP Singh <kpsingh@kernel.org>, 
 Matt Bobrowski <matt@bobrowski.net>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, Mike Bazov <mike.bazov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795172363; l=1271;
 i=mike.bazov@gmail.com; s=gmail-20261116; h=from:subject:message-id;
 bh=OpB06pONNtl7It9Z2DjXFTZ1zpUQ2HlWqwhm6FIcX8I=;
 b=s9wlWDij4BjhO5fW4WXa1A/ivy4hTpJ6a65d6bJNrGAR/Q69mdw7oBUzAmIcIm5747HDAYOE9
 X3RyHFm/97oAzMnDMyEzE3TdCbafBYCFz2PhWnfpq9/Otqpjg8fGT8c
X-Developer-Key: i=mike.bazov@gmail.com; a=ed25519;
 pk=Rr9fagn0pNA+bs8tgc6DXZpRAhl/maU6BeqkttIR7DA=
X-Endpoint-Received: by B4 Relay for mike.bazov@gmail.com/gmail-20261116 with auth_id=1544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bpf_perf_event_output() takes one of three per-CPU perf_sample_data
slots per nesting level, and fails with -EBUSY and a WARN_ON_ONCE() when
it is entered a fourth time on a CPU. Programs get there without any
bug: a kprobe program calls it, and fentry programs on
perf_event_output() call it again from inside. Each program's own
recursion check lets it in once, so three of them reach the fourth
level. With panic_on_warn, that takes the machine down.

Keep the -EBUSY and drop the warning, as commit 3880cdbed1c4 ("bpf: Fix
WARN() in get_bpf_raw_tp_regs") did for the raw tracepoint regs slots.

Signed-off-by: Mike Bazov <mike.bazov@gmail.com>
---
 kernel/trace/bpf_trace.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index b4ff9d4e8..8910d5d05 100644
--- a/kernel/trace/bpf_trace.c
+++ b/kernel/trace/bpf_trace.c
@@ -702,7 +702,7 @@ BPF_CALL_5(bpf_perf_event_output, struct pt_regs *, regs, struct bpf_map *, map,
 	sds = this_cpu_ptr(&bpf_trace_sds);
 	nest_level = this_cpu_inc_return(bpf_trace_nest_level);
 
-	if (WARN_ON_ONCE(nest_level > ARRAY_SIZE(sds->sds))) {
+	if (nest_level > ARRAY_SIZE(sds->sds)) {
 		err = -EBUSY;
 		goto out;
 	}

-- 
2.43.0

