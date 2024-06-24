From: George Chan <gchan9527@gmail.com>
Subject: [PATCH RFT v3 0/5] Add sc7180 camss subsys support
Date: Mon, 24 Jun 2024 20:13:11 +0800
Message-Id: <20240624-b4-sc7180-camss-v3-0-89ece6471431@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANdieWYC/3WNywrCMBREf0Xu2sjNw9a4cuUHiDtxkd6kbcC2k
 khQSv/dkFVBXM4M58wM0QXvIhw3MwSXfPTTmIPcboB6M3aOeZszCBQKK8FZo1ikmh+QkRliZGQ
 tVU2FRjcKMvUMrvXvYrzB5XyFey57H19T+JSXxMv0V5g4Q8aVlrUWupXoTt1g/GNH01BcSax59
 cuLzKNtHVnaI9ZyzS/L8gUgGIAC8wAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719231232; l=3098;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=uy73nECnRMqzWXZWj+nUmjnDanqevHH++6Wp38u6IsU=;
 b=CM8dnmVud0cLkAU2X0elJCsTBQWq5F43ym08E/YAzq4NDa/eKKUvqirK5z6KNOcWs11O68zr5
 hceLKbLVQWhDmpv30hJ/gbpsNUua+tN2dlJwEt6ltzZYba4MNOHphC/
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
Changes in v3:
- Rebased on 20240522154659.510-1-quic_grosikop@quicinc.com - Bryan
- Align email title to sc8280xp series - krzk
- Line-up dt-binding example ordering to same as qcom,sm8250-camss.yaml - krzk 
- Drop non-related patches #5 #6 #7, I will send follow-up patches later
- Add RFT tag to all patches, since no tested-by at all.
- Drop required-opps node from dt
- Link to v2: https://lore.kernel.org/r/20240624-b4-sc7180-camss-v2-0-0dfecdc50073@gmail.com

Changes in v2:
- Revised dt-binding title - krzk
- Revised dt-binding maintainers - krzk
- Drop all dt-binding minItems - krzk
- Drops "|" symbol postfixed to description - krzk 
- Accending order of dt-binding required list - krzk
- Added dt-binding item power-domain-name - Bryan
- Reformat dt-binding example - krzk
- Move reg as 2nd property - krzk
- Move reg-names as 3nd property - krzk
- Reduce iommus maxItems to 3 - rob's bot
- Reduce clocks maxItems to 24 - rob's bot
- Combine patch #2 and #3 - krzk and Bryan
- Split eror-print log for clk name from #5 - Konrad
- Reformat dt-node - krzk
- Corrected phy init sequence for v1.2.2 - Bryan
- Added 3 more debug info for missing clk and low clk-rate issue.
- Adding port info to ports sub-node
- Adding required-opps node to dt
- Link to v1: https://lore.kernel.org/r/20240621-b4-sc7180-camss-v1-0-14937929f30e@gmail.com

---
George Chan (5):
      dt-bindings: media: camss: Add qcom,sc7180-camss
      media: camss: csiphy-3ph: Add Gen2 v1.2.2 two-phase MIPI CSI-2 DPHY init
      media: qcom: camss: Add sc7180 support
      media: qcom: camss: Add sc7180 resources
      arm64: dts: qcom: sc7180: camss: Add CAMSS block definition

 .../bindings/media/qcom,sc7180-camss.yaml          | 328 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sc7180.dtsi               | 133 +++++++++
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 135 +++++++++
 drivers/media/platform/qcom/camss/camss-vfe.c      |   2 +
 drivers/media/platform/qcom/camss/camss.c          | 251 ++++++++++++++++
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 6 files changed, 850 insertions(+)
---
base-commit: 28f69d2ea67db489d4a94e7d04c21b14e5aa6535
change-id: 20240621-b4-sc7180-camss-cddc6b60a9b4

Best regards,
-- 
George Chan <gchan9527@gmail.com>

