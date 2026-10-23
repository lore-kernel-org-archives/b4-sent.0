From: Ishu Brar <patches@brar.si>
Subject: [PATCH v2 0/4] drm/msm/adreno: Add Adreno 620
Date: Fri, 23 Oct 2026 14:18:58 +0530
Message-Id: <20261023-adreno-a620-v2-0-1d654c3f52d5@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ7CIBBFr9LMWgygodZV72G6oGWw4wLMUImm6
 d2FunX5kvffXyEhEya4NiswZkoUQwF9aGCabbijIFcYtNRGSWWEdYwhCmu0FN4imq4bTxftoSy
 ejJ7ee+02/Di9xgdOS01UY6a0RP7sd1lV7385KyHF2bbojFbSta4f2fIxEQzbtn0B0Y5YkLYAA
 AA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792745340; l=4076;
 i=patches@brar.si; h=from:subject:message-id;
 bh=/beW+AELpxp6o1wu1hniusiXifJZlEukCyeC01/aOdM=;
 b=FQHQoc8nksHyFjwH9rtQud/6Sz7XiVo9yW+GxJLlCUUjw1Ls15rVTcsdPiz/S/b0//za1teSJ
 gD3SEC2o7apC+fT/I0o+6AihJHFhbUqZSi01k882SZIwpPELBzyZrqr
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds Adreno 620 GPU found in Qualcomm SM7250 (Snapdragon
765/765G/768G) to msm driver. It is A650 derivative using 
a650 SQE/GMU firmware and a620_zap.mbn. On top of catalog entry it
needs two A620 specific GMU changes:

 - A620 has no PDC setup from AOP, so PDC sequencer is
   programmed from driver (xo/mx/cx addresses from cmd-db). Without
   it RSC never acks second power-up and device hangs.
 - A bandwidth table with BCM addresses of this SoC. The generic
   A630 one does not exist on SM7250, so first GX performance vote
   times out.

Tested on OnePlus Nord (SM7250) running mainline: the GPU, GMU and
Vulkan work. This needs the SM7250 SMMU series [1] as well, otherwise
the device is reset when the first per-process pagetable is created.
The SoC devicetree nodes are not part of this series; they will be sent
separately once the SoC dtsi is accepted.

[1] https://lore.kernel.org/all/20261023-smmu-sm7250-v2-0-8bb881ce19f5@brar.si/

Signed-off-by: Ishu Brar <patches@brar.si>
---
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
      drm/msm/a6xx: Add a bandwidth table for the Adreno 620 GMU
      drm/msm/a6xx: Program the PDC sequencer on Adreno 620
      drm/msm/adreno: Add Adreno 620

 .../devicetree/bindings/display/msm/gmu.yaml       |  2 ++
 .../devicetree/bindings/display/msm/gpu.yaml       |  1 +
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c          | 35 ++++++++++++++++++++++
 drivers/gpu/drm/msm/adreno/a6xx_gmu.c              | 35 ++++++++++++++++++----
 drivers/gpu/drm/msm/adreno/a6xx_hfi.c              | 34 +++++++++++++++++++++
 drivers/gpu/drm/msm/adreno/adreno_gpu.h            |  5 ++++
 6 files changed, 106 insertions(+), 6 deletions(-)
---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261016-adreno-a620-faee699b382f

Best regards,
--  
Ishu Brar <patches@brar.si>

