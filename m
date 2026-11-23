From: Mani Tofigh <mt4022@columbia.edu>
Date: Sun, 22 Nov 2026 19:25:15 -0500
Subject: [PATCH bpf v2 4/4] selftests/bpf: Test rhtab deletes from inside a
 resize
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-bpf-rhtab-irqs-disabled-v2-4-207aedcc2215@columbia.edu>
References: <20261122-bpf-rhtab-irqs-disabled-v2-0-207aedcc2215@columbia.edu>
In-Reply-To: <20261122-bpf-rhtab-irqs-disabled-v2-0-207aedcc2215@columbia.edu>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Mykyta Yatsenko <yatsenko@meta.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 Andrew Morton <akpm@linux-foundation.org>, Shuah Khan <shuah@kernel.org>
Cc: Thomas Graf <tgraf@suug.ch>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, bpf@vger.kernel.org, 
 linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795393512; l=3329;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=9el2Hu//XF7H7n6wCOTuZBRipgte5y1GXzMdDmYtqDk=;
 b=vBG6LrbpIAr++9Zz215gGlxXCBoIlBOmt54+VaYaziPIIojmkctwADigd28cCzhvBAFxIGn5R
 ft7lXRJQNcaApubwwaYPqBYXjlwOTZxr2QaBULP9qmfI5k+BbhrfoJc
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a kprobe program on rhashtable_jhash2() that deletes key 7 of a
resizable hash map whenever the resize worker hashes it there, while
user space keeps the table growing and shrinking.  The worker holds key
7's bucket lock at that point, so the delete fails with -EBUSY.  Without
the fix the CPU spins on that lock forever.

Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 tools/testing/selftests/bpf/prog_tests/rhash.c   | 34 ++++++++++++++++++++++++
 tools/testing/selftests/bpf/progs/rhash_resize.c | 34 ++++++++++++++++++++++++
 2 files changed, 68 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/rhash.c b/tools/testing/selftests/bpf/prog_tests/rhash.c
index 0641bd5b0a9e..5afe07b32289 100644
--- a/tools/testing/selftests/bpf/prog_tests/rhash.c
+++ b/tools/testing/selftests/bpf/prog_tests/rhash.c
@@ -5,6 +5,7 @@
 #include <stdio.h>
 #include "rhash.skel.h"
 #include "bpf_iter_bpf_rhash_map.skel.h"
+#include "rhash_resize.skel.h"
 #include <linux/bpf.h>
 #include <linux/perf_event.h>
 #include <sys/syscall.h>
@@ -149,6 +150,36 @@ static void rhash_iter_test(void)
 	bpf_iter_bpf_rhash_map__destroy(skel);
 }
 
+static void rhash_resize_test(void)
+{
+	struct rhash_resize *skel;
+	int fd, i, n;
+	__u64 val = 0;
+
+	skel = rhash_resize__open_and_load();
+	if (!ASSERT_OK_PTR(skel, "rhash_resize__open_and_load"))
+		return;
+
+	if (!ASSERT_OK(rhash_resize__attach(skel), "rhash_resize__attach"))
+		goto out;
+
+	fd = bpf_map__fd(skel->maps.rhmap);
+	/* let the resize worker run after each half */
+	for (n = 0; n < 5000 && !skel->bss->busy; n++) {
+		for (i = 0; i < 64; i++)
+			bpf_map_update_elem(fd, &i, &val, BPF_ANY);
+		usleep(100);
+		for (i = 0; i < 64; i++)
+			bpf_map_delete_elem(fd, &i);
+		usleep(100);
+	}
+
+	ASSERT_GT(skel->bss->hits, 0, "hits");
+	ASSERT_GT(skel->bss->busy, 0, "busy");
+out:
+	rhash_resize__destroy(skel);
+}
+
 void test_rhash(void)
 {
 	if (test__start_subtest("test_rhash_lookup_update"))
@@ -186,4 +217,7 @@ void test_rhash(void)
 
 	if (test__start_subtest("test_rhash_iter"))
 		rhash_iter_test();
+
+	if (test__start_subtest("test_rhash_resize"))
+		rhash_resize_test();
 }
diff --git a/tools/testing/selftests/bpf/progs/rhash_resize.c b/tools/testing/selftests/bpf/progs/rhash_resize.c
new file mode 100644
index 000000000000..5a1076b30bb0
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/rhash_resize.c
@@ -0,0 +1,34 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <vmlinux.h>
+#include <errno.h>
+#include <bpf/bpf_helpers.h>
+#include <bpf/bpf_tracing.h>
+
+char _license[] SEC("license") = "GPL";
+
+struct {
+	__uint(type, BPF_MAP_TYPE_RHASH);
+	__uint(map_flags, BPF_F_NO_PREALLOC);
+	__uint(max_entries, 128);
+	__type(key, int);
+	__type(value, long);
+} rhmap SEC(".maps");
+
+int hits;
+int busy;
+
+/* The resize worker calls this with the key's bucket lock held */
+SEC("kprobe/rhashtable_jhash2")
+int BPF_KPROBE(rhash_resize_delete, const void *key, u32 length)
+{
+	int k;
+
+	if (length != 1 || bpf_probe_read_kernel(&k, sizeof(k), key) || k != 7)
+		return 0;
+
+	__sync_fetch_and_add(&hits, 1);
+	if (bpf_map_delete_elem(&rhmap, &k) == -EBUSY)
+		__sync_fetch_and_add(&busy, 1);
+	return 0;
+}

-- 
2.53.0

