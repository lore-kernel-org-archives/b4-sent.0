From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Wed, 11 Nov 2026 11:54:59 +0800
Subject: [PATCH] perf stat: Count kernel events in a group led by a tool
 event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-tool-pmu-leader-v1-1-6173b5569f59@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNwQ7CIAyA4VdZOIsBNhAWY3wPs0MHnRLHmLAZE
 +O7i7O3v0m/vknG5DGTtnqThE+ffZxK8F1F7A2mK1LvShPBhOJl6BLjSOew0hHBYaJOyAE1l7U
 0hpSrOeHgX5t46f6d8LEWePkvScCcYYPb6ri5TNRMSyXMnivTmIbT8gfuMMVanK8B/Li3MZx+f
 A8ZaYngl7ay1jAJXINqDqCxBtcI67g0qgdgyPTQg1DYk+7z+QIJ9nYQ6gAAAA==
X-Change-ID: 20261111-tool-pmu-leader-d25fe8153599
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 TAKANO Mitsuhiro <takano32@gmail.com>, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794369299; l=2997;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=VvW12yxTCrB+KnTAFdjmOLOxHwodDVDySkgBau//oek=;
 b=n/Id/pDpNke3bFPw6iGLKQYWvbdCMJGdvHqkDEFmZ2pvyMptXkZ69OZPcSq/GdzE3dlsmmnfa
 Eh8jrX+40duAKZuTY85C568pvrEUK3EX8tIXfEWtgkUoPdAU8TS/vDr
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A tool event like user_time has no perf event in the kernel, but
get_group_fd() still passes its fd, the /proc/stat fd, as the group_fd
of the members.  The kernel rejects each member with EBADF and nothing
is counted:

  $ perf stat -a -e '{user_time,cycles,instructions}' -- sleep 0.05
                   0      user_time
     <not supported>      cycles
     <not supported>      instructions

Open the members with group_fd = -1, as the enable/disable code already
assumes, and don't give them PERF_FORMAT_GROUP since they are now read
on their own:

  $ perf stat -a -e '{user_time,cycles,instructions}' -- sleep 0.05
                   0      user_time
            42637254      cycles
            28279395      instructions

The kernel events in such a group are no longer scheduled together.
perf only builds these groups when the user writes them; metrics move
tool events out of their groups.

Fixes: 6828d6929b76 ("perf evsel: Refactor tool events")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
This goes on top of TAKANO's segfault fix, as asked in that thread.

With -a, this counted before 6828d6929b76 too, because the cpu mismatch
check split the group up, so the kernel events weren't scheduled
together then either.  Ian, is that fine, or would you rather have the
first kernel event lead the rest?
---
 tools/perf/builtin-stat.c | 2 +-
 tools/perf/util/evsel.c   | 4 ++++
 2 files changed, 5 insertions(+), 1 deletion(-)

diff --git a/tools/perf/builtin-stat.c b/tools/perf/builtin-stat.c
index 37752d6bfef4..59890916dcc4 100644
--- a/tools/perf/builtin-stat.c
+++ b/tools/perf/builtin-stat.c
@@ -721,7 +721,7 @@ static int create_perf_stat_counter(struct evsel *evsel,
 	 * the group read (for leader) and ID retrieval for all
 	 * members.
 	 */
-	if (leader->core.nr_members > 1)
+	if (leader->core.nr_members > 1 && !evsel__is_non_perf_event_open_pmu(leader))
 		attr->read_format |= PERF_FORMAT_ID|PERF_FORMAT_GROUP;
 
 	attr->inherit = !config->no_inherit && list_empty(&evsel->bpf_counter_list);
diff --git a/tools/perf/util/evsel.c b/tools/perf/util/evsel.c
index 560741d9599d..5a919303562a 100644
--- a/tools/perf/util/evsel.c
+++ b/tools/perf/util/evsel.c
@@ -2378,6 +2378,10 @@ static int get_group_fd(struct evsel *evsel, int cpu_map_idx, int thread)
 	if (!evsel->supported || evsel__is_group_leader(evsel))
 		return -1;
 
+	/* A userspace PMU leader has no perf event to group with */
+	if (evsel__is_non_perf_event_open_pmu(leader))
+		return -1;
+
 	/*
 	 * Leader must be already processed/open,
 	 * if not it's a bug.

---
base-commit: cc905a18a647a8e3ad42cd1596baa0e08fba26eb
change-id: 20261111-tool-pmu-leader-d25fe8153599
prerequisite-message-id: <20261023085629.1694941-1-takano32@gmail.com>
prerequisite-patch-id: b92ce8b0c6248a4af182670458912b760b98a410

Best regards,
-- 
Hang Zhengyang <hang.zhengyang1010@gmail.com>

