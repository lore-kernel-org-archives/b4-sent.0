From: Cunhao Lu <1579567540@qq.com>
Subject: [PATCH v3 0/2] pmdomain: rockchip: Add RK3572 boot peripheral
 domains
Date: Mon, 26 Oct 2026 11:21:37 +0800
Message-Id: <20261026-add-board-ok3572-c-pmdomain-v3-0-70d614d3d921@qq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEHH3moC/32OQQ6CMBBFr0K6dkw7FUVX3sO4KJ1Bq4Fqi42Gc
 HcBo3FhXL7kz3vTicjBcRSbrBOBk4vONwPoWSbs0TQHBkcDC5S4VBI1GCIovQkE/qzzFYKFS02
 +Nq4BrCSSUUoXSxaD4RK4cvfJvtu/ON7KE9t2VI6Lo4utD48pn9S4e5fwVykpkCBLWVGRG62Yt
 9fr3PpajPaE3/f/P004iFZrIlogr9Gqj6jv+yeBnQf9FQEAAA==
X-Change-ID: 20261023-add-board-ok3572-c-pmdomain-2f02da11386e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Ulf Hansson <ulfh@kernel.org>
Cc: Cunhao Lu <1579567540@qq.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Finley Xiao <finley.xiao@rock-chips.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792984919; l=5260;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=AcZhQE2h3agPWP8/xjxv38mEgdS8HpR3PNxcZ2ZWylw=;
 b=ibcpCH/0lvTn1T/jrYlbaE11ZcaSxH4CSYMvzvOanFPwW7EYWBaz2YcfIYbpzPiOP19liBy+2
 8OeSYy0uPwgBX+WVMc1x61I4EiOXHYiAQTR3MqsSO6QTQOPxi1vUvXm
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is one of the subsystem submissions for RK3572 support.

This series adds the RK3572 power-controller binding and power IDs,
followed by support for the NVM0, NVM1, PHP, and VOP power domains.
The driver uses the system GRF to check firmware shift-ready status.

The RK3572 SoC has eight CPU cores: two Cortex-A73 cores and six
Cortex-A53 cores. It also integrates an Arm Mali-G310V2 MC1 GPU.
The OK3572-C board provides two Gigabit Ethernet ports, three USB3 Type-A
ports, a Type-C dual-role port, eMMC, microSD, and UART.

Power-on progress and restoration are tracked separately so that a
failed transition can be retried without losing pending memory resets or
QoS state. The shared Rockchip power-domain code is updated to support
the RK3572 register layout and retry behavior.

Testing was performed with Debian 13 minimal and Linux 7.3 on the
OK3572-C with the FET3572-C module. Shared peripheral tests were run with
the system booted from SD, while eMMC validation covered the complete
boot chain.

Passed functionality:

- SD and eMMC complete the firmware, kernel, and root filesystem
  boot chain.
- UART console works at 1500000 baud.
- SD read/write and data persistence checks pass.
- All eight CPUs start; CPU frequency scaling and hotplug checks pass.
- Both Ethernet ports obtain IPv4 addresses and pass bidirectional file
  transfers.
- All three Type-A ports pass USB2 and USB3 enumeration, data transfers,
  and reconnect persistence checks.
- Type-C host and device modes pass in both plug orientations. Physical
  reconnects correctly select the expected device, host, and device roles
  in sequence.

Stability:

- Repeated cold and software reboots complete on SD and eMMC without
  data integrity failures or power-domain transition failures.
- A combined CPU, memory, network, SD, and USB3 stress test completes
  without a crash, lockup, CPU offline event, or thermal shutdown.
- Ethernet error and drop counters do not increase during bidirectional
  network tests.

Power-domain fault-path validation:

- Host tests extracted the transition logic and memory operations from
  the driver and simulated register failures during power-status checks,
  memory chain/off/on operations, idle exit, and firmware shift-ready checks.
- The tests also cover retries, shutdown after a failed power-on,
  clock-enable failure, regulator loss, and domains without a firmware
  shift-ready mask. QoS preservation and memory-reset counts were checked.
- The simulated tests pass ASan and UBSan.

Build and checks:

- The kernel, modules, and board DTB build successfully.
- The series passes checkpatch with --strict; only generic reminders about
  new MAINTAINERS entries remain.

Untested hardware and paths:

- NPU
- PCIe
- GPU, video output, and audio
- CPU rates above 1.2 GHz and voltage scaling
- Other low-speed external interfaces

Some files in this series are derived from the Forlinx OK3572-C BSP
Alpha1. Thanks to Forlinx for their support.
Thanks also to Rockchip's David Wu, Elaine Zhang, Finley Xiao, Frank
Wang, William Wu, and Ye Zhang for providing the driver source files.

AI assistance:

- Codex / DeepSeek V4.1 Flash were used for:
  - Reviewing and adjusting code style to follow community conventions
  - Automating tests
  - Collecting data

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
Changes in v3:
- Track incomplete shutdowns to preserve QoS and complete firmware updates.
- Preserve pending memory resets across shutdown and cancel unfinished
  power-on requests.
- Attempt to restore the domain after power-off errors, while preserving
  the original error returned to genpd.
- Link to v2:
  https://patch.msgid.link/20261023-add-board-ok3572-c-pmdomain-v2-0-79ddd42e92c1@qq.com

Changes in v2:
- Split the original RK3572 support series by subsystem.
- Track low-level power-on and restoration separately. Retain unfinished
  memory resets across retries, avoid repeating completed resets, and
  preserve QoS snapshots when shutting down after a failed power-on.
- Link to v1:
  https://patch.msgid.link/20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com

---
Raw dmesg: see v2 cover letter.

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Heiko Stuebner <heiko@sntech.de>
To: Elaine Zhang <zhangqing@rock-chips.com>
To: Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-rockchip@lists.infradead.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-pm@vger.kernel.org

---
Finley Xiao (2):
      dt-bindings: power: rockchip: Add RK3572 power domains
      pmdomain: rockchip: Add RK3572 boot peripheral domains

 .../bindings/power/rockchip,power-controller.yaml  |  17 ++
 drivers/pmdomain/rockchip/pm-domains.c             | 187 ++++++++++++++++++---
 .../power/rockchip,rk3572-power-controller.h       |  30 ++++
 3 files changed, 214 insertions(+), 20 deletions(-)
---
base-commit: a804c5742bff224d4cb4d25dd383554d598be32b
change-id: 20261023-add-board-ok3572-c-pmdomain-2f02da11386e

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

