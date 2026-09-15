From: Alireza Haghdoost <haghdoost@uber.com>
Subject: [PATCH 0/4] perf script: Bounded and lazy symbol loading
Date: Tue, 15 Sep 2026 11:42:42 -0700
Message-Id: <20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtYJ1Pmq4iHLk01YtuRqGyMv
 btVj9/h/1cwVmGDU7OC8ltMSq5wuwbo5vOVUUI1dG13aAfX48Qa0ZY0lgcmTkUXNM4B+UiRvPO
 0DwPUelKOMv/O58vf9hrvTM/vDrbtAz418Kl7AAAA
X-Change-ID: 20260915-perf-symbol-memory-send-e7cfca1ac3d9
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Andrii Nakryiko <andriin@fb.com>, 
 Alexei Starovoitov <ast@kernel.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3069; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=i2H74OGGigBmuYhmxMZk49EwD06ks5w+/N4nWC1cfPU=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqqZHFcDMfo4i4poKnBKXUWqae19aK7vTXIHbuN
 3SbRNgXOoeJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaqmRxRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtgC0Q//bawrXizVdiCBgvq8GADczq9yOkYBhXO
 fVDn+FXYxHEkN4P76MquTjAw9QKMqsXwY4lr8ECEyWNeEzG4QMWWZUdkQZX/p8p7FLv1jfpzbVB
 zXwBg33Dd72xFdTJlhreN1lbeb0OtZqbHHgz4hLyuNe8Bx0HxOuI8HvmHFiyLHZywEWligweBfh
 6H4qkrgbS6Dj7SFd//dgVtdvB8f54INWOeYx1ZaEDHCXI+gL2b37AvHyuOiwy34nXjAOeOhfY0n
 miUO4ng1xcwu+NZE5Qo4b3ckQTOQjUpamvKHjiHg/MrVAiwJRrRlah/RYucHkEQ2ZTYl2RoynQo
 ZaZz1Gexa6/goqZkvizs/s7m7WLfPrd8pKzlGY7bW5Wd6awTLRuhNJpTVXkXulDRIJdHnA3Q+Ja
 TuUAtXp0NApCqJvORUj8EfXvbg2zAyiiBFJHjosUrkMw8E2KcN+c5a79PvWqWURiExlZTb+aArf
 /TeeNxu6kRnRVp0mHuwXDVt/Ul3q6Xl9LToYICEghZo7Sj2tHsDRBsuUmCAQsaYeB8adZ7B17CE
 2gqeaq3DWp2y2dNLumhg+b/x0c/W48nVkkKJzKOS95C8YVVjXMNpZsRaA35+KrPgMbEBIvGiKLQ
 abLix8zbTr4x8z1R6X2BiLRcmjQzSsSVP2KZ6CBj3VuMmeKVQT7M=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf script loads the entire ELF symbol table of every DSO that appears
in a sample, allocating each symbol into an rb-tree held until process
exit.  Therefore, a large enough profile turns symbol loading into an OOM kill.
This is not scalable for profiling a large cgroup with a lot of large
binaries on a production system with limited free memory.

This series adds two independent, opt-in mechanisms and a leading
regression fix they build on:

  [1/4] Fix a broken "#ifdef ELF_C_READ_MMAP" guard so perf actually
        mmaps ELF files instead of malloc'ing section data. This is a
        standalone regression fix introduced by 22dd1ac91a77.

  [2/4] --max-symbol-bytes <size>: a byte budget on struct symbol
        allocations (and the lazy index) enforced at the ELF symbol
        loader, degrading to [unknown] with a warning past the cap.
        An unbounded profile doesn't just risk OOM-killing itself.  It
        also forces memory pressure on the whole host, pushing the kernel
        to reclaim from co-located latency-sensitive processes.  Capping
        it lets the user bound that footprint up front and choose the
        trade-off explicitly.

  [3/4] --lazy-load-symbols: build a compact per-DSO sorted index and
        resolve only the sampled addresses, reading names via pread()
        from the file's string table at lookup time. On the production fixture,
        peak RssAnon drops from 265 MiB to 39 MiB (6.8x) and wall time
        from 3.1 s to 1.85 s (1.7x). Memory optimizations usually cost
        time; this one does not because lazy loading skips a lot of calloc and
        demangle calls. The output is byte-identical to the default loader.

  [4/4] Documentation and a shell test.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
Alireza Haghdoost (4):
      perf symbols: Fix broken ELF_C_READ_MMAP fallback guard
      perf script: Add --max-symbol-bytes to bound ELF symbol memory
      perf script: Add --lazy-load-symbols for lazy symbol loading
      perf script: Document and test --lazy-load-symbols and --max-symbol-bytes

 tools/perf/Documentation/perf-script.txt           |  24 +
 tools/perf/builtin-script.c                        |  33 ++
 tools/perf/tests/shell/script_lazy_load_symbols.sh | 120 +++++
 tools/perf/util/dso.c                              |  10 +
 tools/perf/util/dso.h                              |  29 ++
 tools/perf/util/map.c                              |   9 +-
 tools/perf/util/symbol-elf.c                       | 561 +++++++++++++++++++++
 tools/perf/util/symbol-minimal.c                   |  11 +
 tools/perf/util/symbol.c                           |  87 +++-
 tools/perf/util/symbol.h                           |  18 +-
 tools/perf/util/symbol_conf.h                      |   2 +
 11 files changed, 875 insertions(+), 29 deletions(-)
---
base-commit: aa18964dd64511305de0711fed912054da6f5d18
change-id: 20260915-perf-symbol-memory-send-e7cfca1ac3d9

Best regards,
--  
Alireza Haghdoost <haghdoost@uber.com>

