From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v5 0/3] arm64: dts: qcom: sc8280xp-blackrock: dt definition
 for Windows Dev Kit 2023
Date: Wed, 30 Oct 2024 08:09:18 +0100
Message-Id: <20241030-jg-blackrock-for-upstream-v5-0-830c938437ad@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ7bIWcC/43OQW7DIBAF0KtErDsVDFCgq96j6gLjIaZxQgSOl
 TTy3Uu8qLqp1eUfad7/d1apJKrsdXdnheZUUz61oJ92LAz+tCdIfcsMOSrukMPnHrrRh0PJ4QA
 xF7ic61TIH8EE44NHTlYia//nQjFdV/v9o+Uh1SmX21o1i8eV6aiVNSSAlLagvPTgI0cIGknz4
 IV7UW957GsYch5rHi9T21efu/TFHuSMK/OPcTMCB9dFjKJD4UTYZOUPK7iQW6xsrJWul8pKb8l
 ssuoXi2aLVY01XHaoVQxOxz/ZZVm+AdmkxIHEAQAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Merck Hung <merckhung@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730272174; l=4293;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=FMi9v9rfyShs+0KRXyfefZqFxm7p06wxhQoe9oN6UtQ=;
 b=Ajqw19rSXIkd1RBiABcxiW8b01Bc5t0jFpuKL2AYPGWSGhAnAHIQKbKUJwFM2ooQIaRNYP2Ao
 5gcNAzG2JqrAAOn/iEILZ57/5PJRpBcPbxDvyjahcQHVtepBVA+xE8K
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

"Microsoft Windows Dev Kit 2023" aka "Blackrock" aka "Project Volterra"

Device tree for the Microsoft Windows Dev Kit 2023. This work
is based on the initial work of Merck Hung <merckhung@gmail.com>.

The Windows Dev Kit 2023 is a nice little desktop based on sc8280xp.
Link: https://learn.microsoft.com/en-us/windows/arm/dev-kit/

Supported features:
- USB type-c and type-a ports
- minidp connector
- built-in r8152 Ethernet adapter
- PCIe devices
- nvme
- ath11k WiFi (WCN6855)
- WCN6855 Bluetooth
- A690 GPU
- ADSP and CDSP
- GPIO keys
- Audio definition (works via USB)

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>

Original work: https://github.com/merckhung/linux_ms_dev_kit/blob/ms-dev-kit-2023-v6.3.0/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-dev-kit-2023.dts

This dt is more or less deducted from the Thinkpad X13s.
It contains a lot of guesswork, and also a lot of research on
what works with the Windows Dev Kit.

The WiFi definition references qcom,ath11k-calibration-variant = "volterra"
which is unfortunately not yet in the linux-firmware. You can leave it out,
and the ath11k driver finds the default one for 
"bus=pci,vendor=17cb,device=1103,subsystem-vendor=17cb,subsystem-device=0108,qmi-chip-id=2|18,qmi-board-id=255"
which is quite sub-optimal. I have placed a pr on github/qca-swiss-army-knife:
https://github.com/qca/qca-swiss-army-knife/pull/9 that provides an amended 
board-2.bin and a board-2.json to generate it. 

pcie2 (nvme) is intentionally specified as max-link-speed = <16>. The 
interface is capable of it, most current nvme ssds are capable of it, 
but the physical slot isn't. This leads to a silent downgrade to <8> instead 
of the "device is limited by bus, capable of..." message.

It is in use and under development since May 2023, pretty stable now.

---
Changes in v5:
- removed s-o-b from Merck Hung as suggested by Bjorn Andersson. The credits
  for the original work are in the cover letter and in the dts commit
- removed Venus codec from the list of supported features. It is, but that
  part is not in this patch set.
- Link to v4: https://lore.kernel.org/r/20241027-jg-blackrock-for-upstream-v4-0-703b254fc95f@oldschoolsolutions.biz

Changes in v4:
- removed the redundant regulator definitions
- changed the pinctrl property order
- use microsoft instead of MICROSOFT as subdirectory and device name component
- amend spacing in audio nodes
- change external connector dp1 for mini-dp to DP-3 for consistency
- Link to v3: https://lore.kernel.org/r/20241013-jg-blackrock-for-upstream-v3-0-839d3483a8e7@oldschoolsolutions.biz

Changes in v3:
- tried to heed all advice and comments given - thank you
- re-ordered patches to definition before use
- added "microsoft,blackrock" as compatible in QSEECOM driver
- removed the qseecom node
- ordered nodes alphabetically {address, node name, label}
- amended indentation
- consistently used blackrock as identifier / directory name
- sorted identifiers by the same order for multiple instances
- added some explanation re WiFi
- added definition for PMU on the WCN6855
- added some explanation for pcie2 max-link-speed
- Link to v2: https://lore.kernel.org/r/20240920-jg-blackrock-for-upstream-v2-0-9bf2f1b2191c@oldschoolsolutions.biz

Changes in v2:
- removed whitespaces and breaks
- added compatibility binding
- added feature list
- reformatted Signed-off list
- Link to v1: https://lore.kernel.org/r/5f5487e1-e458-4a3a-af02-c52e50ca1964@oldschoolsolutions.biz

---
Jens Glathe (3):
      dt-bindings: arm: qcom: Add Microsoft Windows Dev Kit 2023
      firmware: qcom: scm: Allow QSEECOM for Windows Dev Kit 2023
      arm64: dts: qcom: sc8280xp-blackrock: dt definition for WDK2023

 Documentation/devicetree/bindings/arm/qcom.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 1383 ++++++++++++++++++++
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 4 files changed, 1386 insertions(+)
---
base-commit: 6fb2fa9805c501d9ade047fc511961f3273cdcb5
change-id: 20240920-jg-blackrock-for-upstream-7c7aca20e832

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

