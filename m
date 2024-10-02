From: Eric Long <i@hack3r.moe>
Date: Wed, 02 Oct 2024 14:25:07 +0800
Subject: [PATCH bpf-next v4 2/2] selftests/bpf: test linking with duplicate
 extern functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241002-libbpf-dup-extern-funcs-v4-2-560eb460ff90@hack3r.moe>
References: <20241002-libbpf-dup-extern-funcs-v4-0-560eb460ff90@hack3r.moe>
In-Reply-To: <20241002-libbpf-dup-extern-funcs-v4-0-560eb460ff90@hack3r.moe>
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2354; i=i@hack3r.moe;
 h=from:subject:message-id; bh=eZzHlRs/qzyTmhLjl1HP9TOQSbvTRsCUeiiuNq2bdvg=;
 b=kA0DAAoWWD+rQAXGUr4ByyZiAGb850TI71YPK2BMRwLyO0afbgs8EE5nBLBdrC2+CLLgYBfZo
 Ih1BAAWCgAdFiEEtMP8JmAvi7KkC5x3WD+rQAXGUr4FAmb850QACgkQWD+rQAXGUr5JigD9FHEU
 HTOhPt1Ytjv+bQsvzADTfJoBgAADvkzRu5RP7eEBAJtugW6Mg1bqPPjiQetdDE+0pfaigQlQVIe
 +jPILQ1IO
X-Developer-Key: i=i@hack3r.moe; a=openpgp;
 fpr=3A7A1F5A7257780C45A9A147E1487564916D3DF5
X-Endpoint-Received: by B4 Relay for i@hack3r.moe/default with auth_id=225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Previously when multiple BPF object files referencing the same extern
function (usually kfunc) are statically linked using `bpftool gen
object`, libbpf tries to get the nonexistent size of BTF_KIND_FUNC_PROTO
and fails. This test ensures it is fixed.

Signed-off-by: Eric Long <i@hack3r.moe>
---
 tools/testing/selftests/bpf/progs/linked_funcs1.c | 8 ++++++++
 tools/testing/selftests/bpf/progs/linked_funcs2.c | 8 ++++++++
 2 files changed, 16 insertions(+)

diff --git a/tools/testing/selftests/bpf/progs/linked_funcs1.c b/tools/testing/selftests/bpf/progs/linked_funcs1.c
index cc79dddac182c20da69a1a57fa39bc81004184f1..049a1f78de3f835e7658dde6f2d03161b6a5a07f 100644
--- a/tools/testing/selftests/bpf/progs/linked_funcs1.c
+++ b/tools/testing/selftests/bpf/progs/linked_funcs1.c
@@ -63,6 +63,8 @@ extern int set_output_val2(int x);
 /* here we'll force set_output_ctx2() to be __hidden in the final obj file */
 __hidden extern void set_output_ctx2(__u64 *ctx);
 
+void *bpf_cast_to_kern_ctx(void *obj) __ksym;
+
 SEC("?raw_tp/sys_enter")
 int BPF_PROG(handler1, struct pt_regs *regs, long id)
 {
@@ -86,4 +88,10 @@ int BPF_PROG(handler1, struct pt_regs *regs, long id)
 	return 0;
 }
 
+/* Generate BTF FUNC record and test linking with duplicate extern functions */
+void kfunc_gen1(void)
+{
+	bpf_cast_to_kern_ctx(0);
+}
+
 char LICENSE[] SEC("license") = "GPL";
diff --git a/tools/testing/selftests/bpf/progs/linked_funcs2.c b/tools/testing/selftests/bpf/progs/linked_funcs2.c
index 942cc5526ddf02004bf82d1f72c74cfba6eaf486..96850759fd8d0074249bbf1f743aab08e20de0fc 100644
--- a/tools/testing/selftests/bpf/progs/linked_funcs2.c
+++ b/tools/testing/selftests/bpf/progs/linked_funcs2.c
@@ -63,6 +63,8 @@ extern int set_output_val1(int x);
 /* here we'll force set_output_ctx1() to be __hidden in the final obj file */
 __hidden extern void set_output_ctx1(__u64 *ctx);
 
+void *bpf_cast_to_kern_ctx(void *obj) __ksym;
+
 SEC("?raw_tp/sys_enter")
 int BPF_PROG(handler2, struct pt_regs *regs, long id)
 {
@@ -86,4 +88,10 @@ int BPF_PROG(handler2, struct pt_regs *regs, long id)
 	return 0;
 }
 
+/* Generate BTF FUNC record and test linking with duplicate extern functions */
+void kfunc_gen2(void)
+{
+	bpf_cast_to_kern_ctx(0);
+}
+
 char LICENSE[] SEC("license") = "GPL";

-- 
2.46.2

