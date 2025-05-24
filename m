From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 24 May 2025 11:19:12 +0200
Subject: [PATCH v3 5/6] arm64: dts: qcom: x1p42100: Add Lenovo ThinkBook 16
 G7 QOY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250524-tb16-dt-v3-5-17e26d935e73@oldschoolsolutions.biz>
References: <20250524-tb16-dt-v3-0-17e26d935e73@oldschoolsolutions.biz>
In-Reply-To: <20250524-tb16-dt-v3-0-17e26d935e73@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, linux-usb@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748078352; l=993;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=iL7H+7E9dNkYXKjNsHdkYJEl/5Eui7TcgzKxZKRPtM4=;
 b=ckcgKkFsVD2mYC6k+k1b2cE4ozKPrFlZLZ4bkSJZ++eqZKG9uYgO9DVQFnoRXvRxhssqX1Ubs
 hV7j/N2UNgrD08C6U4Gzo9DqzDo5WwFlX9tyDY0bAxaInugqL0FZSc4
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Thinkbook 16 appears to be an X1 / X1 Plus only design.
Add make targets for normal and -el2 variant.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/Makefile | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index 669b888b27a1daa93ac15f47e8b9a302bb0922c2..aff4fe3e81ec0d6f6d52e2aa0da327b7576632d8 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -327,3 +327,6 @@ x1e80100-qcp-el2-dtbs	:= x1e80100-qcp.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1e80100-qcp.dtb x1e80100-qcp-el2.dtb
 x1p42100-crd-el2-dtbs	:= x1p42100-crd.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-crd.dtb x1p42100-crd-el2.dtb
+x1p42100-lenovo-thinkbook-16-el2-dtbs	:= x1p42100-lenovo-thinkbook-16.dtb x1-el2.dtbo
+dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-lenovo-thinkbook-16.dtb x1p42100-lenovo-thinkbook-16-el2.dtb
+

-- 
2.48.1

