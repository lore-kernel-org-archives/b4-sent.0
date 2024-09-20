From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v2 0/2] arm64: dts: qcom: sc8280xp-wdk2023: dt definition
 for WDK2023
Date: Fri, 20 Sep 2024 19:47:23 +0200
Message-Id: <20240920-jg-blackrock-for-upstream-v2-0-9bf2f1b2191c@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACu17WYC/x2OQQ6CMBREr2K69ptSWgFX3sOw+JRfqFRKWiAq4
 e5Wlm+SeTMbixQsRXY7bSzQaqP1YwJxPjHd49gR2DYxE1xIXgkOzw4ah3oIXg9gfIBlinMgfEG
 hC9QoOJW5YKk/BTL2fbgfdeLextmHzzG1Zv+UKaNkWVAGJFUJEnMENFyAVoIU15hVV3n3ro269
 95F75Y5/YuXxn5Zve/7D8LzOfG/AAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Merck Hung <merckhung@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726854445; l=1811;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=mGCg4J/5BGD3gJKaTmQFi2kBsoo2r0rrbKe3dG75q5Y=;
 b=fzGBZ1P3km1ktZaT8Bh01lhwQQDgrWbDqJTMI0GAC2A8ZxvaWR2qVT0Hm/Vdr8lTP/WcCmQec
 L6vzhAa+xaNBVnjDvS7KOQsgpQfDFSPrJDsaLdF599bE7mqeD6lO5Qo
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

"Microsoft Windows Dev Kit 2023" aka "Blackrock" aka "Project Volterra"

Device tree for the Windows Dev Kit 2023. This work
is based on the initial work of Merck Hung <merckhung@gmail.com>.

Supported features:
- USB type-c and type-a ports
- minidp connector
- built-in r8152 Ethernet adapter
- PCIe devices 
- nvme 
- ath11k WiFi (WCN6855)
- WCN6855 Bluetooth
- A690 GPU
- Venus codec
- ADSP and CDSP
- GPIO keys
- Audio definition (works via USB)

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Signed-off-by: Merck Hung <merckhung@gmail.com>

Original work: https://github.com/merckhung/linux_ms_dev_kit/blob/ms-dev-kit-2023-v6.3.0/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-dev-kit-2023.dts

This dt is more or less deducted from the Thinkpad X13s.
It contains a lot of guesswork, and also a lot of research on
what works with the Windows Dev Kit.

It is in use and under development since May 2023, pretty stable now.

---
Changes in v2:
- removed whitespaces and breaks
- added compatibility binding
- added feature list
- reformatted Signed-off list
- Link to v1: https://lore.kernel.org/r/5f5487e1-e458-4a3a-af02-c52e50ca1964@oldschoolsolutions.biz

---
Jens Glathe (2):
      arm64: dts: qcom: sc8280xp-wdk2023: dt definition for WDK2023
      dt-bindings: arm: qcom: Add Microsoft Windows Dev Kit 2023

 Documentation/devicetree/bindings/arm/qcom.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 1332 ++++++++++++++++++++
 3 files changed, 1334 insertions(+)
---
base-commit: 98f7e32f20d28ec452afb208f9cffc08448a2652
change-id: 20240920-jg-blackrock-for-upstream-7c7aca20e832

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

