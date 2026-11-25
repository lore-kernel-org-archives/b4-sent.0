From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH RFC net-next 0/7] net: cortina: CS7542 wired IPv4 hardware
 flowtable offload
Date: Wed, 25 Nov 2026 23:50:28 +0300
Message-Id: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43O0UrDMBQG4FcpuTbS9CRtOkQEwQfwVnaRc3LiI
 m0zm25Mxt7ddpsi4oWX/+H8H/9RZB4jZ7EqjmLkfcwxDXNQN4WgjRteWUY/Z1GVVa1UZaTr+jT
 4bbfLMoXQJeflGEgq3VLAqnWeWzGXtyOHeDjDL+L56XG5DTzJgQ+TWF8e8g7fmKaFv1ZGft/NE
 6Zrr+ec3XnCqrj7XkC5MbqS+SNTGuRey1ICQINYekBtH157F7tbSv39ov5toP5ieNrwuCzbVzP
 kS3ZANSM05h8Q/IB6H9MFgVLXhi0oa+AXgi6znEMfp1WBtWuDA02slW0I69YDGWudRgyBQBEbj
 zaI9en0CYrfb+epAQAA
X-Change-ID: 20261125-almondplus-offload-rfc-149cfb29ade9
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Simon Horman <horms@kernel.org>, Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Linus Walleij <linusw@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Russell King <linux@armlinux.org.uk>, 
 Christian Marangi <ansuelsmth@gmail.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=9740;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=vFaO59i6zhCLeVgbrtaJehl+jT+xj4cFoaNX8zHwV8w=;
 b=zSnBxx+WPCS11FL+803ksrONL7/qS0f4qZpajs/fYQuXVsKneyWlqLd8lm63iP3FI20Jn3OrF
 7Da3MY9C1L+APWAKzj1l9JEDf3i3kurbnUKQXX+de6PZM0U9cjQl+wN
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This RFC connects the CS7542 forwarding engine to nftables hardware
flowtables on Securifi Almond+. It is separate from the CPU Ethernet
bring-up series. The main questions are the flowtable context interface,
QCA four-byte CPU framing, and conservative hardware resource lifetime.

The Ethernet driver retains DMA, MMIO, table and reset ownership. A
loadable frontend translates ordinary flowtable requests; a replaceable
algorithm operates through bounded typed table hooks. The switch format
is selected with the existing dsa-tag-protocol property before ports are
opened. Laboratory marker/observer commands and timed tag switching have
been removed from this composition.

Hardware qualification of the OpenWrt 6.18.64 precursor:
- Separate physical LAN 1 and WAN with normal firewall4 NAT and the LuCI
  hardware-flow-offloading option. Server observed the router WAN address.
- UDP IP 512/1400/1500, DF set/clear, exact bidirectional data and TTL 63.
  Without offload CPU captured 72/72 marked packets; with offload 4/212.
- The four CPU packets are refresh pairs near 30 and 60 seconds. Sticky HIT
  bits do not prove a new lastused timestamp, so the driver conservatively
  lets Linux age and relearn a flow rather than inventing activity.
- TCP exchanged 2,293,760 verified bytes over 70 seconds. TCP/UDP conntrack
  showed HW_OFFLOAD at 3, 35 and 69 seconds. TCP stacks accepted the data;
  this is not an independent checksum capture of every TCP segment.
- Eight connections used 16 selectors sharing one immutable result. Removing
  one did not alter the seven remaining selectors or their forwarding.
These are correctness measurements at a controlled rate, not throughput
benchmarks. They were made on the precursor, not these exact Linux bytes.

Validation of this Linux composition:
- Full ARM zImage and modules build, COMPILE_TEST=n, no platform series.
- Seven real sk_buff KUnit tests passed under UML: tag/flow dissection,
  VLAN and checksum metadata, clones, port dispatch and nonlinear headers.
- Current table/algorithm and guard code passed 590,845 checks under each
  of GCC and Clang, with ASan/UBSan. Tests cover concurrent selectors,
  sharing, both removal orders, capacity, transient failures and permanent
  failure retention. This is software fault injection, not hardware proof.

Limits and review questions:
- Wired IPv4 TCP/UDP only; Wi-Fi, IPv6 and unsupported policies use CPU.
- There are 16 selectors and eight immutable results. Identical actions can
  share/rebind results; incompatible results exhaust this pool until a
  verified engine reset. General result reclamation is not implemented.
- HIT accounting can cause a brief CPU refresh on each Linux timeout.
  No hardware packet/byte counters are fabricated.
- Ethernet/QCA/MDIO remain built in; suspend and forced module removal are
  excluded. The development modules require checked detachment. Should
  this replaceable interface be consolidated into the Ethernet driver?
- Is directional route MTU plus established TCP context appropriate in
  flow_cls_offload, or should flowtable expose these differently?
- Is dsa-tag-protocol the right selection interface for this parser need?
- What hardware drain evidence is needed before safely replacing different
  result records or clearing the sticky HIT bitmap?

Prerequisites, applied in this order on Linux 7.4-rc4:
- Global controls v4:
https://lore.kernel.org/all/20261125-cs7542-syscon-v4-0-3337bb0d3b48@gmail.com/
- Ethernet v2:
https://lore.kernel.org/all/20261125-b4-cs7542-ethernet-v2-0-d0ea3c6eb375@gmail.com/
- MDIO v2:
https://lore.kernel.org/all/20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com/

The platform/DTS series is not needed for compilation. A bootable Almond+
configuration additionally needs that board support and qca4 on both CPU
ports. This RFC does not reroll or replace any prerequisite series.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
Fil Dunsky (7):
      dt-bindings: net: dsa: allow the QCA four-byte tag protocol
      net: dsa: add a QCA four-byte CPU tagger
      netfilter: flowtable: expose route MTU and established TCP context
      net: cortina: add a serialized CS7542 forwarding engine owner
      net: dsa: qca8k: select the four-byte format before port activation
      net: cortina: connect wired IPv4 NAT to nftables hardware flowtables
      docs: networking: describe the CS7542 flowtable RFC limits

 .../devicetree/bindings/net/dsa/dsa-port.yaml      |   1 +
 .../ethernet/cortina/cs7542-flowtable.rst          | 112 +++
 MAINTAINERS                                        |   5 +
 drivers/net/dsa/qca/persistent_qca4.h              | 178 ++++
 drivers/net/dsa/qca/persistent_qca4_mtu.h          | 165 ++++
 drivers/net/dsa/qca/qca8k-8xxx.c                   | 123 ++-
 drivers/net/dsa/qca/qca8k-common.c                 |  42 +-
 drivers/net/dsa/qca/qca8k-persistent-boot.inc      | 632 +++++++++++++
 drivers/net/dsa/qca/qca8k-persistent-lifecycle.inc | 394 +++++++++
 drivers/net/dsa/qca/qca8k.h                        |  40 +
 drivers/net/ethernet/cortina/Kconfig               |  64 ++
 drivers/net/ethernet/cortina/Makefile              |  14 +-
 drivers/net/ethernet/cortina/cs752x_ne.c           | 120 +++
 drivers/net/ethernet/cortina/cs7542_fe_live.c      | 735 ++++++++++++++++
 drivers/net/ethernet/cortina/cs7542_ft_live.c      | 415 +++++++++
 drivers/net/ethernet/cortina/cs_fe_acl_encode.c    | 124 +++
 drivers/net/ethernet/cortina/cs_fe_acl_guard.c     | 324 +++++++
 drivers/net/ethernet/cortina/cs_fe_acl_guard.h     |  47 +
 drivers/net/ethernet/cortina/cs_fe_backend.h       | 228 +++++
 .../net/ethernet/cortina/cs_fe_backend_algorithm.c | 976 +++++++++++++++++++++
 .../net/ethernet/cortina/cs_fe_backend_dispatch.c  | 433 +++++++++
 .../net/ethernet/cortina/cs_fe_backend_module.c    | 164 ++++
 drivers/net/ethernet/cortina/cs_fe_encode.c        | 562 ++++++++++++
 drivers/net/ethernet/cortina/cs_fe_encode.h        |   5 +
 drivers/net/ethernet/cortina/cs_fe_fields.h        | 339 +++++++
 drivers/net/ethernet/cortina/cs_fe_format.h        |  23 +
 drivers/net/ethernet/cortina/cs_fe_hot.c           |  84 ++
 drivers/net/ethernet/cortina/cs_fe_hot.h           |  15 +
 drivers/net/ethernet/cortina/cs_fe_hot_access.c    | 276 ++++++
 drivers/net/ethernet/cortina/cs_fe_hot_access.h    |  55 ++
 drivers/net/ethernet/cortina/cs_fe_hot_codec.c     |   2 +
 drivers/net/ethernet/cortina/cs_fe_hot_compare.h   |  47 +
 drivers/net/ethernet/cortina/cs_fe_hot_internal.h  |  44 +
 drivers/net/ethernet/cortina/cs_fe_hot_lineage.c   | 138 +++
 drivers/net/ethernet/cortina/cs_fe_hot_lineage.h   |  70 ++
 drivers/net/ethernet/cortina/cs_fe_hot_tables.c    | 920 +++++++++++++++++++
 drivers/net/ethernet/cortina/cs_fe_native.inc      | 668 ++++++++++++++
 .../net/ethernet/cortina/cs_fe_native_activity.inc | 237 +++++
 drivers/net/ethernet/cortina/cs_fe_native_mtu.h    |  43 +
 drivers/net/ethernet/cortina/cs_fe_native_mtu.inc  | 128 +++
 drivers/net/ethernet/cortina/cs_fe_native_state.h  |  24 +
 drivers/net/ethernet/cortina/flowtable/Makefile    |   2 +
 .../cortina/flowtable/codec/cs_ft_rewrite.c        | 234 +++++
 .../cortina/flowtable/codec/cs_ft_rewrite.h        |  42 +
 .../net/ethernet/cortina/flowtable/cs7542_fw4.c    | 437 +++++++++
 .../ethernet/cortina/flowtable/cs7542_rx_path.c    | 225 +++++
 .../ethernet/cortina/flowtable/cs7542_rx_path.h    |  35 +
 drivers/net/ethernet/cortina/flowtable/nf_native.c |  90 ++
 drivers/net/ethernet/cortina/flowtable/nf_native.h |  31 +
 include/linux/cs7542_fe_backend.h                  |  65 ++
 include/linux/cs7542_fe_codec.h                    | 145 +++
 include/linux/cs7542_fe_live.h                     |  58 ++
 include/linux/cs7542_fe_native.h                   |  34 +
 include/linux/cs7542_ft_live.h                     |  70 ++
 include/linux/dsa/qca8k_persistent.h               |  45 +
 include/net/dsa.h                                  |  21 +-
 include/net/flow_offload.h                         |   5 +
 net/dsa/Kconfig                                    |  30 +
 net/dsa/Makefile                                   |   2 +
 net/dsa/tag_qca4.c                                 | 165 ++++
 net/dsa/tag_qca4_kunit.h                           | 469 ++++++++++
 net/netfilter/nf_flow_table_offload.c              |  25 +-
 62 files changed, 11218 insertions(+), 28 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261125-almondplus-offload-rfc-149cfb29ade9
prerequisite-message-id: <20261125-cs7542-syscon-v4-0-3337bb0d3b48@gmail.com>
prerequisite-patch-id: a9208276c628f8741a807d0e5c5945d4bf211c8a
prerequisite-patch-id: 65d46bb3caaa8518ee561f65d3f603ade396fff9
prerequisite-patch-id: a0ed5fbcfa308b16eaf265371a6697ad0aea6802
prerequisite-patch-id: bb8ffd99cb30e5a0b47881f6ba19a36329d5f4f2
prerequisite-patch-id: 7fbe9405265ef3d1ec62811415a46c0061afd7c8
prerequisite-patch-id: 01ece2c91e080d5cae6af81944159373776484ca
prerequisite-message-id: <20261125-b4-cs7542-ethernet-v2-0-d0ea3c6eb375@gmail.com>
prerequisite-patch-id: aecabdb905864eca2f0634c4d08c78194d3ceffc
prerequisite-patch-id: 14f8d8de3d9bff0276c1f0a54e3f42727d40d41a
prerequisite-patch-id: f42fb7a3c96e1ea44a7cf4495929acb9fdc47349
prerequisite-message-id: <20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com>
prerequisite-patch-id: 3656dbe3324c7bb9ec757a4c13c990cd28ec3d2a
prerequisite-patch-id: 268165424b18f66611028ebbea04dbb43cd4a7c5
prerequisite-patch-id: 33fc64ae4aa932467903052b4f27bce0f8b5e7c7

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

