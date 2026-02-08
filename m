From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/3] arm64: qcom: sm8550: add DDR, LLCC & L3 CPU bandwidth
 scaling
Date: Sat, 07 Feb 2026 19:28:05 -0600
Message-Id: <20260207-sm8550-ddr-bw-scaling-v1-0-d96c3f39ac4b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2M0QpAQBAAf0X7bOtsDvkVeThuscXRbaHk310ep
 2bmAeUorNBmD0Q+RWUPCYo8g3FxYWYUnxjIUGXI1KhbY61B7yMOF+roVgkzDoWlsqF6Sgqk9og
 8yf1/u/59P2wtYWJnAAAA
X-Change-ID: 20260207-sm8550-ddr-bw-scaling-b1524827f207
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770514088; l=786;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=EVmwpsn/M0EHGyo12B1ExZh+qOBLjCpzgI/06Q6roe8=;
 b=EKyQX05TxuL0xd7rCZyfQwoWfv6lm/Nia0Sj+B+8ChM7Mi+vUnZns+9U+/gvl5jSftiKfCqPs
 jDCNIgD0AC7DzT3epb6aYJ8OojdTiLer9y+UfmvfXalBEtX6PtRblDY
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
Aaron Kling (3):
      arm64: dts: qcom: sm8550: add OSM L3 node
      arm64: dts: qcom: sm8550: add cpu interconnect nodes
      arm64: dts: qcom: sm8550: add cpu OPP table with DDR, LLCC & L3 bandwidths

 arch/arm64/boot/dts/qcom/sm8550.dtsi | 367 +++++++++++++++++++++++++++++++++++
 1 file changed, 367 insertions(+)
---
base-commit: 9845cf73f7db6094c0d8419d6adb848028f4a921
change-id: 20260207-sm8550-ddr-bw-scaling-b1524827f207

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

