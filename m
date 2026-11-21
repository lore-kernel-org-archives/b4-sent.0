From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 21 Nov 2026 14:25:23 -0800
Subject: [PATCH] perf dso: Stay in perf's mount namespace for cached
 debuginfo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-perf-dso-ns-fix-v1-1-897322ddadf8@uber.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QpAQBCF4VfRXJva2UR5FbnAzjIulnaQkne3u
 PxOnf8C5SisUGcXRD5EZQkJlGcwTF0YGcUlgzW2JLKEK0ePThcMil5OLLqKemdN6U0B6bVGTvN
 XbNrfuvczD9ubgft+AGy1nlRzAAAA
X-Change-ID: 20261121-perf-dso-ns-fix-4a71bd206f04
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: Arnaldo Carvalho de Melo <acme@redhat.com>, 
 linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2111; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=EAXOQVOAn0fKpuNLh46HZnF+G1un7kl6r1BJ6M/WW0w=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrAhpki5k3op5BAKR22CQszWu6em9YTI3ai3BcO
 t0Wg6G5IgCJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawIaZBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtj8aBAAjJRK/Cjl5VXdRA1uhCypbwd/MdJJQ/C
 dWwRCO099FA6UsipOzsqWHUITdWr7dYjq3A0hYw0d/ReXxsWJaThQ80DLQlXOfnbJcO/T1wl6ep
 EeI1ww3x+amOB4o5vZAwys5IqSnXQybDCuizX3hwXd2vLEkjSpuDOyVDzijP476g+BW9JxY+IOc
 d4m5A1CSYXh91maGUFjKyLGrdN5PWBLT8yyH9D90QaJt8njtZWKerYvfAVBFUx0zhsI/occ+eIv
 +kCEXjZrqnL/0C3IhWDuTkdRC4ZNXKOkFQZyvrzzkOKg3M31BzE3kiH0ENmYRyydjcYeuxaqY3q
 DGVmXLjWeTykhBLTvnt3cy4I24j7t5PdnXXOQLiL5CQJeDHv5tTq1xnscNY0Vvi6NitXhdu4IBF
 WZ6s+ntYgDOM8M2vctBKmfZeigblNwdO29aKpNbjVlluwxqe63z5jcvZf0/83i8EprFVURQRPgO
 30OOGZ5jwYfoxAu94N83N4MP0NDnlGklO6TWtynqk4d3hx075YXQ/Pwl+RvDp5aOrtan9jt26sp
 mIVYtIqzB8O8I0vGmzqa3LOHQ5e9NycnKXLvq72Nyg6K3HWre8n8YgZsywdS+TzTUM0nOTtD0Ed
 YBiE1QysirCqXncOeaYAXQq5zlnIvbJobgbsc8Z3UiUN6ff5YQVc=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When perf reads the data of a DSO that belongs to a process in another
mount namespace, open_dso() enters that namespace to open the file. It
does not do this for files in perf's own build-id cache, but it only
checks for DSO_BINARY_TYPE__BUILD_ID_CACHE.

Cached debuginfo files (DSO_BINARY_TYPE__BUILD_ID_CACHE_DEBUGINFO) are
in the same build-id cache, yet open_dso() looks for them in the
target's namespace. The file is usually not there, so for example
perf script -F +insn prints no instruction bytes. If a file with the
same path does exist there, perf reads the wrong file.

This patch skips the namespace switch for both build-id cache types, as
dso__load() already does.

Fixes: 5363c306787c ("perf symbol: Set binary_type of dso when loading")
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
Found while working on lazy symbol loading [1]. It does not depend on
that series.

[1] https://lore.kernel.org/all/20261121-perf-symbol-memory-send-v8-0-370561cbb5a7@uber.com/
---
 tools/perf/util/dso.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index e46cd614eb21..6aad25e9d4f5 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -707,14 +707,17 @@ static int open_dso(struct dso *dso, struct machine *machine)
 {
 	int fd;
 	struct nscookie nsc;
+	enum dso_binary_type bt = dso__binary_type(dso);
+	bool nsenter = bt != DSO_BINARY_TYPE__BUILD_ID_CACHE &&
+		       bt != DSO_BINARY_TYPE__BUILD_ID_CACHE_DEBUGINFO;
 
-	if (dso__binary_type(dso) != DSO_BINARY_TYPE__BUILD_ID_CACHE) {
+	if (nsenter) {
 		mutex_lock(dso__lock(dso));
 		nsinfo__mountns_enter(dso__nsinfo(dso), &nsc);
 		mutex_unlock(dso__lock(dso));
 	}
 	fd = __open_dso(dso, machine);
-	if (dso__binary_type(dso) != DSO_BINARY_TYPE__BUILD_ID_CACHE)
+	if (nsenter)
 		nsinfo__mountns_exit(&nsc);
 
 	if (fd >= 0) {

---
base-commit: bb27ddbaee56536fb8df0a24f07b526766dfe131
change-id: 20261121-perf-dso-ns-fix-4a71bd206f04

Best regards,
--  
Alireza Haghdoost <haghdoost@uber.com>

