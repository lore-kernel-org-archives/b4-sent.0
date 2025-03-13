From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH v3 0/5] sysctl: Move sysctls from kern_table into their
 respective subsystems
Date: Thu, 13 Mar 2025 17:22:22 +0100
Message-Id: <20250313-jag-mv_ctltables-v3-0-91f3bb434d27@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD4G02cC/23N3wqCMBTH8VeJc91if9TNrnqPiJjbUVemsckox
 HdvChFRl98fnM+ZIKB3GGC/mcBjdMENfQqx3YBpdd8gcTY1cMpzypkkF92QWzybsRt11WEgppY
 5ZpIiVTmks7vH2j1W8nhK3bowDv65fohsWd+Y+sUiI5QYK4pS6UpZXh6u6HvsdoNvYNEi/wiCF
 n8EngTJKp4Jo6yo1Zcwz/MLvJ2Q0PMAAAA=
X-Change-ID: 20250217-jag-mv_ctltables-cf75e470e085
To: Kees Cook <kees@kernel.org>, Joel Granados <joel.granados@kernel.org>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, sparclinux@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2666;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=9BJrspz9yE1EjgzFvirmz3UiLOLMBPHH+mtqER++Sv4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfTBkiMKwNqoKHHDpFPfiyeQ2Fe0oUt/OEGr
 v94WKqL/HG7rIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn0wZIAAoJELqXzVK3
 lkFPvoAL/3V02KJiyAmy9V2bEiQYwDMb29ke6mz1PS2I1Hyq6bTTE+UOFqXEJK3263QufMxE1ym
 1ngbr1fQ9ayJAjPqDVxalEbAM4tm9tUipTiJBCAKrjWIXbn9c8SuonY7lcTWLzuIf9KJDOOO8MP
 ta6m3pLU+J2mbCgPqyJg0CrbyOltjxkWWK0YnyzlTA0EMNYfkTBOOKK+bHpeQdqhV/yM+444WM/
 pBDKXOb3Xtvid9OKx62BqIPJ6d0DlFf+TdmorQWitW0YtjhFJ4p8qyh5Ju5ToW/uoCYKsc8EJqU
 MC74luzxZNer3UwjAwWz0kYQimT8QvW6bGQhBLcDUL70aLr/srJ1KquVbYbGW+L8CfS0buGn9VD
 MDw79Hh9mX8QiUB/B1D5/KIVdaDEFe9IgO6TabiX3NYvJI+gUQB1iSZt2Bo8W8Sy7i1zuPRisYg
 tJDqSuvoCNPD/N/ffv96zxA7FdMtJ5SBRIpvxGyWi4cIxc8Fv2fL2LGkdUgQKwK5ER+I1ouBmr7
 uo=
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
    - Archs: sparc
        arch/sparc/kernel/{Makefile,setup.c}
    - Kernel core:
        kernel/{panic.c,signal.c,trace/trace.c}
        kernel/events/{core.c,callchain.c}

* Testing was done by running sysctl selftests on x86_64 and 0-day.

Comments are greatly appreciated

Changes in v3:
- Removed s390 from the series as it is being upstreamed through s390
  tree. Adjusted the Cc and To to reflect this.
- made stack_tracer_enabled static
- Link to v2: https://lore.kernel.org/r/20250306-jag-mv_ctltables-v2-0-71b243c8d3f8@kernel.org

Changes in v2:
- Dropped the perf and x86 patches as they are making their way
  upstream. Removed relevant ppl from To: and Cc: mail header.
- "ftrace:..." -> "tracing:..." for patch 3
- Moved stac_tracer_enabled to trace_stack.c instead of trace.c
- s390: fixed typo and removed the CONFIG_SMP ifdefs
- Updated trailers
- Link to v1: https://lore.kernel.org/r/20250218-jag-mv_ctltables-v1-0-cd3698ab8d29@kernel.org

---
Signed-off-by: Joel Granados <joel.granados@kernel.org>

---
Joel Granados (5):
      panic: Move panic ctl tables into panic.c
      signal: Move signal ctl tables into signal.c
      tracing: Move trace sysctls into trace.c
      stack_tracer: move sysctl registration to kernel/trace/trace_stack.c
      sparc: mv sparc sysctls into their own file under arch/sparc/kernel

 arch/sparc/kernel/Makefile |   1 +
 arch/sparc/kernel/setup.c  |  46 +++++++++++++++++++
 include/linux/ftrace.h     |   9 ----
 kernel/panic.c             |  30 +++++++++++++
 kernel/signal.c            |  11 +++++
 kernel/sysctl.c            | 108 ---------------------------------------------
 kernel/trace/trace.c       |  36 ++++++++++++++-
 kernel/trace/trace_stack.c |  22 ++++++++-
 8 files changed, 144 insertions(+), 119 deletions(-)
---
base-commit: 0ad2507d5d93f39619fc42372c347d6006b64319
change-id: 20250217-jag-mv_ctltables-cf75e470e085

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

