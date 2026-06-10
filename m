From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v8 0/9] media: camss: Add support for C-PHY configuration
 on Qualcomm platforms
Date: Wed, 10 Jun 2026 20:28:20 +0200
Message-Id: <20260610-qcom-cphy-v8-0-cd4387785179@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMSsKWoC/23Oz07DMAwG8FeZcibIzh8n5cR7IA5N4tAc2EY7V
 RtT352sEmqKOH6Wf599FxOPhSfxcriLkecyldOxBv90EHHojx8sS6pZKFAWETr5FU+fMp6Hmwz
 Bx5B6jGSMqPvnkXO5rl1v7zUPZbqcxttaPeNj+l/LjBIkks2OXReA8bVcy+U5fotHx6w2p8C0T
 lVHQVvOPoBD3jv96wgQXet0dT6yox4ouxT2zmxOA7bOVMdWa6SkYiS7d3ZzVu+cXf9kyKSCSX8
 dba5ebB2t9yAxBGtd7/fOtc62zlVnFEXtuAPweXPLsvwAxrmRR/ABAAA=
X-Change-ID: 20251109-qcom-cphy-bb8cbda1c644
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Cc: Frank Li <Frank.Li@nxp.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6501; i=david@ixit.cz;
 h=from:subject:message-id; bh=93ZJSfEZSJ5zjTpfrChvVSSiLVSjQRNkQ88bLdsaWgg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqKazHYqli7fxnFeO44lHtE9HpNMAk+6wDoRrdO
 20JCb87bpuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaimsxwAKCRBgAj/E00kg
 clXsD/49H3qLZorEIqEEMdjlAE3T28quYx4W45vR3r51Yp7PHUz+vxGvTs1bzOku/nk8sCEFWXj
 m+L7W/TQwIuBn8dPGicN341+NIqztrXKw9yaano2MvT04MX/r4yaBBTUoSoz+N0CwTntCAph+8k
 f+LbheECxSlvWfsH4uwi5ebuLo3TNr7xEUthSumW4Tv3dWx77PNV8aYWInDNHNpOhDQYuf5n4OZ
 JDuJRvJsJ+PpmszEFORrR9YJjrcEb9uopHoZ5x9LLYwZC6Js10auhEnCrxtpNWNWIrwOWRRqGDN
 NqUGWcWoOG3+N7JJ66J5iE/68i70UEZvWdSZdB4q9/2I5oURC0RNL4pEZasrm5CwNiaYxz1IKTk
 a+pmR1TMJ3uC8JDV7DWKwCAB7pQji4fVqw3jwHujebJs1G3/ejynKaL7wqvRIfQ4kScgw7Ajd51
 /BA0pQuiKQ6CH75EWHiV/uKLLO26UjahdvoIe72pJBr1mne7HUBxeF+dQpaGz2iey/bw8Qd+wMc
 chWRrhYXJHOLPoib7kLOkSIkS54OeXJbcEt0+zrh89gFF6Tt3OGisBOlzpMxRM6MypIp4oLsaFJ
 YlZ+w/EWhk2v/c5wGZhtkZg9RH280Sc/Eq39z8SguyuySijHFj7QUDYqAChDCCVKdEgdL8GLqRF
 3jIpYa9KXowgClQ==
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
Changes in v8:
- Refactor the for cycle in csiphy_is_gen2 same way as
  csiphy_get_lane_mask(). (Frank)
- Dropped T-b/R-b/A-b from
  "media: qcom: camss: Account for C-PHY when calculating link frequency"
  as I did refactored the commit to not rely on `csiphy_id`. (Wenmeng)
- csiphy_get_lane_mask calculation fix. (Wenmeng)
- csiphy_lanes_enable now uses csiphy_get_lane_mask. (Wenmeng)
- Link to v7: https://lore.kernel.org/r/20260605-qcom-cphy-v7-0-426c37e9008f@ixit.cz

Changes in v7:
- Move logic out of switch. (Frank)
- Change csid cphy knob to phy_sel using enum. (Bryan, Frank)
- Link to v6: https://lore.kernel.org/r/20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz

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
David Heidelberg (9):
      media: qcom: camss: csiphy: Introduce PHY configuration
      media: qcom: camss: csiphy-3ph: Fix lane mask calculation
      media: qcom: camss: csiphy-3ph: Use odd bits for configuring C-PHY lanes
      media: qcom: camss: Prepare CSID for C-PHY support
      media: qcom: camss: Initialize lanes after lane configuration is available
      media: qcom: camss: csiphy-3ph: Add Gen2 v1.1 MIPI CSI-2 C-PHY init
      media: qcom: camss: csiphy-3ph: Update Gen2 v1.1 MIPI CSI-2 C-PHY init
      media: qcom: camss: Account for C-PHY when calculating link frequency
      media: qcom: camss: Enable C-PHY where available

 .../media/platform/qcom/camss/camss-csid-gen2.c    |   1 +
 drivers/media/platform/qcom/camss/camss-csid.c     |  11 +-
 drivers/media/platform/qcom/camss/camss-csid.h     |   6 +
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 229 ++++++++++++++++-----
 drivers/media/platform/qcom/camss/camss-csiphy.c   |   6 +-
 drivers/media/platform/qcom/camss/camss-csiphy.h   |   2 +
 drivers/media/platform/qcom/camss/camss.c          |  33 ++-
 drivers/media/platform/qcom/camss/camss.h          |   2 +-
 8 files changed, 229 insertions(+), 61 deletions(-)
---
base-commit: abe651837cb394f76d738a7a747322fca3bf17ba
change-id: 20251109-qcom-cphy-bb8cbda1c644

Best regards,
-- 
David Heidelberg <david@ixit.cz>

