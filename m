From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH 0/2] arm64: qcom: add Ayaneo Pocket DS gaming console
Date: Sun, 10 May 2026 23:05:55 +0700
Message-Id: <20260510-pocketds-v1-0-cf05acec06af@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QpAQBSE4VfRuba1CK1XkQvW4FBoD1Ly7haXX
 /0zFwkcQ6gILnI4WHiZPaIwIDvUcw/FrTfFOs50Gmm1LnbC1oqCRt4YY7skM+Tz1aHj87sqq9+
 yNyPs9u7pvh9tj0WwbAAAAA==
X-Change-ID: 20260510-pocketds-e0e7b99cf369
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778429157; l=1248;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=zWM0yjWhrBGeyNEsiYlhIjWmf8MR0q9DFMYfprO6DpQ=;
 b=pAr7WUGqunWuaodzubJ4K97YlUN6/wr7s/x78Tdh18R7mtAjc6EJbe0vIoF7nnuqe6MooiF2E
 JqqvhAk/kNeCDO+uA+uhpbJLwpl1cPbuiMJhevB43lJ2z35qlK4gVui
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Ayaneo Pocket DS, a handheld
gaming console built around the Qualcomm QCS8550 SoC.

This introduces the device tree itself, split into:
- qcs8550-ayaneo-pocket-common.dtsi: shared QCS8550 board base
  intended to be reused by future siblings in the same family.
- qcs8550-ayaneo-pocketds.dts: This device's DTS

Only the basics are wired up at this stage (boot to console, core
peripherals enabled in the common dtsi); additional functionality
will follow in later submissions.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
Teguh Sobirin (2):
      dt-bindings: arm: qcom: document the Ayaneo Pocket DS
      arm64: dts: qcom: add basic devicetree for Ayaneo Pocket DS gaming console

 Documentation/devicetree/bindings/arm/qcom.yaml    |    6 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../dts/qcom/qcs8550-ayaneo-pocket-common.dtsi     | 1596 ++++++++++++++++++++
 .../boot/dts/qcom/qcs8550-ayaneo-pocketds.dts      |  170 +++
 4 files changed, 1773 insertions(+)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260510-pocketds-e0e7b99cf369

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

