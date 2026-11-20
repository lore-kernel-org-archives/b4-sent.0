From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Fri, 20 Nov 2026 14:59:02 +0800
Subject: [PATCH bpf-next] selftests/bpf: Fix
 file_reader/on_open_non_sleepable_first on overlayfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-file-reader-overlayfs-v1-1-81aa7f3041d1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBBG4avIrDuQpFaaXqV0Ec0fHZAokyIW8
 e6GLr/FewcVqKDQqzlIsUmRJVfYW0PDFPIIllhNzrjOWmc4yQxWhAjlZYPO4ZcKm9b7Z4yhe/g
 71XZVJNn/3zf1a+KM/Uuf87wAwDh0gnEAAAA=
X-Change-ID: 20261120-file-reader-overlayfs-04998dda6593
To: Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795157947; l=2542;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=Z42i5/leJVwaMNYSXOof1lDedpwAns1zY51D5qfLFZg=;
 b=BVELy4sSCT416yAlXQDGZOkNtmJrAAIWI07LrHUOPdK4831RXbQ3f0/U5f91jZvgqGiuvGpmL
 WwqN1+FqKaxBANdUCPWmvgNM9CLE67wy3NxSXRR6Y8yeTXZOETej6IR
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

on_open_non_sleepable_first fails every time when the test_progs binary
is on overlayfs, as under /home and /tmp in a virtme-ng guest:

  run_test:FAIL:err unexpected err: actual 4 != expected 0

bpf_task_work_schedule_signal() returns -EBUSY.  On overlayfs, the
open() of /proc/self/exe calls security_file_open() twice: once for
the overlay file, and once more for the backing file through
ovl_open() -> backing_file_open() -> vfs_open().  The program runs
twice in the same task, and the second call finds the work from the
first one still pending, since it only runs on return to user space.

Act only on the first call.  The other file_open programs in the file
either don't schedule task work or don't check the result, so running
twice doesn't affect them.

Fixes: fc38f07781ca ("selftests/bpf: Test per-call site function specialization")
Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
Tested in a virtme-ng guest on bpf-next (82cc2b4383e3): file_reader
passes from overlayfs and from a tmpfs copy, and 20 times in a row
from overlayfs; without the change the subtest fails from overlayfs
and passes from tmpfs.

The patch, this text and the tests were written and run with Claude
Code; I reproduced the issue and reviewed the change.
---
 tools/testing/selftests/bpf/progs/file_reader.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/bpf/progs/file_reader.c b/tools/testing/selftests/bpf/progs/file_reader.c
index 8b972fd26d73..1318b8e0845c 100644
--- a/tools/testing/selftests/bpf/progs/file_reader.c
+++ b/tools/testing/selftests/bpf/progs/file_reader.c
@@ -28,6 +28,7 @@ char tmp_buf[256000];
 int pid = 0;
 int err, run_success = 0;
 __u64 beyond_eof_offset;
+bool done;
 
 static int validate_file_read(struct file *file);
 static int task_work_callback(struct bpf_map *map, void *key, void *value);
@@ -101,8 +102,13 @@ int on_open_non_sleepable_first(void *c)
 	int key = 0;
 	int ret;
 
-	if (bpf_get_current_pid_tgid() >> 32 != pid)
+	/*
+	 * On overlayfs, file_open runs again for the backing file, while the
+	 * work scheduled by the first call is still pending.
+	 */
+	if (bpf_get_current_pid_tgid() >> 32 != pid || done)
 		return 0;
+	done = true;
 
 	file = bpf_get_task_exe_file(task);
 	if (!file) {

---
base-commit: 82cc2b4383e3edfa1026c8612fb4e90a9329ba11
change-id: 20261120-file-reader-overlayfs-04998dda6593

Best regards,
-- 
Hang Zhengyang <hang.zhengyang1010@gmail.com>

