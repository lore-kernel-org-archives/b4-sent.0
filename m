From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 25 Jan 2025 16:23:41 +0800
Subject: [PATCH 6/7] selftests/bpf: probe_read_user_dynptr test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250125-bpf_dynptr_probe-v1-6-c3cb121f6951@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2767;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=a7T0+YDmmVckpfX1xozTGLaOH/fP9fHtnj0E/W62eQI=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnlJ+rQmKvcbdna8/m+XOj/whAV81YEiQ9YOLrE
 8cmCmZPlqqJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ5SfqwAKCRBvO5jUL8bJ
 2GF6EACaZ8KHPYnS/MNa848YuS0BpPvmidykJQig+PVt1wSMDcvBQkT9R2mUPJtuCjAPrGXwflX
 3vOg2qHGB089kxYhwDPkPAJbCgjuYy97Gg5GgXADehDqsYKWOsUjj4J2TdqRYOsCoHk51GzbExE
 iPJRzRvzcb6tLV0HWWzFPgki8S9EjdtkZg5rkdN5VABb1sAlMQCHAhJW3ws0NYEOuVW9rqbmthv
 IepBrGFJj1Mbvj0OJulrUWuZE879Bqn+5ABz7ZangTaDa64nVCcO7adoytZHYURxQNgy5TL2SX7
 T5d60RTNGxoWrKloFr/a86GD6oxL4CtjUDgFlBH1qrKb5oVTAzj+alEM0ItjyW3gaBu6OEELTdp
 21Ew3b2aidpcJesgaj7NsSyR5afTPn+4MUaH8oQwXMVm9P2SRrea0BpiqmsrpdfLSzKDJOcXj3T
 aYgP6kW+SappHso3CR3BioKYdbliHBkWvDEKNThIVwpWDD24plPvUVQCGHk68bB/x/0UiwiSlAu
 7bxJ9qndhuoPOE251Mo5Ov1bN9r7y0wRD1zNBZyy05YKORwu7sSG1qmaC4/Aldxt8Yey8oFWXSc
 5cfu/j7VzY5qEZMl9VDScnsyVRqBxY204PEdPBOQQEVKiBgIhhEUndRtijDhkBOHfallmTVNsTW
 CB32p1UgM5OqJFA==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds a test for probe_read_user_dynptr helper,
which tests reading variable length of user memory into a ringbuf
backed dynptr.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 tools/testing/selftests/bpf/prog_tests/dynptr.c    |  2 ++
 tools/testing/selftests/bpf/progs/dynptr_success.c | 36 +++++++++++++++++++++-
 2 files changed, 37 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/dynptr.c b/tools/testing/selftests/bpf/prog_tests/dynptr.c
index d9a25c2873b6ed4219e063845b1caf978a7016fd..a5a61a4c570d803bfca2af3f1a3b7d5eb0b8197f 100644
--- a/tools/testing/selftests/bpf/prog_tests/dynptr.c
+++ b/tools/testing/selftests/bpf/prog_tests/dynptr.c
@@ -32,6 +32,7 @@ static struct {
 	{"test_dynptr_skb_strcmp", SETUP_SKB_PROG},
 	{"test_dynptr_skb_tp_btf", SETUP_SKB_PROG_TP},
 	{"test_probe_read_kernel_dynptr", SETUP_RINGBUF},
+	{"test_probe_read_user_dynptr", SETUP_RINGBUF},
 };
 
 static int ringbuf_cb(void *ctx, void *data, size_t len)
@@ -61,6 +62,7 @@ static void verify_success(const char *prog_name, enum test_setup_type setup_typ
 		return;
 
 	skel->bss->pid = getpid();
+	skel->bss->user_ptr = (void *)&skel->data->test_buf;
 	skel->data->test_buf.length = 8;
 
 	prog = bpf_object__find_program_by_name(skel->obj, prog_name);
diff --git a/tools/testing/selftests/bpf/progs/dynptr_success.c b/tools/testing/selftests/bpf/progs/dynptr_success.c
index 64c698f83a37bfe924db93d36982a0a1c8defe62..5317860290dccb0862b6a0b94bb6f738c8d92835 100644
--- a/tools/testing/selftests/bpf/progs/dynptr_success.c
+++ b/tools/testing/selftests/bpf/progs/dynptr_success.c
@@ -576,7 +576,7 @@ struct {
 } test_buf = {
 	.length = 0,
 	.buf = "0123456789abcdef",
-};
+}, *user_ptr;
 
 SEC("?tp/syscalls/sys_enter_nanosleep")
 int test_probe_read_kernel_dynptr(void *ctx)
@@ -605,3 +605,37 @@ int test_probe_read_kernel_dynptr(void *ctx)
 	bpf_ringbuf_submit_dynptr(&ptr, 0);
 	return 0;
 }
+
+SEC("?tp/syscalls/sys_enter_nanosleep")
+int test_probe_read_user_dynptr(void *ctx)
+{
+	struct bpf_dynptr ptr;
+	int copy_len;
+
+	if (bpf_get_current_pid_tgid() >> 32 != pid)
+		return 0;
+
+	err = bpf_probe_read_user(&copy_len, sizeof(copy_len), &user_ptr->length);
+	if (err < 0 || copy_len < 0) {
+		err = 1;
+		return 1;
+	}
+
+	if (copy_len > MAX_BUFFER_LEN)
+		copy_len = MAX_BUFFER_LEN;
+
+	bpf_ringbuf_reserve_dynptr(&ringbuf, copy_len, 0, &ptr);
+
+	if (-E2BIG != bpf_probe_read_user_dynptr(&ptr, 0, MAX_BUFFER_LEN + 1,
+		&user_ptr->buf, 0)) {
+		err = 2;
+		goto cleanup;
+	}
+
+	err = bpf_probe_read_user_dynptr(&ptr, 0, copy_len,
+		&user_ptr->buf, 0);
+
+cleanup:
+	bpf_ringbuf_submit_dynptr(&ptr, 0);
+	return 0;
+}

-- 
2.48.1

