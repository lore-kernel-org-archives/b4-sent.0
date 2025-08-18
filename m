From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/2] Make standalone compatible for IPQ5018 tsens v1
 without RPM
Date: Mon, 18 Aug 2025 15:33:45 +0400
Message-Id: <20250818-ipq5018-tsens-fix-v1-0-0f08cf09182d@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJkPo2gC/x2MQQqAIBBFrxKzTtBCk64SLSKnmo2ZExGId29o9
 XgP/i/AmAkZxqZAxoeYzihi2gbWY4k7Kgri0OnOam+8onRZLbwZI6uNXrU5HWyPDsMygOxSRsn
 /5zTX+gHQ7wF9YwAAAA==
X-Change-ID: 20250818-ipq5018-tsens-fix-f60d53e6eda7
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755516829; l=1421;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=0qvPUlus7r6Zs9KuwNFJGjOWcSZWTtIx7LyRA1j0WC4=;
 b=03TTmvYoMn9nFI1mQELD4NphPbJs+2XpT+x7zS14oVRnEQTArMGcmxD0tJsXSc3DHEBNFjDVl
 +6Iq6ZCfMCaD9ldazluYAnQtN7DTlrSwEu7eB/9Ew6WmYQjf8h3uc6K
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The tsens IP found in the IPQ5018 SoC should not use qcom,tsens-v1 as
fallback since it has no RPM and, as such, must deviate from the
standard v1 init routine as this version of tsens needs to be explicitly
reset and enabled in the driver.

Accordingly, update the tsens node in the IPQ5018 dts and remove the
fallback compatible.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Additional background: this was already incorporated in the patch series
which added support for IPQ5018 tsens initially. V9 was applied while
v13 had already been sent for review. In agreement with Bjorn Andersson,
I've submitted this new patch set to correct the issue.

I have taken the liberty to re-apply RB tags provided by Krzysztof,
Konrad, and Dmitry from:
https://lore.kernel.org/r/20250718-ipq5018-tsens-v14-0-28d8a2472418@outlook.com

---
George Moussalem (2):
      dt-bindings: thermal: qcom-tsens: make ipq5018 tsens standalone compatible
      arm64: dts: qcom: ipq5018: Remove tsens v1 fallback compatible

 Documentation/devicetree/bindings/thermal/qcom-tsens.yaml | 7 ++++++-
 arch/arm64/boot/dts/qcom/ipq5018.dtsi                     | 2 +-
 2 files changed, 7 insertions(+), 2 deletions(-)
---
base-commit: 3ac864c2d9bb8608ee236e89bf561811613abfce
change-id: 20250818-ipq5018-tsens-fix-f60d53e6eda7

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

