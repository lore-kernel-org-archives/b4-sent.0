From: Alireza Haghdoost <haghdoost@uber.com>
Date: Wed, 28 Oct 2026 16:42:34 -0700
Subject: [PATCH v6 3/5] perf symbols: Point to the symbol name instead of
 embedding it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-perf-symbol-memory-send-v6-3-7e90415f0101@uber.com>
References: <20261028-perf-symbol-memory-send-v6-0-7e90415f0101@uber.com>
In-Reply-To: <20261028-perf-symbol-memory-send-v6-0-7e90415f0101@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2211; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=StUqBnmB7QE/x00WFgZFXRbs4qC9OsQOqq8JJSIB66s=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBq4oh2X2YhnuN8Atl7FP7ZuNj2so0EbTGJo3DCM
 B8n5IlOJIqJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCauKIdhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtjYExAAm1r7nsfEKO3RCcNzWSYQLbKzprw4Rgc
 h03jixxBalliuQYkyu+VsAhBgTiX0x2ARqszoH8ayjjh15pBGLgIKakavaybX+OmE+Sp9ih3sn8
 zLtZWA0bxz3T+HIGmsAsP/1fJC6e22JYJwFKv1hNWPBi9nlz+t1mxmyOEh1B0ePTk+C53N9E55j
 tNeYzOf7N78mi/TT9zFoD17XY5TpJHqMMbAt5IsPrVFOn4aEbd3+9j+5eUxJiPFVnU/Ff2mJmk6
 VIyoGzMNdSuaUDryBEKDerCjczivPG/xi+oEBYadNN5nNnA0jWRmslXvAsupWvleFxS9WTKO9VJ
 nGE/teWGGes3u/D1DV3M8h6K8fjZ7c/0Z5llOW+a5CF868FwAlsh/vBByzC50BLM00UWRLAWnUW
 YannlalMTPNmdfrMcoskGjddR65iamCAKtpcw4U0FG9cs5Bdm26sL0sqnhqg5buGlbqRfwUrzrR
 aLKtYoiOqIe/FF/51iP54qhIX4VnG+ihFq96QiqyTBHtLcvP9JD4up1fUAs1pfzrKjK2Wu8AXBW
 qhPb7rOOVJpDaH5qysgvBt+hQOiG62dnWQwxcN5JgRlCl/KVCK+UFSEox35KMDyncwKKwAXO5Md
 P0q98P6nDGb53Co0B2Pvjm+1Q9GgzVASs4Ae+87y+vrMdaQBtRuU=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch changes the type of the name field in struct symbol from a
flexible array (char name[]) to a pointer (char *name). It is a
refactoring and does not change behavior, but it adds 8 bytes to each
symbol allocation on 64-bit hosts.

The next patch creates symbols whose names are read only when they are
needed. When perf creates such a symbol, it does not know the length of
the name, so it cannot allocate space for the name after the symbol.
Perf also cannot allocate a larger symbol after it reads the name,
because the rb-tree and the callers keep pointers to the symbol. With a
pointer, perf can allocate the name separately and set the pointer later.

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
index d8386c4a7fc5..c231d8e4427c 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -95,7 +95,7 @@ struct symbol {
 	/** Architecture specific. Unused except on PPC where it holds st_other. */
 	u8		arch_sym;
 	/** The name of length namelen associated with the symbol. */
-	char		name[];
+	char		*name;
 };
 
 void symbol__delete(struct symbol *sym);

-- 
Git-157)

