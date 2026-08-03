From: Michalis Niarchos <michael.niarchos@gmail.com>
Subject: [PATCH v2 0/4] perf tools: Fix memory issues
Date: Mon, 03 Aug 2026 15:05:39 +0200
Message-Id: <20260803-perf-kvm-fixes-v2-0-1b337189fffc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12NzQ6CMBCEX8Xs2TUtoIAn38NwWMoCq/KTFhsN4
 d0tcPP4ZWa+mcGxFXZwPcxg2YuToQ8QHQ9gWuobRqkCQ6Sii0pjjSPbGp++w1o+7JB0WisilWR
 UQRiNlrcgbO7Fzu5dPthMq2VttOKmwX63R6/X3i7PVPwv9xoV0rkqsyQnk6fxrelIXiczdFAsy
 /IDSsbn974AAAA=
X-Change-ID: 20260731-perf-kvm-fixes-a17f0aa048ad
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785762361; l=1983;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=JLIUbwO1UNZ//grQrD2xUdrkkkBP4WBa5dawTqD1mEc=;
 b=P0F/aymsVQS2AtCottU8s0vw8KWxMzzX1YSoqBBlKByBD5IQloImy3zVJ06T6offYWbY59Zjc
 EKCUo+1225pBv1EEujnkCi6c30nFDFCvAiWlS9Zi6z6O/7vpoV9o+R+
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Running:
  $ perf kvm stat record -a sleep 10

gives this output:
  [ perf record: Woken up 1 times to write data ]
  [ perf record: Captured and wrote 1.361 MB perf.data.guest ]
  double free or corruption (!prev)

In the process of resolving this, I came across some memory leaks.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
Changes in v2:
- Removed code block that was rendered dead by the
  get_filename_for_perf_kvm() change.
- Dropped invalid free() fix from kvm_events_report().
- Added double free fixes for: __cmd_record(), __cmd_report(),
  __cmd_buildid_list(), and __cmd_top(), which follow the same pattern
  as kvm_events_record().
- Link to v1: https://patch.msgid.link/20260803-perf-kvm-fixes-v1-0-a5db849ac973@gmail.com

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
Michalis Niarchos (4):
      perf tools: Fix memory leak in cmd_kvm()
      perf tools: Fix double free and memory leak in kvm_events_record()
      perf tools: Fix memory leak in cmd_kvm()
      perf tools: Fix double frees and memory leaks in cmd_kvm()

 tools/perf/builtin-kvm.c                         | 99 +++++++++++-------------
 tools/perf/util/kvm-stat-arch/kvm-stat-powerpc.c |  4 +-
 tools/perf/util/kvm-stat-arch/kvm-stat-x86.c     | 10 +--
 3 files changed, 50 insertions(+), 63 deletions(-)
---
base-commit: a1ed064cb4db70af8c4177b3805ca5b8b0be567e
change-id: 20260731-perf-kvm-fixes-a17f0aa048ad

Best regards,
--  
Michalis Niarchos <michael.niarchos@gmail.com>

