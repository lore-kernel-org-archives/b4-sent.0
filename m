From: Mark Korenberg <socketpair@gmail.com>
Date: Tue, 03 Nov 2026 18:59:53 +0500
Subject: [PATCH bpf-next v5 1/3] bpftool: Fix disposal of the LLVM
 disassembler context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-bpftool-plugin-v5-1-683e08a25df0@gmail.com>
References: <20261103-bpftool-plugin-v5-0-683e08a25df0@gmail.com>
In-Reply-To: <20261103-bpftool-plugin-v5-0-683e08a25df0@gmail.com>
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
 Nick Desaulniers <ndesaulniers@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Stanislav Fomichev <sdf@fomichev.me>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, llvm@lists.linux.dev, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793714393; l=926;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=WFtOq3wdcmZOoH/EhJgh2UIYAu0AaQ6cH9OmA9+kaSo=;
 b=hTCTXZ6eoCML/m1GjNTUVVsHdppz6wlw86fD8uroJrgV44vs3OkUJ9FzaEK2Wmxgp0gqzW6wt
 QJ2H5pwW5ohAsMV1chrBl2iL2VDJeATAWWtAV4uNP1rJgS0JHr911Ng
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
index 04541155e9ccc..5ff144ce84a1c 100644
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

