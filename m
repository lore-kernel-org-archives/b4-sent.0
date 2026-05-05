From: David Wales <daviewales@disroot.org>
Subject: [PATCH v3 0/2] Add initial device tree for Motorola Moto G (2014)
Date: Tue, 05 May 2026 23:51:40 +1000
Message-Id: <20260505-device-motorola-titan-mainline-v3-0-8fcfa280e5d0@disroot.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOywrCMBBFf6VkbSSZPnXlf4iLmE7akZpIEotS+
 u+mVRBXLg9czrkTC+gJA9tnE/M4UiBnE+SbjOle2Q45tYkZCKhEIQreppFGfnXReTcoHikqy6+
 K7EAWuTFV1ZgcygoMS5KbR0OPNXA8vTnczxfUcbEui55CUj3XB6Ncdp8Y5P9io+SCo2xkrgQ0W
 jeHloJ3Lm6d79iSG+ErLAX8FUIS6nonoa51XQj1K5zn+QXJJjkLMQEAAA==
X-Change-ID: 20260404-device-motorola-titan-mainline-ff668f32562f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Wales <daviewales@disroot.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1418;
 i=daviewales@disroot.org; h=from:subject:message-id;
 bh=ZWIongSi2sHc0KkDpAKN24XGWS3ZeBA/lRfNTAcOLT4=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBp+fYDtsh6c0D6MTX5TZ/FaZu87Vt6A22Yz/mIU
 pkVNHm8hPWJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCafn2AwAKCRBtY1eBRvSh
 ZpyoB/9rIGoZkdaH4kIEMPWptwYrA3OXiR3YgdAcqATr1gaKXt4jfQkwUPzQ5ZsgyES3d73vyuu
 n/FqWlfT7L/b3az1GytJtLUmY7Ii2toaBWBaZHMsRrjdMOjcysa9mSQXpMcxewTv1DiAQTmR3X6
 NCb7yi2jnKtBtt/l39jhX/z84iKPU9JeW2dbrJrovR5h8kF9Sx451Ycc0NOvpxuXJZOK3dbu7D6
 uag9kYJsitqshOU99+WOu6yd9cJhjVSRMP3nOoDdS0dy/5F3IHt9rJHmr6oBt30brFA5bATPWcm
 XPbetOSCgC12auRfRjLr+pn1rQzP2MhzlFNs2VjFFx8HFuQq
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

Signed-off-by: David Wales <daviewales@disroot.org>
---
Changes in v3:
- Add missing trailers to commits
- Link to v2: https://patch.msgid.link/20260502-device-motorola-titan-mainline-v2-0-c791277c740a@disroot.org

Changes in v2:
- Remove active-high from reg_lcd_default.
- Add reg_vddio_disp_default, which I somehow missed in the last version.
  (Assuming this also shouldn't use active-high)
- Link to v1: https://patch.msgid.link/20260423-device-motorola-titan-mainline-v1-0-e1813a028cc8@disroot.org

---
David Wales (2):
      dt-bindings: arm: qcom: Add Motorola Moto G2 (2014)
      ARM: dts: qcom: Support Motorola Moto G2 (2014)

 Documentation/devicetree/bindings/arm/qcom.yaml   |   1 +
 arch/arm/boot/dts/qcom/Makefile                   |   1 +
 arch/arm/boot/dts/qcom/msm8226-motorola-titan.dts | 357 ++++++++++++++++++++++
 3 files changed, 359 insertions(+)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260404-device-motorola-titan-mainline-ff668f32562f

Best regards,
--  
David Wales <daviewales@disroot.org>

