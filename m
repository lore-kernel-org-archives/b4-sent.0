From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:13:26 -0400
Subject: [PATCH 3/3] perf/core: publish perf_event_cache with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-perf-core-v1-3-ac56a719c02b@vt.edu>
References: <20260921-mb-perf-core-v1-0-ac56a719c02b@vt.edu>
In-Reply-To: <20260921-mb-perf-core-v1-0-ac56a719c02b@vt.edu>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039609; l=1494;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=9z+ZbfX8GmgFVzF7LoEQWgxvxhbbqsC/PXink/Dvp1s=;
 b=/70/JM8ao0JfXA+VcpOryBnR41mfWf9xjIYk3gz4OXDmfOP19Wd5NrCTzSFwjArTlKZ++Kqap
 tBzOO0xuW58CIFQyCix5JW7wg5t7AIPKjOJP6ASSRmcPYnqO7R4sO79
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf_event_init() creates perf_event_cache with a plain store, after the
pmu_idr has been set up. free_event_rcu() reads the pointer with a plain
load from an RCU callback on any CPU.

Store it with smp_store_release() and read it with smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 kernel/events/core.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/kernel/events/core.c b/kernel/events/core.c
index 3b5c59263..74cfb13fe 100644
--- a/kernel/events/core.c
+++ b/kernel/events/core.c
@@ -5313,7 +5313,8 @@ static void free_event_rcu(struct rcu_head *head)
 		put_pid_ns(event->ns);
 	perf_event_free_filter(event);
 	kfree(event->addr_filter_ranges);
-	kmem_cache_free(perf_event_cache, event);
+	/* Pairs with the smp_store_release() in perf_event_init(). */
+	kmem_cache_free(smp_load_acquire(&perf_event_cache), event);
 }
 
 static void ring_buffer_attach(struct perf_event *event,
@@ -15404,7 +15405,8 @@ void __init perf_event_init(void)
 	ret = init_hw_breakpoint();
 	WARN(ret, "hw_breakpoint initialization failed with: %d", ret);
 
-	perf_event_cache = KMEM_CACHE(perf_event, SLAB_PANIC);
+	/* Pairs with the smp_load_acquire() in free_event_rcu(). */
+	smp_store_release(&perf_event_cache, KMEM_CACHE(perf_event, SLAB_PANIC));
 
 	/*
 	 * Build time assertion that we keep the data_head at the intended

-- 
2.43.0

