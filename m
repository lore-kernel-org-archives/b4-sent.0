From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/3] iommu/mediatek-v1: fix the driver + mt6572 support
Date: Wed, 09 Sep 2026 17:14:04 +0300
Message-Id: <20260909-6572-iommu-v1-0-de261da09fb2@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDWhoRVXEYvRDkbiJ62KRNxds
 fwW713gyTF5qJMLHB3seV0i8jQBM+IykGAbDTKTKtOyEKrUUvA6z0FYJF2hRVSlgRhsjno+v1n
 T/vahm8js7wHu+wGvI8UlbgAAAA==
X-Change-ID: 20260724-6572-iommu-dae78adaa65c
To: Yong Wu <yong.wu@mediatek.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: iommu@lists.linux.dev, linux-mediatek@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788963261; l=1496;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=uOvO7Uzwwoe+4sbG4xOBTQfvrDD2qD2yTL1O7zXzwnA=;
 b=i0i1FiCTJpC+cIW9dxpYnEDhoPKkkIOIjFygBYU4F309XWXCI9cmMfZ1jrIWHFPCUslryK9Ut
 AV1kpB08YqGA78ZvP3n0xfS1XDtxBw7CPzbjyAHi27A+9Ls0LDEO6in
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series fixes silently broken IOMMU v1 driver and adds mt6572
SoC support.

It appears that currently the driver is not working at all... IOMMU core
will silently reject the component bind unless there's of_xlate callback.
The fix is pretty straightforward - provide of_xlate callback (based on
mtk_iommu gen 2 driver) to let IOMMU attach devices.

This makes DRM subsystem use IOMMU like all gen 2 SoCs do.
It can be verified by reading overlay engine input address.
Before:
~ # devmem 0x14007040 32
0xBB900000

After:
~ # devmem 0x14007040 32
0x00000000

Note the changes weren't tested on mt2701, because I don't have such
hardware.

It's worth mentioning that some bits may apply to mt6582 and 6589,
however, they seem to have L2 cache for IOMMU, therefore patch 3 has
MT6572 IOMMU type, and not MT65XX.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Roman Vivchar (3):
      dt-bindings: iommu: mediatek: add mt6572
      iommu/mediatek-v1: fix IOMMU device binding
      iommu/mediatek-v1: add mt6572 support

 .../devicetree/bindings/iommu/mediatek,iommu.yaml  |   3 +
 drivers/iommu/mtk_iommu_v1.c                       | 158 ++++++++++++---------
 .../memory/mediatek,mt6572-memory-port.h           |  26 ++++
 3 files changed, 123 insertions(+), 64 deletions(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260724-6572-iommu-dae78adaa65c

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

