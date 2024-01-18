From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH RFC 0/5] dump_stack: Allow runtime updates of the hardware
 description
Date: Thu, 18 Jan 2024 09:25:11 -0600
Message-Id: <20240118-update-dump-stack-arch-str-v1-0-5c0f98d017b5@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANdCqWUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0ND3dKClMSSVN2U0twC3eKSxORs3cSi5Awgs0jXPM3AwsIgxcg4zdh
 ACWhAQVFqWmYF2PBopSA3Z6XY2loA6bwz0HEAAAA=
To: "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>, 
 Brian King <brking@linux.ibm.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 John Ogness <john.ogness@linutronix.de>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Petr Mladek <pmladek@suse.com>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Steven Rostedt <rostedt@goodmis.org>
Cc: linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705591541; l=2778;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=ZrNZI/+KtaqDAeKBFPjQTAb311LBOoljbtl1LqlVqgU=;
 b=vrcF1cNPIm2O4+bieSkcw1uoqBBdSqf4JkN+kVqZt0fSLkeqYShpMyznUhC+rjw1sJEeTCg3r
 HvE7JadRlXGBBcZSgBWO/h+xHLaE9TtJfvuE3gqdy++muQ22sED6j1/
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the kernel emits a stack trace, typically it includes a hardware
description string, e.g.

  Kernel panic - not syncing: sysrq triggered crash
  CPU: 6 PID: 46433 Comm: bash Tainted: G        W          6.7.0-rc2+ #83
> Hardware name: IBM,9040-MR9 POWER9 (architected) 0x4e2102 0xf000005 of:IBM,FW950.01 (VM950_047) hv:phyp pSeries
  Call Trace:
   dump_stack_lvl+0xc4/0x170 (unreliable)
   panic+0x39c/0x584
   sysrq_handle_crash+0x80/0xe0
   __handle_sysrq+0x208/0x4bc
   [...]

This string is a statically allocated buffer populated during boot by
arch code calling dump_stack_set_arch_desc(). For most platforms this
is sufficient.

But the string may become inaccurate on the IBM PowerVM platform due
to live migration between machine models and firmware versions. Stack
dumps emitted after a migration reflect the machine on which the
kernel booted, not necessarily the machine on which it is currently
running. This is potentially confusing for anyone investigating
kernel issues on the platform.

To address this, this series introduces a new function that safely
updates the hardware description string and updates the powerpc
pseries platform code to call it after a migration. The series also
includes changes addressing minor latent issues identified during the
implementation.

Platforms which do not need the new functionality remain unchanged.

For this initial version at least, the powerpc/pseries part includes
some "self-test" code that 1. verifies that reconstructing the
hardware description string late in boot matches the one that was
built earlier, and 2. fully exercises the update path before any
migrations occur. This could be dropped or made configurable in the
future.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
Nathan Lynch (5):
      dump_stack: Make arch description buffer __ro_after_init
      dump_stack: Allow update of arch description string at runtime
      powerpc/prom: Add CPU info to hardware description string later
      powerpc/pseries: Prepare pseries_add_hw_description() for runtime use
      powerpc/pseries: Update hardware description string after migration

 arch/powerpc/kernel/prom.c                | 12 +++--
 arch/powerpc/platforms/pseries/mobility.c |  5 ++
 arch/powerpc/platforms/pseries/pseries.h  |  1 +
 arch/powerpc/platforms/pseries/setup.c    | 80 +++++++++++++++++++++++++++++--
 include/linux/printk.h                    |  5 ++
 lib/dump_stack.c                          | 57 ++++++++++++++++++++--
 6 files changed, 146 insertions(+), 14 deletions(-)
---
base-commit: 44a1aad2fe6c10bfe0589d8047057b10a4c18a19
change-id: 20240111-update-dump-stack-arch-str-7f0880d23f30

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

