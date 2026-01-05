From: Robert Eckelmann <longnoserob@gmail.com>
Subject: [PATCH v4 0/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 SLPI
Date: Mon, 05 Jan 2026 22:31:50 +0900
Message-Id: <20260105-slpi-v4-0-e6e0abfad3a4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEa9W2kC/23MTQqDMBCG4atI1k2ZSTT9WfUepYsYRx3QKkkJL
 eLdG6XQIl1+wzzvJAJ5piDO2SQ8RQ483NPId5lwrb03JLlKWyhQBaIyMnQjS2fQkLb6hI5Eeh0
 91fxcM9db2i2Hx+BfazXict0EIkqQDgErOJZka3Vpesvd3g29WAJRfZGC4oNUQlVNUCIYV6PdI
 v0P6YQsagUWDrnOi180z/MbEXiS6AIBAAA=
X-Change-ID: 20251126-slpi-c616e3a391ce
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1099; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=NwkKySNn7BVIR5kE9tveB2SWe15fk0mP4kndq0EbwdQ=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKj9+Y27Htl8eiaWNXhJrfJf5btOKQtPTFjZ7GAU/ile
 QUOrsdFOkpZGMS4GGTFFFl2uB3TyXRdGrFx9/4ymDmsTCBDGLg4BWAiB+Yz/E9SOZboO2nXyfgr
 LKrX71+PadjfJ6bdIq1g+sPQx2bXfxlGhjllOvyin3o5Dx29z8tUrZTwOOx1wOF3m3n7ch4p5nz
 +xAwA
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the SLPI dsp on the Xiaomi Pocophone F1 with Qualcom SDM845 SoC.

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
Changes in v4:
- remove not needed status change
- Link to v3: https://lore.kernel.org/r/20251205-slpi-v3-0-a1320a074345@gmail.com

Changes in v3:
- remove stray newline at end of file
- Link to v2: https://lore.kernel.org/r/20251205-slpi-v2-0-dfe0b106cf1a@gmail.com

Changes in v2:
- adjusted firmware paths
- enabled i2c busses
- Link to v1: https://lore.kernel.org/r/20251126-slpi-v1-0-c101d08beaf2@gmail.com

---
Robert Eckelmann (3):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable SLPI
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Adjust firmware paths
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Add placeholders and sort

 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 44 ++++++++++++++++------
 1 file changed, 32 insertions(+), 12 deletions(-)
---
base-commit: 6987d58a9cbc5bd57c983baa514474a86c945d56
change-id: 20251126-slpi-c616e3a391ce

Best regards,
-- 
Robert Eckelmann <longnoserob@gmail.com>

