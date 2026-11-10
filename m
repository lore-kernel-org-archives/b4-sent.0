From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/5] media: verisilicon: Recover the Rockchip VPUs from
 faults and timeouts
Date: Tue, 10 Nov 2026 07:17:30 +0000
Message-Id: <20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBCF4avErBM0QqKrRIu0qaZFxoxFIN09q
 +X34P0JBJlQoC0SMJ4kFLYMUxbgl2GbUdGYDZWurDFGqzxGDoqDOyQqO1jf1BM6py3kz8440fX
 1uv63HG5FH98I3PcD4e6x4nEAAAA=
X-Change-ID: 20261110-hantro-robust-6a6c84febb06
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295050; l=3200;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=wAHE9TDB5EG/9Ciyb0qAJrepsYx4Tb9hG3yp7P255Ic=;
 b=145Zthse/3N7R1g8+D/6hOlCSMrtdtj1ta8EQGhHIpXiRPZt2zdJm7WbMxu2+bgoy3WgIDM/E
 gXyzQ9AKt+vCDIO+YXjJqRbZ980WvBuiiqR62ih0aZZnwqxaADOYfr1
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series makes the Hantro driver recover from a job that times out
on the Rockchip VPUs, and fixes a panic on module unload on the RK3588.

On the RK3588, a VEPU121 JPEG encoder core that reads an unmapped IOVA
faults in its IOMMU and never becomes idle again: the register-level
stop in the encoder reset operation isn't enough, the IOMMU can't be
stalled anymore ("Enable stall request timed out"), every later job
times out and unbinding the driver can lock up the system. Patches 3
and 4 pulse the reset lines of the core on a timeout and reinitialize
the IOMMU afterwards, the way rkvdec does. Patches 1 and 5 describe the
AXI/AHB reset lines of the four VEPU121 cores in the binding and in the
RK3588 device tree; the driver already handles optional resets, so
device trees without them keep working.

Patch 2 fixes a panic on module unload: the AV1 decoder resets of the
RK3588 also cover the bus interface of its IOMMU, and holding them
asserted after remove makes the IOMMU driver's runtime suspend hit
registers in reset (SError).

Patch 5 touches arch/arm64 only and can go through the Rockchip tree
independently of the driver patches; it is only useful together with
patch 3.

Tested on an Orange Pi 5 (RK3588S). Patch 2 was verified by unloading
and reloading the module with the AV1 decoder bound and a 1 s gap, which
panicked before the change and is clean with it. Patches 3 and 4 ran on
every encoder timeout since: a trace of a wedged VEPU121 job shows
hantro_watchdog() -> rockchip_vpu2_enc_reset() -> the IOMMU re-attach
with no stall or paging timeout, the next jobs on the same core succeed,
and the IOMMU runtime-suspends cleanly afterwards; later, ten JPEG
encode jobs with an unmapped input address were each reset by the
timeout and the following jobs encoded normally. The reset lines of
patches 1 and 5 are present on all four VEPU121 nodes of the live
device tree, dt_binding_check and CHECK_DTBS are clean, and the encoder
keeps working with them.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (5):
      dt-bindings: media: rockchip,rk3568-vepu: Add the reset lines
      media: verisilicon: Don't hold a VPU behind an IOMMU in reset after remove
      media: verisilicon: Reset the Rockchip encoder cores on timeout
      media: verisilicon: Reinitialize the IOMMU after a timeout
      arm64: dts: rockchip: Add the reset lines of the RK3588 VEPU121 cores

 .../bindings/media/rockchip,rk3568-vepu.yaml       | 10 +++
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |  8 +++
 drivers/media/platform/verisilicon/hantro.h        |  3 +
 drivers/media/platform/verisilicon/hantro_drv.c    | 77 +++++++++++++++++++++-
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 30 +++++++++
 5 files changed, 126 insertions(+), 2 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hantro-robust-6a6c84febb06

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

