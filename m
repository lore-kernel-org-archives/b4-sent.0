From: Cunhao Lu <1579567540@qq.com>
Subject: [PATCH v4 0/2] pmdomain: rockchip: Add RK3572 power domains
Date: Wed, 04 Nov 2026 16:56:02 +0800
Message-Id: <20261104-add-board-ok3572-c-pmdomain-v4-0-15cf8b5a6e59@qq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACLz6moC/33OQQrCMBAF0KtI1o4kk1qtK+8hLtLMVKO00USDI
 r27jSIqiMsPf96fm4gcHEexGN1E4OSi890QivFI2K3pNgyOhixQYqkkajBEUHsTCPxeT2cIFg4
 t+da4DrCRSEYpPS9ZDMIhcOMuD321fuZ4rndsT5nMja2LJx+uj/mkcu+1hL+WkgIJspYNzadGK
 +bl8TixvhVZT/h5///ThAM0q4ioQK7Qqi9If0Llf0hnSFKpCtJU4Rvq+/4OS2/9dV4BAAA=
X-Change-ID: 20261023-add-board-ok3572-c-pmdomain-2f02da11386e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Ulf Hansson <ulfh@kernel.org>
Cc: Cunhao Lu <1579567540@qq.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Finley Xiao <finley.xiao@rock-chips.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793782666; l=6041;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=p8nhVp0B8dou8lBdSNcuhjAqfSLAPvC5wNytWwZF1yU=;
 b=tdG1T6yiA8cZzkwOWo1Dayi1LTLYp+wZXh3gTCDS1UQ3Cu5606An2QEfmExFJZ/ZBji9sRGMz
 IBXhMfd5IKqDvQ3tZGfzsRVxrWRuOrjDCIeIka8U6y7A8zB2+v+C9ou
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is one of the subsystem submissions for RK3572 support.

This series adds the RK3572 power-controller binding and power IDs,
followed by support for all 14 power domains. It includes system GRF
firmware shift-ready checks, NPU voltage-domain control and genpd startup
protection for boot-enabled IMG, VOP, VOP_PRE and VO.

The RK3572 SoC has eight CPU cores: two Cortex-A73 cores and six
Cortex-A53 cores. It also integrates an Arm Mali-G310V2 MC1 GPU.
The OK3572-C board provides two Gigabit Ethernet ports, three USB3 Type-A
ports, a Type-C dual-role port, eMMC, microSD, and UART.

This series depends on the separately submitted power-on rollback fix [1].
Firmware readiness failures reuse it, preserving the original error and
saved QoS. If rollback fails, the domain may remain on while resources are
released and genpd may power down its parent.

[1] https://patch.msgid.link/20261101-fix-rockchip-pmdomain-power-on-rollback-v1-1-59a45783e33e@qq.com

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

Power-domain validation:

- All 14 domains register; 11 complete 1,140 runtime-PM cycles. NPU VD
  sequencing and startup-protection release are checked.
- Physical cold boot with an eMMC root filesystem succeeds. Read/write
  checks pass on eMMC, SD and two USB storage devices; both Ethernet
  ports pass ping tests bound to their respective interfaces.
- Thirteen return-value injections after successful operations check
  idle-exit and firmware-readiness rollback, NPU cleanup, original errors
  and saved QoS. Retries succeed after removing injection.
- 124 host model cases using the driver and genpd pass ASan and UBSan.

Build and checks:

- The kernel, modules, and board DTB build successfully.
- Strict checkpatch reports no errors.

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
Changes in v4:
- Drop generic pending-state tracking and power-off recovery; reuse the
  separate power-on rollback fix for firmware readiness errors.
- Support all 14 domains, including NPU voltage-domain control and
  cleanup after failed transitions.
- Retain boot-enabled IMG, VOP, VOP_PRE and VO domains until sync_state.
- Use firmware shift-ready naming for the GRF status.
- Build ungate write masks with unsigned arithmetic.
- Link to v3:
  https://patch.msgid.link/20261026-add-board-ok3572-c-pmdomain-v3-0-70d614d3d921@qq.com

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
Cunhao Lu (1):
      pmdomain: rockchip: Add RK3572 power domains

Finley Xiao (1):
      dt-bindings: power: rockchip: Add RK3572 power domains

 .../bindings/power/rockchip,power-controller.yaml  |  17 +++
 drivers/pmdomain/rockchip/pm-domains.c             | 168 +++++++++++++++++++--
 .../power/rockchip,rk3572-power-controller.h       |  30 ++++
 3 files changed, 204 insertions(+), 11 deletions(-)
---
base-commit: 99e3bb2c6f246f38179cc569e38a45d9555206ed
change-id: 20261023-add-board-ok3572-c-pmdomain-2f02da11386e

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

