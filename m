From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 25 Jan 2025 16:23:40 +0800
Subject: [PATCH 5/7] selftests/bpf: probe_read_kernel_dynptr test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250125-bpf_dynptr_probe-v1-5-c3cb121f6951@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4155;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=jMKGNsysp1i//CbcuLXLYuHvxw7b8AHz8NxNTWOsSWc=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnlJ+qgj9hODG8k3+YiUeWSVCBC4TKYd83e1M8M
 dbcbKlDO9yJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ5SfqgAKCRBvO5jUL8bJ
 2FE6D/94fST0WN5qmhZL/BhsuIBonemuglhhMxyAP8256Q2fVDmyZTVZXEjREalt+KKiq0ewSGO
 y4x+IwymH3P9nK3mupjParc0/wjEN1vvoSl8OatMjCHYGWvZv+HDBmZVK5fhyBIubTFWJwulzQk
 CzfKNp7yHMMvISgWol3SANl11LvDMrCQ7+U1vKK/9rfAwZL4e2wvMb/EY+tLSsl+TWJ84EA2qjh
 jOzwFTfdh9eNGNM3NPIdJqNmwYAGQlgn7xqp7JLWgG2xpuyqV0YX5vmqkzKSBgeE2RWqk/GYsHc
 vb9uS/tcwBPvQHRvckXNasgR5ox7E8hZp7SpA89e0LHAHKSwaZcAnNCE57i9RrXp6X/x/itUvBV
 bWExbzSLAr0wqFePJZ84h8/8CKlYa4pFEGv8Y/MFfpO+qv7piLE2uchLQlIOqzXiJ4ChD/Imi/X
 8hjusTIbdRQ77/TNftfMw6RBQVbi5fRigM6FhobUx3aUocCOU2FrPQ2Wd1JXK/MgQNa0WXoMzxQ
 pbIj73tMNU7u6vKVehtbG5YA7GhAXgjLi+gUxg3Z780pjKPeedOcwgAtrKBu+RBAuycfRoaaG/x
 Mg611fo0jEXm65JIo6jsT7oyU+LWAQCdWcgXFeDJt1bPuuEyVE3C3VzuRC+NOEQjFS4FnxiE47M
 YuyiDV2TNF705Sw==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds a test for probe_read_kernel_dynptr helper,
which tests reading variable length of kernel memory into a ringbuf
backed dynptr.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 tools/testing/selftests/bpf/prog_tests/dynptr.c    | 40 +++++++++++++++++++++-
 tools/testing/selftests/bpf/progs/dynptr_success.c | 38 ++++++++++++++++++++
 2 files changed, 77 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/dynptr.c b/tools/testing/selftests/bpf/prog_tests/dynptr.c
index b614a5272dfd6486e287181270a0bcf63f638344..d9a25c2873b6ed4219e063845b1caf978a7016fd 100644
--- a/tools/testing/selftests/bpf/prog_tests/dynptr.c
+++ b/tools/testing/selftests/bpf/prog_tests/dynptr.c
@@ -10,6 +10,7 @@ enum test_setup_type {
 	SETUP_SYSCALL_SLEEP,
 	SETUP_SKB_PROG,
 	SETUP_SKB_PROG_TP,
+	SETUP_RINGBUF,
 };
 
 static struct {
@@ -30,20 +31,37 @@ static struct {
 	{"test_dynptr_skb_no_buff", SETUP_SKB_PROG},
 	{"test_dynptr_skb_strcmp", SETUP_SKB_PROG},
 	{"test_dynptr_skb_tp_btf", SETUP_SKB_PROG_TP},
+	{"test_probe_read_kernel_dynptr", SETUP_RINGBUF},
 };
 
+static int ringbuf_cb(void *ctx, void *data, size_t len)
+{
+	struct dynptr_success *skel = ctx;
+	const char *buf = data;
+
+	if (!ASSERT_EQ(len, skel->data->test_buf.length, "length"))
+		return -E2BIG;
+
+	if (!ASSERT_MEMEQ(buf, skel->data->test_buf.buf, len, "ringbuf_cb"))
+		return -EINVAL;
+
+	return 0;
+}
+
 static void verify_success(const char *prog_name, enum test_setup_type setup_type)
 {
+	struct ring_buffer *rb = NULL;
 	struct dynptr_success *skel;
 	struct bpf_program *prog;
 	struct bpf_link *link;
-	int err;
+	int err, ret;
 
 	skel = dynptr_success__open();
 	if (!ASSERT_OK_PTR(skel, "dynptr_success__open"))
 		return;
 
 	skel->bss->pid = getpid();
+	skel->data->test_buf.length = 8;
 
 	prog = bpf_object__find_program_by_name(skel->obj, prog_name);
 	if (!ASSERT_OK_PTR(prog, "bpf_object__find_program_by_name"))
@@ -63,6 +81,24 @@ static void verify_success(const char *prog_name, enum test_setup_type setup_typ
 
 		usleep(1);
 
+		bpf_link__destroy(link);
+		break;
+	case SETUP_RINGBUF:
+		link = bpf_program__attach(prog);
+		if (!ASSERT_OK_PTR(link, "bpf_program__attach"))
+			goto cleanup;
+
+		rb = ring_buffer__new(bpf_map__fd(skel->maps.ringbuf), ringbuf_cb, skel, NULL);
+		if (!ASSERT_OK_PTR(rb, "ring_buffer__new"))
+			goto cleanup;
+
+		usleep(1);
+
+		ret = ring_buffer__poll(rb, 5000);
+
+		if (!ASSERT_EQ(ret, 1, "ring_buffer__poll"))
+			goto cleanup;
+
 		bpf_link__destroy(link);
 		break;
 	case SETUP_SKB_PROG:
@@ -125,6 +161,8 @@ static void verify_success(const char *prog_name, enum test_setup_type setup_typ
 	ASSERT_EQ(skel->bss->err, 0, "err");
 
 cleanup:
+	if (rb != NULL)
+		ring_buffer__free(rb);
 	dynptr_success__destroy(skel);
 }
 
diff --git a/tools/testing/selftests/bpf/progs/dynptr_success.c b/tools/testing/selftests/bpf/progs/dynptr_success.c
index bfcc85686cf046361b451f97f4cd310a6ccdb1ed..64c698f83a37bfe924db93d36982a0a1c8defe62 100644
--- a/tools/testing/selftests/bpf/progs/dynptr_success.c
+++ b/tools/testing/selftests/bpf/progs/dynptr_success.c
@@ -567,3 +567,41 @@ int BPF_PROG(test_dynptr_skb_tp_btf, void *skb, void *location)
 
 	return 1;
 }
+
+#define MAX_BUFFER_LEN 20
+
+struct {
+	__u32 length;
+	char buf[MAX_BUFFER_LEN];
+} test_buf = {
+	.length = 0,
+	.buf = "0123456789abcdef",
+};
+
+SEC("?tp/syscalls/sys_enter_nanosleep")
+int test_probe_read_kernel_dynptr(void *ctx)
+{
+	int copy_len = test_buf.length;
+	struct bpf_dynptr ptr;
+
+	if (bpf_get_current_pid_tgid() >> 32 != pid)
+		return 0;
+
+	if (test_buf.length > MAX_BUFFER_LEN)
+		copy_len = MAX_BUFFER_LEN;
+
+	bpf_ringbuf_reserve_dynptr(&ringbuf, copy_len, 0, &ptr);
+
+	if (-E2BIG != bpf_probe_read_kernel_dynptr(&ptr, 0, MAX_BUFFER_LEN + 1,
+		test_buf.buf, 0)) {
+		err = 1;
+		goto cleanup;
+	}
+
+	err = bpf_probe_read_kernel_dynptr(&ptr, 0, copy_len,
+		test_buf.buf, 0);
+
+cleanup:
+	bpf_ringbuf_submit_dynptr(&ptr, 0);
+	return 0;
+}

-- 
2.48.1

