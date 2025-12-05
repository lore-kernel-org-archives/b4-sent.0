From: Robert Eckelmann <longnoserob@gmail.com>
Subject: [PATCH v2 0/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 SLPI
Date: Fri, 05 Dec 2025 22:00:03 +0900
Message-Id: <20251205-slpi-v2-0-dfe0b106cf1a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFPXMmkC/13MQQqDMBCF4avIrJuSGWlou+o9xEWMow6okaSEi
 uTuTV12+T8e3wGRg3CEZ3VA4CRR/FqCLhW4ya4jK+lLA2m6IZJRcd5EOYOGa1s/0DGU6xZ4kM/
 JNG3pSeLbh/1UE/7WPyCh0sqhxl7fO7YDvcbFynx1foE25/wFLLVOo5gAAAA=
X-Change-ID: 20251126-slpi-c616e3a391ce
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=823; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=dnuZJZL8TlJbC+gn2skXrXqLMNfZHBRasjG07Eo7sjg=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKNrqcplE0+pf58Mad6g59m6nPVzQuaBQQbr7c9LlX08
 9p8b9KujlIWBjEuBlkxRZYdbsd0Ml2XRmzcvb8MZg4rE8gQBi5OAZiIqAEjw+fbC64FJKy9mPvH
 4NKMva7izUwLy7vXLH05sY/3X3XFtgxGhvPv7ZIS/0THRhbXcWn093x9fC/k/UqX+MDfh6uXpj+
 x4AAA
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the SLPI dsp on the Xiaomi Pocophone F1 with Qualcom SDM845 SoC.

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
Changes in v2:
- adjusted firmware paths
- enabled i2c busses
- Link to v1: https://lore.kernel.org/r/20251126-slpi-v1-0-c101d08beaf2@gmail.com

---
Robert Eckelmann (3):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable SLPI
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Adjust firmware paths
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Add placeholders and sort

 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 47 ++++++++++++++++------
 1 file changed, 35 insertions(+), 12 deletions(-)
---
base-commit: 6987d58a9cbc5bd57c983baa514474a86c945d56
change-id: 20251126-slpi-c616e3a391ce

Best regards,
-- 
Robert Eckelmann <longnoserob@gmail.com>

