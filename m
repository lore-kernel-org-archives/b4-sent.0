From: Michalis Niarchos <michael.niarchos@gmail.com>
Subject: [PATCH 0/4] perf tools: Fix memory issues
Date: Mon, 03 Aug 2026 12:33:19 +0200
Message-Id: <20260803-perf-kvm-fixes-v1-0-a5db849ac973@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc2ND3YLUojTd7LJc3bTMitRi3URD8zSDxEQDE4vEFCWgpoKiVLAEUE9
 0LIRfXJqUlZpcAjJFqbYWALrZqrdyAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785753204; l=929;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=2emraA7vYJ+V/gpaYUlHVZOozsNY0erxhiZGRizAnRk=;
 b=mlRkIPLQJGuCelVBWP8Yafg9cbOuJNC/9/LKkM2UYzC6TGgngfUOBDVIoFb7Eqqp1ysT6e9mn
 Z8uOaN264rJCHl/X3YdFpQjWYORStigeIStyKlKrrBPU5NdRXW/u6+v
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
Michalis Niarchos (4):
      perf tools: Fix memory leak in cmd_kvm()
      perf tools: Fix memory leak in kvm_events_report()
      perf tools: Fix double free and memory leak in kvm_events_record()
      perf tools: Fix memory leak in cmd_kvm()

 tools/perf/builtin-kvm.c | 63 ++++++++++++++++++++++++++++--------------------
 1 file changed, 37 insertions(+), 26 deletions(-)
---
base-commit: 2162d9b24ba1a9a402baabe5382b33e792aa074f
change-id: 20260731-perf-kvm-fixes-a17f0aa048ad

Best regards,
--  
Michalis Niarchos <michael.niarchos@gmail.com>

