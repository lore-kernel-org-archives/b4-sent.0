From: Mark Amirkan <markdamirkan@gmail.com>
Subject: [PATCH v2 0/2] perf evsel: Validate cross-endian samples before
 byte swapping
Date: Thu, 03 Sep 2026 04:04:19 -0700
Message-Id: <20260903-sympwn-linux-002-final-v2-v2-0-0aee1fca1f95@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0K6dkxbSEVX3sOwKGWAMdCSFiqEc
 HcBL+DyJe+/v7KAnjCwR7Iyj5ECObuDvCTMtNo2CFTtzCSXit95CmHph4+Fjuw0A+cSarK6gyg
 BU67zqpaCG8H2/eCxpvlsv4ofh6l8oxmP4GG0FEbnl/M8isP75ycKEHAzCjOhVJmL7Nn0mrqrc
 T0rtm37AtTpQTXUAAAA
X-Change-ID: 20260903-sympwn-linux-002-final-v2-e30a8df210c1
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788433501; l=1879;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=fjTgsBxrgzCHCQ91O9VNEkGJ05DbXsonzo80saT7PMk=;
 b=GpM47J3aBt0a9DqS1ASyqN8OypFVI95A2mbLkewsLzx9dio0alYw/4LnMDxNyc4d1utR2ynbE
 4YbH83CSykhD+DCIwF8V3HDNEeN8uHKdr7err1DcrwNpeaezl8hTpYq
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two paths in __evsel__parse_sample() use values from an
opposite-endian perf.data record to modify the record before checking that
the data fits within event->header.size.

Patch 1 checks the complete branch stack before swapping entry flags.
Patch 2 checks the RAW payload and the complete 64-bit words touched by
mem_bswap_64() before swapping the data.

The malformed branch-stack and RAW records reproduce as out-of-bounds
reads and writes. Each patch adds a Sample parsing regression test that
checks rejected records do not modify data past the declared event.

Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
Changes in v2:
- Add the adjacent PERF_SAMPLE_RAW fix found during v1 review.
- Keep the branch-stack fix unchanged.
- Link to v1: https://patch.msgid.link/20260903-sympwn-linux-002-final-v2-v1-1-7c6e4166b814@gmail.com

To: Peter Zijlstra <peterz@infradead.org>
To: Ingo Molnar <mingo@redhat.com>
To: Arnaldo Carvalho de Melo <acme@kernel.org>
To: Namhyung Kim <namhyung@kernel.org>
To: Mark Rutland <mark.rutland@arm.com>
To: Alexander Shishkin <alexander.shishkin@linux.intel.com>
To: Jiri Olsa <jolsa@kernel.org>
To: Ian Rogers <irogers@google.com>
To: Adrian Hunter <adrian.hunter@intel.com>
To: James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Mark Amirkan (2):
      perf evsel: Validate branch stack before byte swapping
      perf evsel: Validate RAW sample before byte swapping

 tools/perf/tests/sample-parsing.c | 109 ++++++++++++++++++++++++++++++++++++++
 tools/perf/util/evsel.c           |  20 +++----
 2 files changed, 120 insertions(+), 9 deletions(-)
---
base-commit: aadea57f532882d8bab444646863c7ef8a778ff1
change-id: 20260903-sympwn-linux-002-final-v2-e30a8df210c1

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

