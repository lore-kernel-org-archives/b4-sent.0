From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 13 Nov 2026 21:09:07 -0800
Subject: [PATCH v7 2/4] perf symbols: Point to the symbol name instead of
 embedding it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-perf-symbol-memory-send-v7-2-d992eced9f9c@uber.com>
References: <20261113-perf-symbol-memory-send-v7-0-d992eced9f9c@uber.com>
In-Reply-To: <20261113-perf-symbol-memory-send-v7-0-d992eced9f9c@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Alexei Starovoitov <ast@kernel.org>, 
 Andrii Nakryiko <andriin@fb.com>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2165; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=5Vgr4AxcBlLUBP0rquFzxB5nBuvrWCjr8gPD/q+/iIM=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBq9+0kmE9p4X1qwosXQYvGbY/ESDG0k6M0O/a2O
 h07TLHfpFmJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCavftJBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtj5cg/8DrWyiGSKdMn5ny8I4L32N9i9rMFVWJe
 9rzqbhMoZHy8b3Ikza7w1l0GHwfrw3hDawLx9VsBxgcI20UVnSIX9+V8YuvXCJU4NtgmiiV9tA7
 mPvmqNqDbroRXTwcqLIpLw50y/lCcl8+daWCMOxAW0kKZ6D9M70Y6I6BnAzNIUd22QB1AGWpJ7A
 ufW3lhViVaOK08s9E/NUOm2iwMaNnmTuI/i9oX36Fk/Ekmsfz2vFSiV7TU6ZwA+fEWBoxw6tzon
 teK6a+jse422nrfYjyAKk1GQr0nIGh5oUt62uraph/TZUivbYyHWNrbeifeKdxEwte/K0JlMcBx
 7Ce1u9lLJXQaFSV7594xMJ4gOiw0+3qCf4UtaOfkqawtvTf3tTu5c8rFcUYns2O57axD7+zQgQH
 d/azPVw+x4XXDzBF0dh807L3uaDFb6b3ur0EkBCDZz1Xc1M4BQdEzsnG1YmDhnkrg6L9u9k/F6E
 e9z0dPAxgf57cdvVEPY6ZD5eKIDt5aEtwD6eB8dK5kyH8QsOoTPvr4fGqrmN37i9g5bFlG6Xqq6
 gfGk0ylbip1oiw8ZENTUSivU8E92P3Lv5mdDwjsKf7OcE8+6DXTNda9fYSLogs0MofWizpuNoET
 hJNAssTEYvbREOIDrVVTn7zUaMj4hvCS+ltbHEho64fOBn0nEy4o=
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
index 8c4c8925df2c..c65e3aa73a13 100644
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
index 2d611c05d000..02c077d7e2a6 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -362,6 +362,7 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 
 	pr_debug4("%s: %s %#" PRIx64 "-%#" PRIx64 "\n",
 		  __func__, name, start, sym->end);
+	sym->name = (char *)(sym + 1);
 	memcpy(sym->name, name, namelen);
 
 	return sym;
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index ae7ede8f6070..c8b94f54f0e6 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -93,7 +93,7 @@ struct symbol {
 	/** Architecture specific. Unused except on PPC where it holds st_other. */
 	u8		arch_sym;
 	/** The name of length namelen associated with the symbol. */
-	char		name[];
+	char		*name;
 };
 
 void symbol__delete(struct symbol *sym);

-- 
Git-157)

