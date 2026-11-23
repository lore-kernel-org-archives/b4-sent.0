From: Cunhao Lu <1579567540@qq.com>
Subject: [PATCH v7 0/5] clk: rockchip: Add RK3572 clock and reset support
Date: Mon, 23 Nov 2026 17:58:59 +0800
Message-Id: <20261123-add-board-ok3572-c-clk-v7-0-16f6860191a9@qq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGMOBGsC/3XPTU7DMBAF4KtUXmPk/8SsuAdiMfbY1BRqmhQLV
 OXu2EVAIuHlk2a+N3Mhc5hSmMnd7kKmUNKc8rGG4WZH/B6OT4EmrJkIJgxnQlJApC7DhDQfpB4
 E9dS/HCizDCNqLSJaUpffphDTxxV+ePzO87t7Dv7ctDaxT/M5T5/X5sLb3E+J+K+kcMoocyziq
 EHyEO5Pp1ufX0nTi1jvd48sohqWOTuO0rhgtoZcG6ZryGqgAxdBWjRWbAy1NoauoZqhuBZOxYA
 AG0OvDMm6hm6/gJKKSe+4shvD/Bmc9+8w1fDgAE3t8jr+GsuyfAGZGyIqGwIAAA==
X-Change-ID: 20261023-add-board-ok3572-c-clk-090dfd552fd9
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, Jonas Karlman <jonas@kwiboo.se>, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795427940; l=7301;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=RSHw02Kvs0bpE02qsTU/7SnG0z35YiJlKRjefdl+PXk=;
 b=MUHySwll1chqnunnd2B5AnwKjiesT4UoZAKAggsm85lol9u81FTAUpKFwoSk1Zk5D33V3dMPd
 rNlOEvJHmCPCR917fytJE4DxPpHQw/XluwYqALuS4y+zeXtEY9X+Ygj
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is one of the subsystem submissions for RK3572 support.

This series adds the CRU binding, clock and reset IDs, an internal
Rockchip 24-bit fractional divider helper, a composite clock macro with
mux-table support, and the RK3572 clock and reset driver. The shared
helpers precede the driver that uses them.

The RK3572 SoC has eight CPU cores: two Cortex-A73 cores and six
Cortex-A53 cores. It also integrates an Arm Mali-G310V2 MC1 GPU.
The OK3572-C board provides two Gigabit Ethernet ports, three USB3 Type-A
ports, a Type-C dual-role port, eMMC, microSD, and UART.

The driver provides the peripheral clock and reset trees, including the
three audio fractional clocks. It obtains the PMU0 GRF for the AUPLL
reference mux. CPU frequency scaling is controlled through SCMI; BPLL
and LPLL remain enabled for firmware use.

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

- Repeated cold and software reboots complete on SD and eMMC without data
  integrity failures.
- A combined CPU, memory, network, SD, and USB3 stress test completes
  without a crash, lockup, CPU offline event, or thermal shutdown.
- Ethernet error and drop counters do not increase during bidirectional
  network tests.

Build and checks:

- The kernel, modules, and board DTB build successfully.
- Strict checkpatch reports the existing MAINTAINERS and Kconfig help
  warnings and a macro argument-reuse check.

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
Changes in v7:
- Group the SCMI clock IDs separately and prefix them with SCMI_.
- Drop RESETN from reset names in the binding and driver.
- Fully initialize clk_init_data and require direct M/N encoding with a
  16/8-bit field split in the 24-bit fractional divider helper.
- Register the RK3572 CRU as a platform device.
- Return OF clock provider registration errors in a separate preparatory
  patch so the RK3572 driver can free its clock ID lookup table on failure.
- Rebase onto the latest v7.5-clk/next in mmind/linux-rockchip.git.
- Link to v6:
  https://patch.msgid.link/20261117-add-board-ok3572-c-clk-v6-0-cabad6610c5f@qq.com

Changes in v6:
- Explain the v1/v2 fractional-divider differences.
- Improve readability.
- Link to v5:
  https://patch.msgid.link/20261030-add-board-ok3572-c-clk-v5-0-9a43403cb149@qq.com

Changes in v5:
- Select encodable 24-bit fractional-divider ratios using the actual
  compensation and field-width limits.
- Keep fractional-divider rate determination, programming and rate
  recalculation consistent after integer-Hz rounding.
- Correct the clk_ddrphy_top_src and aclk_top parent selector mapping.
- Link to v4:
  https://patch.msgid.link/20261027-add-board-ok3572-c-clk-v4-0-d4152b4fedaa@qq.com

Changes in v4:
- Move COMPOSITE_MUXTBL into clk.h as a separate preparatory patch and
  use it in the RK3572 driver.
- Link to v3:
  https://patch.msgid.link/20261026-add-board-ok3572-c-clk-v3-0-dbabfa39d692@qq.com

Changes in v3:
- Close the reset ID gap while preserving the register mapping of each
  named reset.
- Check fractional-divider scaling against the actual field widths and
  reject unrepresentable compensated ratios during rate determination.
- Use signed negative PLL coefficients in the RK3572 rate table.
- Drop CLK_NR_CLKS from the binding and derive the provider size from
  registered clocks, keeping the existing clock IDs.
- Fix the indentation of the CRU binding example.
- Link to v2:
  https://patch.msgid.link/20261023-add-board-ok3572-c-clk-v2-0-90b98836be6e@qq.com

Changes in v2:
- Split the original RK3572 support series by subsystem.
- Port the vendor 24-bit fractional divider to the internal Rockchip
  clock helpers and adapt it to the determine_rate API.
- Register audio frac0-2. Keep internal SPLL factors outside the DT
  lookup so PPLL retains clock ID 0, and remove the unused xin12m factor.
- Link to v1:
  https://patch.msgid.link/20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com

---
Raw dmesg: see v2 cover letter.

To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney+clk@redhat.com>
To: Jerome Brunet <jbrunet+clk@baylibre.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Heiko Stuebner <heiko@sntech.de>
To: Philipp Zabel <p.zabel@pengutronix.de>
To: Elaine Zhang <zhangqing@rock-chips.com>
Cc: Jonas Karlman <jonas@kwiboo.se>
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-rockchip@lists.infradead.org
Cc: linux-kernel@vger.kernel.org

---
Cunhao Lu (1):
      clk: rockchip: Return errors from rockchip_clk_of_add_provider()

Elaine Zhang (4):
      dt-bindings: clock: rockchip: Add RK3572 CRU
      clk: rockchip: Add 24-bit fractional divider support
      clk: rockchip: Add composite clock macro with mux table
      clk: rockchip: Add RK3572 clock and reset support

 .../bindings/clock/rockchip,rk3572-cru.yaml        |   57 +
 drivers/clk/rockchip/Kconfig                       |    7 +
 drivers/clk/rockchip/Makefile                      |    2 +
 drivers/clk/rockchip/clk-fractional-divider-v2.c   |  354 ++++
 drivers/clk/rockchip/clk-rk3572.c                  | 2023 ++++++++++++++++++++
 drivers/clk/rockchip/clk.c                         |   24 +-
 drivers/clk/rockchip/clk.h                         |   87 +-
 drivers/clk/rockchip/rst-rk3572.c                  |  738 +++++++
 include/dt-bindings/clock/rockchip,rk3572-cru.h    |  561 ++++++
 include/dt-bindings/reset/rockchip,rk3572-cru.h    |  713 +++++++
 10 files changed, 4559 insertions(+), 7 deletions(-)
---
base-commit: e8a4084724e114295aa3a077d9458726e7ef4e90
change-id: 20261023-add-board-ok3572-c-clk-090dfd552fd9

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

