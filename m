From: Robert Eckelmann <longnoserob@gmail.com>
Subject: [PATCH 0/2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable SLPI
Date: Wed, 26 Nov 2025 21:08:34 +0900
Message-Id: <20251126-slpi-v1-0-c101d08beaf2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMLtJmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQyMz3eKcgkzdZDNDs1TjRGNLw+RUJaDSgqLUtMwKsDHRsbW1ALGoOI5
 WAAAA
X-Change-ID: 20251126-slpi-c616e3a391ce
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Eckelmann <longnoserob@gmail.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=595; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=ElnGPqFvz62tr9E8HS/4iLIgaALgD3PStTWgfVE+gkE=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDLV3p4vbGzZ4/RCd07c3ZkWx1brZOfwyWufMOr9/nP3+
 Yh1TI57O0pZGMS4GGTFFFl2uB3TyXRdGrFx9/4ymDmsTCBDGLg4BWAivxcyMkxwF2mqn7e2QVvP
 csmLTQ/P7p88q+WyaWLvD9Z5eU/6GOMYGXY3nsldrhXDd7zupF8lw/oPwQKno6TdVerrT749kGf
 5mRcA
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the SLPI dsp on the Xiaomi Pocophone F1 with Qualcom SDM845 SoC.

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
Robert Eckelmann (2):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable SLPI
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Add placeholders and sort

 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 30 +++++++++++++++++-----
 1 file changed, 23 insertions(+), 7 deletions(-)
---
base-commit: d724c6f85e80a23ed46b7ebc6e38b527c09d64f5
change-id: 20251126-slpi-c616e3a391ce

Best regards,
-- 
Robert Eckelmann <longnoserob@gmail.com>

