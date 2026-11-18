From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Subject: [PATCH 0/3] msm8974/wcn36xx: recover Wi-Fi after a WCNSS crash
Date: Wed, 18 Nov 2026 15:57:58 +0100
Message-Id: <20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPa8/WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0ML3fLkvOJiXYgu3TJD3bQ0E7OUJAPTRGPDZCWgroKi1LTMCrCJ0bE
 QfnFpUlZqcgnIGKXaWgBmx6bscwAAAA==
X-Change-ID: 20261118-wcnss-series-v1-ff46db05a31c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Luca Weiss <luca@lucaweiss.eu>, Eugene Krasnikov <k.eugene.e@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, wcn36xx@lists.infradead.org, 
 linux-wireless@vger.kernel.org, 
 Alexandre Rapaille <arapaille@atlr-engineering.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795013892; l=1299;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=n8yc64Of0fWZA21WPMBAjcjFUjAVUPNfN5qZlFFTgjA=;
 b=dpaJKsS/juYfwL649WABQZENlJBbG0CSt4JcWP76DIQsmjbq6WYGPqFEPosdK4mUTQFxjDjL2
 j32TXZ4SamWALlqXNrknkI4jl2C1PlFhOWdJlM3yvi3hodUyEquqK9X
X-Developer-Key: i=arapaille@atlr-engineering.com; a=ed25519;
 pk=xskH/sIiNU/aZCeGeBB1TK/AuiG3MXlX0m2wMlbMl08=
X-Endpoint-Received: by B4 Relay for arapaille@atlr-engineering.com/20261118 with auth_id=1560
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On msm8974 the wcn36xx re-probe after a WCNSS crash fails on an IRQ type
mismatch (DT edge, driver level), so wlan0 stays gone until reboot; seen
on deployed Fairphone 2 gateways.

Tested on a Fairphone 2 (6.12.113 plus this series): 10/10 forced WCNSS
crashes recovered in ~20 s; unpatched, none did. Build-tested on
next-20261117, dtbs_check unchanged.

Patch 1 is for the qcom tree, 2-3 for ath. Patch 2 needs patch 1 on
msm8974, or its WCNSS IRQs would turn edge-triggered.

Signed-off-by: Alexandre Rapaille <arapaille@atlr-engineering.com>
---
Alexandre Rapaille (3):
      ARM: dts: qcom: msm8974: Fix WCNSS wifi interrupt trigger type
      wifi: wcn36xx: Do not enforce interrupt trigger type
      wifi: wcn36xx: Stop waiting on a dead firmware during remove

 arch/arm/boot/dts/qcom/qcom-msm8974.dtsi   | 4 ++--
 drivers/net/wireless/ath/wcn36xx/dxe.c     | 6 +++---
 drivers/net/wireless/ath/wcn36xx/main.c    | 1 +
 drivers/net/wireless/ath/wcn36xx/smd.c     | 8 ++++++++
 drivers/net/wireless/ath/wcn36xx/wcn36xx.h | 4 ++++
 5 files changed, 18 insertions(+), 5 deletions(-)
---
base-commit: 20eef29b7c8465ac98d7dd6d6f2ac07a8d8056ca
change-id: 20261118-wcnss-series-v1-ff46db05a31c

Best regards,
--  
Alexandre Rapaille <arapaille@atlr-engineering.com>

