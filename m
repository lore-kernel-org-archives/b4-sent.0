From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Wed, 21 Oct 2026 10:56:19 +0800
Subject: [PATCH] perf timechart: Fail IO recording when no syscall
 tracepoint is available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-timechart-io-no-tp-v1-1-71779e7db01e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAfyX23IKP6PUr0UFsqz2koRKB+O9Jx
 2GYyRApMEWYmwyBHo7sXQXZNmBP4w5C3iqDEqqXQklMfFE1ISF7dB7TjZ3UgzWDHu2koIZ3oJ3
 ff7qspXxbF1oWZAAAAA==
X-Change-ID: 20261021-timechart-io-no-tp-4137ca738c92
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Stanislav Fomichev <sdf@fomichev.me>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792551380; l=3030;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=oqWV2I1IZHKBOUj20ITS6+0GsuHEqAmhyLX9MrxOjlE=;
 b=VkXSHYDY5SISGSSN5JPI6RK0QVYT1vneV932Dk9h/zRPHKY/kbK/9Y/eMYCtXYqNMU2TvW7fv
 BVQgX75/DEhDyiBl4M9QFWhykVlU5Gn8wa/7+ZvLdMgacPCdffRyIsb
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'perf timechart record -I' skips the syscall tracepoints that are not
available.  When none is, e.g. tracefs is not readable or the kernel lacks
CONFIG_FTRACE_SYSCALLS, perf record falls back to its default event and
succeeds, and 'perf timechart' later fails with a misleading message:

  No trace sample to read. Did you call 'perf timechart record'?

Fail at record time instead, reporting why like parse_events() does.

Fixes: b97b59b93d10 ("perf timechart: Implement IO mode")
Assisted-by: LLM
Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
Found because the IO-only case of 'perf test timechart' fails as a
normal user; it is now skipped.  Tested as a normal user and as root
(all three cases pass).  The fix and changelog were drafted with an AI
assistant; I reproduced the issue, reviewed and tested the change.
---
 tools/perf/builtin-timechart.c | 35 +++++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/tools/perf/builtin-timechart.c b/tools/perf/builtin-timechart.c
index 9eb335d9db16..69cc89232d6c 100644
--- a/tools/perf/builtin-timechart.c
+++ b/tools/perf/builtin-timechart.c
@@ -9,8 +9,10 @@
  */
 
 #include <errno.h>
+#include <fcntl.h>
 #include <inttypes.h>
 #include <stdlib.h>
+#include <unistd.h>
 
 #include "builtin.h"
 #include "util/color.h"
@@ -28,6 +30,7 @@
 #include "util/header.h"
 #include <subcmd/pager.h>
 #include <subcmd/parse-options.h>
+#include <api/fs/tracing_path.h>
 #include "util/parse-events.h"
 #include "util/event.h"
 #include "util/session.h"
@@ -1793,6 +1796,30 @@ static int timechart__tui(struct timechart *tchart)
 	return ret;
 }
 
+/*
+ * None of the syscall tracepoints can be used: find out why from the
+ * syscalls event directory and explain it the way parse_events() does.
+ */
+static void timechart__io_record_error(void)
+{
+	char errbuf[BUFSIZ];
+	char *path = get_events_file("syscalls");
+	int err = ENOENT;
+	int fd;
+
+	if (path) {
+		fd = open(path, O_RDONLY | O_DIRECTORY);
+		if (fd < 0)
+			err = errno;
+		else
+			close(fd);
+		put_events_file(path);
+	}
+
+	tracing_path__strerror_open_tp(err, errbuf, sizeof(errbuf), "syscalls", NULL);
+	pr_err("No syscall tracepoints available to record IO events\n%s", errbuf);
+}
+
 static int timechart__io_record(int argc, const char **argv, const char *output_data)
 {
 	unsigned int rec_argc, i;
@@ -1922,6 +1949,14 @@ static int timechart__io_record(int argc, const char **argv, const char *output_
 		*p++ = filter;
 	}
 
+	/* With no event, perf record would silently use its default one */
+	if (p == rec_argv + common_args_nr) {
+		timechart__io_record_error();
+		free(rec_argv);
+		free(filter);
+		return -1;
+	}
+
 	for (i = 0; i < (unsigned int)argc; i++)
 		*p++ = argv[i];
 

---
base-commit: 1c90f0a3c8a1c4e38f9edd97af9e20848805a7fb
change-id: 20261021-timechart-io-no-tp-4137ca738c92

Best regards,
-- 
Hang Zhengyang <hang.zhengyang1010@gmail.com>

