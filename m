From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH 0/2] remoteproc: qcom: add SC8180X SLPI support
Date: Sun, 22 Nov 2026 14:36:20 +0100
Message-Id: <20261122-sc8180x-slpi-v1-0-345903fafc96@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrA1kRiqJVykuNE7bEbGSURGCd
 ze2y7f4P4FyFFZoigSRd1H5zhlYFhA+3fxmI0M2kKUakchocOjsYXRaxNjaOf/wWA3kISdL5Jc
 cv92z/Vu3fuSw3g84zwuZ6OyUcAAAAA==
X-Change-ID: 20261122-sc8180x-slpi-068895913d29
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354582; l=1013;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=qrKU9PYXKvGkbkcmvxhVdfuizNi7nVFlwY/5ZILkUr0=;
 b=c44unekNOY2YBEd6u7I5O8tBXcxPB8Jx3uKlMdCJedWQk3tqCEgVfXbaq6jaITg2UVzZGW4gu
 oRG0rTGNk3eD6hkm0kBvTCOflhcQbSWtifgcrjaBCap8oLnHkGxZd3c
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add driver match and SoC devicetree support for the SC8180X SLPI
(Sensors Low-Power Island) remoteproc and its FastRPC SDSP compute
context banks.

The compatible "qcom,sc8180x-slpi-pas" is already documented in
Documentation/devicetree/bindings/remoteproc/qcom,sm8150-pas.yaml and
sc8180x.dtsi already defines the smp2p-slpi node.

Tested on Microsoft Surface Pro X SQ2 (SC8180X) with live FastRPC
(/dev/fastrpc-sdsp) and QMI SSC sensor enumeration.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Robert Ijtsma (2):
      remoteproc: qcom: pas: add SC8180X SLPI compatible
      arm64: dts: qcom: sc8180x: add SLPI remoteproc and FastRPC SDSP node

 arch/arm64/boot/dts/qcom/sc8180x.dtsi | 61 +++++++++++++++++++++++++++++++++++
 drivers/remoteproc/qcom_q6v5_pas.c    |  1 +
 2 files changed, 62 insertions(+)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261122-sc8180x-slpi-068895913d29

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

