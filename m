From: Mark Korenberg <socketpair@gmail.com>
Date: Thu, 29 Oct 2026 17:43:18 +0500
Subject: [PATCH bpf-next v2 1/2] bpftool: Fix disposal of the LLVM
 disassembler context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-bpftool-plugin-v2-1-1a47b2391b0b@gmail.com>
References: <20261029-bpftool-plugin-v2-0-1a47b2391b0b@gmail.com>
In-Reply-To: <20261029-bpftool-plugin-v2-0-1a47b2391b0b@gmail.com>
To: Quentin Monnet <qmo@kernel.org>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Bill Wendling <morbo@google.com>, 
 Justin Stitt <justinstitt@google.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Nick Desaulniers <ndesaulniers@google.com>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, llvm@lists.linux.dev, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793277817; l=924;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=X2MjSY5tQq8kOSRYHXZwlXNvTlqDdyCp9JF2r6O/Qbg=;
 b=XSUs+HmZc7S3AnWxy6PF2YQn5Gmv8CW+4abMPsLsQaliMnixfJmpBuszp+CAc5xHnLaVZY2UH
 DTPbFI/uuWxBp1q2gvXJZXFDMqLAMFjgjyo+3NOr3oYZVQ09S2cXPvf
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

destroy_context() frees the disassembler context with LLVMDisposeMessage(),
which is a plain free() meant for strings returned by LLVM. The context is
therefore never destroyed, leaking about 28 KiB per disassembled function.
Use LLVMDisasmDispose() instead.

Fixes: eb9d1acf634b ("bpftool: Add LLVM as default library for disassembling JIT-ed programs")
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 tools/bpf/bpftool/jit_disasm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/bpf/bpftool/jit_disasm.c b/tools/bpf/bpftool/jit_disasm.c
index 04541155e9cc..5ff144ce84a1 100644
--- a/tools/bpf/bpftool/jit_disasm.c
+++ b/tools/bpf/bpftool/jit_disasm.c
@@ -115,7 +115,7 @@ init_context(disasm_ctx_t *ctx, const char *arch,
 
 static void destroy_context(disasm_ctx_t *ctx)
 {
-	LLVMDisposeMessage(*ctx);
+	LLVMDisasmDispose(*ctx);
 }
 
 static int

-- 
2.56.0

