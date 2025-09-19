From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Subject: [PATCH v6 0/2] power: supply: Add several features support in
 qcom-battmgr driver
Date: Fri, 19 Sep 2025 11:18:49 +0800
Message-Id: <20250919-qcom_battmgr_update_new-v6-0-ed5c38867614@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJnLzGgC/x3MOQqAMBBA0avI1AaMG+pVREKWUacwahIXEO9us
 HzF/w94dIQeuuQBhyd5Wm1EnSagZ2knZGSiIc/yKmt5w3a9LkLJEJbJiWMzMqCweDEz8koVJS8
 b1BDrzeFI93/uh/f9ANHoCARpAAAA
X-Change-ID: 20250918-qcom_battmgr_update_new-df15b34148ec
To: kernel@oss.qualcomm.com, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758251938; l=2035;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=4y7Qat4TBsdLXPPTnpkcAV5ZsirjHTUE90pFEsVfYQU=;
 b=WOa6mruhpl/a5xoK0bbi5B7WSOB8GVBHub+Ew2/i4Jf2teFL57OaUJls5SUrt/sj6vZ22ME4i
 4tAFtj1DwqmCEl+u+Ezmk4KQ20wxFled2523tPSQhmWmd0ghBIRhRGI
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This continues the effort of updating changes which haven't been accepted
in patch v5. Including:
  1. Add nvmem cells for x1-crd device to enable reading back charger
     control threshold.
  2. Add handling for notification 0x83 to avoid unexpected error messages.

Rebase the changes on linux-power-supply.git@for-next

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
Changes in v6:
- Dropped patch[1-7] as they have been accepted and present in linux-power-supply.git@for-next.
- Formatted the commit text for easy reading, and correct the bit positions for the additional
  notifications coming along with code 0x83.
- Added "Reported-by" trailer.
- Link to v5: https://lore.kernel.org/r/20250917-qcom_battmgr_update-v5-0-270ade9ffe13@oss.qualcomm.com

Changes in v5:
- Added additional explanation for "state_of_health" in ABI document as Sebastian suggested.
- Removed "Tested-by" trailers in the patches unrelated to charge control feature.
- Updated the copyright statement in qcom_battmgr.c according to the latest guidelines.
- In [PATCH v4 5/8], add "X1E80100" in the "if" variant checks to ensure
  the correctness even if only this patch is applied.
- Format the entries for "nvmem-cells" DT properties.
- Add a new change at last to fix the error messages for unsupported notifications
- Link to v4: https://lore.kernel.org/r/20250915-qcom_battmgr_update-v4-0-6f6464a41afe@oss.qualcomm.com

---
Fenglin Wu (2):
      arm64: dts: qcom: x1e80100-crd: Add charge limit nvmem
      power: supply: qcom_battmgr: handle charging state change notifications

 arch/arm64/boot/dts/qcom/x1-crd.dtsi         |  7 +++++++
 arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi | 20 ++++++++++++++++++++
 drivers/power/supply/qcom_battmgr.c          |  5 ++++-
 3 files changed, 31 insertions(+), 1 deletion(-)
---
base-commit: cc3e883a06251ba835f15672dbe8724f2687971b
change-id: 20250918-qcom_battmgr_update_new-df15b34148ec

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

