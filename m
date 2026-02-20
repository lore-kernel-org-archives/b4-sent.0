From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/2] arm64: qcom: sm8550: add DDR, LLCC & L3 CPU
 bandwidth scaling
Date: Thu, 19 Feb 2026 22:07:38 -0600
Message-Id: <20260219-sm8550-ddr-bw-scaling-v3-0-75c19152e921@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNyw6CMBAF0F8hXVvTTgsFV/6HcdEXMAkP05qqI
 fy7hRUb4/LezD2zkOgD+kguxUKCTxhxnnIQp4LYXk+dp+hyJsCgYsAUjWNdlow6F6h50Wj1gFN
 HDS9B1qDafELy9hF8i+/dvd1z7jE+5/DZ3yS+tf/ExGnumsqKVjTaSnPtRo3D2c4j2cQEB4XXv
 xTIihQaTOWk8oodlXVdv8o3uIsAAQAA
X-Change-ID: 20260207-sm8550-ddr-bw-scaling-b1524827f207
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Georgi Djakov <djakov@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771560469; l=1208;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=2iCGULRraoRUNzZGJaTBhx5eh+74uNiuFCJjzd4M2Fg=;
 b=QcmoZJV8o0SGOOXkq3FvvTls/WzFEv1HQs36lHVzHMaeH7cebhGzmLFCQK6IUgqSlGPaNYacG
 jmWmWnYT0UVCTw5kx07Hl23CIm19IoTRviKnRIuPgAMr/e9KgADvBmb
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the OSM L3 controller node then add the necessary interconnect
properties with the appropriate OPP table for each CPU cluster to
allow the DDR, LLCC & L3 CPU bandwidth to scale along the CPU
cluster operating point.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- Squash the last two patches
- Link to v2: https://lore.kernel.org/r/20260218-sm8550-ddr-bw-scaling-v2-0-43a2b6d47e70@gmail.com

Changes in v2:
- Squash first two patches
- Update opp tables in last patch to match how the downstream driver
  parses those tables
- Link to v1: https://lore.kernel.org/r/20260207-sm8550-ddr-bw-scaling-v1-0-d96c3f39ac4b@gmail.com

---
Aaron Kling (2):
      dt-bindings: interconnect: OSM L3: Document sm8550 OSM L3 compatible
      arm64: dts: qcom: sm8550: add cpu OPP table with DDR, LLCC & L3 bandwidths

 .../bindings/interconnect/qcom,osm-l3.yaml         |   1 +
 arch/arm64/boot/dts/qcom/sm8550.dtsi               | 367 +++++++++++++++++++++
 2 files changed, 368 insertions(+)
---
base-commit: 9845cf73f7db6094c0d8419d6adb848028f4a921
change-id: 20260207-sm8550-ddr-bw-scaling-b1524827f207

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

