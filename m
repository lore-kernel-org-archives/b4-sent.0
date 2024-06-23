From: George Chan <gchan9527@gmail.com>
Subject: [PATCH v2 0/8] Add sc7180 camss subsys support
Date: Mon, 24 Jun 2024 07:22:39 +0800
Message-Id: <20240624-b4-sc7180-camss-v2-0-0dfecdc50073@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD+ueGYC/3WNQQ6CMBBFr0Jm7Zi2NGBdeQ/Doh0KTCJgOoZoS
 O9uZe/yveS/v4PExFHgWu2Q4sbC61LAnCqgyS9jRO4Lg1HGqsZoDBaFWn1RSH4WQep7akKjvAs
 WyuqZ4sDvo3jvCk8srzV9joNN/+z/1qZRobaubp1xQ63ibZw9P860ztDlnL9m9ZX1rgAAAA==
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, cros-qcom-dts-watchers@chromium.org, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719184973; l=2579;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=DhTilDr3SIjitHMdJcG3ZDB6dsKcEVqpxMzh5u/CJu4=;
 b=d0e0eTFGCBdEmAlzwkVaV5EVF3iIUoGTcFxwLBM3ga77ZM9sLJ18B2N32eUL7OrxxfMBIxttB
 2G+5mhvy5w6CdRKn6kN5+TczlinA+so5/9BV8PZNW2SV9nFHR6BPhbk
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=Ac2fkTqgUBlj2sns9hRIWJTYhWHO1BsmHbdBb5UpUUY=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20240621 with auth_id=176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM7125 is the SoC found in the Xiaomi Redmi Note 9 Pro(joyeuse) cellphone.
This series adds support to bring up the CSIPHY, CSID, VFE/RDI interfaces.

Since SM7125 is a low-speed variant of SC7180, SC7180 testers please
take a look and have a test as well.

sc7180 provides

- 2 x VFE
- 1 x VFE Lite
- 2 x CSID
- 1 x CSID Lite
- 4 x CSI PHY

The sc7180-camss binding should be comaptible with sdm845 yaml.
I've copied a new yaml from sdm845-camss.yaml, strip all _src clk and
put new maintainer information. If this is not desirable then i can add binding to
existing sdm845 yaml instead.

In addition, a bootable tree of sm7125/joyeuse is availble at:
https://github.com/99degree/linux/tree/camss
  

Signed-off-by: George Chan <gchan9527@gmail.com>
---
Changes in v2:
- Revised dt-binding as stated by krzk
- Added dt-binding item power-domain-name as stated by Bryan
- Combine patch #2 and #3 as stated by krzk and Bryan
- Split eror-print log for clk name from patch #5 as suggested by Konrad
- Reformat dt-node of camss as stated by krzk
- Corrected phy init sequence for v1.2.2 as spot by Bryan
- Added 3 more debug info for missing clk and low clk-rate issue.
- Adding port info to ports sub-node
- Adding required-opps node to dt
- Link to v1: https://lore.kernel.org/r/20240621-b4-sc7180-camss-v1-0-14937929f30e@gmail.com

---
George Chan (8):
      Add qcom,sc7180-camss
      Add Gen2 v1.2.2 two-phase MIPI CSI-2 DPHY init
      Add sc7180 support
      Add sc7180 resources
      Add debug log info to camss_enable_clocks function
      Add debug log info to msm_csid_subdev_init function
      Add debug log info to vfe block init and set clock rate
      [RFT]Add support for sc7180 camss subsys

 .../bindings/media/qcom,sc7180-camss.yaml          | 327 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sc7180.dtsi               | 135 +++++++++
 drivers/media/platform/qcom/camss/camss-csid.c     |   4 +-
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 135 +++++++++
 drivers/media/platform/qcom/camss/camss-csiphy.c   |   1 +
 drivers/media/platform/qcom/camss/camss-vfe.c      |  10 +-
 drivers/media/platform/qcom/camss/camss-video.c    |   1 +
 drivers/media/platform/qcom/camss/camss.c          | 218 +++++++++++++-
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 9 files changed, 828 insertions(+), 4 deletions(-)
---
base-commit: 2102cb0d050d34d50b9642a3a50861787527e922
change-id: 20240621-b4-sc7180-camss-cddc6b60a9b4

Best regards,
-- 
George Chan <gchan9527@gmail.com>

