From: Alireza Haghdoost <haghdoost@uber.com>
Subject: [PATCH v4 0/5] perf script: Lazy symbol loading
Date: Fri, 02 Oct 2026 11:45:32 -0700
Message-Id: <20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XOTQ6CMBAF4KuYrq1pO/yIK+9hXNB2KjVCSQtEQ
 ri7BTfERF2+5M33ZiIBvcVATruJeBxssK6JIdnviKrK5obU6piJYCJjBU9pi97QMNbSPWiNtfM
 jDdhoirkyquSlAl2QeN16NPa5ypfrO4de3lF1C7c0Khu6eL5OD3zp/V8ZOGWUa4CMoeCG5edeo
 j8oV5NlZBBbpvjOiMgkRSqPhrFS5+qDgQ0jfnwDkQFMUECiIAO5YeZ5fgEYXfnVXQEAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=9067; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=1buPypiXvTu/cMquRf3aPBXMbSV0t5ikFWvC350DM6g=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqv/vZOBhoQTZSFb27FxK41gdQGZ1RvgCTb8KYA
 SFmlkdvqn6JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCar/72RsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtgEZQ/9E8v7RhKtnOCibC6Xpu7TkP6324ZXAZI
 LuL49BzaNmzvNxXP9swFK2ywtHlIWJl6zNj5ORJYCNoFGavfIC3mbVZsXYzEmGaw14KaKOr3qvx
 gSlj6yUGMeT4fzxt8amgRmt8o6PvUDyFo/eiFulDMMZ2u/oZCgygvQdgn/Fb7uomreafEmAsXUE
 cE1eGKeCJmDF7YLJEba0XDI4FO4LiyDO9OruJDaUscbp6xNeFE3qlD37lXjuBpfD3HadfWHMBqS
 tHv0Az2CCd/SOGBVi2vKSE8UEE/5Fq2rBZOdne2emEpAfMPUF15j9WJBEZDYYboezqh/VsNZOJu
 t+9CFmm/2287ev0hVVUBaSssCOW+/hrJ8VyDeDXFal8SR/cMg0Plrv38AtzmkjH4MD7GNckWVbE
 B9JzP9/N6wl3HE1ffLls8mIIwNAc7BqL+Wbs0UoGt4JqXmVruTZChbCYPBvDCVbiDh2rk4ZHBlu
 O1CyfXAMS27p/rtgolVAO2sL4b2B6cvTST6k+eQ13fgEGcOa9YgtWqiqvlQH7RHT/VIHlgASjtK
 BB7bXw+bJyZVFb9lzo3fV0LHM51sGRLnG/X4y8f8xZqdy3dSAOYlk9GOafKjmazJDMQN83p5tuV
 A6X5gRXegc+ZDgrOFPXLHNn16dzIOAa9rS495CXfIxZCZTf+SvUw=
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

Changes in v4:

- Drop --max-symbol-bytes and all symbol byte accounting (Ian). PLT
  symbols are synthesized exactly as before.
- Rebase onto current perf-tools-next. dso__get_filename() now takes a
  binary type and is shared with debuginfo lookup, so 2/5 applies the
  explicit data path in __open_dso() instead.
- 3/5: explain why symbol__choose_best() and struct symbol_candidate are
  shared (Ian).
- 4/5: bound the second pass of dso__build_ondemand_index() by the count
  from the first pass, so a file that changes in between cannot overflow
  the index (Sashiko). State that materialized symbols still embed their
  names.
- 4/5: read names with the DSO lock dropped. The DSO data cache takes its
  global lock before DSO locks, so reading under the DSO lock could
  deadlock against another thread opening DSO data. Serialize name reads
  per index and free a detached index after its last reader. Check the
  source with open() and pread() at load time, and materialize IFUNCs
  then for PLT synthesis.
- 4/5: index .dynsym together with .symtab as the eager loader does;
  symbols present only in .dynsym were missing. Drop .dynsym copies of
  .symtab entries while indexing.
- 4/5: resolve an address inside nested symbols to the innermost one; an
  address past the end of the inner symbol used to miss.
- 4/5: read names from build-id cache files in perf's own mount
  namespace, where dso__load() opened them.
- 4/5: also load the runtime .dynsym of a DSO whose symbols come from
  .gnu_debugdata eagerly, so that duplicate selection sees both tables.
  It was indexed lazily, and an alias could resolve to a different name.
- 4/5: pass the IFUNC alias mark on through duplicate selection as
  symbols__fixup_duplicate() does. Marking the winner whenever any alias
  was an IFUNC could name an IRELATIVE PLT slot differently.
- 4/5: shorten the --lazy-load-symbols documentation and list the DSOs
  that always load eagerly.
- 5/5: drop the budget tests and the separate skip-status shell test.
  Rename the unit test suite to "Lazy symbol loading"; the race test now
  has address lookups racing name lookups and checks every symbol is
  materialized once. The parity test also checks the names that lazy
  lookups return, before and after materialization. Add tests for
  lookups racing DSO data reads, nested symbols, .dynsym-only symbols,
  .gnu_debugdata, IFUNC aliases and a profiled process in another mount
  namespace. Rename the split-debuginfo shell test to
  lazy_load_symbols_parity.sh, which now covers five binaries.

Link: https://lore.kernel.org/all/20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com/

Changes in v3:

- Rebase onto current perf-tools-next.
- Pick up Namhyung's Reviewed-by for patch 1.
- Split the exact-path DSO data support into its own patch (2/6), with a
  DSO data test for reading and reopening through an explicit path.
- Move the duplicate-selection refactor into a preparatory patch (3/6)
  and factor the whole lazy alias-group handling (traversal, demangling,
  IFUNC propagation, compaction) into one helper.
- Keep struct symbol::namelen as u16. Charge symbol bytes from the stored
  namelen on both allocation and free, and drop the 64 KiB-name test.
- Fix lazy-loading races reported by Sashiko: in lazy mode, address
  lookups always take the DSO lock, and building the name-sorted array
  materializes and frees the lazy index even when the budget truncates
  it, so the name array is never invalidated. dso__reset_symbol_names()
  is gone. Add a concurrent budget-truncation test.
- In lazy mode, when no PT_LOAD covers a symbol and its section is NOBITS
  in the debuginfo file, adjust with the runtime section header as eager
  loading does. Add a lazy/eager symbol parity test and a split-debuginfo
  shell test that exercises this path.
- Keep each unit test with the code it needs (DSO data in 2/6, budget
  reservation in 4/6); the other tests stay in 6/6.

Link: https://lore.kernel.org/all/20260919-perf-symbol-memory-send-v2-0-495b8f00ad7c@uber.com/

Changes in v2:

- Replace direct pread() name reads with the exact symbol source's DSO data
  cache, preserving split-debuginfo offsets and descriptor reopen behavior.
- Drop the byte-identical-output claim and retain eager loading for PPC64
  .opd and .gnu_debugdata.
- Make the symbol budget atomic and strict, account complete name lengths,
  accept a bare 0 as unlimited, and keep partial zero-sized ranges from
  covering omitted symbols.
- Align lazy lookup with eager duplicate and IFUNC selection, PLT clipping,
  and name-sorted materialization.
- Move option documentation into the feature patches. Add unit and shell
  coverage for cache reopen, truncated names, budget truncation, and skip
  handling.

Link: https://lore.kernel.org/all/20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com/

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
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 185 ++++
 tools/perf/tests/symbol-lazy.c                     | 699 ++++++++++++++++
 tools/perf/tests/tests.h                           |   1 +
 tools/perf/util/dso.c                              |  54 +-
 tools/perf/util/dso.h                              |  61 ++
 tools/perf/util/map.c                              |   7 +-
 tools/perf/util/symbol-elf.c                       | 926 +++++++++++++++++++++
 tools/perf/util/symbol-minimal.c                   |   9 +
 tools/perf/util/symbol.c                           |  52 +-
 tools/perf/util/symbol.h                           |  24 +-
 tools/perf/util/symbol_conf.h                      |   1 +
 18 files changed, 2376 insertions(+), 30 deletions(-)
---
base-commit: 705da5b15ab89ba97b11eedbe507c2fd83d31cb9
change-id: 20260915-perf-symbol-memory-send-e7cfca1ac3d9

Best regards,
--  
Alireza Haghdoost <haghdoost@uber.com>

