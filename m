From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:13:24 -0400
Subject: [PATCH 1/3] perf/core: publish the aux_event link with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-perf-core-v1-1-ac56a719c02b@vt.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039609; l=2045;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=Hy0/fktxi3buuF66+I6+QW/1V+ole54AgH7uVyKIW/c=;
 b=qTk3z/ml5HJ1ZgNOvAaiiTN6s5dcMJurLA/dd6L/hXaZ5pFrdMDyzkTnWMC/UqtkzGQ5YsYKr
 h/0ZpyMn9NrCpIXOgzFsu8ubcFfW+7EAoeqsiAm7lTCfZ/Hmttj+k1c
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf_get_aux_event() links an aux_output event to its group leader with
a plain store to event->aux_event once the leader has been validated.
perf_aux_output_begin() and the AUX sample path read the link with plain
loads, from the PMU interrupt on the CPU the event is scheduled on.

Store the link with smp_store_release() and read it with
smp_load_acquire(), so that a reader that sees the link also sees the
state of the leader it points at.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 kernel/events/core.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/kernel/events/core.c b/kernel/events/core.c
index db7b76d6b..7cce3fc7c 100644
--- a/kernel/events/core.c
+++ b/kernel/events/core.c
@@ -2332,7 +2332,8 @@ static int perf_get_aux_event(struct perf_event *event,
 	 * group in torn down, the aux_output events loose their
 	 * link to the aux_event and can't schedule any more.
 	 */
-	event->aux_event = group_leader;
+	/* Pairs with the smp_load_acquire() in the AUX output paths. */
+	smp_store_release(&event->aux_event, group_leader);
 
 	return 1;
 }
@@ -7974,7 +7975,8 @@ static unsigned long perf_prepare_sample_aux(struct perf_event *event,
 					  struct perf_sample_data *data,
 					  size_t size)
 {
-	struct perf_event *sampler = event->aux_event;
+	/* Pairs with the smp_store_release() in perf_get_aux_event(). */
+	struct perf_event *sampler = smp_load_acquire(&event->aux_event);
 	struct perf_buffer *rb;
 
 	data->aux_size = 0;
@@ -8046,7 +8048,8 @@ static void perf_aux_sample_output(struct perf_event *event,
 				   struct perf_output_handle *handle,
 				   struct perf_sample_data *data)
 {
-	struct perf_event *sampler = event->aux_event;
+	/* Pairs with the smp_store_release() in perf_get_aux_event(). */
+	struct perf_event *sampler = smp_load_acquire(&event->aux_event);
 	struct perf_buffer *rb;
 	unsigned long pad;
 	long size;

-- 
2.43.0

