From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 05 Sep 2026 11:28:59 +0200
Subject: [PATCH 4/7] arm64: dts: qcom: ideacentre-mini: Build the Hamoa EL2
 DTB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-x1-ideacentre-mini-prettify-v1-4-9a87882973bb@oldschoolsolutions.biz>
References: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
In-Reply-To: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788600555; l=1213;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=tNnFe+85llnft8rgSu+IZo3lIc8akq9ek2EYr0QF1pk=;
 b=3XODYihKzUjZdZ1FLd6wg6bzzmAqABNNt9UCALkf8pWcXz2ZKfUWGEiy0OnuV5XsTcmWJn7qZ
 7+tGnsrmERCAJHsW+Syo+uUq5ipVnA2TCVi1gAY/rp/D8rKL1w/wJ05
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Other Hamoa boards combine the board DTB with x1-el2.dtbo. Do the same
for the IdeaCentre Mini so the EL2 overlay is produced alongside the
normal image.

Assisted-by: Grok 4.5 (xAI)
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/Makefile | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index e6105e5790954..0cfbf3018a7be 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -24,7 +24,10 @@ dtb-$(CONFIG_ARCH_QCOM)	+= hamoa-iot-evk.dtb
 hamoa-iot-evk-el2-dtbs	:= hamoa-iot-evk.dtb x1-el2.dtbo
 
 dtb-$(CONFIG_ARCH_QCOM)	+= hamoa-iot-evk-el2.dtb
-dtb-$(CONFIG_ARCH_QCOM)	+= hamoa-lenovo-ideacentre-mini-01q8x10.dtb
+
+hamoa-lenovo-ideacentre-mini-01q8x10-el2-dtbs := hamoa-lenovo-ideacentre-mini-01q8x10.dtb x1-el2.dtbo
+dtb-$(CONFIG_ARCH_QCOM)	+= hamoa-lenovo-ideacentre-mini-01q8x10.dtb hamoa-lenovo-ideacentre-mini-01q8x10-el2.dtb
+
 dtb-$(CONFIG_ARCH_QCOM)	+= ipq5018-rdp432-c2.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= ipq5018-tplink-archer-ax55-v1.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= ipq5210-rdp504.dtb

-- 
2.53.0

