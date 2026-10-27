From: Ishu Brar <patches@brar.si>
Subject: [PATCH v4 0/5] drm/msm/adreno: Add Adreno 620
Date: Tue, 27 Oct 2026 12:44:33 +0530
Message-Id: <20261027-adreno-a620-v4-0-b0095e028c76@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ7CIBCF4as0rMXAUKi68h7GBe1MLS5aA5Vom
 t5dqAttYly+ZL5/JhbIOwrsUEzMU3TBDX0a5aZgTWf7C3GHaTMQYKSQhlv01A/cGhC8tURmv6/
 VDlqWxM1T6x5L7XR+73Cvr9SMOZEvOhfGwT+Xd1Hmu9/lKLngpa0IDUiBFR5rb/02OJa7Eb4kq
 LWEJCUaXTaq1YB6LdUfqZIElKiNIU1SfeQ8zy/yclACKgEAAA==
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
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Ishu Brar <patches@brar.si>, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793085280; l=7044;
 i=patches@brar.si; h=from:subject:message-id;
 bh=UZuWL8I8AUCMf4WOo/yxkZDn4vGNt2zk+67Y7dvKnNk=;
 b=2ccy2JF/uZuSGR4dghp3kall8zPnga0maLNT7hhM7FrmSdNrv3bi8Fuy9KnyKerUXwXZ9maZ9
 RPdjkDmhD7FDcvnxoQftmR6adkPjd1wVbz6YEKwLuGIuvxgUTtKLeZM
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
hangs. The last patch reserves a range of GMU registers in the A650
protect list, which A620 and A650 share.

Tested on a OnePlus Nord (a 7.3 based tree): the GPU, GMU and Vulkan work.
This needs the SM7250 SMMU series [1], otherwise the device is reset when
the first per-process pagetable is created. It also needs the SM7250
interconnect series [2]: the GPU OPP table gets its bandwidth levels from
those providers and the GMU bandwidth table is generated from them and the
BCM list of the catalog entry. Without bandwidth levels the GMU falls back
to the generic A630 table, whose BCM addresses do not exist on SM7250, and
the first GX performance vote times out. The GMU clock and the GPU power
domains come from the SM7250 graphics clock controller series [3].
The GPU also needs the SM7250 UBWC configuration [4]: without it
qcom_ubwc_config_get_data() fails and the GPU does not probe.
The SoC devicetree nodes are not part of this series; they will be sent
separately once the SoC dtsi is accepted.

[1] https://lore.kernel.org/all/20261023-smmu-sm7250-v2-0-8bb881ce19f5@brar.si/
[2] https://lore.kernel.org/all/20261026-icc-sm7250-v3-0-aa303226298c@brar.si/
[3] https://lore.kernel.org/all/20261027-gpucc-sm7250-v2-0-773056e4043e@brar.si/
[4] https://lore.kernel.org/all/20261027-ubwc-sm7250-v1-1-e766b1e264cf@brar.si/

---
Changes in v4:
- Patch 1: add Krzysztof Kozlowski's Reviewed-by from v1, which was
  missing in v3 (noticed by Rob Herring). The patch itself is unchanged.
- Patch 2: no code change. I compared the PDC commands with the downstream
  kgsl driver of the platform: for A620 it writes the same mx, cx and xo
  commands and, when cmd-db has the vrm.soc resource, the VRM command at
  vrm.soc + 4, in both TCS1 and TCS3, all with msgid 0x10108 (Konrad
  Dybcio). The VRM commands are only written when cmd-db has vrm.soc, as
  downstream does. The entry is there on the OnePlus Nord (vrm.soc at
  0x43400), so they are written on that phone.
- New patch 5: protect the GMU registers in 0x1c800-0x1e7ff (Konrad
  Dybcio). The downstream kgsl protect table of the OnePlus Nord has no
  entry for this range, so the patch relies on the register list in its
  message.
- Testing: patch 5 was tested on the OnePlus Nord (a 7.3 based tree with
  the line added, not msm-next): vkcube ran 900 frames in a Wayland
  session across GPU frequency changes, with no protect, fault or GMU
  errors in the kernel log. I did not test a write into the range being
  rejected, and A650 and the other users of the table (A621, A623, A702,
  A704) are not tested.
- Updated the interconnect link [2] to v3 and added the graphics clock
  controller series [3] and the UBWC configuration [4] as dependencies.
- Link to v3: https://patch.msgid.link/20261023-adreno-a620-v3-0-2d1d566e5e13@brar.si

Changes in v3:
- Dropped the bandwidth table patch: the GMU table is generated from the
  BCM list in the catalog entry, which needs bandwidth levels in the OPP
  table, provided by the interconnect series [2] (Konrad Dybcio).
- Moved adreno_is_a620() to the PDC patch, its only user.
- New patch: factor the common BCM list out of the A690 entry into a
  shared array; the A620 entry refers to it (Konrad Dybcio).
- Reworded the catalog patch message accordingly.
- Testing: the generated-table path is the one tested for v2 on the
  OnePlus Nord, unchanged here; the shared BCM list refactor was build
  tested.
- Link to v2: https://patch.msgid.link/20261023-adreno-a620-v2-0-1d654c3f52d5@brar.si

Changes in v2:
- Patch 3: also program the VRM command (vrm.soc + 4) in TCS1 and TCS3
  when cmd-db has it, as the downstream driver does (Konrad Dybcio).
- Patch 4: GMU clock gating mode is 0x00020202 as downstream (was
  0x00020200); add the SH0/MC0/ACV BCM list for the generic bandwidth
  table. The bus widths are the ones the other A6xx/A7xx parts use.
- Patch 2 is kept for now: the generic table is only used when the OPP
  table has bandwidth levels, which needs the SM7250 interconnect driver
  and DT that are not upstream yet. Without it the A620 would fall back to
  the A630 table.
- Testing: v2 was re-tested on the OnePlus Nord (these changes on top of
  my 7.3-rc7 port tree, not on msm-next), with the interconnect path and
  OPP bandwidth levels in the GPU node. Vulkan workloads ran across GPU
  power cycles and all four GPU frequencies; each frequency selected its
  own bandwidth level, the generated BCM votes scale linearly with the OPP
  bandwidth and the GMU accepted the table. I could not read back the
  resulting DDR frequency.
- Protect map (patch 4 follow-up suggested by Konrad Dybcio): not included
  yet, waiting for the downstream reference of the 0x1c800 range.
- Link to v1: https://patch.msgid.link/20261016-adreno-a620-v1-0-4a7ed6210d7d@brar.si

To: Rob Clark <robin.clark@oss.qualcomm.com>
To: Dmitry Baryshkov <lumag@kernel.org>
To: Abhinav Kumar <abhinav.kumar@linux.dev>
To: Jessica Zhang <jesszhan0024@gmail.com>
To: Sean Paul <sean@poorly.run>
To: Marijn Suijten <marijn.suijten@somainline.org>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>
To: Maxime Ripard <mripard@kernel.org>
To: Thomas Zimmermann <tzimmermann@suse.de>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
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
Ishu Brar (5):
      dt-bindings: display: msm: Document Adreno 620 and its GMU
      drm/msm/a6xx: Program the PDC sequencer on Adreno 620
      drm/msm/a6xx: Factor out the common BCM list
      drm/msm/adreno: Add Adreno 620
      drm/msm/a6xx: Protect the 0x1c800-0x1e7ff GMU range on A620 and A650

 .../devicetree/bindings/display/msm/gmu.yaml       |  2 +
 .../devicetree/bindings/display/msm/gpu.yaml       |  1 +
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c          | 49 +++++++++++++++++-----
 drivers/gpu/drm/msm/adreno/a6xx_gmu.c              | 35 +++++++++++++---
 drivers/gpu/drm/msm/adreno/adreno_gpu.h            |  5 +++
 5 files changed, 76 insertions(+), 16 deletions(-)
---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261016-adreno-a620-faee699b382f

Best regards,
--  
Ishu Brar <patches@brar.si>

