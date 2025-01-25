From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 25 Jan 2025 16:23:38 +0800
Subject: [PATCH 3/7] bpf: Implement bpf_copy_from_user_dynptr helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250125-bpf_dynptr_probe-v1-3-c3cb121f6951@outlook.com>
References: <20250125-bpf_dynptr_probe-v1-0-c3cb121f6951@outlook.com>
In-Reply-To: <20250125-bpf_dynptr_probe-v1-0-c3cb121f6951@outlook.com>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, KP Singh <kpsingh@kernel.org>, 
 Stanislav Fomichev <sdf@fomichev.me>, Hao Luo <haoluo@google.com>, 
 Jiri Olsa <jolsa@kernel.org>, Matt Bobrowski <mattbobrowski@google.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Mykola Lysenko <mykolal@fb.com>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Andrii Nakryiko <andrii.nakryiko@gmail.com>, 
 Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4919;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=PbsS7Vpr6USg1jk+KBsoBiOuzmKNN5IGam682v3+Quo=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnlJ+o5K9T/oZ8/P9uW/mhlyXmxkrHjL2HQaesf
 ayhCZA2AIqJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ5SfqAAKCRBvO5jUL8bJ
 2JD7EACZuujqM2zIc3AFx3lsUjPfRYvFM9rgdNs3DGqy27g63VsGwyupTptf3ZXqTm77PbHy0j2
 T4CM9U9GZUi+Eh808gkrOgekWJq52eTh4qArPYU3fI2hA1pQamnMMm8ZulmchIox+HQC9AXIC2U
 QK4Uq4s7eHDZ9j+KsqhkV7EHJO/+XKxgFp/cg8M4C57iAK/war7RaSJqChcdoFO1OAahaB2E3jx
 k+gntF6sy7D8SQVd96MzII+hN93qNsZz4nP/qt8SQ+t8GwrsYQbRgfijLiCW65piZrLEzrhiVVr
 5VjC4l/QwddkpzCAITLHd7VY1D/JMAEo8+mBGg2EgHXpEuihnL/ZVUKHDwYyVvCOLPrKuKXSt27
 vG8N6UnK6G8vlcPhX8OeVcGLRyvuWsquZ5xGRmRfyaz7Yl+evNTXAPsXeRevBDFq/MQMPjWmIX/
 5Ias1g1detLoMiC5SE7m+oIoMq2wNkj+ItVFSaRatxz0zXkeAirryiVvzIrlRVau7FiU8vjsn6+
 jFUXJ2Jw70/4VW7HQmbTdRuJvjLxduxBum3b/A6JR20I5VOgP1DTTjpP9fX4RBDSd+i12BXwPXr
 Qb01henk8z8uqDLDQVVeecCoAM5uf8sYTigvSf7ej/e73IKVz4oFzMtiZVHf9wmf8G9haS4Jw6a
 a5IN+TNPGU6eDuw==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch add a helper function bpf_copy_from_user_dynptr:

bpf_copy_from_user_dynptr(const struct bpf_dynptr *dst, u32 offset,
	u32 size, const void *user_ptr, u64 flags)

It is useful for reading variable-length data from kernel memory into
dynptr.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 include/linux/bpf.h      |  1 +
 include/uapi/linux/bpf.h | 17 +++++++++++++++++
 kernel/bpf/helpers.c     | 42 ++++++++++++++++++++++++++++++++++++++++++
 kernel/trace/bpf_trace.c |  2 ++
 4 files changed, 62 insertions(+)

diff --git a/include/linux/bpf.h b/include/linux/bpf.h
index 9d5ae8b4b7d82c4523bf0ab041d4b76bf134a106..d0412eaf63d69c0e437575c77008548edc692335 100644
--- a/include/linux/bpf.h
+++ b/include/linux/bpf.h
@@ -3357,6 +3357,7 @@ extern const struct bpf_func_proto bpf_get_retval_proto;
 extern const struct bpf_func_proto bpf_user_ringbuf_drain_proto;
 extern const struct bpf_func_proto bpf_cgrp_storage_get_proto;
 extern const struct bpf_func_proto bpf_cgrp_storage_delete_proto;
+extern const struct bpf_func_proto bpf_copy_from_user_dynptr_proto;
 
 const struct bpf_func_proto *tracing_prog_func_proto(
   enum bpf_func_id func_id, const struct bpf_prog *prog);
diff --git a/include/uapi/linux/bpf.h b/include/uapi/linux/bpf.h
index d7d7a9ddd5dca07ba89d81ba77101a704af3163b..f92cf809b50bc393d54eb0e8de2e1ce2a39e95d0 100644
--- a/include/uapi/linux/bpf.h
+++ b/include/uapi/linux/bpf.h
@@ -5835,6 +5835,22 @@ union bpf_attr {
  *		support this helper, or if *flags* is not 0.
  *
  *		Or other negative errors on failure reading user space memory.
+ *
+ * long bpf_copy_from_user_dynptr(const struct bpf_dynptr *dst, u32 offset, u32 size, const void *user_ptr, u64 flags)
+ *	Description
+ *		Read *size* bytes from user space address *user_ptr* and store
+ *		the data in *dst* starting from *offset*.
+ *		This is a wrapper of **copy_from_user**\ ().
+ *		*flags* is currently unused.
+ *	Return
+ *		0 on success.
+ *
+ *		**-E2BIG** if *offset* + *len* exceeds the length of *src*'s data
+ *
+ *		**-EINVAL** if *src* is an invalid dynptr or doesn't support this
+ *		support this helper, or if *flags* is not 0.
+ *
+ *		Or other negative errors on failure reading user space memory.
  */
 #define ___BPF_FUNC_MAPPER(FN, ctx...)			\
 	FN(unspec, 0, ##ctx)				\
@@ -6051,6 +6067,7 @@ union bpf_attr {
 	FN(cgrp_storage_delete, 211, ##ctx)		\
 	FN(probe_read_kernel_dynptr, 212, ##ctx)		\
 	FN(probe_read_user_dynptr, 213, ##ctx)		\
+	FN(copy_from_user_dynptr, 214, ##ctx)		\
 	/* */
 
 /* backwards-compatibility macros for users of __BPF_FUNC_MAPPER that don't
diff --git a/kernel/bpf/helpers.c b/kernel/bpf/helpers.c
index ac563d09082e7c721999d7de035aabc000206a29..d756c80596315bd07fe6e71885b61efc8cb2ef4f 100644
--- a/kernel/bpf/helpers.c
+++ b/kernel/bpf/helpers.c
@@ -676,6 +676,48 @@ const struct bpf_func_proto bpf_copy_from_user_proto = {
 	.arg3_type	= ARG_ANYTHING,
 };
 
+BPF_CALL_5(bpf_copy_from_user_dynptr, const struct bpf_dynptr_kern *, dst,
+	u32, offset, u32, size, const void __user *, user_ptr, u32, flags)
+{
+	enum bpf_dynptr_type type;
+	int err;
+
+	if (!dst->data || __bpf_dynptr_is_rdonly(dst))
+		return -EINVAL;
+
+	err = bpf_dynptr_check_off_len(dst, offset, size);
+	if (err)
+		return err;
+
+	type = bpf_dynptr_get_type(dst);
+
+	switch (type) {
+	case BPF_DYNPTR_TYPE_LOCAL:
+	case BPF_DYNPTR_TYPE_RINGBUF:
+		if (flags)
+			return -EINVAL;
+		return ____bpf_copy_from_user(dst->data + dst->offset + offset, size, user_ptr);
+	case BPF_DYNPTR_TYPE_SKB:
+	case BPF_DYNPTR_TYPE_XDP:
+		return -EINVAL;
+	default:
+		WARN_ONCE(true, "%s: unknown dynptr type %d\n", __func__, type);
+		return -EFAULT;
+	}
+}
+
+const struct bpf_func_proto bpf_copy_from_user_dynptr_proto = {
+	.func		= bpf_copy_from_user_dynptr,
+	.gpl_only	= false,
+	.might_sleep	= true,
+	.ret_type	= RET_INTEGER,
+	.arg1_type	= ARG_PTR_TO_DYNPTR | MEM_RDONLY,
+	.arg2_type	= ARG_ANYTHING,
+	.arg3_type	= ARG_ANYTHING,
+	.arg4_type	= ARG_ANYTHING,
+	.arg5_type	= ARG_ANYTHING,
+};
+
 BPF_CALL_5(bpf_copy_from_user_task, void *, dst, u32, size,
 	   const void __user *, user_ptr, struct task_struct *, tsk, u64, flags)
 {
diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index d9f704c1342773c74b2414be4adfc8271d6d364d..424931925fe3b02db083bc19cc64e19918b40c5a 100644
--- a/kernel/trace/bpf_trace.c
+++ b/kernel/trace/bpf_trace.c
@@ -1598,6 +1598,8 @@ bpf_tracing_func_proto(enum bpf_func_id func_id, const struct bpf_prog *prog)
 		return &bpf_copy_from_user_proto;
 	case BPF_FUNC_copy_from_user_task:
 		return &bpf_copy_from_user_task_proto;
+	case BPF_FUNC_copy_from_user_dynptr:
+		return &bpf_copy_from_user_dynptr_proto;
 	case BPF_FUNC_snprintf_btf:
 		return &bpf_snprintf_btf_proto;
 	case BPF_FUNC_per_cpu_ptr:

-- 
2.48.1

