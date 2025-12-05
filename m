From: Robert Eckelmann <longnoserob@gmail.com>
Subject: [PATCH v3 0/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 SLPI
Date: Fri, 05 Dec 2025 22:58:58 +0900
Message-Id: <20251205-slpi-v3-0-a1320a074345@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACLlMmkC/12MywrCMBBFf6XM2shMSoO68j/ERZpO2oG+SCQop
 f9uWgTF5bnccxaIHIQjXIoFAieJMo0ZykMBrrNjy0qazKBRV0TaqNjPopwhw6Utz+QY8nUO7OW
 5Z273zJ3ExxReezXRtv4FEilUjpAaPNVsvb62g5X+6KYBtkDSX0lj9ZF0lhrPWBMa58n+Suu6v
 gET2ilPzQAAAA==
X-Change-ID: 20251126-slpi-c616e3a391ce
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=963; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=SLlMh3YUbCexX05xcDNCw9MPzyvzjL+AToEwatpcYxM=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKNnuo4nn3v53vl7pozfc/Vc288P362YNvGd38kPs918
 ksu/OjQ2lHKwiDGxSArpsiyw+2YTqbr0oiNu/eXwcxhZQIZwsDFKQATaSpmZHh4Plggjot17+xW
 lTvxkVPLA1qXMgSsWHVC+MT6K1xnYpgZ/mnsZXef017C3KmzUa1XMdT5dXDx6oLmrlXbi6fXi5h
 w8gAA
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the SLPI dsp on the Xiaomi Pocophone F1 with Qualcom SDM845 SoC.

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
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

 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 46 ++++++++++++++++------
 1 file changed, 34 insertions(+), 12 deletions(-)
---
base-commit: 6987d58a9cbc5bd57c983baa514474a86c945d56
change-id: 20251126-slpi-c616e3a391ce

Best regards,
-- 
Robert Eckelmann <longnoserob@gmail.com>

