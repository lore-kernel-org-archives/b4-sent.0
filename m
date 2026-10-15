From: Cunhao Lu <1579567540@qq.com>
Subject: [PATCH net v4 0/6] can: fix bus-off restart and device close races
Date: Thu, 15 Oct 2026 13:38:54 +0800
Message-Id: <20261015-rockchip-canfd-restart-close-v4-0-ad149ff79450@qq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO5m0GoC/5XOy27CMBAF0F9BXneQX1DSFf+BWNjjGeI+YrBNB
 EL5d0KQEKzaLu/o6ty5iEI5UhEfs4vI1McSUzcG+zYT2LpuRxDDmIWWeqmkMpATfmEb94Cu4wC
 ZSnW5An6nQkA+0KJZWFaexUjsM3E8TfxGdFTF9n4sR/9JWG/wrdbGUlM+T0/0air/ba9XoOBdo
 0PLjdHI68Nhjuln2un1s2R/kTRIwBX7wC6olTQvkvmPZEaJJXmrZCO11Q9pGIYrEinUx3ABAAA
 =
X-Change-ID: 20261013-rockchip-canfd-restart-close-ebde5954f1bf
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, kernel@pengutronix.de
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 stable@vger.kernel.org, Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792042751; l=6416;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=1gepIM0sB0EjFVmNm1QpbnGZhia/KKyYokRCJb/3ops=;
 b=OawGlbw61zj3S3nkWpRVH9hFn3yVRNwQtZWa6rUzwFs1G2Q4Z7T+6lrCsAfxVnv+VextbSefE
 6tzvOj++24LAjD5y6Ynf2sa/tYiPT1pXZcLHzmXDDGBWAOJqCMtxfQI
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
that race; the fix for the original TX stall will follow separately.

Rockchip currently cancels restart_work in close_candev(), after freeing
the IRQ, disabling RX offload and stopping the controller. A concurrent
restart can re-enable the controller and interrupts after IRQ teardown,
and requeue timestamp work that accesses registers after runtime suspend
has disabled the controller clocks.

The CAN core checks netif_running() before scheduling or starting
recovery. A new close_candev_cancel_restart_sync() helper lets Rockchip
wait for any restart already in progress before tearing down resources.
The final close_candev() call retains cancellation and echo cleanup.

Rockchip restart masks the device's interrupts and drains active IRQ
handlers without disabling the shared interrupt line. It also drains
timestamp work before reinitializing the controller and timecounter.
Shared IRQ handling stays suspended until initialization is complete.
Timestamp locking prevents workers from rearming after deactivation and
keeps timestamp conversions consistent with timecounter updates.

The bus-off path drains TX submission and RX-side echo users before
publishing BUS_OFF, protecting the CAN core's echo flush during manual
recovery. Startup serializes carrier restoration, IRQ resumption and queue
wake with a new bus-off. The series also fixes RX offload cleanup when
request_irq() fails during open.

Hardware testing on a LubanCat-5IO running a Linux 6.18 PREEMPT_RT
kernel covered 2,700 ranging request/response exchanges and 630 seconds
of continuous traffic, including three naturally scheduled timestamp
worker runs. RX, TX echo and TX completion hardware timestamps were
present throughout, with no backward or abnormal jumps.

Recovery tests included 20 automatic and 20 manual restarts, with 100
synthetic fault iterations in total plus one calibration run. Tracing
captured 14 overlaps between normal timestamp conversions and the worker,
and one between close and a running restart. All 20 down/up cycles passed.
No worker ran during about 300 seconds of observation after close, and no
deadlocks or WARN/Oops were observed.

---
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
Cc: linux-can@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-rockchip@lists.infradead.org

---
Cunhao Lu (6):
      can: dev: prevent bus-off recovery when the interface is not running
      can: dev: add close_candev_cancel_restart_sync()
      can: rockchip_canfd: cancel bus-off restart before closing the device
      can: rockchip_canfd: prevent timestamp work from rearming after bus-off
      can: rockchip_canfd: serialize TX with bus-off and restart
      can: rockchip_canfd: serialize timecounter timestamp conversion

 drivers/net/can/dev/dev.c                          | 12 ++--
 drivers/net/can/rockchip/rockchip_canfd-core.c     | 67 ++++++++++++++++++++--
 drivers/net/can/rockchip/rockchip_canfd-rx.c       | 22 ++++---
 .../net/can/rockchip/rockchip_canfd-timestamp.c    | 43 ++++++++++++--
 drivers/net/can/rockchip/rockchip_canfd-tx.c       | 16 +++++-
 drivers/net/can/rockchip/rockchip_canfd.h          | 11 +++-
 include/linux/can/dev.h                            | 12 ++++
 7 files changed, 157 insertions(+), 26 deletions(-)
---
base-commit: 24a19b953e2a3d0ea5a8c4951a0ab8f32720c907
change-id: 20261013-rockchip-canfd-restart-close-ebde5954f1bf

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

