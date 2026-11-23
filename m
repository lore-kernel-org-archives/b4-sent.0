From: Mani Tofigh <mt4022@columbia.edu>
Subject: [PATCH v2 0/2] sched/wait: Queue non-exclusive waiters at the head
 in do_wait_intr*()
Date: Sun, 22 Nov 2026 19:35:11 -0500
Message-Id: <20261122-b4-sched-wait-intr-head-v2-0-4a764b64e8ce@columbia.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNyw6CMBBFf8XM2jG0KfhY+R+GRR9TO0bBtAU1h
 H+34Ad47+ok9zFBosiU4LSZINLIifuugNxuwAbdXQnZFQZZyUYUoVGYbCCHL80ZucsRA2mHtqa
 Dr0ythFdQ2s9Int/r8qX9cRrMjWxe5pZE4JT7+FmvR7Hk/r+MAov31kvta3Ns1Nn29+FhWO/ID
 dDO8/wF5aGI0dMAAAA=
X-Change-ID: 20261111-b4-sched-wait-intr-head-c5e8f0b541f4
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>
Cc: Oleg Nesterov <oleg@redhat.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 Christian Brauner <brauner@kernel.org>, 
 Michal Nazarewicz <mina86@mina86.com>, Wen Yang <wen.yang@linux.dev>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795394112; l=1259;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=jCtwij91dfdagLsRWbPGL+dk8RepKRiMgOkxRuxT9C8=;
 b=L9Ai5mlE7Lz8ZDESqwhYZFIsp7DHH5oMWaV98/BeDTOP2wlDq0TqoZk2Nw9vKWXqwoS1sNkXK
 u6+Trf6KMOyASgkjM18QM5zTgqtmbVPKntcB/6XpTXWokmalKd43MpI
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 is the fix from v1, rebased on top of Linus's commit
cea5f91daa3a ("wait-event: clean up the internal helper arguments").
Patch 2 makes __wait_event_interruptible_locked() take wq_flags like
___wait_event() now does, as Oleg suggested.

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/evexcl.c

gpiolib-cdev and cros_ec_chardev use the same helpers and can be
polled too, so this fixes them as well.

---
Changes in v2:
- Rebased on Linus's master, on top of cea5f91daa3a.
- New patch 2: pass wq_flags instead of a 0/1 "exclusive" argument (Oleg).
- Link to v1: https://patch.msgid.link/20261111-b4-sched-wait-intr-head-v1-1-17cf2af5b964@columbia.edu
- Discussion: https://lore.kernel.org/all/awMhxEuMHULvk8SA@redhat.com/

---
Mani Tofigh (2):
      sched/wait: Queue non-exclusive waiters at the head in do_wait_intr*()
      sched/wait: Pass wq_flags to __wait_event_interruptible_locked()

 include/linux/wait.h | 11 ++++++-----
 kernel/sched/wait.c  | 16 ++++++++++++----
 2 files changed, 18 insertions(+), 9 deletions(-)
---
base-commit: 6e4122f0242a3262512ee3e6f2e7e6de0bd5792b
change-id: 20261111-b4-sched-wait-intr-head-c5e8f0b541f4

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

