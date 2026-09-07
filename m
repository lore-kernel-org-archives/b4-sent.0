From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v2 0/3] MediaTek mt6572 GCE support
Date: Mon, 07 Sep 2026 21:03:04 +0300
Message-Id: <20260907-6572-gce-v2-0-412a5b037290@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/0WNwQ6CMBAFf4Xs2ZpSpQVO/ofhUOoCa6QlLRIN4
 d9tMcbjJPPmrRDQEwaosxU8LhTI2QjikIEZtO2R0S0yCC4kV0IxWSjBeoNM6kLl2J11xyuI+uS
 xo9eeujZfDs/2jmZO+2QMFGbn3/vXkifvly3/2SVnnKmCt60+CVlWeJm8m50dNT2Oxo3QbNv2A
 ZzsLqW3AAAA
X-Change-ID: 20260727-6572-gce-6a571ef4af09
To: Jassi Brar <jassisinghbrar@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Houlong Wei <houlong.wei@mediatek.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788804305; l=2164;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=HgtayXsCIUeIjoLCd0VAVdyko3X79N+4XUCCWbHtSaE=;
 b=yayniW8Y6yLSeyUq3xZdAXuP0zHHoULMDH2Eb0J1TF6URCM2+dc94llu+rpbp5wEMXr8+eK2K
 eeAZ43tehwhBaToqLAV+a59vmdYg8ps0G8CbjJEjI3QT+dSsuyjVLK2
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the Global Command Engine found in
the mt6572 SoC.

Notably, the patch 2 introduces legacy ISA format, which is used on
mt6572, 6582 and 6592 SoCs. mt6577 doesn't have the GCE at all and
mt6595 is much more close to 6795/8173.
Patch 3 adds mt6572 platform data and legacy_isa forwarding to the
instruction JIT.

This format was reverse engineered from the Android HAL and uses 22-bit
offset with 2-bit subsystem ID, unlike the newer 16-bit offset and 8-bit
subsystem ID.
The mt6572 HAL includes workarounds for WFE and EOC instructions, emitting
another WFE as barrier at WFE, and JUMP +8 at EOC.
mt6582 and 6592 HAL dropped WFE barrier, but still have JUMP +8.

This sounds very much like some kind of software mitigations for hardware
bugs, but during testing on 6572 nothing bad happened so far. These
additional instructions are not included in the patches.

Note that while GCE can be used for e.g. mt6592 UFOE (which is at
0x14013000, so outside of the u16 range), currently the driver still uses
u16 for the offset, because I don't have any 6592 device.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v2:
- Move dt-bindings to mailbox directory from gce (Krzysztof)
- Clarify that only v2 and v3 GCEs support PA writes
- Link to v1: https://patch.msgid.link/20260728-6572-gce-v1-0-750bba32689e@protonmail.com

---
Roman Vivchar (3):
      dt-bindings: mailbox: mediatek,gce-mailbox: add mt6572
      soc: mediatek: cmdq-helper: add legacy GCE ISA support
      mailbox: mtk-cmdq: add mt6572 support

 .../bindings/mailbox/mediatek,gce-mailbox.yaml     |  1 +
 drivers/mailbox/mtk-cmdq-mailbox.c                 | 11 +++++
 drivers/soc/mediatek/mtk-cmdq-helper.c             | 57 +++++++++++++++-------
 include/dt-bindings/mailbox/mediatek,mt6572-gce.h  | 52 ++++++++++++++++++++
 include/linux/mailbox/mtk-cmdq-mailbox.h           |  1 +
 5 files changed, 104 insertions(+), 18 deletions(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260727-6572-gce-6a571ef4af09

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

