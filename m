From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Subject: [PATCH v2 0/3] msm8974/wcn36xx: recover Wi-Fi after a WCNSS crash
Date: Fri, 20 Nov 2026 09:05:44 +0100
Message-Id: <20261120-wcnss-series-v1-v2-0-3fed518decfb@atlr-engineering.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFj//2oC/3WNQQ6CMBBFr0K6dgxTgRBX3sOwKGUKY7SYDqKG9
 O4WWJvM5iXvv1mUUGASdc4WFWhm4dEn0IdM2cH4noC7xErnukLEGt7Wi8C+ghnBuaLq2rw0J7Q
 qrZ6BHH+24rXZWV7tjey0ZlZjYJnG8N1ezrh6/+vpcjBV0dWasMTWXcx0D0C+Z0/J8v3Rjg/Vx
 Bh/vPMC3MsAAAA=
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
 Alexandre Rapaille <arapaille@atlr-engineering.com>, stable@vger.kernel.org, 
 Luca Weiss <luca.weiss@fairphone.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795161947; l=1635;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=V8zx3VibnXSuUNdUrf1O+xzW97DEkNrO4W7jOoPrVv8=;
 b=zi7O5UNapFKo5i3SLpIXYAdq5DBOnd0W7Ir1xiZXrGw8NDdAQ3yruJPt5HsjHIoMf7HFMD/+k
 WM1pWnN3Y0ODjYLCK3LpoLTNclfCi3PqLpX8nQLU7odqJXTjjTM94cI
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
Changes in v2:
- Patch 1: Cc stable; picked up Luca's Reviewed-by
- Patch 2: explain the failure in the message; drop Fixes: so only
  patch 1 goes to stable (Loic)
- Patch 3: say why removing alone is not enough (Loic)
- Link to v1: https://patch.msgid.link/20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com

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

