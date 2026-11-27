From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH net-next v4 0/3] Add Cortina Systems CS7542 network engine
 support
Date: Fri, 27 Nov 2026 15:53:43 +0300
Message-Id: <20261127-b4-cs7542-ethernet-v4-0-ea4d8cd6ef18@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33QwU7DMAwG4FepciaoiZOmmxDiPRCH2HG3INpCk
 1Wbpr07WRlShSaOVuzPf3wWiafISWyrs5h4jimOQynMQyVo74cdyxhKLXStG6U0SDSSkrNGS85
 7ngbO0m5I2YDk2LEog58Td/G4oK/i2jDwMYu3n5d0wHemfDVvvRN/HcrefBtAn1jS2Pcxbyts/
 KbzYIiNah1hswlAtm29Qew6AkVcNrfdleo5Jb8E3lZPt7z2N2w6JRoHORtZSwBwiHUANO3Lrvf
 x47Hse14S7mPK43Ra7jGrJdB/X59V8bqAllvSwdYrb+FmvSbsXUIXItTsgRpGcPYvAWuiuUtAI
 codbACnWWFYE5fL5RvW0r/h5gEAAA==
X-Change-ID: 20261123-b4-cs7542-ethernet-59c15dbc7e7e
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Russell King <linux@armlinux.org.uk>
Cc: Philipp Zabel <p.zabel@pengutronix.de>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Russell King <linux@armlinux.org.uk>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795784023; l=6644;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=RNl0JlHhjuvh1aWNI+g2JDijPtPR+EGlkS41ffVGy8g=;
 b=7x8mLPT3EPrd3HpiRKRT8YKov8AT6zcQYGwMLBZISPi1J8ohDVPkae9QQCVdT/ASPW3g1mMff
 rJWExeKVxssBpftjb5aHW5yf1JTio9eC4i99TM5fsxJbjCPJvGHSxmh
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CS7542 CPU network datapath with phylink for three GMACs.
Almond+ connects two GMACs to QCA8337 CPU ports handled by DSA.

This series depends on the combined CS7542 global controls v4 series,
posted separately against Linux v7.4-rc4. The consumer acquires the NI,
FE, TM, SCH, QM, DMA and NI-XRAM reset controls exclusively. Board DTS
support is separate. The verified 64 MiB no-map queue-manager reservation
is required. NAND uses PIO; a separate SSP DMA consumer cannot run
concurrently with the shared DMA reset domain.

Use normal NAPI weight 64 and external-DDR QM/TM setup, with no module
parameters. Support scatter-gather TX and multi-buffer RX, bounded
initialization, tracked DMA ownership, shared NI register serialization
and protective reset before freeing active mappings. No checksum/NAT
offload or performance capability is added.

Changes in this revision:
- Bound immediate polling of a DMA-owned RX head to four NAPI polls.
  Thereafter complete NAPI with the interrupt masked and defer the next
  attempt to delayed work. Never recycle the hardware-owned descriptor;
  cancel retry work when closing or removing the port.
- Disable bottom halves when scheduling NAPI from ndo_open and the retry
  worker. Restore the RX lock and IRQ state before enabling bottom halves.

Validation of these changes:
- Actual-source ownership/backoff cases cover transient and persistently
  owned heads, recovery without a new IRQ edge, stop and retry cancellation.
- Nine actual callback cases per GCC and Clang ASan/UBSan exercise process
  and softirq scheduling contexts. The pre-fix source reproduces two
  context defects. Native ARM, basic Ethernet ARM and integrated OpenWrt
  6.18 ARM compilation pass with W=1 and KCFLAGS=-Werror.
- These new retry/context fault cases are host checks; they were not
  injected on the board. The final folded source matches the already
  reviewed and compiled source byte for byte.

Earlier combined-kernel Almond+ checks covered reset/probe/removal, LAN1
protected-data transfers and automatic watchdog return to normal OpenWrt.
Separate earlier fixtures checked 600 UDP echoes, 20 ICMPv6 replies and
448 scatter-gather/jumbo frames. Protected-region hashes and flash layout
matched; unrelated concurrent settings activity was excluded from any
unchanged-settings claim. These observations predate the new retry/context
fixes and are integration/functional checks, not throughput or offload
results. The old hardware matrix was not repeated for this reroll.

---
Changes in v4:
- Bound DMA-owned RX head polling and defer retries with the IRQ masked.
- Schedule NAPI with bottom halves disabled from process context.
- Link to v3: https://lore.kernel.org/all/20261126-b4-cs7542-ethernet-v3-0-5db5d372e1bd@gmail.com/

Changes in v3:
- Include FCS in RX buffer recycling and retry transient descriptor ownership.
- Validate the shared MAC prefix and reject sibling-clobbering changes.
- Drop the RESET_CONTROLLER select from the Ethernet consumer.
- Rely on reset provider error propagation instead of redundant status reads.
- Use bulk deassert on bring-up; preserve all protective assertions on teardown.
- Link to v2: https://patch.msgid.link/20261125-b4-cs7542-ethernet-v2-0-d0ea3c6eb375@gmail.com

Changes in v2:
- Use the common parent provider and all seven exclusive reset lines;
  remove the virtual reset child, duplicate provider and consumer hook.
- Assert and verify every line without protective-assert rollback;
  retain active DMA allocations on any error and deassert in reverse order.
- Use rgmii-id in the binding example for switch-inserted RX/TX delays.
- Remove module parameters and unused internal-buffer mode; retain the
  previous default external-DDR initialization policy.
- Use NAPI weight64, plain static MMIO helpers and goto-based open cleanup;
  retain the lock-protected publication and stopping gates.
- Serialize shared NI RMW and stop on the first scheduler command error.
- Keep MAC preflight before hardware cleanup registration and preserve
  a late NVMEM probe defer instead of replacing it with a random MAC.
- Recycle bounded RX fragments also when the frame is dropped.
- Poll already queued RX after open and retain safe closed-port TX reaping.
- Review Sashiko 231860: existing NI/SCH/NAPI fixes address the older v1;
  temporary BM initialization bypass clearing follows the vendor sequence.
- Link to v1: https://lore.kernel.org/all/20261123-b4-cs7542-ethernet-v1-0-fdb5e8c2d508@gmail.com/

To: Fil Dunsky <filipp.dunsky@gmail.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@kernel.org>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Hans Ulli Kroll <ulli.kroll@googlemail.com>
To: Linus Walleij <linusw@kernel.org>
To: Philipp Zabel <p.zabel@pengutronix.de>
To: Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org

---
Fil Dunsky (3):
      dt-bindings: net: Add Cortina CS7542 network engine
      net: cortina: Add CS7542 CPU network datapath
      MAINTAINERS: Add CS7542 network engine support

 .../bindings/net/cortina,cs7542-ethernet.yaml      |  162 ++
 MAINTAINERS                                        |    7 +
 drivers/net/ethernet/cortina/Kconfig               |   13 +
 drivers/net/ethernet/cortina/Makefile              |    3 +
 drivers/net/ethernet/cortina/cs752x_fe.c           |  477 +++++
 drivers/net/ethernet/cortina/cs752x_ne.c           | 1965 ++++++++++++++++++++
 drivers/net/ethernet/cortina/cs752x_ne.h           |   13 +
 drivers/net/ethernet/cortina/cs752x_sch_tm.c       |  688 +++++++
 8 files changed, 3328 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-ethernet-59c15dbc7e7e
prerequisite-message-id: <20261125-cs7542-syscon-v4-0-3337bb0d3b48@gmail.com>
prerequisite-patch-id: a9208276c628f8741a807d0e5c5945d4bf211c8a
prerequisite-patch-id: 65d46bb3caaa8518ee561f65d3f603ade396fff9
prerequisite-patch-id: a0ed5fbcfa308b16eaf265371a6697ad0aea6802
prerequisite-patch-id: bb8ffd99cb30e5a0b47881f6ba19a36329d5f4f2
prerequisite-patch-id: 7fbe9405265ef3d1ec62811415a46c0061afd7c8
prerequisite-patch-id: 01ece2c91e080d5cae6af81944159373776484ca

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

