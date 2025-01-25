From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 25 Jan 2025 16:23:37 +0800
Subject: [PATCH 2/7] bpf: Implement bpf_probe_read_user_dynptr helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250125-bpf_dynptr_probe-v1-2-c3cb121f6951@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6307;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=FYHnq6c7uuywFLvG8HAAKztCiF4RpinK4T4T/ey1n7A=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnlJ+nEpWi8WVFFFpmE/yDFE3vE7ZHL5J7vC5nM
 TkoVwhS6uSJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ5SfpwAKCRBvO5jUL8bJ
 2N6VD/0cM0FdKOQ7gznBEKm/XPX/48L+fiSM1RHmji4OLxZo45M/pfQS2pPimcfXMtYDM1YOaXJ
 eiSXpES8b6yGv9QVAtGVCBfAIK3IF+eaObl+oH1FmUO1Hd2eAQ4LzvUHYiICNlKdJ/T73J7uVIk
 5EE3iAjSXRl8+9O3Y4nj4YrmFYWW2DLDzQgVQJvgegGM+IDOVjZf5Kgmm3KoC/Q7dcR5ISgEcu2
 ITXEieFHkbYjCJfdWLAsOzgBfgb2KyAQQTNxWdZY8njYHAWjTl5T9gM+l77uoaiTFB8NW0ajcpA
 GdSTpXEHY19vlGdiu+WgSTVypaQEQpSxi6YIDjoXScwrteynjiNH34MSAUuDbA5yAnDh80Ik0cL
 Wjveja4nOnIbjn+NR71+Yaq9GmR4BzOHZxvuuGLbYLJy091+7XT/9pZEDWUzd6nmMVznuTatV2e
 rzSwRCYR+Nx6SA1w5MLK1Eh+PNrg9kKkDxCe9PxGTo8XsRXXSJf88tBmmIEFaZvv4+S4ZYxyPYG
 PbaLxZsTRYityEdJo0FVPIyopMIyA2q71WJO0jSXdT2msUPqLykK/izkyRIAlODd0CAm2QoUKGD
 ycKf40voksgTzNe9j5nNTKOGz9em8sMgX3l8n9oMgWuUoi2AaVwmAW+oBbwGXKpFi2tzHKNubmD
 bbVwD1mnZw3sm9A==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch add a helper function bpf_probe_read_user_dynptr:

long bpf_probe_read_user_dynptr(const struct bpf_dynptr *dst,
	u32 offset, u32 size, const void *unsafe_ptr, u64 flags);

It is useful for reading variable-length data from user memory into
dynptr.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 include/uapi/linux/bpf.h | 16 ++++++++++
 kernel/bpf/helpers.c     |  3 ++
 kernel/trace/bpf_trace.c | 76 +++++++++++++++++++++++++++++++++---------------
 3 files changed, 71 insertions(+), 24 deletions(-)

diff --git a/include/uapi/linux/bpf.h b/include/uapi/linux/bpf.h
index 2e08a59527ecf56732ea14ac34446b5eb25b5690..d7d7a9ddd5dca07ba89d81ba77101a704af3163b 100644
--- a/include/uapi/linux/bpf.h
+++ b/include/uapi/linux/bpf.h
@@ -5820,6 +5820,21 @@ union bpf_attr {
  *		support this helper, or if *flags* is not 0.
  *
  *		Or other negative errors on failure reading kernel memory.
+ *
+ * long bpf_probe_read_user_dynptr(const struct bpf_dynptr *dst, u32 offset, u32 size, const void *unsafe_ptr, u64 flags)
+ *	Description
+ *		Safely attempt to read *size* bytes from user space address
+ *		*unsafe_ptr* and store the data in *dst* starting from *offset*.
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
@@ -6035,6 +6050,7 @@ union bpf_attr {
 	FN(cgrp_storage_get, 210, ##ctx)		\
 	FN(cgrp_storage_delete, 211, ##ctx)		\
 	FN(probe_read_kernel_dynptr, 212, ##ctx)		\
+	FN(probe_read_user_dynptr, 213, ##ctx)		\
 	/* */
 
 /* backwards-compatibility macros for users of __BPF_FUNC_MAPPER that don't
diff --git a/kernel/bpf/helpers.c b/kernel/bpf/helpers.c
index a736dc9e7be98571103ba404420be0da4dac4fbe..ac563d09082e7c721999d7de035aabc000206a29 100644
--- a/kernel/bpf/helpers.c
+++ b/kernel/bpf/helpers.c
@@ -1898,6 +1898,7 @@ const struct bpf_func_proto bpf_get_current_task_proto __weak;
 const struct bpf_func_proto bpf_get_current_task_btf_proto __weak;
 const struct bpf_func_proto bpf_probe_read_user_proto __weak;
 const struct bpf_func_proto bpf_probe_read_user_str_proto __weak;
+const struct bpf_func_proto bpf_probe_read_user_dynptr_proto __weak;
 const struct bpf_func_proto bpf_probe_read_kernel_proto __weak;
 const struct bpf_func_proto bpf_probe_read_kernel_str_proto __weak;
 const struct bpf_func_proto bpf_probe_read_kernel_dynptr_proto __weak;
@@ -2029,6 +2030,8 @@ bpf_base_func_proto(enum bpf_func_id func_id, const struct bpf_prog *prog)
 		return &bpf_get_current_task_btf_proto;
 	case BPF_FUNC_probe_read_user:
 		return &bpf_probe_read_user_proto;
+	case BPF_FUNC_probe_read_user_dynptr:
+		return &bpf_probe_read_user_dynptr_proto;
 	case BPF_FUNC_probe_read_kernel:
 		return security_locked_down(LOCKDOWN_BPF_READ_KERNEL) < 0 ?
 		       NULL : &bpf_probe_read_kernel_proto;
diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index 75c9d1e8d04c3b8930ae81345f5586756ce8b5ec..d9f704c1342773c74b2414be4adfc8271d6d364d 100644
--- a/kernel/trace/bpf_trace.c
+++ b/kernel/trace/bpf_trace.c
@@ -181,6 +181,36 @@ bpf_probe_read_user_common(void *dst, u32 size, const void __user *unsafe_ptr)
 	return ret;
 }
 
+static int bpf_probe_read_check_dynptr(const struct bpf_dynptr_kern *dst,
+	u32 offset, u32 size, u64 flags)
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
+		return 0;
+	case BPF_DYNPTR_TYPE_SKB:
+	case BPF_DYNPTR_TYPE_XDP:
+		return -EINVAL;
+	default:
+		WARN_ONCE(true, "%s: unknown dynptr type %d\n", __func__, type);
+		return -EFAULT;
+	}
+}
+
 BPF_CALL_3(bpf_probe_read_user, void *, dst, u32, size,
 	   const void __user *, unsafe_ptr)
 {
@@ -196,6 +226,26 @@ const struct bpf_func_proto bpf_probe_read_user_proto = {
 	.arg3_type	= ARG_ANYTHING,
 };
 
+BPF_CALL_5(bpf_probe_read_user_dynptr, const struct bpf_dynptr_kern *, dst,
+	u32, offset, u32, size, void *, unsafe_ptr, u64, flags)
+{
+	int ret = bpf_probe_read_check_dynptr(dst, offset, size, flags);
+
+	return ret ?: bpf_probe_read_user_common(dst->data + dst->offset + offset,
+				size, unsafe_ptr);
+}
+
+const struct bpf_func_proto bpf_probe_read_user_dynptr_proto = {
+	.func		= bpf_probe_read_user_dynptr,
+	.gpl_only	= true,
+	.ret_type	= RET_INTEGER,
+	.arg1_type	= ARG_PTR_TO_DYNPTR | MEM_RDONLY,
+	.arg2_type	= ARG_ANYTHING,
+	.arg3_type	= ARG_ANYTHING,
+	.arg4_type	= ARG_ANYTHING,
+	.arg5_type	= ARG_ANYTHING,
+};
+
 static __always_inline int
 bpf_probe_read_user_str_common(void *dst, u32 size,
 			       const void __user *unsafe_ptr)
@@ -251,32 +301,10 @@ const struct bpf_func_proto bpf_probe_read_kernel_proto = {
 BPF_CALL_5(bpf_probe_read_kernel_dynptr, const struct bpf_dynptr_kern *, dst,
 	u32, offset, u32, size, void *, unsafe_ptr, u64, flags)
 {
-	enum bpf_dynptr_type type;
-	int err;
-
-	if (!dst->data || __bpf_dynptr_is_rdonly(dst))
-		return -EINVAL;
+	int ret = bpf_probe_read_check_dynptr(dst, offset, size, flags);
 
-	err = bpf_dynptr_check_off_len(dst, offset, size);
-	if (err)
-		return err;
-
-	type = bpf_dynptr_get_type(dst);
-
-	switch (type) {
-	case BPF_DYNPTR_TYPE_LOCAL:
-	case BPF_DYNPTR_TYPE_RINGBUF:
-		if (flags)
-			return -EINVAL;
-		return bpf_probe_read_kernel_common(dst->data + dst->offset + offset,
+	return ret ?: bpf_probe_read_kernel_common(dst->data + dst->offset + offset,
 				size, unsafe_ptr);
-	case BPF_DYNPTR_TYPE_SKB:
-	case BPF_DYNPTR_TYPE_XDP:
-		return -EINVAL;
-	default:
-		WARN_ONCE(true, "%s: unknown dynptr type %d\n", __func__, type);
-		return -EFAULT;
-	}
 }
 
 const struct bpf_func_proto bpf_probe_read_kernel_dynptr_proto = {

-- 
2.48.1

