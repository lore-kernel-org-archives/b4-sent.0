From: Mark Amirkan <markdamirkan@gmail.com>
Date: Thu, 03 Sep 2026 03:08:19 -0700
Subject: [PATCH] perf evsel: Validate branch stack before byte swapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-sympwn-linux-002-final-v2-v1-1-7c6e4166b814@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCQAxA0auUrA1kUhD1KuJinGY0UmOZ2Fopv
 bujLt/i/wVciorDoVmgyKSuD6sImwbSNdpFULtqYOIt7alFf9+Hl2GvNs5IxJjVYo8To7QUd13
 mQClA7YciWeff+3j628fzTdLzO4R1/QCPldH3fQAAAA==
X-Change-ID: 20260903-sympwn-linux-002-final-v2-e30a8df210c1
To: namhyung@kernel.org, acme@kernel.org
Cc: jolsa@kernel.org, peterz@infradead.org, 
 alexander.shishkin@linux.intel.com, adrian.hunter@intel.com, 
 linux-kernel@vger.kernel.org, mark.rutland@arm.com, james.clark@linaro.org, 
 mingo@redhat.com, linux-perf-users@vger.kernel.org, irogers@google.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788430131; l=3854;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=1QaosPwDGDLYOEtRj7PUXBnmCUkFKdpxpXkSjRMNBI4=;
 b=yx86HJ7Wmyz1M6NZHzsIok9mDkvy04ZT1MoIBHP15SF+miQwCAlyZrfHhILE1DPbmIL1eiJsU
 418RUu9pdcTCOfCYJI7N/6RKv7pMhkOT15NjQPYYRYkaLo2d2vC+Nsg
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When perf reads an opposite-endian branch stack, __evsel__parse_sample()
swaps each entry before checking whether all entries fit in the event. A
truncated sample can therefore make the swap loop read and write past the
event boundary.

A truncated perf.data file makes perf report crash with SIGSEGV. ASan
reports an out-of-bounds read. A regression test puts an entry just past
the declared end and shows that its flags are changed before the parser
returns -EFAULT.

Move the bounds check before the byte-swap loop. Valid samples are handled
as before.

Fixes: 63c12ae2f246 ("perf evsel: Add bitfield_swap() to handle branch_stack endian issue")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 tools/perf/tests/sample-parsing.c | 48 +++++++++++++++++++++++++++++++++++++++
 tools/perf/util/evsel.c           |  3 ++-
 2 files changed, 50 insertions(+), 1 deletion(-)

diff --git a/tools/perf/tests/sample-parsing.c b/tools/perf/tests/sample-parsing.c
index 32dbc484487a..583951534937 100644
--- a/tools/perf/tests/sample-parsing.c
+++ b/tools/perf/tests/sample-parsing.c
@@ -1,5 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 #include <stdbool.h>
+#include <errno.h>
 #include <inttypes.h>
 #include <stdlib.h>
 #include <string.h>
@@ -417,6 +418,49 @@ static int do_test(u64 sample_type, u64 sample_regs, u64 read_format)
 	return ret;
 }
 
+static int test_truncated_branch_stack(void)
+{
+	struct perf_event_attr attr = {
+		.sample_type = PERF_SAMPLE_BRANCH_STACK,
+	};
+	struct {
+		struct perf_event_header header;
+		u64 nr;
+		struct branch_entry entry;
+	} input = {
+		.header = {
+			.type = PERF_RECORD_SAMPLE,
+			.size = sizeof(input.header) + sizeof(input.nr),
+		},
+		.nr = 1,
+	};
+	struct perf_sample sample;
+	struct evsel *evsel;
+	u64 flags = 1;
+	int err;
+
+	input.entry.flags.value = flags;
+	evsel = evsel__new(&attr);
+	if (!evsel)
+		return -1;
+
+	evsel->sample_size = __evsel__sample_size(attr.sample_type);
+	err = __evsel__parse_sample(evsel, (union perf_event *)&input,
+				    &sample, /*needs_swap=*/true);
+	perf_sample__exit(&sample);
+	evsel__put(evsel);
+
+	if (err != -EFAULT) {
+		pr_debug("truncated branch stack returned %d, expected -EFAULT\n", err);
+		return -1;
+	}
+	if (input.entry.flags.value != flags) {
+		pr_debug("truncated branch stack modified data past the event\n");
+		return -1;
+	}
+	return 0;
+}
+
 /**
  * test__sample_parsing - test sample parsing.
  *
@@ -433,6 +477,10 @@ static int test__sample_parsing(struct test_suite *test __maybe_unused, int subt
 	size_t i;
 	int err;
 
+	err = test_truncated_branch_stack();
+	if (err)
+		return err;
+
 	/*
 	 * Fail the test if it has not been updated when new sample format bits
 	 * were added.  Please actually update the test rather than just change
diff --git a/tools/perf/util/evsel.c b/tools/perf/util/evsel.c
index d4cb455f4a7d..cc0bc0857754 100644
--- a/tools/perf/util/evsel.c
+++ b/tools/perf/util/evsel.c
@@ -3639,6 +3639,8 @@ int __evsel__parse_sample(struct evsel *evsel, union perf_event *event,
 			e = (struct branch_entry *)&data->branch_stack->hw_idx;
 		}
 
+		OVERFLOW_CHECK(array, sz, max_size);
+
 		if (swapped) {
 			/*
 			 * struct branch_flag does not have endian
@@ -3654,7 +3656,6 @@ int __evsel__parse_sample(struct evsel *evsel, union perf_event *event,
 				e->flags.value = evsel__bitfield_swap_branch_flags(e->flags.value);
 		}
 
-		OVERFLOW_CHECK(array, sz, max_size);
 		array = (void *)array + sz;
 
 		if (evsel__has_branch_counters(evsel)) {

---
base-commit: aadea57f532882d8bab444646863c7ef8a778ff1
change-id: 20260903-sympwn-linux-002-final-v2-e30a8df210c1

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

