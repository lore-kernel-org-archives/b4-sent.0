From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/3] arm64: qcom: sm8550: add DDR, LLCC & L3 CPU
 bandwidth scaling
Date: Wed, 18 Feb 2026 12:16:17 -0600
Message-Id: <20260218-sm8550-ddr-bw-scaling-v2-0-43a2b6d47e70@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNSw6CMBRFt0Le2GdK+TtyH4ZBf8BLaEtaUzWEv
 VvZgMNzcj87RBPIRLgVOwSTKJJ3GfilALUINxsknRk44y3jrMNo+6ZhqHVA+cKoxEpuRlk2vO5
 5N+UI5O4WzETvc/cxZl4oPn34nDep/Nl/i6nE7IZWVVM1CFXL+2wFrVflLYzHcXwB0XFx0boAA
 AA=
X-Change-ID: 20260207-sm8550-ddr-bw-scaling-b1524827f207
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Georgi Djakov <djakov@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771438580; l=1135;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Gcm4qVHExOEVMXPGeceeOhHrV8lE0lvyc/lJzKXr9KE=;
 b=C0HAxvfbORFTufxT5rgl1D1byfeP3nL2nahiROonuwq8HhU+DsdwxGWAjHXR4Kuq4Qy14BCit
 uP03bwJo/RWA13hOEmn4myjiZaCKehyv0DUCM1m0+CLrIPh4pH5Djsb
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
Changes in v2:
- Squash first two patches
- Update opp tables in last patch to match how the downstream driver
  parses those tables
- Link to v1: https://lore.kernel.org/r/20260207-sm8550-ddr-bw-scaling-v1-0-d96c3f39ac4b@gmail.com

---
Aaron Kling (3):
      dt-bindings: interconnect: OSM L3: Document sm8550 OSM L3 compatible
      arm64: dts: qcom: sm8550: add OSM L3 node and cpu interconnect nodes
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

