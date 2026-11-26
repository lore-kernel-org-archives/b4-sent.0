From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v5 0/4] media: rockchip: Add the IEP2 deinterlacer of
 RK3568/RK3588
Date: Thu, 26 Nov 2026 19:51:26 +0000
Message-Id: <20261126-iep2-v5-0-3deac0976f10@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13Oyw6CMBAF0F8hXVtDhxaoK//DuCjtADXyCMVGQ
 /h3y8OEuLzJPXdmIg4Hi45cookM6K2zXRuCOEVE16qtkFoTMoEYUsZYTC32QAuppE4xyzTnJFT
 7AUv7Xmdu9y27V/FAPS52adTWjd3wWe94tvR+k3yb9IzGVOVoDAoFDNm1apR9nnXXkGXSwxGJH
 UFAickzmWsjlRD/KDkg2J/3SUAoORayTEEa+Ef8iNiOeEBZGusSRJkAFEc0z/MXItBd+UkBAAA
 =
X-Change-ID: 20261110-iep2-b9a9c6e77c44
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-rockchip@lists.infradead.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Alex Bee <knaerzche@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795722687; l=3049;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=dVuriuFsWIYJJR6FOm+moA+R4Cr1AZjWCwJzDebEMao=;
 b=zPucMdWJlKkneePzNkJIwe10RjrEJn9QLQJ6YaDMIjFjWPipShzWy/uh9Nppa6xt12jMeqG4J
 tKtU+lwvDyYA3FXnFlNRd5aHdPEpeMSYndhcyOaBC/0WyRmwdULdUjl
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 mem2mem driver for the IEP2 deinterlacer of the RK3568 and
RK3588, with its binding and the RK3588 DT node. The V4L2 side follows
Alex Bee's IEP driver. 2/4 adds the Rockchip IOMMU helper the driver
uses after a reset. 2/4 needs an ack from the IOMMU maintainers to go
through the media tree.

Tested on an Orange Pi 5 (RK3588S) with a 7.3-based kernel (KASAN,
lockdep); build-tested on media next. The test kernel also carries the
rockchip-iommu fixes 1-4 of
<20261110-iommu-rockchip-faults-v1-0-b1dda574dbb8@gmail.com>.
v4l2-compliance 59/59, FFmpeg deinterlacing (local patches; no
upstream application uses the driver yet), suspend and unbind while
streaming, forced watchdog and IOMMU fault resets. Not tested: RK3568.

Open: a reset that cuts a transfer (seen only with forced 1 ms
watchdogs) can leave the IOMMU with the transfer outstanding: its
stall and reset commands then time out. Jobs fail until PD_VDPU
powers off.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

---
Changes in v5:
- 1/4: clocks before interrupts (Sashiko)
- 2/4: new: rockchip_iommu_restore() (Nicolas)
- 3/4: use it instead of attaching an empty domain (Nicolas)
- 3/4: IRQ saves and clears the status; the thread finishes the job
  only if it cancels the watchdog; no spinlock (Nicolas)
- 3/4: drop the IOMMU fault detection, forced suspend and reset
  retries (Nicolas)
- 3/4: after a failed IOMMU restore, fail jobs until PD_VDPU powers
  off
- 3/4: defines for md_lambda and the default size; comment the motion
  table (Nicolas)
- Link to v4: https://patch.msgid.link/20261121-iep2-v4-0-760cf25f322b@gmail.com

---
Arun Iyengar (4):
      media: dt-bindings: Add Rockchip IEP2 deinterlacer
      iommu/rockchip: Add rockchip_iommu_restore()
      media: rockchip: Add IEP2 deinterlacer driver
      arm64: dts: rockchip: Add IEP2 deinterlacer to RK3588

 Documentation/admin-guide/media/rockchip-iep2.rst  |   32 +
 Documentation/admin-guide/media/v4l-drivers.rst    |    1 +
 .../bindings/media/rockchip,rk3568-iep2.yaml       |   95 ++
 MAINTAINERS                                        |    8 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |   22 +
 drivers/iommu/rockchip-iommu.c                     |   36 +
 drivers/media/platform/rockchip/Kconfig            |    1 +
 drivers/media/platform/rockchip/Makefile           |    1 +
 drivers/media/platform/rockchip/iep2/Kconfig       |   16 +
 drivers/media/platform/rockchip/iep2/Makefile      |    3 +
 drivers/media/platform/rockchip/iep2/iep2-regs.h   |  191 +++
 drivers/media/platform/rockchip/iep2/iep2.c        | 1263 ++++++++++++++++++++
 drivers/media/platform/rockchip/iep2/iep2.h        |  107 ++
 include/soc/rockchip/rockchip_iommu.h              |   17 +
 14 files changed, 1793 insertions(+)
---
base-commit: b4e3c4b6a36fd76f57bf3e48638f68ddecc54ba4
change-id: 20261110-iep2-b9a9c6e77c44

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

