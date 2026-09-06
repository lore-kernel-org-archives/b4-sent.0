From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH 0/3] arm64: dts: qcom: Add Lenovo IdeaPad Slim 5x 14Q8X9
Date: Sun, 06 Sep 2026 14:22:35 +0200
Message-Id: <20260906-x1-ideapad-slim5x-v1-0-7ccffbe6bc4a@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7TlBBwb4SHUzXWigThRDEvycdZ
 2CmQcFMWGCZGmR8qdATB4h5AnfaeCAjPxgkl5obrlgVw6BN1rNy0a0qc3430luhAw8wupQxUP2
 f69b7B/EOWANjAAAA
X-Change-ID: 20260905-x1-ideapad-slim5x-cdb92da16f0f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788697362; l=2359;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=ADxRjnNzSi7Z4fhchcNFTSRw6rQSjI4jcShXFeLELO4=;
 b=TVTp4IZeGvqhF6yrtvlKbOeDVxYLO2sKjwQfQskLdmCS4sOoyc+6FC1CfUYFTqfLwIZdgvhtu
 DL+pCdiLptVDxXuEv2Q/EinzybiSpwKI1GRxtkfm2aKbkwrrIQwVKtt
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device-tree support for the Lenovo IdeaPad Slim 5 14Q8X9
(machine type 83HL) on Snapdragon X Plus X1P42100 (Purwa). In
some regions the laptop is sold as "IdeaPad Slim 5x"; the "x"
is Lenovo's Qualcomm suffix (i = Intel, a = AMD, x = Qualcomm).

Working:
- keyboard and HID-over-I2C touchpad (several vendor ICs)
- eDP (LCD PWM backlight and OLED)
- HDMI
- USB-C including DP altmode
- USB-A
- NVMe
- microSD on PCIe3
- WCN7850 Wi-Fi and Bluetooth
- lid switch
- Adreno GPU
- speakers, headphone jack, internal DMICs, DP outs
- battery / charging
- camera (on usb_2)
- fingerprint (on usb1_ss2)

These device trees have been in use for about a year [1] and
are well tested. Bring-up started on the IdeaPad 5 2-in-1
14Q8X9 (83GH). That machine is a different design [2], closer
to the ThinkBook 16 G7 QOY (its DMI even contains an IdeaPad 5
string). 83GH will be a separate series.

Audio needs the X1E80100-LENOVO-Ideapad-5 card name, a symlink
to the T14s/Romulus topology firmware, and the alsa-ucm-conf
change already merged as [3].

Thanks to everyone who tested, especially in [1], [2] and [4].
83HL was one of the quirkier boards to bring up.

[1] https://github.com/jglathe/linux_ms_dev_kit/discussions/36
[2] https://bugs.launchpad.net/ubuntu-concept/+bug/2098124
[3] https://github.com/alsa-project/alsa-ucm-conf/pull/599
[4] https://github.com/jglathe/linux_ms_dev_kit/issues/61

Assisted-by: Grok 4.5 (xAI)
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Jens Glathe (3):
      dt-bindings: arm: qcom: Add Lenovo Ideapad Slim 5 variants
      firmware: qcom: scm: Allow QSEECOM on Lenovo IdeaPad 5 models
      arm64: dts: qcom: Add Lenovo IdeaPad Slim 5x 14Q8X9

 Documentation/devicetree/bindings/arm/qcom.yaml    |    7 +
 arch/arm64/boot/dts/qcom/Makefile                  |    4 +
 .../qcom/x1p42100-lenovo-ideapad-slim5x-lcd.dts    |   30 +
 .../qcom/x1p42100-lenovo-ideapad-slim5x-oled.dts   |   15 +
 .../dts/qcom/x1p42100-lenovo-ideapad-slim5x.dtsi   | 1695 ++++++++++++++++++++
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 6 files changed, 1752 insertions(+)
---
base-commit: af5f12805e5cefa4fe68d6127c7e1fb78cd5535c
change-id: 20260905-x1-ideapad-slim5x-cdb92da16f0f

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

