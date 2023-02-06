From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH v2 00/19] RTAS maintenance
Date: Mon, 06 Feb 2023 12:54:16 -0600
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-0-9aa6bd058063@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANhM4WMC/x2OQQ6DIBQFr2JY9xtBsdpV79G4APqpJBQsiLUx3
 r3ociZ5mbeRiMFgJLdiIwEXE413GdilIGoU7oVgnpkJq1hdUcZBNjD5L4ZJQZhFhE/ChKB0x1E
 1Lde6J3krRUSQQTg15rVL1mY5BdRmPWOPIfNo4uzD72wv9LBHhlFKO8qrK6dl0/Z1XwMFJ+b8x
 t6tcWktjXyXyr/JsO/7H3cymp7CAAAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Kajol Jain <kjain@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Andrew Donnellan <ajd@linux.ibm.com>, Nick Child <nnac123@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=6172;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=wq37oRMfEAOKfFU8vXR47uunp3Y8BkUds7FY3ZDc+Dg=;
 b=XgsHIJnHQNmGQvEYO7aEc9fqjPmye4UN5QRmIZ0ZhykRrx3RjKlmGfPu6BZ6LnCgZPqVMA0BF
 maslNQ74aegCkp/wj5kxk4GDARMdhl1EV/jT3ON6RncRMEK6orM259H
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Proposed changes for the RTAS subsystem and client code.

Fixes that are subject to backporting are at the front of the queue.
The rest of the queue is roughly ordered with respect to maturity:
i.e. patches that have already garnered some review and discussion
precede newer, more experimental changes.

Major features:

* Static tracepoints around RTAS entry/exit.
* An allocator for work area buffers.
* A new client of the work area allocator in the form of a
  higher-level API for PAPR system parameter retrieval.
* Constant-time symbolic RTAS function token lookups.

Tested with ppc64le in PowerVM LPARs and QEMU's pseries
model. Obsolescent RTAS platforms (chrp, cell, maple) get build
coverage.

---
Changes in v2:

* Drop applied patches:
  - powerpc/rtas: document rtas_call()
  - powerpc/rtasd: use correct OF API for event scan rate
  - powerpc/rtas: avoid device tree lookups in rtas_os_term()
  - powerpc/rtas: avoid scheduling in rtas_os_term()
  - powerpc/pseries/eeh: use correct API for error log size
  - powerpc/rtas: clean up rtas_error_log_max initialization
  - powerpc/rtas: clean up includes
  - powerpc/rtas: define pr_fmt and convert printk call sites
  - powerpc/rtas: mandate RTAS syscall filtering

* Additions:
  - Safe early-boot fallback in rtas_busy_delay().
  - Fixes for missed RTAS function call retries in various places.
  - Remove RTAS timebase sync from pseries, previously posted
    separately as "powerpc/pseries: drop RTAS-based timebase
    synchronization":
    https://lore.kernel.org/linuxppc-dev/20230110042845.121792-1-nathanl@linux.ibm.com/T/#u
  - RTAS work area buffer allocator.
  - Conversion of pseries DLPAR code to work area allocator.
  - A pseries-specific PAPR system parameter API built on top of the
    RTAS work area allocator.
  - Conversion of ibm,get-system-parameter users to papr_sysparm API.
  - New rtas_function_token() API and associated conversions.

* Modifications to existing patches:
  - Convert RTAS tracepoint definitions to unconditional
    variants (TRACE_EVENT_CONDITION() -> TRACE_EVENT()), dropping a
    cpu_online() check that duplicates work already done at the call
    site.
  - Skip tracepoints in unsafe contexts (real mode, CPU
    offline). (Nicholas Piggin)
  - Use bool bitfield for "banned on LE" function flag.
  - Better documentation for "banned on LE" function flag. (Andrew Donnellan)
  - Drop unnecessary cast for xa_load() key argument. (Nick Child)

* Link to v1: https://lore.kernel.org/r/20221118150751.469393-1-nathanl@linux.ibm.com

---
Nathan Lynch (19):
      powerpc/rtas: handle extended delays safely in early boot
      powerpc/perf/hv-24x7: add missing RTAS retry status handling
      powerpc/pseries/lpar: add missing RTAS retry status handling
      powerpc/pseries/lparcfg: add missing RTAS retry status handling
      powerpc/pseries/setup: add missing RTAS retry status handling
      powerpc/pseries: drop RTAS-based timebase synchronization
      powerpc/rtas: improve function information lookups
      powerpc/rtas: strengthen do_enter_rtas() type safety, drop inline
      powerpc/tracing: tracepoints for RTAS entry and exit
      powerpc/rtas: add tracepoints around RTAS entry
      powerpc/rtas: add work area allocator
      powerpc/pseries/dlpar: use RTAS work area API
      powerpc/pseries: PAPR system parameter API
      powerpc/pseries: convert CMO probe to papr_sysparm API
      powerpc/pseries/lparcfg: convert to papr_sysparm API
      powerpc/pseries/hv-24x7: convert to papr_sysparm API
      powerpc/pseries/lpar: convert to papr_sysparm API
      powerpc/rtas: introduce rtas_function_token() API
      powerpc/rtas: arch-wide function token lookup conversions

 arch/powerpc/include/asm/papr-sysparm.h       |  38 ++
 arch/powerpc/include/asm/rtas-work-area.h     |  45 ++
 arch/powerpc/include/asm/rtas.h               | 185 +++++
 arch/powerpc/include/asm/trace.h              | 103 +++
 arch/powerpc/kernel/Makefile                  |   3 +-
 arch/powerpc/kernel/rtas-proc.c               |  24 +-
 arch/powerpc/kernel/rtas-rtc.c                |   6 +-
 arch/powerpc/kernel/rtas-work-area.c          | 208 ++++++
 arch/powerpc/kernel/rtas.c                    | 942 +++++++++++++++++++++-----
 arch/powerpc/kernel/rtas_flash.c              |  21 +-
 arch/powerpc/kernel/rtas_pci.c                |   8 +-
 arch/powerpc/kernel/rtasd.c                   |   2 +-
 arch/powerpc/perf/hv-24x7.c                   |  45 +-
 arch/powerpc/platforms/52xx/efika.c           |   4 +-
 arch/powerpc/platforms/cell/ras.c             |   4 +-
 arch/powerpc/platforms/cell/smp.c             |   4 +-
 arch/powerpc/platforms/chrp/nvram.c           |   4 +-
 arch/powerpc/platforms/chrp/pci.c             |   4 +-
 arch/powerpc/platforms/chrp/setup.c           |   4 +-
 arch/powerpc/platforms/maple/setup.c          |   4 +-
 arch/powerpc/platforms/pseries/Makefile       |   2 +-
 arch/powerpc/platforms/pseries/dlpar.c        |  29 +-
 arch/powerpc/platforms/pseries/eeh_pseries.c  |  22 +-
 arch/powerpc/platforms/pseries/hotplug-cpu.c  |   4 +-
 arch/powerpc/platforms/pseries/io_event_irq.c |   2 +-
 arch/powerpc/platforms/pseries/lpar.c         |  37 +-
 arch/powerpc/platforms/pseries/lparcfg.c      | 104 +--
 arch/powerpc/platforms/pseries/mobility.c     |   4 +-
 arch/powerpc/platforms/pseries/msi.c          |   4 +-
 arch/powerpc/platforms/pseries/nvram.c        |   4 +-
 arch/powerpc/platforms/pseries/papr-sysparm.c | 151 +++++
 arch/powerpc/platforms/pseries/pci.c          |   2 +-
 arch/powerpc/platforms/pseries/ras.c          |   2 +-
 arch/powerpc/platforms/pseries/setup.c        |  27 +-
 arch/powerpc/platforms/pseries/smp.c          |  12 +-
 arch/powerpc/sysdev/xics/ics-rtas.c           |   8 +-
 arch/powerpc/xmon/xmon.c                      |  16 +-
 37 files changed, 1660 insertions(+), 428 deletions(-)
---
base-commit: 0bfb97203f5f300777624a2ad6f8f84aea3e8658
change-id: 20230125-b4-powerpc-rtas-queue-cf85ec465ff9

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

