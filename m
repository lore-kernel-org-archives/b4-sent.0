From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH v2 0/2] Enable uart and bluetooth for Xperia devices
Date: Tue, 20 Jan 2026 13:24:23 +0100
Message-Id: <20260120-akatsuki-uart-v2-0-867ee7f042d0@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPdzb2kC/13MQQ6CMBCF4auQWVvT1kLRlfcwLEYoMkFa0haiI
 b27haXL/yXv2yAYTybArdjAm5UCOZtDngpoB7Qvw6jLDZLLUkihGY4YwzISW9BHpjrNS11X6ok
 a8mf2pqfP4T2a3AOF6Pz34Fexr7tUcSGuf9IqGGfyUveqQ9VjWd1n76KzE9L73LoJmpTSD6M9K
 dyvAAAA
X-Change-ID: 20251217-akatsuki-uart-4d7057864ba7
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Petr Hodina <petr.hodina@protonmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768911867; l=887;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=cABijGtH5qtV4tilYuBX2OxEKmyd4+buX5dd0F3c//E=;
 b=8rewuacEgvIP8DbcRvn9B7+krUMaZJ6zZXJ0TfP2pU3lIGOpq44oRl06poMNxgG2V21gKaBCk
 r/tJf4Z9vJBCrpt61ZYXuH2JDpmXaE0+L8PHEWEV4o0WG13dLILcH4v
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the uart instances defined in the dts so the serial
console will now work if uart is attached to Rx pin on the uSD pinout.
Also now enables bluetooth.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Changes in v2:
- Added comment about serial0 console
- Fixed firmware-name to expected path
- Link to v1: https://lore.kernel.org/r/20260119-akatsuki-uart-v1-0-238f4da4fa56@protonmail.com

---
Petr Hodina (2):
      arm64: dts: qcom: sdm845-sony-xperia-tama: Correct uart instances
      arm64: dts: qcom: sdm845-sony-xperia-tama: Add bluetooth

 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi | 17 +++++++++++++++--
 1 file changed, 15 insertions(+), 2 deletions(-)
---
base-commit: f417b7ffcbef7d76b0d8860518f50dae0e7e5eda
change-id: 20251217-akatsuki-uart-4d7057864ba7

Best regards,
-- 
Petr Hodina <petr.hodina@protonmail.com>

