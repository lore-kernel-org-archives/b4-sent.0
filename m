From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH 0/5] arm64: dts: qcom: x1e80100-hp-x14: add
 usb-1-ss1-sbu-mux
Date: Thu, 10 Apr 2025 11:13:21 +0200
Message-Id: <20250410-hp-x14-v1-0-b4e5ca253ec9@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALGL92cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEwNL3YwC3QpDE12DNMMUC7Ok5CQzS0sloOKCotS0zAqwQdGxtbUAw4u
 B9lgAAAA=
X-Change-ID: 20250409-hp-x14-0f1d86bcb699
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744276408; l=1300;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=z14bFgffIMF84MH2SbzPe5mYlhRgz6DlUsTYSQpfWNg=;
 b=4rsuzTGzDm1t027Nmwxw+rLz+DcUAZnFM6lXltDJdWndm0SdmwiP3z9Px5k18w1p7oGOo5Ely
 lj+aBylgQP0CCgDN6W1Pd2I9mh7HW5wUGPacKsWsnP1lju4IZAWv3hq
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

- remove unused retimer, regulators, pinctrls 
- remove unused i2c buses
- amend order of nodes
- explicitly activate smb2360 eUSB2 repeaters for the type-c connectors.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Jens Glathe (5):
      arm64: dts: qcom: x1e80100-hp-x14: add usb-1-ss1-sbu-mux
      arm64: dts: qcom: x1e80100-hp-x14: remove PS8830 retimer 1 definitions
      arm64: dts: qcom: x1e80100-hp-x14: remove unused i2c buses
      arm64: dts: qcom: x1e80100-hp-x14: amend order of nodes
      arm64: dts: qcom: x1e80100-hp-x14: explicitly enable smb2360 eUSB2 repeaters

 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 236 ++++++---------------
 1 file changed, 66 insertions(+), 170 deletions(-)
---
base-commit: 46086739de22d72319e37c37a134d32db52e1c5c
change-id: 20250409-hp-x14-0f1d86bcb699

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

