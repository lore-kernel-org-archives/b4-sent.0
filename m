From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:13:25 -0400
Subject: [PATCH 2/3] perf/core: install the guest callbacks before the
 guest_state gate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-perf-core-v1-2-ac56a719c02b@vt.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039609; l=2132;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=EKbfAAEuHXRbqtIgqar7H0RYkgyyMtdCwdbGpT3bE1g=;
 b=ZpaU9ZI7WaXpXDJiGjpiEAoMai0KL5ezxVwvrrROvMJEBwc+0IBlyTwqSd1W2F0D6S/fniuMh
 wzTVRlQWoAoDYA3yPvj1G9kbXzDwywaxXX1uYJwID+O076zZvPR98hn
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf_register_guest_info_callbacks() updates the __perf_guest_state
static call first and __perf_guest_get_ip and the interrupt handlers
afterwards. perf_instruction_pointer() and perf_misc_flags() test
perf_guest_state() and then call perf_guest_get_ip().

Without CONFIG_HAVE_STATIC_CALL, which arm64 selects only under CFI, a
static call is a plain load of key->func. A PMI on another CPU can then
see the new state callback while get_ip still resolves to the RET0
default, and report an instruction pointer of zero for a guest sample.

Install the callees first and the gate last, separated by smp_wmb(). The
reader keeps its control dependency.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 kernel/events/core.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/kernel/events/core.c b/kernel/events/core.c
index 7cce3fc7c..3b5c59263 100644
--- a/kernel/events/core.c
+++ b/kernel/events/core.c
@@ -7760,7 +7760,14 @@ void perf_register_guest_info_callbacks(struct perf_guest_info_callbacks *cbs)
 		return;
 
 	rcu_assign_pointer(perf_guest_cbs, cbs);
-	static_call_update(__perf_guest_state, cbs->state);
+
+	/*
+	 * perf_guest_state() is the gate the PMI paths test before they call
+	 * perf_guest_get_ip() and the interrupt handlers. On architectures
+	 * without inline static calls the updates are plain pointer stores,
+	 * so install the callees first and the gate last, behind a write
+	 * barrier.
+	 */
 	static_call_update(__perf_guest_get_ip, cbs->get_ip);
 
 	/* Implementing ->handle_intel_pt_intr is optional. */
@@ -7771,6 +7778,10 @@ void perf_register_guest_info_callbacks(struct perf_guest_info_callbacks *cbs)
 	if (cbs->handle_mediated_pmi)
 		static_call_update(__perf_guest_handle_mediated_pmi,
 				   cbs->handle_mediated_pmi);
+
+	/* Order the callee updates above before the gate below. */
+	smp_wmb();
+	static_call_update(__perf_guest_state, cbs->state);
 }
 EXPORT_SYMBOL_GPL(perf_register_guest_info_callbacks);
 

-- 
2.43.0

