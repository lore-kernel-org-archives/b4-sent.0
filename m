From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH v2 0/6] sysctl: Move sysctls from kern_table into their
 respective subsystems
Date: Thu, 06 Mar 2025 12:29:40 +0100
Message-Id: <20250306-jag-mv_ctltables-v2-0-71b243c8d3f8@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACSHyWcC/2WNQQ7CIBQFr9L8tRhAsdSV9zCNofDborQYaIim4
 e5iE1cuZ5I3b4WIwWKEc7VCwGSj9XMBvqtAj2oekFhTGDjlgnJWk7sayJRuenGL6hxGovta4LG
 mSKWAMnsG7O1rS17bwqONiw/v7SGxr/3F5H8sMUKJNodTI1UnDW8uDwwzur0PA7Q55w/EtyoXs
 QAAAA==
X-Change-ID: 20250217-jag-mv_ctltables-cf75e470e085
To: Kees Cook <kees@kernel.org>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, Heiko Carstens <hca@linux.ibm.com>, 
 Vasily Gorbik <gor@linux.ibm.com>, 
 Alexander Gordeev <agordeev@linux.ibm.com>, 
 Christian Borntraeger <borntraeger@linux.ibm.com>, 
 Sven Schnelle <svens@linux.ibm.com>, 
 Gerald Schaefer <gerald.schaefer@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, sparclinux@vger.kernel.org, 
 linux-s390@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2670;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=BmDtc+FyqXKq5Ekj07+RwoaOM9j4PHP6W+rOCluL/1o=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfJhz0pXhCw8tJC7aq0JL8ffmfIACv+dko10
 KYUtpwbFikijokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnyYc9AAoJELqXzVK3
 lkFPtk4MAIpWsMgmVxyhJ6wKBpjaEYZOheqIKr6SQhHOLorhW96JeBB9DUG+0WdzSPAfH+NMxac
 AhYpnsugPC1HCuh1B71jLYrAakkFaL6ICRAatsS6Pt2Rm6rlmMZkcp/A8IkTiZ0jYbesFJ3fQh0
 AUdGpWYyQ18QIqQ+GR7RgT/IKnGdlMmIWNuuAKEbnNF/VoR8gPFfoCF8sJWvrpl2pV+earsiqr9
 4JpCEmwNlZbyzDuFqQNQXGsl7Men+LmxIWzynDbdaAobW8w8F8h4aHF2+RBKF2N+i1cl1p/UaLt
 CeUJ9/MzGhKA43O9yK74TmDjzqindrTkHgPh5f1DLcFGltgu1JGmZQjVAG7DtW5WZdKfiPkpS/f
 EaWJRoXEZQW1hvPsQDoe1RWGEBnn3ikZVugt998Vwozrmw/CD16lkIkl022Ds/K3IKkrDXEhaU3
 X2MIUPmf0WDi5AkBkgVNkFR6C2UcmG4I5hj7xpjAyQpd/QIwV+wijsGaG6otJ25mwxa+FwaQw35
 hw=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series relocates sysctl tables from kern_table to their respective
subsystems. To keep the scope manageable, this patchset focuses on
architecture-specific and core kernel sysctl tables. Further relocations
will follow once this series progresses.

By decentralizing sysctl registrations, subsystem maintainers regain
control over their sysctl interfaces, improving maintainability and
reducing the likelihood of merge conflicts. All this is made possible by
the work done to reduce the ctl_table memory footprint in commit
d7a76ec87195 ("sysctl: Remove check for sentinel element in ctl_table
arrays").

* Birds eye view of what has changed:
    - Archs: sparc, s390 and x86
        arch/s390/{lib/spinlock.c,mm/fault.c}
        arch/sparc/kernel/{Makefile,setup.c}
        arch/x86/include/asm/{setup.h,traps.h}
    - Kernel core:
        kernel/{panic.c,signal.c,trace/trace.c}
        kernel/events/{core.c,callchain.c}

* Testing was done by running sysctl selftests on x86_64 and 0-day.

Comments are greatly appreciated

Changes in v2:
- Dropped the perf and x86 patches as they are making their way
  upstream. Removed relevant ppl from To: and Cc: mail header.
- "ftrace:..." -> "tracing:..." for patch 3
- Moved stac_tracer_enabled to trace_stack.c instead of trace.c
- s390: fixed typo and removed the CONFIG_SMP ifdefs
- Updated trailers
- Link to v1: https://lore.kernel.org/r/20250218-jag-mv_ctltables-v1-0-cd3698ab8d29@kernel.org

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
---
Joel Granados (5):
      panic: Move panic ctl tables into panic.c
      signal: Move signal ctl tables into signal.c
      tracing: Move trace sysctls into trace.c
      stack_tracer: move sysctl registration to kernel/trace/trace_stack.c
      sparc: mv sparc sysctls into their own file under arch/sparc/kernel

joel granados (1):
      s390: mv s390 sysctls into their own file under arch/s390 dir

 arch/s390/lib/spinlock.c   |  18 +++++++
 arch/s390/mm/fault.c       |  17 ++++++
 arch/sparc/kernel/Makefile |   1 +
 arch/sparc/kernel/setup.c  |  46 +++++++++++++++++
 include/linux/ftrace.h     |   7 ---
 kernel/panic.c             |  30 +++++++++++
 kernel/signal.c            |  11 ++++
 kernel/sysctl.c            | 126 ---------------------------------------------
 kernel/trace/trace.c       |  36 ++++++++++++-
 kernel/trace/trace_stack.c |  20 +++++++
 10 files changed, 178 insertions(+), 134 deletions(-)
---
base-commit: 0ad2507d5d93f39619fc42372c347d6006b64319
change-id: 20250217-jag-mv_ctltables-cf75e470e085

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

