From: Alireza Haghdoost <haghdoost@uber.com>
Subject: [PATCH v2 0/4] perf script: Bounded and lazy symbol loading
Date: Sat, 19 Sep 2026 19:33:55 -0700
Message-Id: <20260919-perf-symbol-memory-send-v2-0-495b8f00ad7c@uber.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7Zi2RAiuvAdhAe1UaiwlHSASw
 t0teACXL/nvvw2YoiOGe7ZBpMWxC0MCdclA9+3wJHQmMSihClHJG44ULfLqu/BGTz7EFZkGg1R
 qq1vZ6txUkOwxknWf87lufsxz9yI9HXfHonc8Jf1ML/LY/a8sEgVKk+eFICWtKB9zR/Gqg4dm3
 /cvB1OQm88AAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4316; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=4VCBXfJVofxyyT0RDxutQE8DtQhSmd5uEOtKwOdl87Y=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqr0Y2Q9+6RUrJJinzBl358kmTMnP+Mu+455/Ye
 Iqx72Y1iRmJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaq9GNhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtjUOA/+MTMiVz2HbgFHwNRXgnlndYPSfcC4Dzb
 9YEZu/BDN9qZyEMDy4tt4F/BazhhS2tlpIdjVwroeWEycB3q+9eoNCoJBY/IN/r1/8ADYjVtiWr
 JpS6V12/FWWsWtY72e8sfdp6uCQYrNL+aNprYof3DPOzFux9ELGW8pINDeAVc40U4Q8WyzELTBL
 X6c7hrisctaQydtIvMTS+7updRX/jSTIrMapVcJtQKhFL1C2ljuHC28ht6yGXS047IVa61LAyh+
 il72MkyORST+m/MllAHBk4Ki6Sn5N7XEjzMHAQV3AAd8YArbfcZDyAsBTRG8E0OV2N6/rvhPeR7
 j1wK9Bp8B5hEeITztXHBnObzo8ru5kMCKT/P5lby8Mq0ZOCLKr1VVh4yMQd6SNuoZdUZFvNUBx1
 4Y0J38O/wu9IG89gQPdloXi8YK9aydhSnY1ItcmVBnU4aFq04JyCbphMw8ZRdHWBjCP6wlBFPx1
 v9FJsdImn7BqrBOq66d9GWzqYKKMEAXfR/7Y/AX59wy69UMfzjrtbNE36yXub3afVmI4XNnG5Dt
 YVNWToEcL4gXtPlg8YyYj7+XynNjiBFsMCrwzXrMp6CWp62dRJkLBWKLNS304C2lLGodKKztUnX
 Z4+jX34eFCoiwq99aY8SIyxRzGbkX9p18PT/iPugcfPwRSktbFm0=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf script loads the entire ELF symbol table of every DSO that appears
in a sample, allocating each symbol into an rb-tree held until process
exit. Therefore, a large enough profile turns symbol loading into an
OOM kill.
This is not scalable for profiling a large cgroup with a lot of large
binaries on a production system with limited free memory.

This series adds two independent, opt-in mechanisms and a leading
regression fix they build on:

  [1/4] Fix a broken "#ifdef ELF_C_READ_MMAP" guard so perf actually
        mmaps ELF files instead of malloc'ing section data. This is a
        standalone regression fix that is introduced by 22dd1ac91a77.

  [2/4] --max-symbol-bytes <size>: a byte budget on struct symbol
        allocations (and the lazy index) enforced at the ELF symbol
        loader, degrading to [unknown] with a warning past the cap.
        An unbounded profile doesn't just risk OOM-killing itself. It
        also forces memory pressure on the whole host, pushing the kernel
        to reclaim from co-located latency-sensitive processes. Capping
        it lets the user bound that footprint up front and choose the
        trade-off explicitly.

  [3/4] --lazy-load-symbols: build a compact per-DSO sorted index and
        resolve only the sampled addresses, reading names through the DSO
        data cache at lookup time. On the production fixture, peak RssAnon
        drops from 265 MiB to 39 MiB (6.8x) and wall time from 3.1 s to
        1.85 s (1.7x). Memory optimizations usually cost time; this one
        does not because lazy loading skips a lot of calloc and demangle
        calls.

  [4/4] Shell and unit tests for both options.

Lazy loading handles the common userspace ELF symtab/dynsym path. Eager
loading remains available for dense coverage and for PPC64 .opd and
.gnu_debugdata.

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
Alireza Haghdoost (4):
      perf symbols: Fix broken ELF_C_READ_MMAP fallback guard
      perf script: Add --max-symbol-bytes to bound ELF symbol memory
      perf script: Add --lazy-load-symbols for lazy symbol loading
      perf test: Test lazy symbol loading and symbol memory limits

 tools/perf/Documentation/perf-script.txt           |  28 +
 tools/perf/arch/powerpc/util/sym-handling.c        |   5 +-
 tools/perf/builtin-script.c                        |  44 ++
 tools/perf/tests/Build                             |   1 +
 tools/perf/tests/builtin-test.c                    |   1 +
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 278 ++++++++
 .../tests/shell/script_lazy_load_symbols_skip.sh   |  26 +
 tools/perf/tests/symbol-bytes.c                    | 340 ++++++++++
 tools/perf/tests/tests.h                           |   1 +
 tools/perf/util/dso.c                              |  63 +-
 tools/perf/util/dso.h                              |  49 ++
 tools/perf/util/map.c                              |  30 +-
 tools/perf/util/symbol-elf.c                       | 733 ++++++++++++++++++++-
 tools/perf/util/symbol-minimal.c                   |  17 +
 tools/perf/util/symbol.c                           | 140 +++-
 tools/perf/util/symbol.h                           |  24 +-
 tools/perf/util/symbol_conf.h                      |   2 +
 17 files changed, 1723 insertions(+), 59 deletions(-)
---
base-commit: aa18964dd64511305de0711fed912054da6f5d18
change-id: 20260915-perf-symbol-memory-send-e7cfca1ac3d9

Best regards,
--  
Alireza Haghdoost <haghdoost@uber.com>

