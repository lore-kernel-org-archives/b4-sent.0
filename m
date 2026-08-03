From: Michalis Niarchos <michael.niarchos@gmail.com>
Date: Mon, 03 Aug 2026 12:33:20 +0200
Subject: [PATCH 1/4] perf tools: Fix memory leak in cmd_kvm()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-perf-kvm-fixes-v1-1-a5db849ac973@gmail.com>
References: <20260803-perf-kvm-fixes-v1-0-a5db849ac973@gmail.com>
In-Reply-To: <20260803-perf-kvm-fixes-v1-0-a5db849ac973@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785753204; l=909;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=pkvE3n3gTEaq2KuDwi9uZbKHwl+KAztpvrJQ/tTLtCs=;
 b=WNwQczX2dy1XjwQwopzjgQDoEkFVdosmmiIGscy2JIeCAu4XCNQ7KYP8ZjihRf+4Nog+608gw
 PVbVva6K74YCcQRQECSbghjCfKM6mnjXf77YXFqN1BINueMxS0ASA4l
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

filename may get allocated by get_filename_for_perf_kvm(), but is
never freed. Use string literals to remove the need for freeing.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
 tools/perf/builtin-kvm.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/tools/perf/builtin-kvm.c b/tools/perf/builtin-kvm.c
index 394302ebdb16..44c6998f2ee5 100644
--- a/tools/perf/builtin-kvm.c
+++ b/tools/perf/builtin-kvm.c
@@ -606,11 +606,11 @@ static const char *get_filename_for_perf_kvm(void)
 	const char *filename;
 
 	if (perf_host && !perf_guest)
-		filename = strdup("perf.data.host");
+		filename = "perf.data.host";
 	else if (!perf_host && perf_guest)
-		filename = strdup("perf.data.guest");
+		filename = "perf.data.guest";
 	else
-		filename = strdup("perf.data.kvm");
+		filename = "perf.data.kvm";
 
 	return filename;
 }

-- 
2.55.0

