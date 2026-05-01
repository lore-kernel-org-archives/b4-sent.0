From: David Wales <daviewales@disroot.org>
Subject: [PATCH v2 0/2] Add initial device tree for Motorola Moto G (2014)
Date: Sat, 02 May 2026 08:50:16 +1000
Message-Id: <20260502-device-motorola-titan-mainline-v2-0-c791277c740a@disroot.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOwQ7CIBAFf6Xh7BqglRBP/ofpAenSrmnBADaap
 v8urd49TvIy8xaWMBImdq4WFnGmRMEXkIeK2cH4HoG6wkxyqXjDG+jKyCJMIYcYRgOZsvEwGfI
 jeQTnlNKuliclHSuSR0RHrz1wbb+cnrc72rxZt8VAqaje+4NZbLtfTNb/YrMADii0qA2X2lp96
 SjFEPIxxJ6167p+AOooW2XgAAAA
X-Change-ID: 20260404-device-motorola-titan-mainline-ff668f32562f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Wales <daviewales@disroot.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1255;
 i=daviewales@disroot.org; h=from:subject:message-id;
 bh=dPALcF1cGW3yRPLb5Psr4qawY7TyHT8ACn9Ct8gjlBg=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBp9S5IyUOu9TX1vcC3o83yQ2v4nAVUccswWmy/f
 F8zO0iuPuSJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCafUuSAAKCRBtY1eBRvSh
 Zr4PCACMPqBbPwt4ywRJ4lupv8XF6u7uE6/tngeJlhq/+J1vhUGTRV56N3q8j8REZw/9KEVZqB3
 MB515DnHxVW/0qiH+heG8B0WYNZna8gXYCj8rAa1CLG2kUqKCZL0fDhue3G+C0K36p3Mt8jYuzW
 5WPmMdf9mh2LjKIOsq1fJFZq+jGx3yPhhbJ2a69PU23nngS21mdpNOnuMA3xOlv83z+1JMpVbnJ
 xT+F5VQzlQoX3IOrgHykYs4Can4TuEt0xw7cLQqi8kfTik/cGYZ8XRR8hN9GpbXmd3xgjbqeufC
 bGvkwWfEoABxCPRQpGqywNpkep+ZULBX665JVhAIn+ekXhn3
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

