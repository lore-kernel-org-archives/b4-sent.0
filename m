From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Wed, 11 Nov 2026 09:48:50 +0800
Subject: [PATCH v2] perf parse-events: Don't report unreadable tracepoint
 globs as unknown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-tp-glob-errno-v2-1-ca45efb07d31@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMQQrCMBCF4auUWTuSCZhaV95Dumji2A60SUlKU
 Erubuze5f/gfTskjsIJbs0OkbMkCb6GPjXgpsGPjPKsDVppQ0QKtxXHOVjkGH1A02oeiG17NRb
 qZ438kvfhPfrak6QtxM/BZ/qt/6RMSGicdtaozl06dR+XQeazCwv0pZQvcthdzqoAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794361735; l=2091;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=oKOhzpzzihzjzROHP90IK3skpmdwiZ3od9qtUe5u8x0=;
 b=X16E1srTe/q4EZ1klblgXdNEd7t6M0s9GxwKTspiFMc3meJyyDw7zwYCiW72kql09RdtaBgze
 FAH1G29AinGAnydJqtp1/bdG2+cEBUnrugBG89z7HnMtlYT7dfFzdwa
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As a normal user, a tracepoint glob gets the wrong error:

  $ perf stat -e 'syscalls:*' true
  event syntax error: 'syscalls:*'
                       \___ unknown tracepoint

  Error:  File /sys/kernel/tracing//events/syscalls/* not found.
  Hint:   Perhaps this kernel misses some CONFIG_ setting to enable this feature?.

add_tracepoint_multi_sys() returns ENOENT when nothing matched and
drops the error from reading the directories.  Return that error
instead, so the glob reports what a plain tracepoint name does:

  $ perf stat -e 'syscalls:*' true
  event syntax error: 'syscalls:*'
                       \___ can't access trace events

  Error:  No permissions to read /sys/kernel/tracing//events/syscalls/*
  Hint:   Try 'sudo mount -o remount,mode=755 /sys/kernel/tracing/'

Fixes: d002aab87de8 ("perf tp_pmu: Factor existing tracepoint logic to new file")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
Thanks for the review, Ian.
---
Changes in v2:
- Show the output after the fix (Ian)
- Link to v1: https://lore.kernel.org/r/20261110-tp-glob-errno-v1-1-6c2cb609c590@gmail.com
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

