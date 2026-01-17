From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/8] media: camss: Add support for C-PHY configuration
 on Qualcomm platforms
Date: Sat, 17 Jan 2026 16:36:15 +0100
Message-Id: <20260117-qcom-cphy-v3-0-8ce76a06f7db@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG+sa2kC/22MOw6DMBAFr4K2jiOv+afKPaIU2Cxhi/CxkQVB3
 D2GhhQp5+nNrODIMjm4RStY8uy47wLElwhMW3UvElwHBiVViihLMZr+LczQLkLrwui6QpMlCYT
 /YKnh+Wg9noFbdlNvlyPtcV//VTwKKTBLm5zyUkvCO888Xc0H9oZXp6dk8uup4GU6TqkptMyRT
 m/bti+2p12J2AAAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4344; i=david@ixit.cz;
 h=from:subject:message-id; bh=F3SEn1sLYe7ROUROXBKAcPkurB0TMGJUaJLz2fK8U2o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpa6xzIz5FLUmYPnnGLkio7Q9ENrEW6LBZ2/a6O
 4ui3KkQjbuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWuscwAKCRBgAj/E00kg
 csyND/sE2zetHzTbc31qZCUsykGeszeB/xLu6cnyYvwC2QFIX+xVfMUs3KX0FL6X7+T+LaCdWJK
 7f8yWzZFkyOdPplxizcTstTe9dFjp6WwKHgjOBdx0SFV1J2OR3uZZj1NzjkD8UT4GsFeubLrgAC
 LZ94t3MOflQRr8ZJii2FByul+2uikKCCbLdFLG9cle0LGYAxHRLh6KzCvOG3kMVpMrsoyeBeAkl
 lQJKVJ9fC2sHDkMBEwupKSH2y1Qr9MerEbw5XD+d0vfDVF+zjbjgOQiMU5Yn2axjN62GorIdYFY
 HqAOs0wuv4umFWku3mHWeOOjsVaVGmYnM/bxSDAgHKubVi4mSx+HS5DL71XxJi9Aq8WfB7v2jGj
 KdIScftw9Zejvy56PattstQ58Crdp4ySt5GOD4m6Iilj3sA9MvTGrSUA0fC6iJbZ1mnatiRUsQo
 nih2hVcJm3nceYMCHysILGp8nHhVDjxF8dB4ghTKAMWEUMn6bRffJSscVS0cP6UfMskK+WvxXcG
 t+g7iZLQmOyjnwL1hzef9HHrzJg6qVwf7ukHhY/KV5hL0yivzz8PGDRzL7tsCggYQYqA+sKIM/H
 wS/f0MPt5y1GZrH5kKkC3Dj5eQ6Am1WabnKJ4dM5woNOQW5tqKZzdr04JJ/GxL74F31ZWm1BI9/
 uztyia+wEUgKyOw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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
  https://gitlab.com/sdm845/sdm845-next/-/commits/b4/qcom-cphy

Signed-off-by: David Heidelberg <david@ixit.cz>
---
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

David Heidelberg (5):
      media: qcom: camss: csiphy: Introduce PHY configuration
      media: qcom: camss: csiphy-3ph: Use odd bits for configuring C-PHY lanes
      media: qcom: camss: Prepare CSID for C-PHY support
      media: qcom: camss: csiphy-3ph: C-PHY needs own lane configuration
      media: qcom: camss: Account for C-PHY when calculating link frequency

Luca Weiss (1):
      media: qcom: camss: csiphy-3ph: Add Gen2 v1.2.1 MIPI CSI-2 C-PHY init

Petr Hodina (1):
      media: qcom: camss: Initialize lanes after lane configuration is available

 .../media/platform/qcom/camss/camss-csid-gen2.c    |   1 +
 drivers/media/platform/qcom/camss/camss-csid.c     |   3 +-
 drivers/media/platform/qcom/camss/camss-csid.h     |   1 +
 .../platform/qcom/camss/camss-csiphy-2ph-1-0.c     |   8 +-
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 332 ++++++++++++++++++---
 drivers/media/platform/qcom/camss/camss-csiphy.c   |  10 +-
 drivers/media/platform/qcom/camss/camss-csiphy.h   |   8 +-
 drivers/media/platform/qcom/camss/camss.c          |  34 ++-
 drivers/media/platform/qcom/camss/camss.h          |   2 +-
 9 files changed, 331 insertions(+), 68 deletions(-)
---
base-commit: 46fe65a2c28ecf5df1a7475aba1f08ccf4c0ac1b
change-id: 20251109-qcom-cphy-bb8cbda1c644

Best regards,
-- 
David Heidelberg <david@ixit.cz>

