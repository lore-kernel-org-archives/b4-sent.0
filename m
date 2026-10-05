From: Alireza Haghdoost <haghdoost@uber.com>
Subject: [PATCH v5 0/5] perf script: Lazy symbol loading
Date: Mon, 05 Oct 2026 10:30:30 -0700
Message-Id: <20261005-perf-symbol-memory-send-v5-0-165dceb2b049@uber.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XOTU7DMBAF4KtUXmM0nrETzIp7IBb+GVMjklR2G
 1FVuTtOkVBUqbB80pvvzUVULpmreN5dROE51zyNLZiHnQh7N76zzLFlgYAdWGXkgUuS9Tz46VM
 OPEzlLCuPUXIfUnDKBYpWtOtD4ZS/rvLr20+uJ//B4bhya2Of67GdX6dntfb+X5mVBKkiUQeMK
 kH/cvJcHsM0iHVkxi1j7zPYGG2Nf0oALvbhhqENg398Q40h1oykA3Xkbxj9yygAvM/oxoAzFr1
 HQ5Y3zLIs3/aeJdekAQAA
X-Change-ID: 20260915-perf-symbol-memory-send-e7cfca1ac3d9
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5138; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=w34ZdHPq0ui1Un6FPxOcyWKvK+hADeprzI+FvSObBlA=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqw98fs97yYKaQAVOcmvTLWgA706WtYj/4pQh7f
 XRcOxVS5jSJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCasPfHxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtgMrw//cHu4+95taSBQ/UGZlB4Yd5RnwmuIXpN
 Ry6ljcRon3Qur8RyXEg1F5iLMJxU5kzy/xiAhKTOccI6Nb/1TQMSkF9i1E26Lxl6BAUYKOpif+K
 r+1IaG7SsyMIRLD/a8fa9g7oVIOtrvVPeZrkkgklFz1SnVq6In8ChUVYB0Go5h/0rGlxEmPLuyo
 VXPN5R7FEg0EaUIdTzgeIkiOi7xKzAIu1cK9nY81GhaVkRzqhqjK1XKzcIGYQ3YhWg1yRHEGaM9
 f9uw2ZTwKH5J8kYd+QqCysG3yiWKh30FkINm+B3UbfESMgG0yYhY1F3ajGIQpSPKJpxkEHk8Xcv
 lvcT3LYunHkCjDcH9pp9e9V/L2MdJn8f2b3dBGtbKvK7LjvK5bIMLeCMls9KZ4Qh6oAK6mU8O6w
 gECmGPe7+5JUqdH8LoJqRDpKB6UbZrhdtAvsKNYp5ZZe0pUThsV8XhOgDdWE6ewpr9hL1cOLiWu
 QON5lntGAQi8dbiAK2DDExzxbJX4g8N22mUHcytdWgIugQPqyFjP3lAxd6ccTv7JaSoi+7xCijv
 wLLIM5KCYBbCjaXYPNzFlzD+t3gL4vbL8kMgSCuR3F89qOMAh/76a2ccby8qeH0eXBmXHRdcaXy
 Se3gZqjCga6Lmykucl2FD6Orv4M3sLGLIZR1GgXgrhQNU4U6HkgM=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf script loads the entire ELF symbol table of every DSO that appears
in a sample, allocating each symbol into an rb-tree held until process
exit. Most of those symbols are never sampled. On a large profile this
turns symbol loading into the main memory cost of perf script, and in a
memory-constrained cgroup into an OOM kill.

This series adds an opt-in lazy loader for userspace ELF DSOs, after a
regression fix and two preparatory patches:

  [1/5] Fix a broken "#ifdef ELF_C_READ_MMAP" guard so perf actually
        mmaps ELF files instead of malloc'ing section data. This is a
        standalone regression fix for 22dd1ac91a77.

  [2/5] Let a DSO read its data from one explicit file through the DSO
        data cache. This fixes the split-debuginfo case where offsets from
        the debuginfo file would be applied to the runtime image.

  [3/5] Factor duplicate-symbol selection so it works on symbol
        attributes rather than struct symbol. No functional change.

  [4/5] --lazy-load-symbols: build a compact per-DSO sorted index and
        resolve only the sampled addresses, reading names through the DSO
        data cache at lookup time.

  [5/5] Unit and shell tests.

Patches 1-3 stand on their own and can be applied first.

On a 120 second cgroup profile of a production database service (54k
samples across 11 DSOs), peak RssAnon drops from 314 MiB to 80 MiB and
wall time from 4.49 s to 3.75 s, with identical output. Memory
optimizations usually cost time; this one does not because lazy loading
skips a lot of calloc and demangle calls.

This series does not change struct symbol. The new sorted index holds
only the address range, binding, type and string-table offset of each
symbol. When a sample hits an entry, perf reads and demangles the name
and creates a normal struct symbol with the name embedded, so the rest
of perf never sees an unresolved name.

Lazy loading handles the common userspace ELF symtab/dynsym path. The
kernel, modules, PPC64 .opd and .gnu_debugdata still load eagerly, and
eager loading remains the default.

This is independent of Ian's reference counting and shrinking series
[1]. The two should complement each other: lazy loading avoids creating
symbols that are never used, and shrinking can reclaim the ones that
were.

[1] https://lore.kernel.org/all/20260928075237.3055101-1-irogers@google.com/

Changes in v5:

- Rebase onto current perf-tools-next.
- 1/5: add Ian's Reviewed-by.
- 4/5: add kernel-doc for struct dso_ondemand (Ian).
- 4/5: choose between lazy and eager lookup in dso__find_symbol() instead
  of map__find_symbol(), so direct callers also use the lazy index (Ian).
- 4/5: share one bound search between the lower- and upper-bound callers,
  and say why bsearch() does not fit (Ian).
- 4/5: explain the ARM Thumb bit stripping (Ian). Trim comments that
  restated the code.
- 5/5: call dso__find_symbol() directly in the lookup test, and add a
  nested range lookup test.

Previous versions:

v4: https://lore.kernel.org/all/20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com/
v3: https://lore.kernel.org/all/20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com/
v2: https://lore.kernel.org/all/20260919-perf-symbol-memory-send-v2-0-495b8f00ad7c@uber.com/
v1: https://lore.kernel.org/all/20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com/

---
Alireza Haghdoost (5):
      perf symbols: Fix broken ELF_C_READ_MMAP fallback guard
      perf dso: Allow reading DSO data from an explicit file
      perf symbols: Factor out duplicate symbol selection
      perf script: Add --lazy-load-symbols for lazy symbol loading
      perf test: Test lazy symbol loading

 tools/perf/Documentation/perf-script.txt           |   9 +
 tools/perf/arch/powerpc/util/sym-handling.c        |   6 +-
 tools/perf/builtin-script.c                        |   2 +
 tools/perf/tests/Build                             |   1 +
 tools/perf/tests/builtin-test.c                    |   1 +
 tools/perf/tests/dso-data.c                        |  42 +
 tools/perf/tests/shell/lazy_load_symbols_parity.sh | 326 ++++++++
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 185 +++++
 tools/perf/tests/symbol-lazy.c                     | 760 +++++++++++++++++
 tools/perf/tests/tests.h                           |   1 +
 tools/perf/util/dso.c                              |  54 +-
 tools/perf/util/dso.h                              |  82 ++
 tools/perf/util/map.c                              |   5 +-
 tools/perf/util/symbol-elf.c                       | 920 +++++++++++++++++++++
 tools/perf/util/symbol-minimal.c                   |   9 +
 tools/perf/util/symbol.c                           |  61 +-
 tools/perf/util/symbol.h                           |  25 +-
 tools/perf/util/symbol_conf.h                      |   1 +
 18 files changed, 2459 insertions(+), 31 deletions(-)
---
base-commit: 1dc462fc214907671600172280c2e79ef9fe6fcf
change-id: 20260915-perf-symbol-memory-send-e7cfca1ac3d9

Best regards,
--  
Alireza Haghdoost <haghdoost@uber.com>

