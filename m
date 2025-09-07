From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH 0/4] Add CAMSS support for MSM8939
Date: Mon, 08 Sep 2025 00:04:14 +0200
Message-Id: <20250908-camss-8x39-vbif-v1-0-f198c9fd0d4d@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAF4BvmgC/23OSw7CIBCA4asY1mIYcLC48h7GBeVRSVQMGFLT9
 O7SxkVNXf6TzDczkOxScJkcNwNJroQc4qMGbDfEXPWjczTY2oQzjgzhQI2+50ybXiha2uCpOqD
 32IAC1ZC69UzOh34Wz5fa15BfMb3nAwWm6dfibGUVoIxq4MZKxqT26nTX4RbjLqaOTFjhSwDXA
 K+AtMKiQe33KFeAWADizweiAt4osIBti/YXGMfxA/StPzgxAQAA
X-Change-ID: 20250517-camss-8x39-vbif-975ff5819198
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757282673; l=2310;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=9+FmzHBVrcCtqXllvP6hTlSCZ5CvZZym/HB8c4kj5mE=;
 b=sdrcJ3hmiqBjErZCuxj8R0+8gYYznFsn/UaMWjBactkUePKhr9bgMpGrsog5PwVLNWYRdbi7M
 D2RLjHQ5hEmBgr4AfURmHK3x+otqq8amfVKoreTakUBvC4GTqTLlrgI
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

(This series resumes [1].)

This series adds CAMSS support for MSM8939.  It's mostly identical to
MSM8916, except for some clocks and an additional CSI.

To fix black stripes across sensor output, and garbage in CSID TPG
output, 2 VFE VBIF register settings are needed.  So the 2nd patch adds
helper functions to do just that.

Patch 1: documents qcom,msm8939-camss DT bindings
Patch 2: adds helper for VFE VBIF settings
Patch 3: adds CAMSS_8x39 version in CAMSS driver
Patch 4: adds camss and cci in msm8939.dtsi

Changes compared to [1]:
- Move bindings patch to the beginning
- Make the order of {reg, clock, interrupt} items the same as in 8916 +
  append additional items
- Drop R-b tags from bindings and dts patches as order of items was
  changed

[1] https://lore.kernel.org/all/20250613-camss-8x39-vbif-v5-0-a002301a7730@mailoo.org/

Signed-off-by: Vincent Knecht <vincent.knecht@mailoo.org>
[André: Apply reviewer comments]
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
Vincent Knecht (4):
      media: dt-bindings: Add qcom,msm8939-camss
      media: qcom: camss: vfe: Add VBIF setting support
      media: qcom: camss: Add support for MSM8939
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
base-commit: be5d4872e528796df9d7425f2bd9b3893eb3a42c
change-id: 20250517-camss-8x39-vbif-975ff5819198

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

