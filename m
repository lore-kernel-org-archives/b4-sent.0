From: Alireza Haghdoost <haghdoost@uber.com>
Subject: [PATCH v3 0/6] perf script: Bounded and lazy symbol loading
Date: Fri, 25 Sep 2026 12:09:37 -0700
Message-Id: <20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNyw6CMBQFf4V07TV9CIgr/8O4oO2t1FhKWiASw
 r9bcMPGuJzknJmZRAwWI7lkMwk42mh9m0AcMqKaun0gWJ2YcMoLWrEcOgwG4uSkf4FD58MEEVs
 NWCqjalYroSuS3l1AY9+b+Xb/chzkE1W/6tZFY2Of7lt6ZOvuf2VkQIFpIQqKnBlaXgeJ4ai8I
 2tk5HtN9VvDk+ZU5fJsKK11qXaaZVk+pUMJVhYBAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6328; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=wB1IWHvfiUUxQ26hZ9avozlTFpDkKE3hhM7NvTyeO2s=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqtsg9ytl0/71RJ8EH2E1PoMloisQ0wHIB1ZH7I
 WmK8JBBvv+JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCarbIPRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtiLSw//TOpAAfPtfo1ifjvMrq/ydO2S2UiJoZ/
 g2AkOZb6V/kMOw4O/HxAwGI4ZMGNbcGKkrVBi4AW8/SSs5VtZa4+HDEOxOj0SstLgh22g8fyJqF
 NVl7xTJ9zoDmZMgldc/t+iXxhyorJ/8Omhrcqq9/jhblXdXIiyfZIQNJUQTumNvfYC+LB0erljE
 LC1rBQNDTgjIDvORyazmAFHltAe361sd9D6WqIfXwPv7R5wQYdzAMOl0zt4BMdDHz7wCyaMtl11
 kPdO4LmJFTUBKvy5RVGJNXMyplmq8XJqXo0g+tLT9NMaWa3UaJa72E4Y6hTNhzIHG3reAdQ5HH3
 Py9ao0y9L/+B/4vkL8CBxcY5UNESLhn4wfV+/5gDmpvc1itJEYY5mrtAhTGd7eyaIgbP4+aT3TW
 oZDIn4RTV1riXt/okITsKrKHlo75KLB/4H1/esVBevGMwBEp9iU5pmLygQn1Q3admU+lw4Wo7Yl
 KW/kNyXlF4sfJ7/SdZCEv7ZvyPbQBFT3HjKReI4k+5qaVMplOeGLgNeK7gQoqZg8qsQ6tPtSbyy
 r+vrs8Y4WWCshCucYz7X3NxOM+MITIL+IC+Ga2DKvGeRfjcvGVwb8H0n0nGqkufPgL0Q3rkkfXc
 hotv0+Wx/GqJZ5DNPzod0McomUbjkcE4CoP8pfftU/p/jXsZUvCo=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf script loads the entire ELF symbol table of every DSO that appears
in a sample, allocating each symbol into an rb-tree held until process
exit. Therefore, a large enough profile turns symbol loading into an
OOM kill. This does not scale to profiling a large cgroup with many large
binaries on a production system with limited free memory.

This series adds two independent, opt-in mechanisms, a leading
regression fix, and two preparatory patches:

  [1/6] Fix a broken "#ifdef ELF_C_READ_MMAP" guard so perf actually
        mmaps ELF files instead of malloc'ing section data. This is a
        standalone regression fix for 22dd1ac91a77.

  [2/6] Let a DSO read its data from one explicit file through the DSO
        data cache. This fixes the split-debuginfo case where offsets from
        the debuginfo file would be applied to the runtime image.

  [3/6] Factor duplicate-symbol selection so it works on symbol
        attributes rather than struct symbol. No functional change.

  [4/6] --max-symbol-bytes <size>: a byte budget on struct symbol
        allocations (and the lazy index) enforced at the ELF symbol
        loader, degrading to [unknown] with a warning past the cap.
        An unbounded profile doesn't just risk OOM-killing itself. It
        also forces memory pressure on the whole host, pushing the kernel
        to reclaim from co-located latency-sensitive processes. Capping
        it lets the user bound that footprint up front and choose the
        trade-off explicitly.

  [5/6] --lazy-load-symbols: build a compact per-DSO sorted index and
        resolve only the sampled addresses, reading names through the DSO
        data cache at lookup time. On the production fixture, peak RssAnon
        drops from 265 MiB to 39 MiB (6.8x) and wall time from 3.1 s to
        1.85 s (1.7x). Memory optimizations usually cost time; this one
        does not because lazy loading skips a lot of calloc and demangle
        calls.

  [6/6] Shell and unit tests for both options.

Lazy loading handles the common userspace ELF symtab/dynsym path. Eager
loading remains available for dense coverage and for PPC64 .opd and
.gnu_debugdata.

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
Alireza Haghdoost (6):
      perf symbols: Fix broken ELF_C_READ_MMAP fallback guard
      perf dso: Allow reading DSO data from an explicit file
      perf symbols: Factor out duplicate symbol selection
      perf script: Add --max-symbol-bytes to bound ELF symbol memory
      perf script: Add --lazy-load-symbols for lazy symbol loading
      perf test: Test lazy symbol loading and symbol memory limits

 tools/perf/Documentation/perf-script.txt           |  26 +
 tools/perf/arch/powerpc/util/sym-handling.c        |   6 +-
 tools/perf/builtin-script.c                        |  44 ++
 tools/perf/tests/Build                             |   1 +
 tools/perf/tests/builtin-test.c                    |   1 +
 tools/perf/tests/dso-data.c                        |  42 ++
 .../tests/shell/lazy_load_symbols_split_debug.sh   | 113 ++++
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 278 ++++++++
 .../tests/shell/script_lazy_load_symbols_skip.sh   |  26 +
 tools/perf/tests/symbol-bytes.c                    | 599 +++++++++++++++++
 tools/perf/tests/tests.h                           |   1 +
 tools/perf/util/dso.c                              |  60 +-
 tools/perf/util/dso.h                              |  47 ++
 tools/perf/util/map.c                              |  19 +-
 tools/perf/util/symbol-elf.c                       | 728 ++++++++++++++++++++-
 tools/perf/util/symbol-minimal.c                   |  16 +
 tools/perf/util/symbol.c                           | 143 +++-
 tools/perf/util/symbol.h                           |  30 +-
 tools/perf/util/symbol_conf.h                      |   2 +
 19 files changed, 2133 insertions(+), 49 deletions(-)
---
base-commit: edd8a9fe2eca009599e013a29c421c7a6b5ad1b9
change-id: 20260915-perf-symbol-memory-send-e7cfca1ac3d9

Best regards,
--  
Alireza Haghdoost <haghdoost@uber.com>

