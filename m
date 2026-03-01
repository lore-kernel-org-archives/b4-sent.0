From: David Heidelberg <david@ixit.cz>
Subject: [PATCH WIP v4 0/9] media: camss: Add support for C-PHY
 configuration on Qualcomm platforms
Date: Sun, 01 Mar 2026 01:51:19 +0100
Message-Id: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIeNo2kC/23Muw6CMBSA4Vcxna3pKaUFJ1c3NwfjQMupdBAQS
 AMS3t2miQETx3P5/pn02DnsyXE3kw69611Th0Hsd8RURf1A6sowE854CsBy+jLNk5q2mqjWmdF
 lAUYKQcJ/26F1Y2zdyPV8IfewrFw/NN0U+x7i6U/KA2UUZGoVqlwzhJMb3XAw79jwfHWcia3jw
 UmdpGgzzRTgr0u+TjIAtXVJcJlBJQsmrSr16pZl+QCdJfJDFQEAAA==
X-Change-ID: 20251109-qcom-cphy-bb8cbda1c644
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5235; i=david@ixit.cz;
 h=from:subject:message-id; bh=P4p3ugAcHqTk+0DSfkLgtIU+9VorZXljd6RfXXUyi5I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42IV0TNY4ylY0guVSnG7gNMrIpkNrp+zn8FT
 8r/Pk7eUo2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiAAKCRBgAj/E00kg
 cvTND/9IT2OLptE9TpGq4YhPzIHHaJO0BFJiO4iSd464rVGDRLX+JUUXe3LorKDoui4X7DtebqQ
 L8DYKLyg6uDkP0f6+AuAxkn68VBKMxOOqOLAxV1sOEOFOPosg564RnQo0LSEYB47jtzDvkIh+gy
 t53eWRRs8SR3CAFNp6Iy0PSBYkMHCUpggwaHgXjIiZOc+yXPs6Ct/msfGjbG+Q5YPHp66apaZT1
 w+FcGh7/onk3cYhfeFok1XeUyBmwAsUIufvP+qnDKYiQ7R6IGQ3+7sPL9yb5jwa3i57qCW/hWaA
 PW6h0FawwyEUDsuH60acRoe8MNgGAZXz6Kd8/LE9BKZzxTDH4vt0rvvSAnwIL3OWX4xDSaMJPWI
 EhBiIWX5kQKvehbVG/6S4hC16Dx4tYOqfyJEmYLqPta5Kat+gT4yeBdK4tkggnrlSqF28gBpByA
 d7DDtK0wssU/lKTM2MfDrn9wjJ02gB8ngZc/s+vxxb9xzgjz/GThXzfHkCMQhtS2jOTX6pC4HBP
 v8vYqTkBiZsE/vLBrEuU8INIzm1YmGCIuGnhcHDDCkN21gar75NbjO26IQZ78CxmA08brEF4CcF
 /L6AWCWLKywXIucmqKK7vN959P3Qygf+9i9ON3lfLH+hxgVaHmXA8f+y3i6YJFiipB1/o4jxeY1
 KH7W9oFGBvrZ6Dg==
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
Casey Connolly (1):
      media: qcom: camss: csiphy-3ph: Add Gen2 v1.1 MIPI CSI-2 CPHY init

David Heidelberg (6):
      media: qcom: camss: csiphy: Introduce PHY configuration
      media: qcom: camss: csiphy-3ph: Use odd bits for configuring C-PHY lanes
      media: qcom: camss: Prepare CSID for C-PHY support
      media: qcom: camss: csiphy-3ph: Update Gen2 v1.1 MIPI CSI-2 CPHY init
      media: qcom: camss: csiphy-3ph: C-PHY needs own lane configuration
      media: qcom: camss: Account for C-PHY when calculating link frequency

Luca Weiss (1):
      media: qcom: camss: csiphy-3ph: Add Gen2 v1.2.1 MIPI CSI-2 C-PHY init

Petr Hodina (1):
      media: qcom: camss: Initialize lanes after lane configuration is available

 .../media/platform/qcom/camss/camss-csid-gen2.c    |   1 +
 drivers/media/platform/qcom/camss/camss-csid.c     |  12 +-
 drivers/media/platform/qcom/camss/camss-csid.h     |   1 +
 .../platform/qcom/camss/camss-csiphy-2ph-1-0.c     |   8 +-
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 336 ++++++++++++++++++---
 drivers/media/platform/qcom/camss/camss-csiphy.c   |  11 +-
 drivers/media/platform/qcom/camss/camss-csiphy.h   |   8 +-
 drivers/media/platform/qcom/camss/camss.c          |  36 ++-
 drivers/media/platform/qcom/camss/camss.h          |   2 +-
 9 files changed, 342 insertions(+), 73 deletions(-)
---
base-commit: 3fa5e5702a82d259897bd7e209469bc06368bf31
change-id: 20251109-qcom-cphy-bb8cbda1c644

Best regards,
-- 
David Heidelberg <david@ixit.cz>

