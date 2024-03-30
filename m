From: Sam Ravnborg <sam@ravnborg.org>
Subject: [PATCH 00/10] sparc64: Fix CPU online bug and warning fixes
Date: Sat, 30 Mar 2024 10:57:36 +0100
Message-Id: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABHiB2YC/x3MQQqAIBBA0avErBNMTaqrRAuzsWZjMQMVRHdPW
 r7F/w8IMqHAUD3AeJLQnguauoK4hbyioqUYjDZOW9MrOQJH79QVOFNeRXnfxdhrTK2doWQHY6L
 7X47T+35CLiOJYgAAAA==
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>, 
 Atish Patra <atish.patra@oracle.com>, stable@vger.kernel.org, 
 Bob Picco <bob.picco@oracle.com>, Vijay Kumar <vijay.ac.kumar@oracle.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=2071;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=eDnRUPngHqoQZ7G0b6cjOURT4uhlTvBwqKCHkp86dUI=;
 b=XbiHaZ/tYJDLA+a14/hq+RNLsBlpQeOA1+rEeZk7TbiaKPXwytF49GTZiGF68WZIeOwb02V/RLnH
 CJVACzeFBQ/ioYueEX2mS2PTVVtDyJVb3DKSvYn8mxZNLwri6H+R
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Nick Bowler reported that sparc64 failed to bring all his CPU's online,
and that turned out to be an easy fix.

The sparc64 build was rather noisy with a lot of warnings which had
irritated me enough to go ahead and fix them.
With this set of patches my arch/sparc/ is almost warning free for
all{no,yes,mod}config + defconfig builds.

There is one warning about "clone3 not implemented", which I have ignored.

The warning fixes hides the fact that sparc64 is not yet y2038 prepared,
and it would be preferable if someone knowledgeable would fix this
poperly.

All fixes looks like 6.9 material to me.

	Sam 

---
Sam Ravnborg (10):
      sparc64: Fix prototype warning for init_vdso_image
      sparc64: Fix prototype warnings in traps_64.c
      sparc64: Fix prototype warning for vmemmap_free
      sparc64: Fix prototype warning for alloc_irqstack_bootmem
      sparc64: Fix prototype warning for uprobe_trap
      sparc64: Fix prototype warning for dma_4v_iotsb_bind
      sparc64: Fix prototype warnings in adi_64.c
      sparc64: Fix prototype warning for sched_clock
      sparc64: Fix number of online CPUs
      sparc64: Fix prototype warnings for vdso

 arch/sparc/include/asm/smp_64.h  |  2 --
 arch/sparc/include/asm/vdso.h    | 10 ++++++++++
 arch/sparc/kernel/adi_64.c       | 14 +++++++-------
 arch/sparc/kernel/kernel.h       |  4 ++++
 arch/sparc/kernel/pci_sun4v.c    |  6 +++---
 arch/sparc/kernel/prom_64.c      |  4 +++-
 arch/sparc/kernel/setup_64.c     |  3 +--
 arch/sparc/kernel/smp_64.c       | 14 --------------
 arch/sparc/kernel/time_64.c      |  1 +
 arch/sparc/kernel/traps_64.c     | 10 +++++-----
 arch/sparc/kernel/uprobes.c      |  2 ++
 arch/sparc/mm/init_64.c          |  5 -----
 arch/sparc/vdso/vclock_gettime.c |  1 +
 arch/sparc/vdso/vma.c            |  5 +++--
 14 files changed, 40 insertions(+), 41 deletions(-)
---
base-commit: 84b76d05828a1909e20d0f66553b876b801f98c8
change-id: 20240329-sparc64-warnings-668cc90ef53b

Best regards,
-- 
Sam Ravnborg <sam@ravnborg.org>

