From: Lawrence Lin <deduce@gmail.com>
Subject: [PATCH v2 0/2] ftrace: Drop weak function locations of modules
 when loading them
Date: Sun, 04 Oct 2026 14:50:59 -0500
Message-Id: <20261004-ftrace-mod-bsearch-v2-0-c1de73e72e73@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr2Jm7Zh2EERX3sOwKO0Uxgg1LRIN4
 e4C7l2+5P33J0gchRNcdhNEHiVJ6Beg/Q5sa/qGUdzCQIoKrVSGfojGMnbBYZ3YRNtinh1NWeR
 0Ys5hGT4je3lv0Vv14/Sq72yHtbQaraQhxM/2OurV+3swatR4JibvyJXK+2vTGXkcbOigmuf5C
 3BDhAvGAAAA
X-Change-ID: 20261003-ftrace-mod-bsearch-534a86527ee5
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>
Cc: Aaron Tomlin <atomlin@atomlin.com>, Stanislaw Gruszka <stf_xl@wp.pl>, 
 David Laight <david.laight.linux@gmail.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 linux-modules@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, Lawrence Lin <deduce@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791143460; l=4647;
 i=deduce@gmail.com; s=default; h=from:subject:message-id;
 bh=3Sigvhw+L/OlVihWUd9LQkEhSI+4BhYNZ1amrSocJKc=;
 b=ciZFAjAHbBLuF4fZPT+bc9C2cX3Yl0madySEtJ4UGMccuznt9mWHLS6dEjBG3CpHDMVnuaPTG
 ve4mF4ehQg/B+wiouOfd1mwUBKoGjmvJcpEBmaj/lTwv0Jvzg+28ndb
X-Developer-Key: i=deduce@gmail.com; a=ed25519;
 pk=Ws6hmG/zoco3lMoykbeaYjo9S7a6sDddQY8EALjp9cM=
X-Endpoint-Received: by B4 Relay for deduce@gmail.com/default with auth_id=1106
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Loading a module calls test_for_valid_rec() for each of its ftrace
records, and each call scans the whole module symbol table. For amdgpu
that is 16821 records against about 67000 symbols, and it delays boot by
seconds on a small machine.

v1 kept the per-record check and made it a binary search. Steve replied
that the check could go if it no longer finds anything [1]. It still does
for modules [2], so this version takes the approach proposed there: as
commit ef378c3b8233 ("scripts/sorttable: Zero out weak functions in
mcount_loc table") does for vmlinux at build time, the weak function
locations of a module are zeroed before its records are created, and
ftrace_module_enable() no longer checks each record. Patch 1 adds a
module helper that walks the symbols find_kallsyms_symbol() resolves to,
which also works while the module is still unformed. Patch 2 uses it in
ftrace_process_locs().

This replaces the v2 announced in [3], which only folded
ftrace_cmp_addr() into ftrace_cmp_ips(); that function is no longer
needed. A sorted symbol index for all module lookups, as David asked
about [4], is not needed for this either.

On a Ryzen 3 3200U (x86_64, v7.2.5, three boots each; a new set of boots,
so v1 differs slightly from the numbers in [3]):

                                  unpatched      v1      v2
  amdgpu initialized at              6.19 s  2.03 s  2.00 s
  kernel boot (systemd-analyze)      6.65 s  2.48 s  2.46 s
  modprobe radeon, median of 5       137 ms   70 ms   64 ms
  modprobe nouveau, median of 5      457 ms  125 ms  118 ms
  __ftrace_invalid_address___            18      18       0

Of the 6484 modules of that x86_64 distribution build, only kvm.ko has
weak function locations (18 of 249503 locations in total); the same holds
for ppc64le_defconfig (kvm.ko, 4 with clang and 3 with gcc). Other than
those entries, available_filter_functions is unchanged.

The rule differs slightly from test_for_valid_rec(): a location is kept
when any symbol of the module lies at most FTRACE_MCOUNT_MAX_OFFSET before
it, without checking that the symbol is in the same module memory region.
The two can only differ when a symbol of another memory region lies that
close before a location, that is, when two regions are at most
FTRACE_MCOUNT_MAX_OFFSET bytes apart.

Tested on x86_64 with IBT, v7.3-rc5 with and without the series, under
virtme-ng: the ftrace selftests (157 passed, 0 failed, the same
unresolved, unsupported and xfail cases on both), all eight livepatch
selftests, and loading kvm_amd (1502 kvm records before, 1484 after, none
of them invalid). Built at W=1 without warnings for ppc64le (clang with
patchable function entry and out-of-line stubs, gcc with
MPROFILE_KERNEL), ppc32 (pmac32), arm64, which does not define
FTRACE_MCOUNT_MAX_OFFSET, and x86_64 without modules. powerpc is build
tested only.

[1] https://lore.kernel.org/all/20261004050904.06a5ecab@fedora/
[2] https://lore.kernel.org/all/20261004170600.1541723-1-deduce@gmail.com/
[3] https://lore.kernel.org/all/20261004030438.434327-1-deduce@gmail.com/
[4] https://lore.kernel.org/all/20261004100030.189b1c3d@pumpkin/

---
Changes in v2:
- Zero weak function locations of modules before records are created,
  instead of looking every record up at load time (Steve).
- Add module_kallsyms_on_each_addr() to the module code (new patch 1)
  rather than reading the module symbol table from ftrace.
- Add the module maintainers.
- Link to v1: https://patch.msgid.link/20261003-ftrace-mod-bsearch-v1-1-92e2fd2d80ff@gmail.com

To: Luis Chamberlain <mcgrof@kernel.org>
To: Petr Pavlu <petr.pavlu@suse.com>
To: Daniel Gomez <da.gomez@kernel.org>
To: Sami Tolvanen <samitolvanen@google.com>
To: Aaron Tomlin <atomlin@atomlin.com>
To: Steven Rostedt <rostedt@goodmis.org>
To: Masami Hiramatsu <mhiramat@kernel.org>
To: Mark Rutland <mark.rutland@arm.com>
To: Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: linux-modules@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-trace-kernel@vger.kernel.org

---
Lawrence Lin (2):
      module: Add module_kallsyms_on_each_addr()
      ftrace: Drop weak function locations of modules when loading them

 include/linux/module.h   | 10 ++++++
 kernel/module/kallsyms.c | 44 ++++++++++++++++++++------
 kernel/trace/ftrace.c    | 82 +++++++++++++++++++++++++++++++++++++++++-------
 3 files changed, 115 insertions(+), 21 deletions(-)
---
base-commit: e767a4ea70a3992c37ed604157d32f0dfbf9b1e3
change-id: 20261003-ftrace-mod-bsearch-534a86527ee5

Best regards,
--  
Lawrence Lin <deduce@gmail.com>

