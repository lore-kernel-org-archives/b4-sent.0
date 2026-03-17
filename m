From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/5] Add framebuffer on Xiaomi Poco F1 and disable the
 MDSS on tianma panel variant
Date: Tue, 17 Mar 2026 23:12:30 +0100
Message-Id: <20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM7RuWkC/1XMQQ6CMBCF4auQWVszLSKNK+9hWNB2kEkQTIsNS
 Hp3K65c/i953waBPFOAS7GBp8iBpzGHOhRg+3a8k2CXGxSqM0qshSG/DgO/HqIzwpWka2MVGkL
 Il6enjpeduzW5ew7z5Nddj/K7/qBSyn8oSoHihLqtNDqpKrrywvPRvqFJKX0AauYrz6YAAAA=
X-Change-ID: 20260107-beryllium-fb-d3e87bc20be0
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1522; i=david@ixit.cz;
 h=from:subject:message-id; bh=y243D6Ne6ta8m6pwl19zt5ZKjdhAH8edxSmktq9NqqU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpudHQ+dDsZMmxVdjdT95CwZwEQ8WZdO1Y+hAJi
 SsMoNpogICJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabnR0AAKCRBgAj/E00kg
 cpoID/wJY1PrVCkHjF7CseuHrjO2y4z5UerUXFD04e8qh3pgNpH9epcpN6kNdhMFux3NmidW8wq
 hh93DpYgfyZ5AAfRhXJFspw78jTBPwZHZuhxZkBIfosoklUFqTKiIZGxSaz+V+CExThbNx9r9t7
 IOTMBx0am1Jbnc2SD3J26EgDwboRfSnQ++QAvVPcWCALMhkNTsJB4I9fF56hmj9h08DXfzHd9qv
 E6KQsIjlH4h0IncecABl106/2odbezK+XzBRZgEkgBow5132oEFEF3CUmoIsg+/H91GCZ5Rp/FT
 tCNd7H5zNHVKGTSWgclVUB7zrd9zkoxs8sic8ziJCTH1L2WRp0Rjx2nTj5F4gbBdSHPKRN1lT8v
 21iZ+h72jATQriYLraONUxdrrojSOpuCCI8k/zDs9P9GW146YXDzlCXSmH+pxttsm7bz6V5fmlq
 9T9xFoM25xOk2NM1EWn7/oPvk1nv33MLdSwriQAb30z/HWtKsFSMk2te2m5T5k8kz2ZmTjZ6aas
 YG4kbZe3AIVM/1Fhi/Q2gVl8jCO3NIXDWPIpeC/4ZCfisGmDXrqNUE50pQ8nFe+VkrS593OvKq7
 s5QCh4KOTxiIYviKaXib8AFkQAuobp+qGP93uwL9wJgVML/GU/h7E9cIG0yFPXRbrJTXrQYxcLz
 Ew7FghT0H4GxX6Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable framebuffer for early console output.

Due to broken panel driver on tianma and no visual output it's better
to disable the MDSS so the framebuffer stays on. 

In case second patch gets rejected, please apply the first one standalone

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Changes in v2:
- Added few conversion to use memory-region.
- Corrected framebuffer node name. (Konrad)
- Link to v1: https://lore.kernel.org/r/20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz

---
David Heidelberg (3):
      arm64: dts: qcom: sdm845-oneplus: Drop address from framebuffer node
      arm64: dts: qcom: sdm845-shift-axolotl: Convert fb to use memory-region
      arm64: dts: qcom: sdm845-samsung-starqltechn: Convert fb to use memory-region

Petr Hodina (2):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Introduce framebuffer
      arm64: dts: qcom: sdm845-xiaomi-beryllium-tianma: Disable MDSS

 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi      |  2 +-
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts  |  7 ++++---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts        |  6 +++---
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi    | 16 ++++++++++++++++
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts     | 10 ++++++++++
 5 files changed, 34 insertions(+), 7 deletions(-)
---
base-commit: 8e5a478b6d6a5bb0a3d52147862b15e4d826af19
change-id: 20260107-beryllium-fb-d3e87bc20be0

Best regards,
-- 
David Heidelberg <david@ixit.cz>

