From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Wed, 04 Nov 2026 18:37:58 +0700
Subject: [PATCH bpf-next 2/2] selftests/bpf: Test local storage max value
 size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-local-storage-max-v1-2-c836731bd184@gmail.com>
References: <20261104-local-storage-max-v1-0-c836731bd184@gmail.com>
In-Reply-To: <20261104-local-storage-max-v1-0-c836731bd184@gmail.com>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, Amery Hung <ameryhung@gmail.com>, 
 Shuah Khan <shuah@kernel.org>, Christian Brauner <brauner@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Amery Hung <ameryhung@gmail.com>, 
 Slava Imameev <slava.imameev@crowdstrike.com>, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793792278; l=3581;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=sbS2w6xefcyYIn4G7cqCv6ZgI7XpeANsGRjBwSGkGqU=;
 b=rQNa/Dfm/Af0QN97+0IUJCG2LTuk806TrnWh4gLHs4MVZbOhOj4RJN8w/7QgzeYew77aLlQPF
 kYTu0cA8q9fCKNr6Vm+AFguOlIPuDj7IYejHwIMbyRCNFfTsEYdjb4y
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test that finds the largest value size accepted for a task
storage map using binary search, then checks that a value of this
size can be stored. It also checks the size is >=4096 to make sure
the limit is not set too low. This test fails without the previous
patch with ENOMEM.

Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
 .../selftests/bpf/prog_tests/task_local_storage.c  | 87 ++++++++++++++++++++++
 1 file changed, 87 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/task_local_storage.c b/tools/testing/selftests/bpf/prog_tests/task_local_storage.c
index 5b2b56cc3a4f..c7e9fa6743b9 100644
--- a/tools/testing/selftests/bpf/prog_tests/task_local_storage.c
+++ b/tools/testing/selftests/bpf/prog_tests/task_local_storage.c
@@ -495,6 +495,91 @@ static void test_uptr_map_failure(const char *map_name, int expected_errno)
 	uptr_map_failure__destroy(skel);
 }
 
+static int create_task_storage_map(__u32 value_size)
+{
+	LIBBPF_OPTS(bpf_map_create_opts, create_attr);
+	struct btf *btf;
+	int int_id, char_id, arr_id, err, saved_errno;
+	int map_fd = -1;
+
+	btf = btf__new_empty();
+	if (!ASSERT_OK_PTR(btf, "btf__new"))
+		goto done;
+
+	int_id = btf__add_int(btf, "int", 4, BTF_INT_SIGNED);
+	char_id = btf__add_int(btf, "char", 1, 0);
+	arr_id = btf__add_array(btf, int_id, char_id, value_size);
+	err = btf__load_into_kernel(btf);
+	if (!ASSERT_OK(err, "btf__load_into_kernel"))
+		goto done;
+
+	create_attr.map_flags = BPF_F_NO_PREALLOC;
+	create_attr.btf_fd = btf__fd(btf);
+	create_attr.btf_key_type_id = int_id;
+	create_attr.btf_value_type_id = arr_id;
+	map_fd = bpf_map_create(BPF_MAP_TYPE_TASK_STORAGE, "big_ls_map",
+				sizeof(int), value_size, 0, &create_attr);
+
+done:
+	saved_errno = errno;
+	btf__free(btf);
+	errno = saved_errno;
+	return map_fd;
+}
+
+/* Return the largest value_size the kernel accepts for a local storage
+ * map, or -1 on an unexpected error.
+ */
+static int find_max_value_size(void)
+{
+	int lo = 1, hi = 65535, mid, map_fd;
+
+	while (lo < hi) {
+		mid = lo + (hi - lo + 1) / 2;
+
+		map_fd = create_task_storage_map(mid);
+		if (map_fd >= 0) {
+			close(map_fd);
+			lo = mid;
+		} else {
+			if (!ASSERT_EQ(errno, E2BIG, "create_task_storage_map errno"))
+				return -1;
+			hi = mid - 1;
+		}
+	}
+	return lo;
+}
+
+static void test_local_storage_max_value_size(void)
+{
+	int map_fd, task_fd = -1, max_size, err;
+	void *buf = NULL;
+
+	max_size = find_max_value_size();
+	if (!ASSERT_GE(max_size, 4096, "find_max_value_size"))
+		return;
+
+	map_fd = create_task_storage_map(max_size);
+	if (!ASSERT_OK_FD(map_fd, "create_task_storage_map"))
+		return;
+
+	task_fd = sys_pidfd_open(getpid(), 0);
+	if (!ASSERT_OK_FD(task_fd, "sys_pidfd_open"))
+		goto out;
+
+	buf = calloc(1, max_size);
+	if (!ASSERT_OK_PTR(buf, "calloc"))
+		goto out;
+	err = bpf_map_update_elem(map_fd, &task_fd, buf, 0);
+	ASSERT_OK(err, "bpf_map_update_elem");
+
+out:
+	free(buf);
+	if (task_fd >= 0)
+		close(task_fd);
+	close(map_fd);
+}
+
 void test_task_local_storage(void)
 {
 	if (test__start_subtest("sys_enter_exit"))
@@ -521,5 +606,7 @@ void test_task_local_storage(void)
 		test_uptr_map_failure("empty_uptr_map", EINVAL);
 	if (test__start_subtest("uptr_map_failure_kstruct"))
 		test_uptr_map_failure("kstruct_uptr_map", EINVAL);
+	if (test__start_subtest("local_storage_max_value_size"))
+		test_local_storage_max_value_size();
 	RUN_TESTS(uptr_failure);
 }

-- 
2.56.0

