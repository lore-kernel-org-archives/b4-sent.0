From: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
Subject: [PATCH v5 0/2] Samsung Galaxy Z Fold5 initial support
Date: Wed, 10 Apr 2024 23:28:32 +0200
Message-Id: <20240410-samsung-galaxy-zfold5-q5q-v5-0-9311ee9a55f7@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIAEF2YC/x3MMQ6DMAxA0asgz7UUKBngKlUHK3FSSxAgVlEAc
 fdGHd/w/wXKWVhhbC7IvIvKkirsowH3oRQZxVdDZ7re9K1BpVm/KWKkicqBZ1gmb3GzG/pn6zw
 zOTMEqP2aOUj5v1/v+/4BA4Vix2sAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712784514; l=2250;
 i=serdeliuk@yahoo.com; s=20240326; h=from:subject:message-id;
 bh=TUqiqernw9WGEO3cMf2cvZV3VHIcszDG5hcc58McQQw=;
 b=QRhN4tQuLBYQVROA6KpSYR/5M2GxLW8ZFmZnPrskPmJ+rvTiuQADpNPAqKZqRwSPxJfMDQevK
 tM13mVl2blWA0ptFDwMLFzV21OVvH3MZ5Iz7wLn7ZUcEaqG6ZifVvKR
X-Developer-Key: i=serdeliuk@yahoo.com; a=ed25519;
 pk=aWyveUE11qfDOOlRIFayXukrNn39BvZ9k9uq94dAsgY=
X-Endpoint-Received: by B4 Relay for serdeliuk@yahoo.com/20240326 with auth_id=147
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This documents and add intial dts support for Samsung Galaxy Z Fold5 (samsung,q5q)
which is a foldable phone by Samsung based on the sm8550 SoC.

ChangeLog
	
- v5
  . Added ChangeLog
  . Added missing Acked-by tags in their respective section in ChangeLog

- v4
  . removed a spurious new line
  . removed pcie_1_phy_aux_clk as requested
  . removed secondary pcie1 which does not exists on the device
  . changed firmware extension from .mbn to .mdt
  . added missing reserved memory regions required by firmware to properly load

- v3
  . added b4 version 3
  . removed address and size cells in device description
  Acked-by: Rob Herring <robh@kernel.org>

- v2 
  . added both but added an extra v2 in the subject line instead to b4 subject header, was requested to send the patch again, along with following mods:
  . removed whole bootargs line
  . fixed underscores in reserved memory by removing all reserved memory regions
  . added missing idetation to  spash_screen remark
  . validated the dts with "dtbs_check"
  . removed all comments at the end of nodes
  . moved status of the node at the end of the node
  . reversed pin control name with control numbers
  . ordered the  nodes alphabetically

- v1
  . The initial request was split in two patches sent due to the following checkpatch warning, was requested to re send them together:
    WARNING: DT binding docs and includes should be a separate patch. See: Documentation/devicetree/bindings/submitting-patches.rst
  Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>

Signed-off-by: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
---
Alexandru Marc Serdeliuc (2):
      dt-bindings: arm: qcom: Document the Samsung Galaxy Z Fold5
      arm64: dts: qcom: sm8550: Add support for Samsung Galaxy Z Fold5

 Documentation/devicetree/bindings/arm/qcom.yaml |   1 +
 arch/arm64/boot/dts/qcom/Makefile               |   1 +
 arch/arm64/boot/dts/qcom/sm8550-samsung-q5q.dts | 593 ++++++++++++++++++++++++
 3 files changed, 595 insertions(+)
---
base-commit: 2c71fdf02a95b3dd425b42f28fd47fb2b1d22702
change-id: 20240410-samsung-galaxy-zfold5-q5q-d31cdeeac09f

Best regards,
-- 
Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>

