From: David Wales <daviewales@disroot.org>
Subject: [PATCH v4 0/2] Add initial device tree for Motorola Moto G (2014)
Date: Fri, 05 Jun 2026 23:19:10 +1000
Message-Id: <20260605-device-motorola-titan-mainline-v4-0-08a7be31f05c@disroot.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XOzW7CMBAE4FdBPtfVep0ftyfeA3FwnTVsBXZlm
 wgU5d3rUCRa9ZDjSKNvZhKZElMW75tJJBo5cww1NC8b4Y42HEjyULNAwA4aaORQS47kOZaY4sn
 KwsUGebYcThxIet91xmtsO/SiIl+JPF/vA7v9T86Xj09yZVGXxpFzpW73B6Naeo8x1Gtjo5IgS
 RmlLaBxzmwHzinG8hrTQSxzIz7BFnAVxAq6/k1h37u+Afsf1L/BdhXUFTTeeYsGqB3gLzjP8zc
 GGszWggEAAA==
X-Change-ID: 20260404-device-motorola-titan-mainline-ff668f32562f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 David Wales <daviewales@disroot.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1857;
 i=daviewales@disroot.org; h=from:subject:message-id;
 bh=J/BBiDOtg87dY6XX/rpTbFHNhKF1CVqcYk+STuw6bIo=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBqIszXmtullhdX19O3o0UI3LZETYtj6yQqyAecw
 0GWZZfC9/aJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCaiLM1wAKCRBtY1eBRvSh
 ZuSqB/9sSAXxItl+Zc/4i1daKZqk4mpqVE8gdw5+ozK9UxosI684gM/XqmhsbjcuKxQN7dP+es0
 oXWheuLIlSbbd0gt2oKM4iPuXs8EiZHZd4LBBUmESMBUpjW1Ehjn/GQwVQSAbIP3D0xwVIVOjps
 75Nx4wXqqHmhhcb2fq4o3Mf5BVF7LnbSgPaVGwh7N9q0HrDZtruR+ovKgvf4yAywSChfI9QAV6M
 WvovgR5nkb7bgagTtZIkADj6AYqIUbdTKbtuM3G+ANkLG0EF8Bfmo8w6aCTSQ6uiNHmyRGM/b6T
 2Hpo9qWc3ME4mZPc+WA26IJSle3oqLpx5rJd2ndWZ9WHVfmh
X-Developer-Key: i=daviewales@disroot.org; a=openpgp;
 fpr=8F5BAFB15444A769DC3B61684022B817D275D037
X-Endpoint-Received: by B4 Relay for daviewales@disroot.org/default with auth_id=737
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Motorola Moto G (2014) is the second device in the Moto G series,
with codename motorola-titan.

This series documents the motorola-titan, and adds an initial device
tree.

These patches have been previously discussed and merged into the
downstream msm8226-mainline fork:
https://github.com/msm8226-mainline/linux/pull/18

---
Changes in v4:
- Remove reg_vddio_disp_default as it is not used.
- Link to v3: https://patch.msgid.link/20260505-device-motorola-titan-mainline-v3-0-8fcfa280e5d0@disroot.org

Changes in v3:
- Add missing trailers to commits
- Link to v2: https://patch.msgid.link/20260502-device-motorola-titan-mainline-v2-0-c791277c740a@disroot.org

Changes in v2:
- Remove active-high from reg_lcd_default.
- Add reg_vddio_disp_default, which I somehow missed in the last version.
  (Assuming this also shouldn't use active-high)
- Link to v1: https://patch.msgid.link/20260423-device-motorola-titan-mainline-v1-0-e1813a028cc8@disroot.org

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
David Wales (2):
      dt-bindings: arm: qcom: Add Motorola Moto G2 (2014)
      ARM: dts: qcom: Support Motorola Moto G2 (2014)

 Documentation/devicetree/bindings/arm/qcom.yaml   |   1 +
 arch/arm/boot/dts/qcom/Makefile                   |   1 +
 arch/arm/boot/dts/qcom/msm8226-motorola-titan.dts | 350 ++++++++++++++++++++++
 3 files changed, 352 insertions(+)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260404-device-motorola-titan-mainline-ff668f32562f

Best regards,
--  
David Wales <daviewales@disroot.org>

