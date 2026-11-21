From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v4 0/3] media: rockchip: Add the IEP2 deinterlacer of
 RK3568/RK3588
Date: Sat, 21 Nov 2026 14:25:36 +0000
Message-Id: <20261121-iep2-v4-0-760cf25f322b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13Oyw6CMBAF0F8hXVtDh/KoK//DuCjtADXySIuNh
 vDvlocJcXmTe+7MRBxag45coolY9MaZvguBnyKiGtnVSI0OmUAMGWMspgYHoKWQQmWY54pzEqq
 Dxcq815nbfcvuVT5QjYtdGo1xY28/6x3Plt5vkm+TntGYygK1xlQCQ3atW2meZ9W3ZJn0cETpj
 iCgRBe5KJQWMk3/UXJAsD/vk4BQcCxFlYHQcETzPH8B7n4B2hQBAAA=
X-Change-ID: 20261110-iep2-b9a9c6e77c44
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Alex Bee <knaerzche@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795271137; l=2350;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=G5R9VMIFiJU1tJNOmYpfUElrCWf6JYYQ7tduXHilQTo=;
 b=ZF5lg+BDUPoifHZlr601YFWm6SGCsP1AN87K283TtzRWDsLlHl5SL2TGW2Lv9oYTFxeFc4gKc
 hTIQcAzvEloCEcX2AMsVyk/x1pUuoIzYGbygGRUlUAdbcJPa5q9B+Oz
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 mem2mem driver for the IEP2 deinterlacer of the RK3568 and
RK3588, with its binding and the RK3588 DT node. The V4L2 side follows
Alex Bee's IEP driver.

Tested on an Orange Pi 5 (RK3588S) with a 7.3-based kernel (KASAN,
lockdep); build-tested on media next. v4l2-compliance 59/59, all four
modes at 1080i without IOMMU faults, s2idle and deep suspend while
streaming, unbind while streaming, forced watchdog and IOMMU fault
resets. Not tested: RK3568. DMABUF imports of exactly the image size
are refused, because of the 4 KiB OUTPUT padding (see 2/3).

One case is still open: a reset during a transfer, seen only with
forced watchdog resets, can leave the IOMMU busy. Jobs then fail
without DMA and the driver suspends at once so that PD_VDPU powers
off, which restores it. While another device of the domain, e.g. a
video decoder, keeps it on, the jobs keep failing.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

---
Changes in v4:
- 2/3: fail the probe if the IOMMU domain allocation fails (Sashiko)
- Link to v3: https://patch.msgid.link/20261120-iep2-v3-0-e94eb9f629d2@gmail.com

---
Arun Iyengar (3):
      media: dt-bindings: Add Rockchip IEP2 deinterlacer
      media: rockchip: Add IEP2 deinterlacer driver
      arm64: dts: rockchip: Add IEP2 deinterlacer to RK3588

 Documentation/admin-guide/media/rockchip-iep2.rst  |   32 +
 Documentation/admin-guide/media/v4l-drivers.rst    |    1 +
 .../bindings/media/rockchip,rk3568-iep2.yaml       |   95 ++
 MAINTAINERS                                        |    8 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |   22 +
 drivers/media/platform/rockchip/Kconfig            |    1 +
 drivers/media/platform/rockchip/Makefile           |    1 +
 drivers/media/platform/rockchip/iep2/Kconfig       |   16 +
 drivers/media/platform/rockchip/iep2/Makefile      |    3 +
 drivers/media/platform/rockchip/iep2/iep2-regs.h   |  191 +++
 drivers/media/platform/rockchip/iep2/iep2.c        | 1319 ++++++++++++++++++++
 drivers/media/platform/rockchip/iep2/iep2.h        |  108 ++
 12 files changed, 1797 insertions(+)
---
base-commit: ccf78740d63813c452c035b57d17a650492562fa
change-id: 20261110-iep2-b9a9c6e77c44

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

