From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Mon, 02 Nov 2026 11:15:15 +0700
Subject: [PATCH bpf-next] selftests/bpf: Use memfd_create instead of
 mkstemp in d_path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-d-path-memfd-v1-1-692a5664b36d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBtIg6yuEi3KGWsWmWhEEN49a
 fkW/7+QOAonGKsXIt+S5PQFqq7A7ovfGIWKQTe6U6rRSBiWa8eDD0c49Ko3w2qpJQMlCZGdPP9
 ugjU49PxcMOf8AVqhSIFoAAAA
X-Change-ID: 20261102-d-path-memfd-981879bcd3d7
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Shuran Liu <electronlsr@gmail.com>, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793592917; l=1984;
 i=thamrinjonathan@gmail.com; s=20261005; h=from:subject:message-id;
 bh=TeJTaf4tRSKGbLwDa/44eFD6DQOyzppP99cx6sinrxM=;
 b=tCepcmKWaKlDygccQxSfS6IBJUclXSj5Eujzq3IucunRtsSHY72EraktC+4Qp4ocgMRskLro9
 8AvEPe3dLaVBfmEhdMInkWogaim0kdC4rK8pIDSb/DnFGXGV2xZrNI/
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=QU907bIMYty/tEI/iJF2SrD1lqOf/+2B1MI1zwJ5cBw=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261005 with auth_id=1114
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
index 1a2a2f1abf03..0f0150d73262 100644
--- a/tools/testing/selftests/bpf/prog_tests/d_path.c
+++ b/tools/testing/selftests/bpf/prog_tests/d_path.c
@@ -4,6 +4,7 @@
 #include <sys/stat.h>
 #include <linux/sched.h>
 #include <sys/syscall.h>
+#include <sys/mman.h>
 
 #define MAX_PATH_LEN		128
 #define MAX_FILES		7
@@ -220,7 +221,6 @@ static void test_d_path_check_types(void)
 static void test_d_path_mem_access(void)
 {
 	int localfd = -1;
-	char path_template[] = "/dev/shm/d_path_loadgen.XXXXXX";
 	struct test_d_path__bss *bss;
 	struct test_d_path *skel;
 
@@ -230,13 +230,12 @@ static void test_d_path_mem_access(void)
 
 	bss = skel->bss;
 
-	localfd = mkstemp(path_template);
-	if (CHECK(localfd < 0, "trigger", "mkstemp failed\n"))
+	localfd = memfd_create("d_path_loadgen", 0);
+	if (CHECK(localfd < 0, "trigger", "memfd_create failed\n"))
 		goto cleanup;
 
 	if (CHECK(fallocate(localfd, 0, 0, 1024) < 0, "trigger", "fallocate failed\n"))
 		goto cleanup;
-	remove(path_template);
 
 	if (CHECK(!bss->path_match_fallocate, "check",
 		  "failed to read fallocate path"))

---
base-commit: a30c772627b2ef4bc715332b1b04938a914556cd
change-id: 20261102-d-path-memfd-981879bcd3d7

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

