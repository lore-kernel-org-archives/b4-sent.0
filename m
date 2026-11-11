From: Vishal Balasubramanian <vishal.bala.nps@gmail.com>
Subject: [PATCH 0/2] (no cover subject)
Date: Wed, 11 Nov 2026 09:35:31 +0530
Message-Id: <20261111-master-v1-0-07b4f06a9dd5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIvp82oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINDNTSwuSS3SNTdJMjZNtjRIMzFJVgIqLihKTcusABsUHVtbCwABg2f
 AWAAAAA==
X-Change-ID: 20261111-master-74b35c90f44c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Vishal Balasubramanian <vishal.bala.nps@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794369932; l=986;
 i=vishal.bala.nps@gmail.com; s=20261111; h=from:subject:message-id;
 bh=KiusWAhSK4OQ0JyY8lYHbC/AU+upoKs1lAbK8klr2jE=;
 b=7pIQL4mHz0R9KgBAWaTCzFrikBumWNR5t+7mupL34uYw+c034KWw6nGylSvp1QVRl6FDZ1rqZ
 SjPD0enwYxjAL4KlOLT3tgtYkAiocR4MZbLDBHFYdbjQIwGZvSdPn6R
X-Developer-Key: i=vishal.bala.nps@gmail.com; a=ed25519;
 pk=GDcoc+SAK+BHD1Eq17X/BJa9U2HZkBW+dmxS8s1xMAY=
X-Endpoint-Received: by B4 Relay for vishal.bala.nps@gmail.com/20261111 with auth_id=1486
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Samsung Galaxy Tab S7 FE LTE
(SM-T735), a tablet based on the Qualcomm SM7225 SoC.

Supported in this initial version:
- Display via simple-framebuffer
- Volume keys and power button
- UFS and microSD
- USB
- Wi-Fi and Bluetooth (WCN3991)
- ADSP, CDSP and modem, including mobile data

Signed-off-by: Vishal Balasubramanian <vishal.bala.nps@gmail.com>
---
Vishal Balasubramanian (2):
      dt-bindings: arm: qcom: Add Samsung Galaxy Tab S7 FE LTE
      arm64: dts: qcom: sm7225: Add Samsung Galaxy Tab S7 FE LTE

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/sm7225-samsung-gts7xllite.dts    | 575 +++++++++++++++++++++
 3 files changed, 577 insertions(+)
---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261111-master-74b35c90f44c

Best regards,
-- 
Vishal Balasubramanian <vishal.bala.nps@gmail.com>

