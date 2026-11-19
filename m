From: Cunhao Lu <1579567540@qq.com>
Subject: [PATCH net v10 00/10] can: fix Rockchip TX stalls and bus-off
 restart/close races
Date: Thu, 19 Nov 2026 16:39:41 +0800
Message-Id: <20261119-rockchip-canfd-restart-close-v10-0-df23913aa33a@qq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM21/moC/5XSyU7EMAwG4FdBOROUfeHEeyAOieMwYWln0lKBR
 vPupOUw7anM0Zb1+bfkMxmwFhzI492ZVJzKUPquFZzd3xE4hO4VaUmtQQQThjMuae3hHQ7lSCF
 0OdGKwxjqSOGjH5BiTKi9VpnHTBpxrJjL9+I/kw5H8vLXHL7iG8I4w/PYoQxjX3+WFBNfhv+3b
 +KUUysggMpeCshPp9MD9J/LnkmsJbUjCcoouBxTDok7JjeSvEWSTcoMo+LMM6HERlJrSe9Iqkk
 tjfI5W68020j6FknPElorhWXSgt9IZi3ZHck0CZNhOrcLo8GNZK8SZ2ZHsnMmgBQ5j+CU3khuL
 bkdyTVJog1C5uQxbDP5lcT5juSbZIySWTqhY7h+weVy+QW+x8xmLQMAAA==
X-Change-ID: 20261013-rockchip-canfd-restart-close-ebde5954f1bf
To: Marc Kleine-Budde <mkl@pengutronix.de>, kernel@pengutronix.de, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Wolfgang Grandegger <wg@grandegger.com>
Cc: linux-can@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Cunhao Lu <1579567540@qq.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795077587; l=10566;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=lTsdnwCHqwAoxAmeYNGgy9yRcSKjH5pM5w7N5WL7PJo=;
 b=FuX8UwsdDtydpORReZh0QXGB9ddEG1/a9JvLNw/bdZ3NsKpgR5tZWRJBa+9/RIn4BvGs64NAJ
 OkcXOh01kFZBrTyw4ZPRoebf0ITttp1F2TEFesMSIujQGkDj/KwJzgG
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a production robot using a LubanCat-5IO with an RK3588, the CAN TX
queue remained stopped while RX continued, and subsequent sends returned
ENOBUFS. The interface still reported ERROR-ACTIVE, with neither a
hardware bus-off condition nor a pending TX request.

During CAN traffic, the driver also repeatedly reported an inconsistent
TX echo state:

  rockchip_canfd fea60000.can can0: rkcanfd_tx_tail_is_eff:
  echo_skb[0]=NULL tx_head=0x00060f7d tx_tail=0x00060f7c

The Rockchip CAN-FD driver completes transmissions by matching
self-received frames with entries in the echo skb ring. A race between its
transmit and completion paths can expose a partially updated echo entry,
dereference an skb queued for NAPI, or stop the TX queue without a later
completion to wake it. If the driver cannot install an echo skb, it now
drops the frame before issuing a TX request. Retries use the outstanding
frame's slot and block new TX until both request bits clear, even if the
original echo arrives first.

While testing the echo-loss fix with fault injection, I discovered a
separate race between bus-off restart and device close.

Rockchip currently cancels restart_work in close_candev(), after freeing
the IRQ, disabling RX offload and stopping the controller. A concurrent
restart can re-enable the controller and interrupts after IRQ teardown,
and requeue timestamp work that accesses registers after runtime suspend
has disabled the controller clocks.

The CAN core skips scheduling or starting recovery when its
netif_running() check observes the interface down. These checks apply to
CAN core software recovery and do not serialize it with device close.
Rockchip waits for active core restart work before freeing the IRQ and
stopping the controller. The final close_candev() call still cancels
restart work and flushes the echo ring.

Rockchip restart masks the device's interrupts and drains active IRQ
handlers without disabling the shared interrupt line. It also drains
timestamp work before reinitializing the controller and timecounter.
The reset path restores and flushes the interrupt mask immediately after
reset deassertion. The Rockchip IRQ handler stays suspended until
initialization is complete.

Disabling timestamp work prevents workers from rearming after bus-off.
Timestamp locking keeps timestamp conversions consistent with timecounter
updates.

The bus-off path drains TX submission and RX-side echo users before
publishing BUS_OFF. Consumed RX FIFO entries are dropped while TX is
disabled to prevent self-transmitted frames from reaching ordinary RX.
Startup serializes carrier restoration, IRQ resumption and queue wake
with a new bus-off. The series also fixes RX offload cleanup when
request_irq() fails during open.

Hardware testing used a LubanCat-5IO running Linux 6.18 PREEMPT and
PREEMPT_RT kernels with v7 and the applicable prerequisites backported.
Tests on each kernel covered 600 seconds of bidirectional classic CAN
traffic, plus CAN FD and CAN FD+BRS. Local echo and both software and
hardware TX timestamps were also verified.

All 1,000 socket-close iterations passed. Instrumentation captured
1,150 cases where the last TX skb of a closed socket was destroyed,
all after releasing tx_lock and with IRQs enabled.

All 200 injected echo clone failures dropped the frame without
submitting TX, advancing tx_head or adding BQL bytes; subsequent sends
succeeded after removing the injection. BUSY, occupied slots, missing
echo skbs and invalid indices were also tested, along with automatic and
manual recovery from hardware bus-off triggered by bitrate mismatches.
All passed.

Test-only instrumentation captured 20 restart/close and 20 close/FIFO
interleavings. No timestamp worker ran during about 300 seconds after
close, and no WARN/Oops, deadlocks or persistent TX stalls were observed
during CAN testing.

Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v10:
- Move the retry fix (v9 03) after TX/IRQ synchronization and block new
  submissions after a retry until both TX request bits clear.
- Limit the recovery documentation to CAN core software recovery and
  clarify that running checks do not serialize recovery with shutdown.
- Link to v9:
  https://patch.msgid.link/20261111-rockchip-canfd-restart-close-v9-0-6643f3825ba3@qq.com

Changes in v9:
- Use workqueue disable/enable operations to prevent timestamp work from
  rearming after bus-off, balancing repeated stop calls.
- Move worker requeueing and initial scheduling outside timestamp_lock.
- Restore and flush device interrupt masking immediately after hardware
  reset, before the remaining controller configuration.
- Count consumed RX FIFO entries discarded while TX is disabled.
- Link to v8:
  https://patch.msgid.link/20261108-rockchip-canfd-restart-close-v8-0-3e7a23fd9eae@qq.com

Changes in v8:
- Merge the previously submitted Rockchip TX fixes, with TX serialization
  before the retry fix.
- Move retained-skb handling and the missing-echo guard into the echo
  failure fix, using the original skb as the frame-data source.
- Establish the TX/RX critical sections and caller-held helper locking in
  the TX serialization patch, covering queue updates, TX diagnostics and
  RX pending checks, with assertions for command writes.
- Reuse those critical sections in the bus-off/restart lifecycle patch.
- Rebase onto the latest testing branch in the mkl/linux-can-next repository.
- Link to the Rockchip TX fixes:
  https://lore.kernel.org/linux-can/tencent_E25C9BE6689264E4138A464803B810FDFD09@qq.com
- Link to v7:
  https://patch.msgid.link/20261106-rockchip-canfd-restart-close-v7-0-accdb11bc845@qq.com

Changes in v7:
- Clarify that running checks do not serialize recovery with close, and
  keep the restart-ms example tied to configuration while down.
- Introduce Rockchip restart/IRQ synchronization and TX protection
  together, keeping close cancellation and open failure cleanup in
  separate patches.
- Build on the CAN skb and Rockchip TX fixes, reusing the TX lock and
  adapting failure cleanup to the updated skb ownership contract.
- Link to v6:
  https://patch.msgid.link/20261017-rockchip-canfd-restart-close-v6-0-ed605feb4b6e@qq.com

Changes in v6:
- Update the can_bus_off() comment and document the running-interface
  requirement for automatic recovery.
- Explain Rockchip's use of the cancellation helper.
- Release the original TX skb after unlocking.
- Abort TX submission if echo preparation fails.
- Link to v5:
  https://patch.msgid.link/20261015-rockchip-canfd-restart-close-v5-0-ae77327037c9@qq.com

Changes in v5:
- Drop consumed RX FIFO entries under tx_lock when TX is disabled
  instead of only skipping echo filtering.
- Link to v4:
  https://patch.msgid.link/20261015-rockchip-canfd-restart-close-v4-0-ad149ff79450@qq.com

Changes in v4:
- Serialize timecounter_cyc2time() with the worker's timecounter_read()
  and startup's timecounter_init() using timestamp_lock.
- Update rkcanfd_skb_set_timestamp() to take a non-const private pointer
  and document the expanded scope of timestamp_lock.
- Link to v3:
  https://patch.msgid.link/20261014-rockchip-canfd-restart-close-v3-0-f0eb41090242@qq.com

Changes in v3:
- Replace disable_irq()/enable_irq() in Rockchip restart with device
  interrupt masking, mask readback, irq_suspended and synchronize_irq().
- Use release/acquire ordering when resuming the IRQ handler.
- Initialize timestamp delayed work once at probe and synchronously
  cancel it before restart reinitializes the timecounter.
- Balance RX offload enablement when request_irq() fails during open.
- Prevent timestamp work from reading the counter or rearming after
  deactivation, with cancellation outside the lock.
- Drain TX submission and RX-side echo users before publishing BUS_OFF,
  protecting the core's pre-restart echo flush.
- Serialize carrier restoration, IRQ enablement and queue wake with a new
  bus-off; suspend shared IRQ handling during open until startup finishes.
- Link to v2:
  https://lore.kernel.org/linux-can/tencent_82C93561D200C84C24608C80049C23EEF80A@qq.com/

Changes in v2:
- Split the series into the common checks, the cancellation helper, and
  its use in Rockchip.
- Check netif_running() after the do_set_mode capability check and before
  the restart notification, echo cleanup, and carrier update.
- Only queue automatic recovery for a running interface; keep reporting
  bus-off and make the log message match the scheduling decision.
- Add close_candev_cancel_restart_sync() in linux/can/dev.h and use it in
  close_candev() without changing the existing cleanup order.
- Replace the Rockchip mutex and closing flag with an early call to the
  helper. Drop the extra close-path IRQ synchronization and mask readback.
- Retain IRQ exclusion around hardware reinitialization in the restart
  callback.
- Link to v1:
  https://lore.kernel.org/linux-can/tencent_5802EE88434010229EDF7A53084D994C6106@qq.com/

---
Cunhao Lu (10):
      can: rockchip_canfd: prevent TX stall on echo skb failure
      can: rockchip_canfd: serialize TX state and command writes
      can: dev: check netif_running() before bus-off recovery
      can: dev: add close_candev_cancel_restart_sync()
      can: rockchip_canfd: cancel bus-off restart before closing the device
      can: rockchip_canfd: disable RX offload on open failure
      can: rockchip_canfd: serialize TX with bus-off and restart
      can: rockchip_canfd: retry the outstanding TX buffer
      can: rockchip_canfd: prevent timestamp work from rearming after bus-off
      can: rockchip_canfd: serialize timecounter timestamp conversion

 Documentation/networking/can.rst                   |   9 +-
 drivers/net/can/dev/dev.c                          |  17 ++-
 drivers/net/can/rockchip/rockchip_canfd-core.c     |  79 ++++++++++++-
 drivers/net/can/rockchip/rockchip_canfd-rx.c       |  30 +++--
 .../net/can/rockchip/rockchip_canfd-timestamp.c    |  41 ++++++-
 drivers/net/can/rockchip/rockchip_canfd-tx.c       | 124 +++++++++++++++++++--
 drivers/net/can/rockchip/rockchip_canfd.h          |  19 +++-
 include/linux/can/dev.h                            |  17 +++
 8 files changed, 303 insertions(+), 33 deletions(-)
---
base-commit: 48bcad36a131fa67a29a5ac430aceedf2d6f3d0f
change-id: 20261013-rockchip-canfd-restart-close-ebde5954f1bf

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

