From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/3] media: rockchip: Add the IEP2 deinterlacer of
 RK3568/RK3588
Date: Sun, 15 Nov 2026 08:47:41 +0000
Message-Id: <20261115-iep2-v2-0-3d8798cd9a55@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zWNQQ6CMBBFr0JmbQ3TVBBX3MOwKO0IY4SSFomG9
 O4WiMuXvP/+CoE8U4BbtoKnhQO7MYE8ZWB6PXYk2CYGmcsCEXPBNEnRVroyBZWlUQqSOnl68Gf
 P3JuDw7t9kpm37Wb0HGbnv/vPgpv3T6ojuaDIhb6StXTREgnrbtD8Ohs3QBNj/AHMdJxwqgAAA
 A==
X-Change-ID: 20261110-iep2-b9a9c6e77c44
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Alex Bee <knaerzche@gmail.com>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794732461; l=2184;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=CP/GfEF6q6iAXiPRajx03x8XxJzaza0j12kU0I34ReM=;
 b=/nL2ov0291Jhw5UthMWgnc2poPEBaUsCuTKzVtpKz58fI7340e/KpJ6qb6YBiIy99TQA5Hl+p
 jUZxhdkzTpaDizpV5GUYw8t0eNPHHHVyv0nDWfUfG5b/rfTkHCGFwGF
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 mem2mem driver for the IEP2 deinterlacer of the RK3568 and
RK3588, with its binding and the RK3588 DT node. It is based on the
Rockchip vendor driver; the V4L2 side follows Alex Bee's IEP driver.

Tested on an Orange Pi 5 (RK3588S) with a 7.3-based kernel; build-tested
on media next. v4l2-compliance 59/59, all four modes at 576i/1080i without
IOMMU faults. Not tested: RK3568. DMABUF imports of exactly the image
size are refused, because of the 4 KiB OUTPUT padding (see 2/3).

Developed with Claude (Anthropic), which wrote the code and the commit
messages; I reviewed every change.

---
Changes in v2:
- 2/3: return the held OUTPUT and second CAPTURE buffers when a job cannot start (Sashiko)
- 2/3: clear only the interrupt bits that were read (Sashiko)
- 2/3: in remove(), unregister the video device before suspending the m2m core (Sashiko)
- Shorter cover, driver commit message, doc and comments
- Link to v1: https://patch.msgid.link/20261114-iep2-v1-0-a8edde5a21e1@gmail.com

---
Arun Iyengar (3):
      media: dt-bindings: Add Rockchip IEP2 deinterlacer
      media: rockchip: Add IEP2 deinterlacer driver
      arm64: dts: rockchip: Add IEP2 deinterlacer to RK3588

 Documentation/admin-guide/media/rockchip-iep2.rst  |   32 +
 Documentation/admin-guide/media/v4l-drivers.rst    |    1 +
 .../bindings/media/rockchip,rk3568-iep2.yaml       |   95 ++
 MAINTAINERS                                        |    9 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |   22 +
 drivers/media/platform/rockchip/Kconfig            |    1 +
 drivers/media/platform/rockchip/Makefile           |    1 +
 drivers/media/platform/rockchip/iep2/Kconfig       |   16 +
 drivers/media/platform/rockchip/iep2/Makefile      |    3 +
 drivers/media/platform/rockchip/iep2/iep2-regs.h   |  191 +++
 drivers/media/platform/rockchip/iep2/iep2.c        | 1280 ++++++++++++++++++++
 drivers/media/platform/rockchip/iep2/iep2.h        |  106 ++
 12 files changed, 1757 insertions(+)
---
base-commit: ad6549a46748d00818483b535e5cd2a704685c98
change-id: 20261110-iep2-b9a9c6e77c44

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

