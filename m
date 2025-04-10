From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v2 0/3] arm64: dts: qcom: x1e80100-hp-x14: add
 usb-1-ss1-sbu-mux
Date: Thu, 10 Apr 2025 12:07:27 +0200
Message-Id: <20250410-hp-x14-v2-0-d36414704a0a@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF+Y92cC/zXOQQ6CMBCF4auQWVvTViDWFfcwLGgZ7CSEkg4Sl
 PTuVqLL/2XyZXZgjIQMt2KHiCsxhSmHPhXgfDc9UFCfG7TUlSylEX4WmyqFHFR/ra2ztTGQj+e
 IA20HdG9ze+IlxNfhruq7/ggl/8SqhBS2xMp1urqgM00Ye3Y+hJHD+FzyJ3y29IY2pfQBG99Ut
 6kAAAA=
X-Change-ID: 20250409-hp-x14-0f1d86bcb699
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744279681; l=1464;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=63Q2CP1BjWPMJIsb/dxHjtnUbcBupGKBm9IiQVKWr7o=;
 b=tuqFUauzJa7LaauxOGCboKN4tSuMaOgeQubZN0kK0oeSGsOJFIel2tA1kTb4gywWqDDSUfRFw
 V4xOSZ+9scmDW5Od13VRx9SUYjG3VbroHfZ+7DLgFiIsCimIbrouG90
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usb_1_1 port doesn't have the PS8830 repeater, but apparently some
MUX for DP altmode control. After a suggestion from sgerhold on
'#aarch64-laptops' I added gpio-sbu-mux nodes from the x1e80100-QCP
tree, and this appears to work well. It is still guesswork, but
working guesswork.

Added and rewired for usb_1_1

Also, did some more changes as tested here:

- remove unused i2c buses
- amend order of nodes.

The series is based on [1] from Johan.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Changes in v2:
- removed overlapping patches with [1] and [2] - thanks Johan
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://lore.kernel.org/r/20250410-hp-x14-v1-0-b4e5ca253ec9@oldschoolsolutions.biz

[1] https://lore.kernel.org/lkml/20250328084154.16759-1-johan+linaro@kernel.org/
[2] https://lore.kernel.org/r/20250319160509.1812805-1-juerg.haefliger@canonical.com

---
Jens Glathe (3):
      arm64: dts: qcom: x1e80100-hp-x14: add usb-1-ss1-sbu-mux
      arm64: dts: qcom: x1e80100-hp-x14: remove unused i2c buses
      arm64: dts: qcom: x1e80100-hp-x14: amend order of nodes

 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 98 ++++++++++++++--------
 1 file changed, 62 insertions(+), 36 deletions(-)
---
base-commit: 2791023c72489c91f59cfe818776fc6cd164ddad
change-id: 20250409-hp-x14-0f1d86bcb699

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

