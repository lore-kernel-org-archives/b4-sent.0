From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Tue, 10 Nov 2026 11:04:59 +0800
Subject: [PATCH] perf parse-events: Don't report unreadable tracepoint
 globs as unknown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-tp-glob-errno-v1-1-6c2cb609c590@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQqAMAxA0atIZgNNh1a8ijhYjRqQVlIRQXp3i
 +Mb/n8hswpn6JsXlG/JkmIFtQ3M+xQ3RlmqwRrriMjgdeJ2pICsGhM6b3kiDr5zAWpzKq/y/L9
 hLOUDxtgMZV8AAAA=
X-Change-ID: 20261110-tp-glob-errno-672ea1eb786b
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794279900; l=2440;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=Z9hAImHuDRxUoABhn8rkY6eaA7NrOxV85HdeeidRhWg=;
 b=oEMG3CJWJVJ6V6xWRWQ+xm27XiPnWV0rDQ0DoRdyme5FYv07EkjpJK+G1VWdGqTW9BQg0BhdR
 mUh0IjxB4ilCbxHELMbXP4SC6lD3BUX1q/rOxu6Uy1WP8IPc765LZGY
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the events directory can't be read, a tracepoint glob like
'syscalls:*' is reported as an unknown tracepoint, with a hint about a
missing CONFIG_ option.  A plain tracepoint name reports the permission
problem instead:

  $ perf stat -e 'syscalls:*' true
  event syntax error: 'syscalls:*'
                       \___ unknown tracepoint

  Error:  File /sys/kernel/tracing//events/syscalls/* not found.

add_tracepoint_multi_sys() reports ENOENT whenever nothing matched and
ignores the error returned while reading the directories, which got
lost when this code moved to tp_pmu.c.  Report that error when there
is one.  As a normal user 'syscalls:*' now gets "can't access trace
events" and the remount hint, and perf test 5.1 is skipped again
instead of failing.

Fixes: d002aab87de8 ("perf tp_pmu: Factor existing tracepoint logic to new file")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
Found running perf test as a normal user.  Tested on perf-tools-next
13a8d580433a.  As a normal user, 'syscalls:*', 'sched:*',
'syscalls:sys_enter_open*' and '*:sys_enter_openat' now report the
permission problem, perf test 5 passes with 5.1 skipped, and the rest
of perf test is unchanged.  As root, 'nosuchsys:*' still reports an
unknown tracepoint, 'syscalls:sys_enter_open*' counts, and perf test
5.1 passes.

The issue was found and the fix and changelog drafted with Claude; I
reproduced the issue and reviewed and tested the change.
---
 tools/perf/util/parse-events.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/tools/perf/util/parse-events.c b/tools/perf/util/parse-events.c
index f3ba70d4f76b..8a6d5a13863d 100644
--- a/tools/perf/util/parse-events.c
+++ b/tools/perf/util/parse-events.c
@@ -572,8 +572,10 @@ static int add_tracepoint_multi_sys(struct parse_events_state *parse_state,
 		ret = tp_pmu__for_each_tp_sys(&args, add_tracepoint_multi_sys_cb);
 	}
 	if (args.found == 0) {
-		tracepoint_error(err, ENOENT, sys_glob, evt_glob, loc->first_column);
-		return -ENOENT;
+		if (!ret)
+			ret = -ENOENT;
+		tracepoint_error(err, ret, sys_glob, evt_glob, loc->first_column);
+		return ret;
 	}
 	return ret;
 }

---
base-commit: 13a8d580433a3b72b10be34f0e26787fe5659d3c
change-id: 20261110-tp-glob-errno-672ea1eb786b

Best regards,
-- 
Hang Zhengyang <hang.zhengyang1010@gmail.com>

