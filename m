From: Mark Korenberg <socketpair@gmail.com>
Date: Tue, 03 Nov 2026 18:59:54 +0500
Subject: [PATCH bpf-next v5 2/3] bpftool: Don't require a disassembler to
 dump a JITed program to a file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-bpftool-plugin-v5-2-683e08a25df0@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793714393; l=1265;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=YA3fRuAfEUIVwaShslcQVsu+SC7z7OAIjbkZp9Lhxg0=;
 b=Z1J5xoIL49fKB2/6kCpqsAROwLn77sNLXyfAPF2ORHGm7kAnGSTxyan1auk6kRSUjMkiR2WI5
 KCduzWdu52ZDu0nmPhTrlj+6w6t3kpQTrqmmq4euw27vHcl+W9dqkxB
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

"bpftool prog dump jited PROG file FILE" only writes the JITed image to
FILE, but do_dump() calls disasm_init() before it parses the arguments,
so the command fails when bpftool has no disassembler.

Call disasm_init() only when the image is disassembled.

Fixes: 29a9c10e4110 ("bpftool: make libbfd optional")
Suggested-by: Alexei Starovoitov <ast@kernel.org>
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 tools/bpf/bpftool/prog.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/tools/bpf/bpftool/prog.c b/tools/bpf/bpftool/prog.c
index 43599c79c93ac..15efc6eebffb1 100644
--- a/tools/bpf/bpftool/prog.c
+++ b/tools/bpf/bpftool/prog.c
@@ -894,8 +894,6 @@ static int do_dump(int argc, char **argv)
 	int err = -1;
 
 	if (is_prefix(*argv, "jited")) {
-		if (disasm_init())
-			return -1;
 		mode = DUMP_JITED;
 	} else if (is_prefix(*argv, "xlated")) {
 		mode = DUMP_XLATED;
@@ -959,6 +957,8 @@ static int do_dump(int argc, char **argv)
 		p_err("'visual' is not compatible with JSON output");
 		goto exit_close;
 	}
+	if (mode == DUMP_JITED && !filepath && disasm_init())
+		goto exit_close;
 
 	if (json_output && nb_fds > 1)
 		jsonw_start_array(json_wtr);	/* root array */

-- 
2.56.0

