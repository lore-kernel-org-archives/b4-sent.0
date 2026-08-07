From: Michalis Niarchos <michael.niarchos@gmail.com>
Date: Fri, 07 Aug 2026 17:08:35 +0200
Subject: [PATCH 1/2] perf kvm: Fix memory leak in process_sample_event()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-perf-kvm-leaks-v1-1-7b5e2f97905a@gmail.com>
References: <20260807-perf-kvm-leaks-v1-0-7b5e2f97905a@gmail.com>
In-Reply-To: <20260807-perf-kvm-leaks-v1-0-7b5e2f97905a@gmail.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michalis Niarchos <michael.niarchos@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786115324; l=1353;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=UAZeAebDM873C0dbCUU7lvlcAJE4j8rs08YgESgmpsA=;
 b=qtTjJiu01JaYfeHbocbCEWEI7xu5ZDiixjxUlsRwASTEx6l8a1f3WZ/OYh7JSdC4iJJbIZv2C
 IfJTtZKqDzKD4WMIUnzWL3Vo12eX/f6gsBY7hGlOoW0yWOE0Mrh8F3o
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

machine__resolve() indirectly acquires a thread reference via
machine__findnew_thread(). Release it, as suggested by the documentation
of the former.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
 tools/perf/builtin-kvm.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/tools/perf/builtin-kvm.c b/tools/perf/builtin-kvm.c
index 00baafb05603..8e7bc7b2db18 100644
--- a/tools/perf/builtin-kvm.c
+++ b/tools/perf/builtin-kvm.c
@@ -1145,7 +1145,7 @@ static int process_sample_event(const struct perf_tool *tool,
 	if (machine__resolve(machine, &kvm->al, sample) < 0) {
 		pr_warning("WARNING: at offset %#" PRIx64 ": fail to resolve address location, skipping sample\n",
 			   sample->file_offset);
-		return 0;
+		goto out;
 	}
 
 	thread = machine__findnew_thread(machine, sample->pid, sample->tid);
@@ -1153,13 +1153,16 @@ static int process_sample_event(const struct perf_tool *tool,
 		pr_debug("problem processing %s (%u) event at offset %#" PRIx64 ", skipping it.\n",
 			 perf_event__name(event->header.type), event->header.type,
 			 sample->file_offset);
-		return -1;
+		err = -1;
+		goto out;
 	}
 
 	if (!handle_kvm_event(kvm, thread, sample))
 		err = -1;
 
 	thread__put(thread);
+out:
+	addr_location__exit(&kvm->al);
 	return err;
 }
 

-- 
2.55.0

