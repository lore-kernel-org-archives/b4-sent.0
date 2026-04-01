From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/4] Add framebuffer on Xiaomi Poco F1 and disable the
 MDSS on tianma panel variant
Date: Thu, 02 Apr 2026 00:39:34 +0200
Message-Id: <20260402-beryllium-fb-v4-0-46170004da28@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKaezWkC/13Oyw6CMBCF4VcxXVszvdiiK9/DuKDtIJMgmqKNl
 /DuFlwgLE+T759+WIeRsGP71YdFTNTRtc1Dr1fM12V7Rk4hbyZBGhBgucP4ahp6XHjleFBYWOc
 lOASWyS1iRc8xdzzlXVN3v8bXWE9ieP2FlBDzUBIcuIai3BYQhNzigZ503/g3GzJJ/tPFH5LMV
 BlndqFy1oCfUzVRDcurKlP0NmitNMjSTbTv+y+9ezesHAEAAA==
X-Change-ID: 20260107-beryllium-fb-d3e87bc20be0
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, Dzmitry Sankouski <dsankouski@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1771; i=david@ixit.cz;
 h=from:subject:message-id; bh=biZ7mTjsG56f0OApK0tI4n92r/opIl7/ocWbNT26owc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzZ6pZjk2323McF5sFbwKWL7BkYDzm1It3+tEH
 u6LNfxzv1mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2eqQAKCRBgAj/E00kg
 cl52D/9t/R1++EPMjpK3Sc8864pED+qlGJUEum1udwAwdDqW4L2R3QYMooKM4oZEpoRuNFcrjMx
 OfyYDAnBa8Au7OciWoLyHfC3x4GQUFAlrMWxlOjJ7fbHVqPRo2bYs28Kv7uuaTLMHQegqCWtry0
 4pD3XAmlHPOjNK9DT6O/y9+nGRTwNtQajsOkFhwBVjT9MwMVpVEOv0D8wCCDIDsUy4/Xkodq4Pn
 zvcSAM/JNuGEze2yks9dAMi7zyMlDJ1tJLnX9Rhjf3j+K8W+dDfCUsCiOsbzJAnsDbKxOxMCYg0
 cN/yQnWfc4TMbGgYddq/hSH+fmFgsn9xDP7Pn6hF4eUDLGAu8N7JQfi5EoSO4uer0DFZMYsiu3Y
 eVea1JGl2rdGGcpJN31R9yqPujDWghwFC+AHEaCnzv/FeTyvNIOoKz/Um+R+2wNz3dwE4rPgmDA
 TmthgH20MaVkiOOUQFEuWqW+Bv6v6dVX8N+yhB/N4Tni9t0wD8MTD419srJw6nLuQJqsalR8RC8
 cju0AgyVxjeAjLFwd9Q7K85LB0jyfjMyLK8DWdwrQzrFWeUzjrLPO4kOXVJRFldl4kr5Bp2n712
 fXyHKWVfTWkG5U/66AJicgNik36wqehpFZCCyOqyjPHj2GCnbM/7R440OC5hwdRQZP4lUUlLj3V
 /MI2hVlSO0TICUQ==
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
Changes in v4:
- Stripped too many labels, OnePlus 6 does use the label in the OP6/OP6T
  variants. Re-add.
- Link to v3: https://lore.kernel.org/r/20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz

Changes in v3:
- Strip label from framebuffer nodes where unused and remove -0 postfix. (Konrad)
- Link to v2: https://lore.kernel.org/r/20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz

Changes in v2:
- Added few conversion to use memory-region.
- Corrected framebuffer node name. (Konrad)
- Link to v1: https://lore.kernel.org/r/20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz

---
David Heidelberg (3):
      arm64: dts: qcom: sdm845-oneplus: Drop address from framebuffer node
      arm64: dts: qcom: sdm845-shift-axolotl: Convert fb to use memory-region
      arm64: dts: qcom: sdm845-samsung-starqltechn: Convert fb to use memory-region

Petr Hodina (1):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Introduce framebuffer

 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi      |  2 +-
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts  |  7 ++++---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts        |  8 ++++----
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi    | 16 ++++++++++++++++
 4 files changed, 25 insertions(+), 8 deletions(-)
---
base-commit: bd0f139e5fc11182777b81cefc3893ea508544ec
change-id: 20260107-beryllium-fb-d3e87bc20be0

Best regards,
-- 
David Heidelberg <david@ixit.cz>

