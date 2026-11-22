From: YanXin Li <fadouse@pm.me>
Date: Sun, 22 Nov 2026 20:35:37 +0800
Subject: [PATCH bpf v4 2/2] selftests/bpf: test arena allocation after a
 short mmap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-v4-2-d542d1233623@pm.me>
References: <20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-v4-0-d542d1233623@pm.me>
In-Reply-To: <20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-v4-0-d542d1233623@pm.me>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>
Cc: Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, bpf@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795350970; l=4531;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=12pf/DDajqKWIUwZFygjYQjcysYQ35Yyf+7SvH1neXs=;
 b=fVfGRrZf0kiKVP2LKGaSIX/uR/eyOguX6/Qmruahgzv2FWL+SHwDe4d7mI/D2Pf/18F5CgN/J
 G8bWfg5VzBsDTJzawjXmrA6TQfeTyYdeFbs5rhQYyFXRAxCyCH7uFj4
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without map_extra, the first mmap of an arena can be shorter than the
map's max_entries. Automatic allocations must stay within that VMA.

Create an eight-page arena and mmap only four pages before loading a BPF
program. Reuse the map FD so libbpf does not mmap the full arena. The
program occupies offset zero and allocates two more pages, leaving one
page within the VMA. A two-page request must fail, and a final one-page
request must succeed. Before the preceding fix, the two-page request
succeeds outside the VMA.

When JIT is disabled, arena map creation can succeed while loading a
program that uses the map returns -EOPNOTSUPP. Skip the subtest in that
case.

Signed-off-by: YanXin Li <fadouse@pm.me>
---
 .../testing/selftests/bpf/prog_tests/arena_mmap.c  | 53 ++++++++++++++++++++++
 .../testing/selftests/bpf/progs/arena_mmap_alloc.c | 33 ++++++++++++++
 2 files changed, 86 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/arena_mmap.c b/tools/testing/selftests/bpf/prog_tests/arena_mmap.c
index f55d950720f..ff1fe0a6f22 100644
--- a/tools/testing/selftests/bpf/prog_tests/arena_mmap.c
+++ b/tools/testing/selftests/bpf/prog_tests/arena_mmap.c
@@ -2,6 +2,7 @@
 
 #include <test_progs.h>
 #include <sys/mman.h>
+#include "arena_mmap_alloc.skel.h"
 
 #define ARENA_PAGES 8
 
@@ -34,6 +35,56 @@ static void test_refused(__u64 map_extra, __u64 addr, int pages, int flags, int
 	close(fd);
 }
 
+static void test_short_mmap_alloc(void)
+{
+	LIBBPF_OPTS(bpf_map_create_opts, map_opts, .map_flags = BPF_F_MMAPABLE);
+	LIBBPF_OPTS(bpf_test_run_opts, run_opts);
+	struct arena_mmap_alloc *skel = NULL;
+	size_t size = 4 * getpagesize();
+	void *area;
+	int fd, err;
+
+	fd = bpf_map_create(BPF_MAP_TYPE_ARENA, "arena", 0, 0,
+			    ARENA_PAGES, &map_opts);
+	if (fd == -EOPNOTSUPP) {
+		test__skip();
+		return;
+	}
+	if (!ASSERT_GE(fd, 0, "bpf_map_create"))
+		return;
+
+	/* The short mapping must be the first mmap() of this arena. */
+	area = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
+	if (!ASSERT_NEQ(area, MAP_FAILED, "short_mmap"))
+		goto out_close;
+
+	/* Reuse the map so libbpf does not mmap all ARENA_PAGES on load. */
+	skel = arena_mmap_alloc__open();
+	if (!ASSERT_OK_PTR(skel, "arena_mmap_alloc__open"))
+		goto out_unmap;
+	err = bpf_map__reuse_fd(skel->maps.arena, fd);
+	if (!ASSERT_OK(err, "reuse_arena_fd"))
+		goto out_destroy;
+	err = arena_mmap_alloc__load(skel);
+	if (err == -EOPNOTSUPP) {
+		test__skip();
+		goto out_destroy;
+	}
+	if (!ASSERT_OK(err, "arena_mmap_alloc__load"))
+		goto out_destroy;
+	err = bpf_prog_test_run_opts(bpf_program__fd(skel->progs.alloc_beyond_vma),
+				     &run_opts);
+	if (ASSERT_OK(err, "alloc_beyond_vma"))
+		ASSERT_OK(run_opts.retval, "alloc_beyond_vma_retval");
+
+out_destroy:
+	arena_mmap_alloc__destroy(skel);
+out_unmap:
+	munmap(area, size);
+out_close:
+	close(fd);
+}
+
 void serial_test_arena_mmap(void)
 {
 	__u64 page = getpagesize(), last = -(ARENA_PAGES * page);
@@ -50,4 +101,6 @@ void serial_test_arena_mmap(void)
 		test_refused(0, -page, ARENA_PAGES, MAP_FIXED, 0);
 	if (test__start_subtest("map_extra_last_pages"))
 		test_refused(last, last, ARENA_PAGES, MAP_FIXED, 0);
+	if (test__start_subtest("short_mmap_alloc"))
+		test_short_mmap_alloc();
 }
diff --git a/tools/testing/selftests/bpf/progs/arena_mmap_alloc.c b/tools/testing/selftests/bpf/progs/arena_mmap_alloc.c
new file mode 100644
index 00000000000..9c46a393eae
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/arena_mmap_alloc.c
@@ -0,0 +1,33 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#define BPF_NO_KFUNC_PROTOTYPES
+#include <vmlinux.h>
+#include <bpf/bpf_helpers.h>
+#include "bpf_arena_common.h"
+
+struct {
+	__uint(type, BPF_MAP_TYPE_ARENA);
+	__uint(map_flags, BPF_F_MMAPABLE);
+	__uint(max_entries, 8);
+} arena SEC(".maps");
+
+SEC("syscall")
+int alloc_beyond_vma(void *ctx)
+{
+	void __arena *page;
+
+	page = bpf_arena_alloc_pages(&arena, NULL, 1, NUMA_NO_NODE, 0);
+	if (!page)
+		return 4;
+	page = bpf_arena_alloc_pages(&arena, NULL, 2, NUMA_NO_NODE, 0);
+	if (!page)
+		return 1;
+	/* Only one of the four mmap()ed pages remains available. */
+	page = bpf_arena_alloc_pages(&arena, NULL, 2, NUMA_NO_NODE, 0);
+	if (page)
+		return 2;
+	page = bpf_arena_alloc_pages(&arena, NULL, 1, NUMA_NO_NODE, 0);
+	return page ? 0 : 3;
+}
+
+char _license[] SEC("license") = "GPL";

-- 
Git-157)

