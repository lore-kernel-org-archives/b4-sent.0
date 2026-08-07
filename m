From: Michalis Niarchos <michael.niarchos@gmail.com>
Date: Fri, 07 Aug 2026 17:08:36 +0200
Subject: [PATCH 2/2] perf kvm: Fix memory leak in cmd_kvm()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-perf-kvm-leaks-v1-2-7b5e2f97905a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786115324; l=579;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=bQ7xS4XFaVpnKKpn8MtN9GGFSGILFZ8PV3h9QmDPDm4=;
 b=ZEL/sEM4aOyQHDXYLa183cP3yfbP/aR9Z7x09kFLrR2Opvj8qjGUEqwryW1+OOYzK+dKokOBk
 B5H70klsqtcDuizvPnu7Msy4jezVygI2JVsfjBtKg1wapQNWaADsjF2
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set the thread private data destructor.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
 tools/perf/builtin-kvm.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/tools/perf/builtin-kvm.c b/tools/perf/builtin-kvm.c
index 8e7bc7b2db18..21cb16b10f91 100644
--- a/tools/perf/builtin-kvm.c
+++ b/tools/perf/builtin-kvm.c
@@ -2149,6 +2149,8 @@ int cmd_kvm(int argc, const char **argv)
 	if (!argc)
 		usage_with_options(kvm_usage, kvm_options);
 
+	thread__set_priv_destructor(free);
+
 	if (!perf_host)
 		perf_guest = 1;
 

-- 
2.55.0

