From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH net-next 0/5] net: cortina: Add CS7542 network engine
 support
Date: Mon, 23 Nov 2026 21:44:09 +0300
Message-Id: <20261123-b4-cs7542-ethernet-v1-0-fdb5e8c2d508@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z2OTW7DIBCFr2LNulTBgA1e9R5VFjAeEqoatwyJU
 kW5e3Fqdfn0fr53B6aSiGHq7lDomjituQn50gGefT6RSHPT0B/6QcpeiaAF8mh0L6ieqWSqwji
 UZg440kjQil+FYro9R99hC2S6VTj+OXwJH4R129yzhb4vjVv3QvBMAtdlSXXqwuBd9EojaWlHD
 IObFRprvQ4hRlQSqZFt3KYWYvbPw1P3f3f/yj+MaxZXKQ5CO2ssDUpq7d5Oi0+frw0Hx8fjF1X
 dTlkOAQAA
X-Change-ID: 20261123-b4-cs7542-ethernet-59c15dbc7e7e
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Linus Walleij <linusw@kernel.org>, Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459449; l=4440;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=LeaWLqxAis70C57qJ2TkPR2rGUR35IIvdrZPO5ZWMxo=;
 b=VpNX0QkmzL8UhlH1vyDAY2gb2UkTdTsvcZieISVbZwONR0kkncKFDMB2NxwMFsp2qbe82X3BF
 2D1gOAJgTwOCeNEqRepguPnzuN9sLOLjbzMohlnT5fZ5KjmQFKQhipy
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a CPU datapath for the Cortina Systems CS7542 network engine and
an exclusive reset provider for its NI/FE/TM/QM/scheduler/XRAM and
DMA-LSO/SSP domain. The three GMACs use phylink; Almond+ connects two
of them to the CPU ports of a QCA8337 switch handled by DSA.

The driver uses NAPI receive queues and a shared coherent TX ring,
with scatter-gather TX and multi-buffer RX. Hardware-returned RX
addresses are checked against tracked mappings and their ownership.
Indirect initialization waits are bounded and errors prevent activation.
Unregister/remove drains ports and software work, then confirms the
complete reset domain before releasing DMA allocations. If reset fails
after activation, those allocations remain pinned until reboot.

The whole DMA-LSO/SSP block is exclusively owned. Another SSP DMA user
cannot run concurrently; the separately prepared CS7542 NAND driver
uses PIO. Initial QM support requires a no-map reservation of the upper
64 MiB of the verified 512 MiB DDR layout. Hardware offload, unverified
coalescing clock assumptions and power management are not advertised.

This series depends on the CS7542 global clock/pinctrl v1 series:
https://lore.kernel.org/all/20261123-cs7542-syscon-v1-0-49858e631449@gmail.com/
Both series are based on Linux v7.4-rc4. Board DTS enablement is
kept in the integration branch and OpenWrt target, outside these five
patches. The reset provider and Ethernet driver do not depend on the
Cortina platform Kconfig symbol or COMPILE_TEST.

Validation on Securifi Almond+:
- Full independent ARM vmlinux and module builds, =y and =m, with
  COMPILE_TEST=n and no platform series; DT schemas and examples.
- Actual helper fault-path tests under ASan/UBSan, including RX ownership,
  TX mapping rollback, probe failures, table timeouts and reset failures.
- RAM module lifecycle: 132 checks / 0 failures, ten load/unload cycles,
  active-port teardown, reset readback and reset-failure DMA retention.
- External LAN1: 600/600 UDP echoes with byte comparison and 20/20 ICMPv6
  packets with 1400-byte payloads; no GMAC RX/TX errors.
- QCA CPU6-to-CPU0: 448/448 nonlinear packets, including RX buffer
  boundaries and 8192-byte payloads, with TX descriptor-ring wrap.
- Combined RAM test with PCIe and read-only NAND: all six PCIe devices,
  protected NAND hashes while the NE reset is held, and Ethernet reload.
- The original 14 protected flash/configuration hashes remained unchanged
  after returning to the installed OpenWrt.

Only LAN1 has been externally cable-tested in these runs. No throughput
or entropy claim follows from these functional checks.

---
Fil Dunsky (5):
      dt-bindings: reset: Add Cortina CS7542 network engine reset domain
      reset: Add Cortina CS7542 network engine domain control
      dt-bindings: net: Add Cortina CS7542 network engine
      net: cortina: Add CS7542 CPU network datapath
      MAINTAINERS: Add CS7542 network engine support

 .../bindings/net/cortina,cs7542-ethernet.yaml      |  139 ++
 .../bindings/reset/cortina,cs7542-ne-reset.yaml    |   42 +
 .../soc/cortina/cortina,cs7542-syscon.yaml         |    4 +
 MAINTAINERS                                        |    9 +
 drivers/net/ethernet/cortina/Kconfig               |   14 +
 drivers/net/ethernet/cortina/Makefile              |    3 +
 drivers/net/ethernet/cortina/cs752x_fe.c           |  477 ++++++
 drivers/net/ethernet/cortina/cs752x_ne.c           | 1783 ++++++++++++++++++++
 drivers/net/ethernet/cortina/cs752x_ne.h           |   13 +
 drivers/net/ethernet/cortina/cs752x_sch_tm.c       |  679 ++++++++
 drivers/reset/Kconfig                              |   10 +
 drivers/reset/Makefile                             |    2 +
 drivers/reset/reset-cs7542-ne.c                    |  114 ++
 13 files changed, 3289 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-ethernet-59c15dbc7e7e
prerequisite-message-id: 20261123-cs7542-syscon-v1-0-49858e631449@gmail.com
prerequisite-patch-id: 4b568d742095f1a61312c911d2b6e81c8e754312
prerequisite-patch-id: a4bba26a3aac57e4e4229a727fdf94677373493a
prerequisite-patch-id: f8a2ba71717f71ca2bedda986f8b861995cdc586
prerequisite-patch-id: 7a2275c69dcde437fc8badf2bba06d451943a66f
prerequisite-patch-id: 25220835f5d2506a01ba652d86f9b9ac3ad5121a

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

