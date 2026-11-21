From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 21 Nov 2026 08:41:02 -0800
Subject: [PATCH v8 2/7] perf symbols: Point to the symbol name instead of
 embedding it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-perf-symbol-memory-send-v8-2-370561cbb5a7@uber.com>
References: <20261121-perf-symbol-memory-send-v8-0-370561cbb5a7@uber.com>
In-Reply-To: <20261121-perf-symbol-memory-send-v8-0-370561cbb5a7@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2165; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=X3XQyODxuaREhcHmNWercdhA15/A72ND/YbOdegAntc=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrAcmuCxVQhqj5c5cxtsJ21gBCGQlnUgsnKHgHl
 x9p+gkMARKJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawHJrhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtjBARAAjk8ev3TdlAfVl8vKlDGeut4Tu0EF4oj
 Xamwc4TT7d82OOYH56fQJC5s9cTcHlLpJnATyP/pXAQ672n0+p6DRHyeiWUNslcRyOi9B2ypzjk
 PAAqLivJvf7OFKeszVP9MBw/TlswxmPNHg+V57sJmyi0EW0M+BQ+e2E79+j4JDytT2v0nQxKidj
 b3kUAX+L/U+FcdaRRiOOwY8SEtPbtKtR3wU/oh4UCKk7AvCn+Y4gYk51GH28Qb7lHKgrQPkUTzu
 gIXJ8RXc0da4iv9rFSlXBN2S0VxqQCDpnxqTCLaLtmuv4oww/b16EwQKPzj/JmdhieBUFtLvgUz
 rF3Hyx8VTjk3uc3uRvwCY8OIXasMN2BnfpO/vDBRykztPqf6ezY159oEOEdeiI3yiBBY8mIiLE/
 NALK3GMFiy/dTPfEeY4PcxmmovF9bIQYkyhrOBmaTmQmz6Y0zeYKt4NsURKu4xaumV6V7aCK7H5
 SseaBUG7UCB8kS9m6YgkicoMBewk7q6rBl/wrvx/7I9Bd+fcEQfOoml/vlsBE5GHtZ28bhxdJfE
 plcABb50WyHyoAZG8lHR9WxpES8ssJg/2FM7K14girMcyJWNebITS8ezQKioGFf+qYzcix0BVUv
 0OC/onTlkyK9X/B8MyYPPnU9B2IwjslqatSFgjPaOsxcpBveVMr8=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch changes the name field of struct symbol from a flexible
array (char name[]) to a pointer (char *name). It does not change
behavior, but each symbol allocation grows by 8 bytes on 64-bit hosts.

The next patch creates symbols whose names are read only when needed.
perf does not know the length of such a name when it creates the symbol,
so it cannot allocate the name after the symbol. It cannot reallocate
the symbol later either, because the rb-tree and the callers hold
pointers to it. With a pointer, the name is allocated separately and set
when it is read.

Reviewed-by: Ian Rogers <irogers@google.com>
Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/ui/stdio/hist.c | 1 +
 tools/perf/util/symbol.c   | 1 +
 tools/perf/util/symbol.h   | 2 +-
 3 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/tools/perf/ui/stdio/hist.c b/tools/perf/ui/stdio/hist.c
index 3240c39bd025..45841eac6f52 100644
--- a/tools/perf/ui/stdio/hist.c
+++ b/tools/perf/ui/stdio/hist.c
@@ -106,6 +106,7 @@ static void init_rem_hits(void)
 		return;
 	}
 
+	rem_sq_bracket->name = (char *)(rem_sq_bracket + 1);
 	strcpy(rem_sq_bracket->name, "[...]");
 	rem_hits.ms.sym = rem_sq_bracket;
 }
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index a5ed8a65986b..ad4bf7685293 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -354,6 +354,7 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 
 	pr_debug4("%s: %s %#" PRIx64 "-%#" PRIx64 "\n",
 		  __func__, name, start, sym->end);
+	sym->name = (char *)(sym + 1);
 	memcpy(sym->name, name, namelen);
 
 	return sym;
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index fc98fab1c8d0..a449c170d834 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -92,7 +92,7 @@ struct symbol {
 	/** Architecture specific. Unused except on PPC where it holds st_other. */
 	u8		arch_sym;
 	/** The name of length namelen associated with the symbol. */
-	char		name[];
+	char		*name;
 };
 
 void symbol__delete(struct symbol *sym);

-- 
Git-157)

