From: Mitchell Levy <levymitchell0@gmail.com>
Subject: [PATCH RFC 0/2] hyperv: Use raw_spinlock_t when not sleepable
Date: Wed, 09 Aug 2023 22:36:31 +0000
Message-Id: <20230809-b4-rt_preempt-fix-v1-0-7283bbdc8b14@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAO8U1GQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDCwNz3SQT3aKS+IKi1NTcghLdtMwKXWPTRDPTZEuDZLNkSyWgPqAcUBh
 sZrRSkJuzUmxtLQClwbL1aAAAAA==
To: "K. Y. Srinivasan" <kys@microsoft.com>, 
 Haiyang Zhang <haiyangz@microsoft.com>, Wei Liu <wei.liu@kernel.org>, 
 Dexuan Cui <decui@microsoft.com>, Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-hyperv@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Mitchell Levy <levymitchell0@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691620601; l=1712;
 i=levymitchell0@gmail.com; s=20230725; h=from:subject:message-id;
 bh=4BUjLFkJfQA+chP1T8/lb7tqG9vwUxCWszoSKHdT3eE=;
 b=zwEsCCDdslAFmIWp4oNviyDHd5myOXZRtA1QQR2rS9NQGtc/DMRVBWzSi1Pr59mMz36bE6h/v
 PwwMRSmnPQcBjaCXBrPqy1hROOTwu3N5KyJscY76lir1pZb7CmLb6vw
X-Developer-Key: i=levymitchell0@gmail.com; a=ed25519;
 pk=o3BLKQtTK7QMnUiW3/7p5JcITesvc3qL/w+Tz19oYeE=
X-Endpoint-Received: by B4 Relay for levymitchell0@gmail.com/20230725 with auth_id=69
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When compiled with PREEMPT_RT, spinlock_t is sleepable. While I did not
observe this causing any lockups on my system, it did cause warnings to
be emitted when compiled with lock debugging. This series fixes some
instances where spinlock_t is used in non-sleepable contexts, though it
almost certainly does not find every such instance.

An example of the warning raised by lockdep:
=============================
[BUG: Invalid wait context ]
6.5.0-rc1+ #16 Not tainted
-----------------------------
swapper/0/1 is trying to lock:
ffffa05a014d64c0 (&channel→sched_lock) {...}-{3:3}, at: vmbus_isr+0x179/0x320
other info that might help us debug this:
context-{2:2}
2 locks held by swapper/0/1:
 #0: ffffffff909a9c70 (misc_mtx){+.+.}-{4:4}, at: misc_register+0x34/0x180
 #1: ffffffff9079b4c8 (rcu_read_lock) {...}-{1:3}, at: rcu_lock_acquire+0x0/0x40
stack backtrace:
CPU: 0 PID: 1 Comm: swapper/0 Not tainted 6.5.0-rc1+ #16
Hardware name: Microsoft Corporation Virtual Machine/Virtual Machine, BIOS Hyper-V UEFI Release v4.1 05/09/2022

Signed-off-by: Mitchell Levy <levymitchell0@gmail.com>
---
Mitchell Levy (2):
      Use raw_spinlock_t for vmbus_channel.sched_lock
      Use raw_spinlock_t in vmbus_requestor

 drivers/hv/channel.c                | 6 +++---
 drivers/hv/channel_mgmt.c           | 2 +-
 drivers/hv/vmbus_drv.c              | 4 ++--
 drivers/pci/controller/pci-hyperv.c | 6 +++---
 include/linux/hyperv.h              | 8 ++++----
 5 files changed, 13 insertions(+), 13 deletions(-)
---
base-commit: 14f9643dc90adea074a0ffb7a17d337eafc6a5cc
change-id: 20230807-b4-rt_preempt-fix-35a65c90c6c9

Best regards,
-- 
Mitchell Levy <levymitchell0@gmail.com>

