From: Mark Amirkan <markdamirkan@gmail.com>
Date: Thu, 03 Sep 2026 04:04:21 -0700
Subject: [PATCH v2 2/2] perf evsel: Validate RAW sample before byte
 swapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-sympwn-linux-002-final-v2-v2-2-0aee1fca1f95@gmail.com>
References: <20260903-sympwn-linux-002-final-v2-v2-0-0aee1fca1f95@gmail.com>
In-Reply-To: <20260903-sympwn-linux-002-final-v2-v2-0-0aee1fca1f95@gmail.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: Mark Amirkan <markdamirkan@gmail.com>, linux-perf-users@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788433501; l=4545;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=UB7egJdlaxZNL6OHQ6khTPm+2pfri3frePTZlRlCqf8=;
 b=ie3cYz6bQEfs+7mvYXYFFEqddNBl59PMbYh/SgBtwFegU4qnuAC341JnrdPcbmwXJi6LUG27f
 t4WHIpSRyzdAH8mL50TibG20qKsbP6WTbEOtkxTRPvdcndh+7VO3akw
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For an opposite-endian RAW sample, __evsel__parse_sample() passes the
input-controlled size to mem_bswap_64() before checking whether the
payload fits in the event. A truncated record can therefore make the helper
read and write past the event boundary.

A crafted perf.data file makes perf report crash with SIGSEGV. ASan
reports the out-of-bounds access. A regression test puts backed data past
the declared end and shows that it is changed before the parser returns
-EFAULT.

Move the bounds checks before mem_bswap_64(). Check the rounded length too,
because the helper accesses complete 64-bit words. Complete records are
handled as before.

Fixes: f9d8adb345d7 ("perf evsel: Fix swap for samples with raw data")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 tools/perf/tests/sample-parsing.c | 61 +++++++++++++++++++++++++++++++++++++++
 tools/perf/util/evsel.c           | 17 ++++++-----
 2 files changed, 70 insertions(+), 8 deletions(-)

diff --git a/tools/perf/tests/sample-parsing.c b/tools/perf/tests/sample-parsing.c
index 583951534937..bd30f6d4c31b 100644
--- a/tools/perf/tests/sample-parsing.c
+++ b/tools/perf/tests/sample-parsing.c
@@ -461,6 +461,55 @@ static int test_truncated_branch_stack(void)
 	return 0;
 }
 
+static int test_truncated_swapped_raw(u16 event_size, u32 raw_size)
+{
+	struct perf_event_attr attr = {
+		.sample_type = PERF_SAMPLE_RAW,
+	};
+	struct {
+		struct perf_event_header header;
+		union {
+			u64 value;
+			u32 words[2];
+		} raw;
+		u64 canary;
+	} input = {
+		.header = {
+			.type = PERF_RECORD_SAMPLE,
+			.size = event_size,
+		},
+		/* Parsing a pre-swapped word exchanges these two u32 values. */
+		.raw.words = { 0x12345678, raw_size },
+		.canary = 0x8877665544332211ULL,
+	};
+	struct perf_sample sample;
+	struct evsel *evsel;
+	u64 raw = input.raw.value;
+	u64 canary = input.canary;
+	int err;
+
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
+		pr_debug("truncated swapped RAW sample (size %u, raw %u) returned %d, expected -EFAULT\n",
+			 event_size, raw_size, err);
+		return -1;
+	}
+	if (input.raw.value != raw || input.canary != canary) {
+		pr_debug("truncated swapped RAW sample modified data before validation\n");
+		return -1;
+	}
+	return 0;
+}
+
 /**
  * test__sample_parsing - test sample parsing.
  *
@@ -481,6 +530,18 @@ static int test__sample_parsing(struct test_suite *test __maybe_unused, int subt
 	if (err)
 		return err;
 
+	/* The declared RAW payload extends past an otherwise aligned event. */
+	err = test_truncated_swapped_raw(sizeof(struct perf_event_header) +
+					 sizeof(u64), 16);
+	if (err)
+		return err;
+
+	/* The final complete word touched by mem_bswap_64() extends past it. */
+	err = test_truncated_swapped_raw(sizeof(struct perf_event_header) +
+					 sizeof(u32) + 9, 9);
+	if (err)
+		return err;
+
 	/*
 	 * Fail the test if it has not been updated when new sample format bits
 	 * were added.  Please actually update the test rather than just change
diff --git a/tools/perf/util/evsel.c b/tools/perf/util/evsel.c
index cc0bc0857754..ce429eb247b6 100644
--- a/tools/perf/util/evsel.c
+++ b/tools/perf/util/evsel.c
@@ -3584,7 +3584,10 @@ int __evsel__parse_sample(struct evsel *evsel, union perf_event *event,
 	}
 
 	if (type & PERF_SAMPLE_RAW) {
+		const __u64 *raw;
+
 		OVERFLOW_CHECK_u64(array);
+		raw = array;
 		u.val64 = *array;
 
 		/*
@@ -3600,16 +3603,14 @@ int __evsel__parse_sample(struct evsel *evsel, union perf_event *event,
 		}
 		data->raw_size = u.val32[0];
 
-		/*
-		 * The raw data is aligned on 64bits including the
-		 * u32 size, so it's safe to use mem_bswap_64.
-		 */
-		if (swapped)
-			mem_bswap_64((void *) array, data->raw_size);
-
 		array = (void *)array + sizeof(u32);
-
 		OVERFLOW_CHECK(array, data->raw_size, max_size);
+		if (swapped) {
+			/* mem_bswap_64() accesses complete 64-bit words. */
+			sz = roundup((u64)data->raw_size, sizeof(u64));
+			OVERFLOW_CHECK(raw, sz, max_size);
+			mem_bswap_64((void *)raw, data->raw_size);
+		}
 		data->raw_data = (void *)array;
 		array = (void *)array + data->raw_size;
 	}

-- 
Git-146)

