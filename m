From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Mon, 05 Oct 2026 16:37:40 +0700
Subject: [PATCH bpf-next] selftests/bpf: Fix wq test by changing 50us sleep
 to polling over 1s
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-wq-poll-fix-v1-1-99ce4bac59f4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MWwqAIBAAryL73YLaC7pK9NFjrYVQ0yghunvS5
 wzMPBApMEXoxAOBLo7sbAZVCJi30a6EvGQGLXWjpKzxPtC7fUfDCU3VzFW7TKORJeTCB8r6v/U
 weYOW0gnD+36q4uuHZwAAAA==
X-Change-ID: 20261005-wq-poll-fix-f46c47dbaf03
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791193062; l=1776;
 i=thamrinjonathan@gmail.com; s=20261005; h=from:subject:message-id;
 bh=PyP8WYl7h3i0e+qMKJnBwJw8uVyt/3gufaH7HZJsx30=;
 b=MV6DKh4M8wIRsCymZTo6WYAbR9zbZOVVqYVtmlHYLJIaB7/jW35tryb2G0q1SP+BfBrIUpY+G
 ge/On1jAr9bD9u04c60PfH+kXWHItLZhUcQJ4hCqB++imEzQvYjlKZH
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=QU907bIMYty/tEI/iJF2SrD1lqOf/+2B1MI1zwJ5cBw=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261005 with auth_id=1114
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wq test fails with ok_sleepable reading 0 instead of 2 as workqueue
callback hasn't executed before check.

This happens as callback runs later on a kworker and 50us isn't always
enough.

Change from 50us sleep to polling over 1s.

Before (usleep(50)): 3 fails out of 5000 runs
Diagnosing issue (usleep(0)): 23 out of 100 runs
After (Polling): 0 out of 5000 runs
Tested using vmtest on x86_64, test pinned to one CPU with `yes` load

Link: https://github.com/kernel-patches/vmtest/issues/455

Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
 tools/testing/selftests/bpf/prog_tests/wq.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/wq.c b/tools/testing/selftests/bpf/prog_tests/wq.c
index 84831eecc..b55d8547f 100644
--- a/tools/testing/selftests/bpf/prog_tests/wq.c
+++ b/tools/testing/selftests/bpf/prog_tests/wq.c
@@ -7,7 +7,7 @@
 void serial_test_wq(void)
 {
 	struct wq *wq_skel = NULL;
-	int err, prog_fd;
+	int err, prog_fd, tries;
 
 	LIBBPF_OPTS(bpf_test_run_opts, topts);
 
@@ -28,7 +28,13 @@ void serial_test_wq(void)
 	ASSERT_OK(err, "test_run");
 	ASSERT_EQ(topts.retval, 0, "test_run");
 
-	usleep(50); /* 10 usecs should be enough, but give it extra */
+	/* loop check over 1 sec to make sure it doesn't fail early when busy */
+	for (tries = 1000; tries >= 0; tries--) {
+		if (wq_skel->bss->ok_sleepable == (1 << 1))
+			break;
+
+		usleep(1000);
+	}
 
 	ASSERT_EQ(wq_skel->bss->ok_sleepable, (1 << 1), "ok_sleepable");
 clean_up:

---
base-commit: b5a4aa31abd6fe90009b63e35dc18c67d041ec0c
change-id: 20261005-wq-poll-fix-f46c47dbaf03

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

