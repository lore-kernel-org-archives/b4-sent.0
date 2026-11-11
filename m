From: Vishal Balasubramanian <vishal.bala.nps@gmail.com>
Subject: [PATCH v2 0/2] Add Samsung Galaxy Tab S7 FE LTE (gts7xllite)
Date: Wed, 11 Nov 2026 17:54:49 +0530
Message-Id: <20261111-master-v2-0-5eb864e9f38d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJFe9GoC/2WMwQ6DIBAFf8XsuTRAUWNP/Y/GA8KimxQxYEgbw
 7+Xeu27zctkDkgYCRPcmwMiZkoU1gry0oBZ9DojI1sZJJedqGNepx0j69V0a83AnVIGqrxFdPQ
 +Q8+x8kJpD/FzdrP4vX+JLBhnvJ+U450erG0fs9f0uprgYSylfAHEl89mnAAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794399891; l=1585;
 i=vishal.bala.nps@gmail.com; s=20261111; h=from:subject:message-id;
 bh=1CzGOPtoQOQ5ftnC93rBD5AZUNBTmg/XmuRqFrI/w+Y=;
 b=t3z2R7aYNTWMCQNkyyCGEwyoK1suv1Lr6YnXtI/4XCtA9tPksBJKx19gpJMoJewJPxRI0q1RK
 RJxp18GCGA0CZKNFBWYhZ4Phuj6nWPe2B4Vcm/wLNa3xj945Fz3wjAa
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
Changes in v2:
- Add cover letter (v1 was sent without one)
- Set PMK8350_SID to 6 and disable pmk8350_pon (Sashiko)
- Fix swapped vdda-phy/vdda-pll supplies on usb_1_qmpphy (Sashiko)
- Drop unresolvable stdout-path and unused cells from /chosen (Sashiko)
- Use cont_splash_memory for the framebuffer instead of a duplicate region (Sashiko)
- Add sd-cd pin configuration for gpio94 (Sashiko)
- Drop IPA properties already set in sm6350.dtsi (Sashiko)
- Rename knox_reserved to fastuh_mem (Sashiko)
- Link to v1: https://lore.kernel.org/r/20261111-master-v1-0-07b4f06a9dd5@gmail.com

---
Vishal Balasubramanian (2):
      dt-bindings: arm: qcom: Add Samsung Galaxy Tab S7 FE LTE
      arm64: dts: qcom: sm7225: Add Samsung Galaxy Tab S7 FE LTE

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/sm7225-samsung-gts7xllite.dts    | 586 +++++++++++++++++++++
 3 files changed, 588 insertions(+)
---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261111-master-74b35c90f44c

Best regards,
-- 
Vishal Balasubramanian <vishal.bala.nps@gmail.com>

