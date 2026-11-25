From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH net-next v2 0/3] net: cortina: Add CS7542 network engine
 support
Date: Wed, 25 Nov 2026 13:36:30 +0300
Message-Id: <20261125-b4-cs7542-ethernet-v2-0-d0ea3c6eb375@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32QTW6EMAxGr4KybiryBwFVVe9RzSJxnCHVAG2SQ
 TMacfcGSqWuurRsv+/ZD5IwBkykrx4k4hJSmKdS8KeKwGCmM9LgSk14zRvGuKBWUkitkpxiHjB
 OmKnqgClnocUWSVn8jOjDbYe+k21gwlsmp59OutoPhLwxj9mIX9eSm48FaxJSmMcx5L6yjem8E
 RJQMt2CbTonQGltpLXeg2CAJVn7DTViSmYX7quXw1f9yqZ7gnmii6Q1FUK01tZOWKnfzqMJl+e
 S97obDiHlOd73fyxsF/rv9IUVnndWoQbuVP2HR07run4DvRG3aGABAAA=
X-Change-ID: 20261123-b4-cs7542-ethernet-59c15dbc7e7e
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>
Cc: Philipp Zabel <p.zabel@pengutronix.de>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Russell King <linux@armlinux.org.uk>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795602990; l=5902;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=hzfTSEncl8+6lQFtXl+HvtjdqGsPTGMtg6pa3a7jny0=;
 b=0ioYPAfU7bBMgacGabqirz3qfnCgZP6w9zOFbJdu1Kz6Kej95t+FkeymnfMXfAz/EdfRpFL3+
 yYK4yjei4ysDY0MQsawJPbe6Bvbr62Lfl1aUGdsdkth6w2DdQOOVlh/
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CS7542 CPU network datapath with phylink for three GMACs.
Almond+ connects two GMACs to QCA8337 CPU ports handled by DSA. Use the
global reset controller's seven exclusive lines, including the shared
LSO/SSP DMA block. The reset provider binds to the existing syscon.

Apply the combined CS7542 global controls series to Linux v7.4-rc4
first. Its clock and reset patches describe the NI, FE, TM, SCH, QM,
DMA and NI-XRAM reset IDs. The board DTS is posted separately.

Use normal NAPI weight64 and the supported external-DDR QM/TM setup,
with no module parameters. Preserve scatter-gather TX, multi-buffer RX,
tracked DMA ownership and bounded initialization. Require the verified
64 MiB no-map queue-manager reservation; NAND uses PIO and a separate
SSP DMA consumer cannot run concurrently.

Attempt and check every protective assertion without rolling back
already asserted controls. Preserve the first reset error, and retain
all active DMA allocations if any line cannot be confirmed asserted.
Serialize shared NI register updates and stop scheduler initialization
on its first command failure before publishing DMA buffers.

Validation includes actual-source reset/cleanup/error models, shared NI
RMW interleavings and scheduler command failures, ARM builds and binding
examples.

A separate combined Almond+ Linux v7.4-rc4 RAM kernel with private
log-only instrumentation passed two network-engine probe/removal epochs.
The trace checked all seven reset lines and their readbacks. Twenty-nine
exclusive-acquisition negative tests returned -EBUSY in a private test
module; they are intentional test warnings, not ordinary driver activity.
The external host matched 600 UDP echoes (six payload sizes, 0..1400
bytes) and 20 ICMPv6 replies. A distinct CPU-port scatter-gather/jumbo
fixture completed 448 frames. These are separate trace, host functional
and fixture observations, not a throughput or hardware-offload result.
The composed kernel also contained PCIe/PHY and other board drivers;
this is not a standalone provider-only hardware test. Watchdog expiry
returned to normal firmware. Protected-region hashes and flash layout
matched. Concurrent unrelated settings activity is excluded from any
unchanged-settings claim.
No checksum/NAT offload or performance capability is added.

The additional MAC-deferral/unwind correction is tested separately on
the host with actual-source fault models, not on the board. The hardware
evidence above describes the preceding source revision; its successful
factory-address path and packet datapath are unchanged by this error-path
correction. Missing NVMEM now defers before registering reset cleanup;
a late defer is returned instead of assigning a random address.

Additional local review corrections are tested with focused actual-source
fault/ownership models and ARM compilation. They have not yet been run
on the board: count bounded RX fragments independently of delivery
eligibility, schedule an initial masked NAPI poll on open, and retain
completion reaping for outstanding TX while all ports are closed.
No hardware offload capability or packet-MAC rewrite is added.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
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

---
Fil Dunsky (3):
      dt-bindings: net: Add Cortina CS7542 network engine
      net: cortina: Add CS7542 CPU network datapath
      MAINTAINERS: Add CS7542 network engine support

 .../bindings/net/cortina,cs7542-ethernet.yaml      |  160 ++
 MAINTAINERS                                        |    7 +
 drivers/net/ethernet/cortina/Kconfig               |   14 +
 drivers/net/ethernet/cortina/Makefile              |    3 +
 drivers/net/ethernet/cortina/cs752x_fe.c           |  477 +++++
 drivers/net/ethernet/cortina/cs752x_ne.c           | 1869 ++++++++++++++++++++
 drivers/net/ethernet/cortina/cs752x_ne.h           |   13 +
 drivers/net/ethernet/cortina/cs752x_sch_tm.c       |  687 +++++++
 8 files changed, 3230 insertions(+)
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

