From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 15 May 2025 22:38:57 +0200
Subject: [PATCH 3/4] arm64: dts: qcom: x1p42100: add Lenovo ThinkBook 16 G7
 QOY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250515-tb16-dt-v1-3-dc5846a25c48@oldschoolsolutions.biz>
References: <20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz>
In-Reply-To: <20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747341542; l=946;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=etQdHXyoLuErHhEhjcOJ713jpC1/4AMxjblfzFJ1r/k=;
 b=hnqBEXEPyG9aeqmAS8/pbW33X5Ksq0cAY3VWsZb/HAIddeUvtOzEnCJwyVnqCTcH7kZ8/mnAm
 Ww9/WEva2dgDitElsx/GJ8kAFBE1igLz6sSeDRV/1AmXGIBUkyLDkjr
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Thinkbook 16 appears to be an X1 / X1 Plus only design.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/Makefile | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index 4300b29397c6a0087e5c5909d756d733f308d373..345b13f50d433c3df1da6b20e4c5c4c415e63dbe 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -323,3 +323,6 @@ x1e80100-qcp-el2-dtbs	:= x1e80100-qcp.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1e80100-qcp.dtb x1e80100-qcp-el2.dtb
 x1p42100-crd-el2-dtbs	:= x1p42100-crd.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-crd.dtb x1p42100-crd-el2.dtb
+x1p42100-lenovo-thinkbook-16-el2-dtbs	:= x1p42100-lenovo-thinkbook-16.dtb x1-el2.dtbo
+dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-lenovo-thinkbook-16.dtb x1p42100-lenovo-thinkbook-16-el2.dtb
+

-- 
2.48.1

