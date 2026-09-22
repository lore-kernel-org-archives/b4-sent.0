From: Jaidev Shastri <jaidevshastri@vt.edu>
Subject: [PATCH 0/3] perf/core: order three publications against their
 readers
Date: Mon, 21 Sep 2026 21:13:23 -0400
Message-Id: <20260921-mb-perf-core-v1-0-ac56a719c02b@vt.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADPWsWoC/yXMzQ6CMBAE4Fche3ZNfxSir0I8bNdFamIhWyUmh
 He3xeM3mZkVsmiUDNdmBZUl5jilAntogEdKD8F4LwZnXGsuzuIr4Cw6IE8qeDZtR5aCZ/JQJrP
 KEL/7XX/7O3/CU/hdP2ojUBYMSonHGu1cuqNH5RNs2w82YdNekAAAAA==
X-Change-ID: 20260921-mb-perf-core-5067a1ab3ca3
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039609; l=1596;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=Nb54YeIaV3E3NlTttD9OOWd6wAuG/Hsz8+JaRWecMqg=;
 b=Qufw9awzqgW30NW3R8Rvt7FlPangeXfqjc1Vcsvx28UERBU41CkZExuqs2IpSdYBKslMa56IO
 kxQ9Kj0rPauCTreGFniqP/ZsiyGykJKBMTxqcUMbkBZRfw4d8BzJnw4
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three plain publications in kernel/events/core.c are read by paths running on
other CPUs: the aux_output link set in perf_get_aux_event() and read from the
PMU interrupt, the guest callbacks installed by
perf_register_guest_info_callbacks() and tested through perf_guest_state()
before perf_guest_get_ip() is called, and perf_event_cache read by
free_event_rcu().

The guest callback case is the one with a visible symptom. Without
CONFIG_HAVE_STATIC_CALL, which arm64 selects only under CFI, a static call is
a plain load of key->func, so a PMI on another CPU can observe the new state
callback while get_ip still resolves to the RET0 default and report an
instruction pointer of zero for a guest sample. The callees are now installed
before the gate, separated by a write barrier.

The other two are ordered in practice by the ctx->lock hand-off at schedule-in
and by initialisation order, and those patches make the publication explicit.

Found with MBCheck, a static herd7-based memory consistency checker.
Compile-tested on arm64 with W=1, no new warnings.

---
Jaidev Shastri (3):
      perf/core: publish the aux_event link with release semantics
      perf/core: install the guest callbacks before the guest_state gate
      perf/core: publish perf_event_cache with release semantics

 kernel/events/core.c | 28 ++++++++++++++++++++++------
 1 file changed, 22 insertions(+), 6 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-perf-core-5067a1ab3ca3

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

