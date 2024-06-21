From: George Chan <gchan9527@gmail.com>
Subject: [PATCH 0/6] media: qcom: camss: Add sc7180 support
Date: Fri, 21 Jun 2024 17:40:52 +0800
Message-Id: <20240621-b4-sc7180-camss-v1-0-14937929f30e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKRKdWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDMyND3SQT3eJkc0MLA93kxNziYt3klJRksyQzg0TLJBMloK6CotS0zAq
 widGxtbUA0tGVeGEAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718962855; l=1917;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=ZVXJbWByUzIKTOC7VscBLLwylCglSs2J2Rvmr2V8T5A=;
 b=BnsW7oejRFpwuGmmirMaAx9oEYiaBpv3Qz/M2DX4n3OI8yXFjAvAEpaiy89G07uhalR+jN7Gy
 AaiYtcEU7BxBFzn//FTtSNerwZ79KNwxLH9n3Zcgy1FR9/ZUjzk6zkA
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
I've copied a new yaml from sdm845-camss.yaml, strip all _src clk and leave
original maintainer. If this is not desirable then i can add binding to
existing sdm845 yaml instead.

In addition, a bootable tree of sm7125/joyeuse is availble at:
https://github.com/99degree/linux/tree/camss
  

Signed-off-by: George Chan <gchan9527@gmail.com>
---
George Chan (6):
      media: dt-bindings: media: camss: Add qcom,sc7180-camss binding
      media: qcom: camss: Add CAMSS_SC7180 enum
      media: qcom: camss: csiphy-3ph: Add Gen2 v1.2.2 two-phase MIPI CSI-2 DPHY init
      media: qcom: camss: Add sc7180 support
      media: qcom: camss: Add sc7180 resources
      [RFT]arm64: dts: qcom: sc7180: Add support for camss subsys

 .../bindings/media/qcom,sc7180-camss.yaml          | 324 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sc7180.dtsi               | 134 +++++++++
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 120 ++++++++
 drivers/media/platform/qcom/camss/camss-csiphy.c   |   1 +
 drivers/media/platform/qcom/camss/camss-vfe.c      |   3 +
 drivers/media/platform/qcom/camss/camss-video.c    |   1 +
 drivers/media/platform/qcom/camss/camss.c          | 218 +++++++++++++-
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 8 files changed, 801 insertions(+), 1 deletion(-)
---
base-commit: 2102cb0d050d34d50b9642a3a50861787527e922
change-id: 20240621-b4-sc7180-camss-cddc6b60a9b4

Best regards,
-- 
George Chan <gchan9527@gmail.com>

