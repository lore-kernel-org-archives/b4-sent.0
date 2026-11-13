From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 00/12] media: verisilicon: Recover the Rockchip VPUs
 from faults and timeouts
Date: Fri, 13 Nov 2026 16:40:31 +0000
Message-Id: <20261113-hantro-robust-v3-0-82383c722ad2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ7CIBAFf6XhLAZou0FP/ofxABRajC0GKNE0/
 XehXhoTj7N5M7ugoL3VAZ2rBXmdbLBuylAfKqQGMfUa2y4zYoQBpZTgfIzeYe/kHCIGAYo3Rkt
 JAGXn6bWxr613vX05zPKuVSyRshhsiM6/t4eJlt2/dqKYYJDA4KRIK4249KOwj6NyIyrtxPY2+
 7VZtilvgZqu4bzme3td1w/AVxFU+gAAAA==
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
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: linux-media@vger.kernel.org, iommu@lists.linux.dev, 
 linux-rockchip@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sergei Khomenkov <shomenkow@gmail.com>, 
 Tharit Tangkijwanichakul <tharitt97@gmail.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588031; l=4890;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=AkkpZ+LzE3TI1DSPHQD95rroQvGeE01mP9oQsvvu9Z8=;
 b=Kb/N48draMY3CGgfyjmit/qt8xxtPSYAF59vR/1Q6hrsglNElhsPerE2qwinJw62QJxWRLYHX
 rJvWMwqphWhC8Fp/eeQQutkZ6NlXXq3wL+jZ3A8Q6Ch5hOMWVf2XXvH
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the RK3588, a VEPU121 encoder core that faults on an unmapped IOVA
never becomes idle again, and every later job times out. Patch 6
pulses the reset lines of the core on a timeout, and patch 7 then
reinitializes its IOMMU like rkvdec does. Patch 5 re-enables the
encoder interrupt after a reset. Patches 1 and 11 describe the optional
reset lines; patch 11 can go through the Rockchip tree.

Patch 4 stops asserting the resets on remove: the RK3588 AV1 resets
also cover its IOMMU, which then faults (SError) on runtime suspend.
It touches the same lines as Sergei Khomenkov's remove fix [1]; the
one applied second needs a trivial rebase.

Patches 8 to 10 and 12 describe the AV1 resets on its IOMMU too
(Philipp Zabel): vsi-iommu deasserts them on probe, and both drivers
acquire them only while using them. Patches 9 and 10 can go through
the iommu tree; patch 12 needs patch 8.

Patches 2 and 3 fix older bugs found by Sashiko: a NULL match in probe,
and a request left queued when the VPU can't resume. The ->run() error
paths are left to Sascha Hauer's series [2].

Tested on an Orange Pi 5 (RK3588S) on a v7.3 based kernel with other
out-of-tree Hantro patches (no 556ab0b2741d or 8e26d4c20ed2); v7.4-rc1
is build-tested only. AV1 unbind/rebind hit the SError before patch 4
and is clean with it. Provoked encoder timeouts and unmapped-IOVA
faults are reset and the next jobs encode.
All VPU cores still probe, H.264 fluster is unchanged, v4l2-compliance
-s passes on the JPEG encoder, and a job refused after a failed IOMMU
restore completes its request. Patch 3: code reading only.
With patches 8 to 10 and 12: AV1 unbind/rebind 20/20, AV1 fluster
unchanged (203/242), s2idle 3/3, encoder timeout recovery unchanged.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261106-hantro-remove-v1-1-d0a4678886d7@gmail.com
[2] https://lore.kernel.org/r/20260824-rk3588-jpegdec-v1-0-180a30a2852d@pengutronix.de

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>

---
Changes in v3:
- New patch 2: check the match data in hantro_probe() (Sashiko, v1)
- New patch 3: complete the request when the VPU can't resume
- Patch 7 (was 5): complete the request of a job refused after a failed
  IOMMU restore (Sashiko); fail the probe if the empty domain can't be
  allocated
- Patches 4 to 7 (were 2 to 5): shorter commit messages and comments
- New patches 8 to 10, 12: the AV1 resets on its IOMMU, released
  reset controls (Philipp Zabel)
- Patch 11 was 6
- Patch 1: Acked-by from Krzysztof
- Link to v2: https://patch.msgid.link/20261112-hantro-robust-v2-0-18561fd48838@gmail.com

Changes in v2:
- Patch 2: never assert the resets on remove or on the probe error path
- New patch 3: re-enable the encoder interrupt after a VEPU1/VEPU2 reset
- Patch 5 (was 4): restore the IOMMU only from the Rockchip encoder
  reset, only with reset lines and a DMA domain; refuse later jobs if
  the attach fails
- Link to v1: https://patch.msgid.link/20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com

---
Arun Iyengar (12):
      dt-bindings: media: rockchip,rk3568-vepu: Add the reset lines
      media: verisilicon: Check the match data in hantro_probe()
      media: verisilicon: Complete the request when the VPU can't resume
      media: verisilicon: Don't hold the VPU in reset after remove
      media: verisilicon: Enable the Rockchip encoder interrupt again after a reset
      media: verisilicon: Reset the Rockchip encoder cores on timeout
      media: verisilicon: Reinitialize the IOMMU after resetting an encoder core
      media: verisilicon: Acquire the reset lines only while using them
      dt-bindings: iommu: verisilicon: Add the reset lines
      iommu/vsi: Deassert the reset lines on probe
      arm64: dts: rockchip: Add the reset lines of the RK3588 VEPU121 cores
      arm64: dts: rockchip: Add the reset lines of the RK3588 AV1 IOMMU

 .../bindings/iommu/verisilicon,iommu.yaml          |  10 ++
 .../bindings/media/rockchip,rk3568-vepu.yaml       |  10 ++
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |  10 ++
 drivers/iommu/vsi-iommu.c                          |  16 ++++
 drivers/media/platform/verisilicon/hantro.h        |   5 +
 drivers/media/platform/verisilicon/hantro_drv.c    | 102 +++++++++++++++++----
 drivers/media/platform/verisilicon/hantro_hw.h     |   1 +
 .../media/platform/verisilicon/rockchip_vpu_hw.c   |  44 +++++++++
 .../media/platform/verisilicon/stm32mp25_vpu_hw.c  |   4 +
 drivers/media/platform/verisilicon/sunxi_vpu_hw.c  |   4 +
 10 files changed, 188 insertions(+), 18 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hantro-robust-6a6c84febb06

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

