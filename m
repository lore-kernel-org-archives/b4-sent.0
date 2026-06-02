From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v6 0/8] media: camss: Add support for C-PHY configuration
 on Qualcomm platforms
Date: Wed, 03 Jun 2026 01:30:38 +0200
Message-Id: <20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ5nH2oC/23OTWrDMBCG4asErasyo5+R01XvUbqwRqNai8aJH
 UzS4LtXMRTb0OU36HnRQ40yFBnV2+GhBpnKWPpTHfRyUNy1py/RJdWtDBiPCEd94f5b87m76xg
 bjqlFJudUfX8eJJfb0vr4rLsr47Uf7kt6wuf1v8qEGjSSz0HCMYLge7mV6yv/qGdjMqsz4LbOV
 EfReslNhICyd/bPESCGrbPVNSyBWqAcUtw7tzoLuHWuOvHWIiXDTH7v/Oq83Tm//FMgk4kubd0
 8z7/nOvhOgAEAAA==
X-Change-ID: 20251109-qcom-cphy-bb8cbda1c644
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5747; i=david@ixit.cz;
 h=from:subject:message-id; bh=FQSGsxJUavVmIbh1PvZEytyiaMY/zidGTGCoSvDEAkg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqH2ep7nbK5dTtpq95ihAgQkfyuvPJS9obA8Xib
 EAE5R1I8mmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCah9nqQAKCRBgAj/E00kg
 cuysEAC16VFplCtzOM6q48ppiN4rKxPYJMT79NqDnarWODRUJlU1tiKrUxy1dU2vlaQbjSOBLMT
 N57YfYv4JC7tp+zkdKG1LLWFIsNkwTw7U4abM4cI/ZYI2gjOWJTH+Cp/vIQ8oEF9sN4Tgnk1BUK
 dlTpQXDsPO4QoM1Bb+C5RYxZI4BYaIAx1DkfFHF0p1mypM1i0BqAh7a+eCYytc++OaA+Sc7hRZb
 GSGwz3qcU52w+mKQtEVts0gaygxxcAb7A9LytUWv01bwW3CADWSpc3srZz6TR79eQxmGKCFYnd8
 HR0t4IMGHABPbkpr/KR3gROaDvmzKe6tWHMAxGjuLteDhiIa65MyXzm2OoPQ/Geq3+WKPKeFy3S
 h5G4lU6xJBqCU/ztL1UURF9gs1rdIjEUOrcJ8PevxPYR5S3wUIKXGlhmq3Teb17lZSjJe1liwRZ
 LdLeOqd7q/bLshRb0b3WSuHHU6xiRRpdD2SGM6FSGJl/qrbF7Afqyb+jjWLIDWsc6e6PLt/nRfC
 4EpbplBejLMA4NTDGd5qYdDHflSpo6UEQWhCFs68GzgIqUzrnR3eISbgAMah8lbQifa+R27D34s
 novDoWzZGfnQLcyDEu7cQ1chZpGz4yKhS+Pynjr4mjf4yUCjjaUGsF4x38/Gnc/iSV7G64swFrs
 3EAh6iZL4eoJbSA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Note: WIP tag added, as not everything from the previous review round has
been addressed.

# Short summary

This patch series extends the Qualcomm CAMSS (Camera Subsystem),
including CSID and CSIPHY components, to support C-PHY mode configuration.

# Background and motivation

Modern smartphone cameras increasingly rely on MIPI C-PHY rather than 
D-PHY, thanks to its higher data throughput and signal efficiency.
As a result, many OEMs adopt C-PHY interfaces for main (rear) cameras on
Qualcomm-based devices.

Until now, mainline Linux lacked C-PHY configuration support for Qualcomm
chipsets, preventing bring-up of primary camera sensors on several
Snapdragon platforms. This series closes that gap.

 - Introduces C-PHY configuration support for the CAMSS driver stack,
   covering both CSID and CSIPHY blocks.
 - Successfully enables C-PHY operation on the Snapdragon 845 platform.
 - Tested on OnePlus 6 and 6T phones running mainline Linux,
   using the Sony IMX519 main camera sensor.
 - The new configuration allows other chipsets versionsto enable C-PHY by
   simply adding corresponding sensor driver support and csiphy
   initialization data, following the example set for sdm845.

With this patch series, mainline Linux gains working C-PHY support for
Snapdragon 845, paving the way for improved main camera functionality
across many Qualcomm-based devices. The groundwork also simplifies
future enablement efforts for additional SoCs and sensors.

Until merged, the series will be also available at:
  https://codeberg.org/sdm845/linux/commits/branch/b4/qcom-cphy

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v6:
- lanes_enable now uses WARN_ONCE instead of return values. (Sakari)
- Dropped Kodiak patch until it gets better documented.
- Document the 3ph C-PHY sdm845 registers a bit.
- Link to v5: https://lore.kernel.org/r/20260531-qcom-cphy-v5-0-6be0f62b4d65@ixit.cz

Changes in v5:
- Split first patch enabling C-PHY part into last patch. (Bryan)
- Fix the camss_get_link_freq crash. (Cory)
- Dropped patch whitelisting C-PHY, instead use nullptr check. (Bryan)
- Dropped A-b/R-b from
 "media: qcom: camss: Initialize lanes after lane configuration is available"
 and changed Petr to Co-developed by and owned the patch.
- Link to v4: https://lore.kernel.org/r/20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz

Changes in v4:
- Documented cphy parametr to camss_get_link_freq.
- Use BIT() macro for lane_mask. (Bryan)
- Correct lane_mask calculation. (Kieran + me)
- Removed comment for the D/C-PHY sequences init. (Bryan)
- Pass &csid->phy for calculate freq. (Bryan)
- Added missing cphy description to camss_get_link_freq. (kernel test robot)
- Gen2 v1.1 MIPI CSI-2 CPHY init hex to lowercase.
- Added back missed commit with improved electrical for sdm845 3ph.
- NOT addressed yet:
  - Proliferating special cases in switch statements on a per-SoC basis is verboten. 
  - is it possible to set clock_lane to say 0xff in DT ? 
- Link to v3: https://lore.kernel.org/r/20260117-qcom-cphy-v3-0-8ce76a06f7db@ixit.cz

Changes in v3:
- Make lanes_enable return sucess or error, since I couldn't move the
  configuration to the _init.
- Dropped R-b tags on
  "media: qcom: camss: Initialize lanes after lane configuration is available"
  as I changed formatting.
- Link to v2: https://lore.kernel.org/r/20251204-qcom-cphy-v2-0-6b35ef8b071e@ixit.cz

Changes in v2:
- This is still WIP patch series, thus I wanted to publish already
  changed parts to get feedback regarding to the direction of patchset.
- When switch to using odd bits, zeroed val which was left unitialized in v1.
- Accidentally missed archs added back in the commit moving lane regs to
  new location.
- Remove commit with reverting check for only D-PHY is supported and
  adjusted the check to also account for C-PHY.
- Documented link frequency calculation with defines. (Casey)
- Changed the cphy boolean to phy_cfg enum in the camss/camss-csiphy.
  (Brian)
- Added patch for csiphy-3ph enablement for sm7280 from Luca as I'm
  meanwhile trying to bring up the C-PHY sensor on FairPhone 5.
- Merged these two commits together
    csiphy-3ph: Enable sdm845 C-PHY sequence
    csiphy-3ph: Add Gen2 v1.1 MIPI CSI-2 CPHY init
  merged R-b.
- Link to v1: https://lore.kernel.org/r/20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz

---
David Heidelberg (8):
      media: qcom: camss: csiphy: Introduce PHY configuration
      media: qcom: camss: csiphy-3ph: Use odd bits for configuring C-PHY lanes
      media: qcom: camss: Prepare CSID for C-PHY support
      media: qcom: camss: Initialize lanes after lane configuration is available
      media: qcom: camss: csiphy-3ph: Add Gen2 v1.1 MIPI CSI-2 C-PHY init
      media: qcom: camss: csiphy-3ph: Update Gen2 v1.1 MIPI CSI-2 C-PHY init
      media: qcom: camss: Account for C-PHY when calculating link frequency
      media: qcom: camss: Enable C-PHY where available

 .../media/platform/qcom/camss/camss-csid-gen2.c    |   1 +
 drivers/media/platform/qcom/camss/camss-csid.c     |   8 +-
 drivers/media/platform/qcom/camss/camss-csid.h     |   1 +
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 243 +++++++++++++++++----
 drivers/media/platform/qcom/camss/camss-csiphy.c   |   6 +-
 drivers/media/platform/qcom/camss/camss-csiphy.h   |   2 +
 drivers/media/platform/qcom/camss/camss.c          |  36 ++-
 drivers/media/platform/qcom/camss/camss.h          |   2 +-
 8 files changed, 236 insertions(+), 63 deletions(-)
---
base-commit: b7bee4ca5688e30ca50fbc87b1b8f7eed7006c17
change-id: 20251109-qcom-cphy-bb8cbda1c644

Best regards,
-- 
David Heidelberg <david@ixit.cz>

