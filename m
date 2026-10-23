From: Ishu Brar <patches@brar.si>
Subject: [PATCH v3 0/4] drm/msm/adreno: Add Adreno 620
Date: Fri, 23 Oct 2026 15:23:30 +0530
Message-Id: <20261023-adreno-a620-v3-0-2d1d566e5e13@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwQ6CMBAFf4X0bE27hSKe/A/jodCtrAcgLTYaw
 r/b4kFNPE7yZt7CAnrCwI7FwjxGCjQOCdSuYF1vhitysokZCNBSSM2N9TiM3GgQ3BlE3TStOoB
 jyZg8OnpstfPlzeHe3rCbcyIvegrz6J/bXZR5978cJRe8NDVaDVLY2p5ab/w+EMvdCF8mqF8Tk
 imtrspOuQps9THXdX0B3G78avAAAAA=
X-Change-ID: 20261016-adreno-a620-faee699b382f
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792749211; l=5003;
 i=patches@brar.si; h=from:subject:message-id;
 bh=q46zBhiazj9Xsh580kJqKCGh/wiL2DqG+nYc6I/waQg=;
 b=d++vNnmxKYjiPwNGMBGPCpNwz4XIfHtO66axuDrueods6TC1fLl2qj8WLX+02xj8LUVAzS84n
 fk7Ln1MlrYIDjvafH1tLuVe9O3eP/N6Utqv8Ucu2EdK8EdgnCYBz9+0
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds the Adreno 620 GPU found in the Qualcomm SM7250 (Snapdragon
765/765G/768G) to the msm driver. It is an A650 derivative using the a650
SQE/GMU firmware and a620_zap.mbn. On top of the catalog entry it needs
one A620 specific GMU change: the A620 has no PDC setup from AOP, so the
PDC sequencer is programmed from the driver (xo/mx/cx addresses from
cmd-db). Without it the RSC never acks the second power-up and the device
hangs.

Tested on a OnePlus Nord (SM7250) running mainline: the GPU, GMU and
Vulkan work. This needs the SM7250 SMMU series [1], otherwise the device
is reset when the first per-process pagetable is created. It also needs
the SM7250 interconnect series [2]: the GPU OPP table gets its bandwidth
levels from those providers and the GMU bandwidth table is generated from
them and the BCM list of the catalog entry. Without bandwidth levels the
GMU falls back to the generic A630 table, whose BCM addresses do not
exist on SM7250, and the first GX performance vote times out.
The SoC devicetree nodes are not part of this series; they will be sent
separately once the SoC dtsi is accepted.

[1] https://lore.kernel.org/all/20261023-smmu-sm7250-v2-0-8bb881ce19f5@brar.si/
[2] https://lore.kernel.org/all/20261023-icc-sm7250-v1-0-1e47c1226857@brar.si/

Signed-off-by: Ishu Brar <patches@brar.si>
---
Changes in v3:
- Dropped the bandwidth table patch: the GMU table is generated from the
  BCM list in the catalog entry, which needs bandwidth levels in the OPP
  table, provided by the interconnect series [2] (Konrad).
- Moved adreno_is_a620() to the PDC patch, its only user.
- New patch: factor the common BCM list out of the A690 entry into a
  shared array; the A620 entry refers to it (Konrad).
- Reworded the catalog patch message accordingly.
- Testing: the generated-table path is the one tested for v2 on the
  OnePlus Nord, unchanged here; the shared BCM list refactor was build
  tested.
- Link to v2: https://patch.msgid.link/20261023-adreno-a620-v2-0-1d654c3f52d5@brar.si

Changes in v2:
- Patch 3: also program the VRM command (vrm.soc + 4) in TCS1 and TCS3
  when cmd-db has it, as the downstream driver does (Konrad).
- Patch 4: GMU clock gating mode is 0x00020202 as downstream (was
  0x00020200); add the SH0/MC0/ACV BCM list for the generic bandwidth
  table. The bus widths are the ones the other A6xx/A7xx parts use.
- Patch 2 is kept for now: the generic table is only used when the OPP
  table has bandwidth levels, which needs the SM7250 interconnect
  driver and DT that are not upstream yet. Without it the A620 would
  fall back to the A630 table.
- Testing: v2 was re-tested on the OnePlus Nord (these changes on top
  of my 7.3-rc7 port tree, not on msm-next), with the interconnect
  path and OPP bandwidth levels in the GPU node. Vulkan workloads ran
  across GPU power cycles and all four GPU frequencies; each frequency
  selected its own bandwidth level, the generated BCM votes scale
  linearly with the OPP bandwidth and the GMU accepted the table. I
  could not read back the resulting DDR frequency.
- Protect map (patch 4 follow-up suggested by Konrad): not included
  yet, waiting for the downstream reference of the 0x1c800 range.
- Link to v1: https://patch.msgid.link/20261016-adreno-a620-v1-0-4a7ed6210d7d@brar.si

To: Rob Clark <robin.clark@oss.qualcomm.com>
To: Dmitry Baryshkov <lumag@kernel.org>
To: Abhinav Kumar <abhinav.kumar@linux.dev>
To: Jessica Zhang <jesszhan0024@gmail.com>
To: Sean Paul <sean@poorly.run>
To: Marijn Suijten <marijn.suijten@somainline.org>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>
To: Maxime Ripard <mripard@kernel.org>
To: Thomas Zimmermann <tzimmermann@suse.de>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: dri-devel@lists.freedesktop.org
Cc: freedreno@lists.freedesktop.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Ishu Brar (4):
      dt-bindings: display: msm: Document Adreno 620 and its GMU
      drm/msm/a6xx: Program the PDC sequencer on Adreno 620
      drm/msm/a6xx: Factor out the common BCM list
      drm/msm/adreno: Add Adreno 620

 .../devicetree/bindings/display/msm/gmu.yaml       |  2 +
 .../devicetree/bindings/display/msm/gpu.yaml       |  1 +
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c          | 48 +++++++++++++++++-----
 drivers/gpu/drm/msm/adreno/a6xx_gmu.c              | 35 +++++++++++++---
 drivers/gpu/drm/msm/adreno/adreno_gpu.h            |  5 +++
 5 files changed, 75 insertions(+), 16 deletions(-)
---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261016-adreno-a620-faee699b382f

Best regards,
--  
Ishu Brar <patches@brar.si>

