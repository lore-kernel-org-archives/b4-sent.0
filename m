From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Fri, 06 Nov 2026 10:37:09 +0700
Subject: [PATCH v2 2/2] selftests/bpf: Use memfd_create instead of mkstemp
 in d_path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-dpath-memfd-v2-2-1dc0799b4aa6@gmail.com>
References: <20261106-dpath-memfd-v2-0-1dc0799b4aa6@gmail.com>
In-Reply-To: <20261106-dpath-memfd-v2-0-1dc0799b4aa6@gmail.com>
To: Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793936228; l=1757;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=alou4cuIJ+oB76ZkZMUDEGCS67LRRaNUDOwQBWbIbMg=;
 b=g+JlCapFuWchf5QNuE7dfcj6YN5orNFWBIG7ivFHngGurbPwKuJWuiPHqAKyX2bOGCGyVsW7s
 Krx+xvbwCY5DXyn4Y0j2ZL9tTXEeuK/mCyjTAlhS6LhPF/QD554DB30
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

check_mem_access currently creates a temp file in /dev/shm, which
isn't mounted under vmtest.sh in local runs. This causes mkstemp
to fail with ENOENT. The fix is similar to
commit 47687a29b2c3 ("selftests/bpf: Use memfd_create instead of
shm_open in cgroup_iter_memcg") where memfd_create gives a
shmem-backed file with no mount needed while still reaching
vfs_fallocate.

Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
 tools/testing/selftests/bpf/prog_tests/d_path.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/d_path.c b/tools/testing/selftests/bpf/prog_tests/d_path.c
index b7998606aa98..ec73291ef060 100644
--- a/tools/testing/selftests/bpf/prog_tests/d_path.c
+++ b/tools/testing/selftests/bpf/prog_tests/d_path.c
@@ -4,6 +4,7 @@
 #include <sys/stat.h>
 #include <linux/sched.h>
 #include <sys/syscall.h>
+#include <sys/mman.h>
 
 #define MAX_PATH_LEN		128
 #define MAX_FILES		7
@@ -201,7 +202,6 @@ static void test_d_path_check_types(void)
 static void test_d_path_mem_access(void)
 {
 	int localfd = -1;
-	char path_template[] = "/dev/shm/d_path_loadgen.XXXXXX";
 	struct test_d_path__bss *bss;
 	struct test_d_path *skel;
 
@@ -211,13 +211,12 @@ static void test_d_path_mem_access(void)
 
 	bss = skel->bss;
 
-	localfd = mkstemp(path_template);
-	if (!ASSERT_OK_FD(localfd, "mkstemp"))
+	localfd = memfd_create("d_path_loadgen", 0);
+	if (!ASSERT_OK_FD(localfd, "memfd_create"))
 		goto cleanup;
 
 	if (!ASSERT_OK(fallocate(localfd, 0, 0, 1024), "fallocate"))
 		goto cleanup;
-	remove(path_template);
 
 	if (!ASSERT_TRUE(bss->path_match_fallocate, "fallocate path"))
 		goto cleanup;

-- 
2.56.0

