From: Vincent Knecht <vincent.knecht@mailoo.org>
Subject: [PATCH v4 0/4] CAMSS support for MSM8939
Date: Mon, 02 Jun 2025 19:27:26 +0200
Message-Id: <20250602-camss-8x39-vbif-v4-0-32c277d8f9bf@mailoo.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP7ePWgC/23OSw6CMBCA4auQrq3pgwHqynsYF6UPaCLUtKbBE
 O5uIS4wuPwnmW9mRtEEZyK6FDMKJrno/JijPBVI9XLsDHY6N2KEAQFaYyWHGHEzcYFT6ywWNVg
 LDRVUNChvPYOxbtrE2z137+LLh/d2INF1+rUYOViJYoIlZUpXhFTSiusg3cP7sw8dWrHE9gAcA
 ZaBSnMNCqQtoToAfAfwPx/wDFglqKbQtqB/gWVZPoZh4WExAQAA
X-Change-ID: 20250517-camss-8x39-vbif-975ff5819198
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748885254; l=3491;
 i=vincent.knecht@mailoo.org; s=20250414; h=from:subject:message-id;
 bh=tusFr6vqIW4SyQkabsISqQQ1/RpKHpF913C78L81Pys=;
 b=CtN63Fz0a4w/C6OpUXiNhepIpVTVRQhV29+1YLr9zR9PJ/u/SC5stRtQcILD9q0zerTS75ynf
 MnXruY3VRnbBOA/zGLiBDwRdS7sE8XjgP9Hu3DkLmuO/7oJV3piC/UG
X-Developer-Key: i=vincent.knecht@mailoo.org; a=ed25519;
 pk=MFCVQkhL3+d3NHDzNPWpyZ4isxJvT+QTqValj5gSkm4=
X-Endpoint-Received: by B4 Relay for vincent.knecht@mailoo.org/20250414 with auth_id=377
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds CAMSS support for MSM8939.
It's mostly identical to MSM8916, except for some clocks
and an additional CSI.

To fix black stripes across sensor output, and garbage in
CSID TPG output, 2 VFE VBIF register settings are needed.
So the 1st patch adds helper functions to do just that.

Patch 1: adds helper for VFE VBIF settings
Patch 2: adds CAMSS_8x39 version in CAMSS driver
Patch 3: documents qcom,msm8939-camss DT bindings
Patch 4: adds camss and cci in msm8939.dtsi

Signed-off-by: Vincent Knecht <vincent.knecht@mailoo.org>
---
Changes in v4:
- Picked up tags
- Patch 1:
  - Fix alignment to match opening parenthesis (Bryan)
- Patch 2: no change
- Patch 3:
  - Wrap line at 80 chars (Krzysztof)
- Patch 4: no change
- Link to v3: https://lore.kernel.org/r/20250530-camss-8x39-vbif-v3-0-fc91d15bb5d6@mailoo.org

Changes in v3:
- Patch 1:
  - Use braces around multiline (Bryan)
  - Rename vfe_vbif_reg_write to vfe_vbif_write_reg (Bryan)
  - Get rid of switch block on CAMSS version (Bryan)
- Patch 2:
  - Get rid of switch block on CAMSS version (Bryan)
- Patch 3: no change
- Patch 4: no change
  - Tried to get rid of CCI camss_ahb but this resulted in device
    freeze+reboot (Konrad)
- Link to v2: https://lore.kernel.org/r/20250525-camss-8x39-vbif-v2-0-6d3d5c5af456@mailoo.org

Changes in v2:
- Patch 1:
  - Fix devm_platform_ioremap_resource_byname line to not end with
    opening parenthesis (media-ci/1-checkpatch)
  - Move camss-vfe-4-1.c handling of VBIF previously in patch 2 here
    (Dmitry)
- Patch 2:
  - Declare regulators in PHY entries, not CSID ones (Bryan)
- Patch 3: (bindings)
  - Fix bindings checks for new errors (Rob)
  - Fix properties ordering, code-style and example (Krzysztof)
  - Sort reg-names, clock-names and interrupt-names alphanumerically (Bryan)
- Patch 4: (dtsi)
  - Move #address/#size cells before status (Konrad)
  - Aligned CCI with msm8916, thus removing ispif_ahb mention (Konrad)
    If "camss_ahb should be unnecessary", it's still required by qcom,i2c-cci.yaml
- Link to v1: https://lore.kernel.org/r/20250520-camss-8x39-vbif-v1-0-a12cd6006af9@mailoo.org

---
Vincent Knecht (4):
      media: qcom: camss: vfe: Add VBIF setting support
      media: qcom: camss: Add support for MSM8939
      media: dt-bindings: Add qcom,msm8939-camss
      arm64: dts: qcom: msm8939: Add camss and cci

 .../bindings/media/qcom,msm8939-camss.yaml         | 254 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/msm8939-pm8916.dtsi       |   4 +
 arch/arm64/boot/dts/qcom/msm8939.dtsi              | 146 ++++++++++++
 drivers/media/platform/qcom/camss/Makefile         |   1 +
 drivers/media/platform/qcom/camss/camss-csiphy.c   |   1 +
 drivers/media/platform/qcom/camss/camss-ispif.c    |   8 +-
 drivers/media/platform/qcom/camss/camss-vfe-4-1.c  |  12 +
 drivers/media/platform/qcom/camss/camss-vfe-vbif.c |  31 +++
 drivers/media/platform/qcom/camss/camss-vfe-vbif.h |  19 ++
 drivers/media/platform/qcom/camss/camss-vfe.c      |  10 +
 drivers/media/platform/qcom/camss/camss-vfe.h      |   3 +
 drivers/media/platform/qcom/camss/camss.c          | 157 +++++++++++++
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 13 files changed, 645 insertions(+), 2 deletions(-)
---
base-commit: 8566fc3b96539e3235909d6bdda198e1282beaed
change-id: 20250517-camss-8x39-vbif-975ff5819198

Best regards,
-- 
Vincent Knecht <vincent.knecht@mailoo.org>

