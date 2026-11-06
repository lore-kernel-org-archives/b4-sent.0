From: Cunhao Lu <1579567540@qq.com>
Subject: [PATCH net v7 0/7] can: fix bus-off restart and device close races
Date: Fri, 06 Nov 2026 17:37:19 +0800
Message-Id: <20261106-rockchip-canfd-restart-close-v7-0-accdb11bc845@qq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM+f7WoC/5XPy07EMAwF0F8ZZU1Qns2EFf+BWDSOzYRHO5OUC
 jTqv5MWCbWrMstrWcfXV1YwJyzs4XBlGcdUUt/V4O4ODE5t94I8xZqZEqqRQmqee3iDUzpzaDu
 KPGMZ2jxweO8LcgwRrbeGZCBWiXNGSl8L/8Q6HNjz77B8hleEYYbntVMqQ5+/lxKjXJb/d2+UX
 HKnoAVDXiugx8vlHvqP5c6o1pLZkRQXHI4UIrVRHoXeSPoWSVeJBAYjhRfKqI1k1pLdkUyVahv
 jiZw3Vmwke4tkZwmd08oJ7cBvpGYtuR2pqRLGRliqH4YG/6Rpmn4A2uY2W04CAAA=
X-Change-ID: 20261013-rockchip-canfd-restart-close-ebde5954f1bf
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, kernel@pengutronix.de, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: Cunhao Lu <1579567540@qq.com>, linux-can@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793957851; l=9750;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=M2fY2hER5h7zA91MRzeJLSBSv75PdpfkX+JAnpGPIY0=;
 b=qnneYFZSq1q8txUAeEA7r0Ze4CgVmjzYCBTKwgVSyEFjHQZWftSmHrxDjm+4wc8qyZ3Fu+FBp
 buFuX/1VKONCB2fu5apXFdh5E+81sK6vwCb0m/bRZ/B+a5WPbXMD9y7
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This work started from a real failure on a production robot using a
LubanCat-5IO with an RK3588. RX continued, but the TX queue remained
stopped and subsequent sends returned ENOBUFS. The interface still
reported ERROR-ACTIVE, and the hardware indicated neither a bus-off
condition nor a pending TX request.

While testing the echo-loss fix with fault injection, I discovered a
separate race between bus-off restart and device close. This series fixes
that race.

Rockchip currently cancels restart_work in close_candev(), after freeing
the IRQ, disabling RX offload and stopping the controller. A concurrent
restart can re-enable the controller and interrupts after IRQ teardown,
and requeue timestamp work that accesses registers after runtime suspend
has disabled the controller clocks.

The CAN core skips scheduling or starting recovery when its
netif_running() check observes the interface down. A new
close_candev_cancel_restart_sync() helper lets Rockchip wait for any
restart already in progress before tearing down resources.
The final close_candev() call retains cancellation and echo cleanup.

Rockchip restart masks the device's interrupts and drains active IRQ
handlers without disabling the shared interrupt line. It also drains
timestamp work before reinitializing the controller and timecounter.
Shared IRQ handling stays suspended until initialization is complete.
Timestamp locking prevents workers from rearming after deactivation and
keeps timestamp conversions consistent with timecounter updates.

The bus-off path drains TX submission and RX-side echo users before
publishing BUS_OFF, protecting the CAN core's echo flush during manual
recovery. Consumed RX FIFO entries are dropped while TX is disabled to
prevent self-transmitted frames from reaching ordinary RX. Startup
serializes carrier restoration, IRQ resumption and queue wake with a new
bus-off. The series also fixes RX offload cleanup when request_irq() fails
during open.

TX submission retains the original skb until after unlocking, so echo
preparation cannot run its socket destructor with IRQs disabled. The
prerequisites already abort TX when echo installation fails; this series
also rejects a successful return without an installed echo skb and
preserves the failure cleanup under the wider TX critical section.

The following issues were also identified during this work:

- Races in the Rockchip bus error counter cache.
- Incomplete runtime PM clock cleanup in Rockchip during removal or
  failed registration.
- Missing explicit interrupt-mask write completion before free_irq() in
  the Rockchip close path.

These three issues are outside this series. When I have time,
I will send separate patches to fix them one by one.

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

This series depends on the three patches in "can: skb: make CAN skb
freeing safe in any IRQ context" [1] and the three patches in "can:
rockchip_canfd: fix TX stalls and races" [2].

[1] https://lore.kernel.org/linux-can/tencent_CD05F020BAFB2537F5D1F4CBB425588EA80A@qq.com/
[2] https://lore.kernel.org/linux-can/tencent_E25C9BE6689264E4138A464803B810FDFD09@qq.com/

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
Changes in v7:
- Clarify that running checks do not serialize recovery with close, and
  keep the restart-ms example tied to configuration while down.
- Introduce Rockchip restart/IRQ synchronization and TX protection
  together, keeping close cancellation and open failure cleanup in
  separate patches.
- Build on the CAN skb and Rockchip TX fixes, reusing the TX lock and
  adapting failure cleanup to the updated skb ownership contract.
- Link to v6: https://patch.msgid.link/20261017-rockchip-canfd-restart-close-v6-0-ed605feb4b6e@qq.com

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

To: Marc Kleine-Budde <mkl@pengutronix.de>
To: Vincent Mailhol <mailhol@kernel.org>
To: Heiko Stuebner <heiko@sntech.de>
To: "David S. Miller" <davem@davemloft.net>
To: Wolfgang Grandegger <wg@grandegger.com>
To: Oliver Hartkopp <socketcan@hartkopp.net>
To: kernel@pengutronix.de
To: Eric Dumazet <edumazet@kernel.org>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Simon Horman <horms@kernel.org>
To: Jonathan Corbet <corbet@lwn.net>
To: Shuah Khan <skhan@linuxfoundation.org>
To: Randy Dunlap <rdunlap@infradead.org>
Cc: linux-can@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-rockchip@lists.infradead.org
Cc: netdev@vger.kernel.org
Cc: linux-doc@vger.kernel.org

---
Cunhao Lu (7):
      can: dev: check netif_running() before bus-off recovery
      can: dev: add close_candev_cancel_restart_sync()
      can: rockchip_canfd: cancel bus-off restart before closing the device
      can: rockchip_canfd: disable RX offload on open failure
      can: rockchip_canfd: serialize TX with bus-off and restart
      can: rockchip_canfd: prevent timestamp work from rearming after bus-off
      can: rockchip_canfd: serialize timecounter timestamp conversion

 Documentation/networking/can.rst                   | 10 +++-
 drivers/net/can/dev/dev.c                          | 17 ++++--
 drivers/net/can/rockchip/rockchip_canfd-core.c     | 66 ++++++++++++++++++++--
 drivers/net/can/rockchip/rockchip_canfd-rx.c       | 59 ++++++++++---------
 .../net/can/rockchip/rockchip_canfd-timestamp.c    | 43 ++++++++++++--
 drivers/net/can/rockchip/rockchip_canfd-tx.c       | 62 +++++++++++---------
 drivers/net/can/rockchip/rockchip_canfd.h          | 13 ++++-
 include/linux/can/dev.h                            | 17 ++++++
 8 files changed, 209 insertions(+), 78 deletions(-)
---
base-commit: 4bb7b8e21e34ad06131468d0a719becdb67ad7ac
change-id: 20261013-rockchip-canfd-restart-close-ebde5954f1bf

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

