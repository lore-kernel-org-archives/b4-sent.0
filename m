From: David Heidelberg <david@ixit.cz>
Date: Wed, 01 Apr 2026 22:40:14 +0200
Subject: [PATCH v3 1/4] arm64: dts: qcom: sdm845-xiaomi-beryllium:
 Introduce framebuffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-beryllium-fb-v3-1-ec7d443402ab@ixit.cz>
References: <20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz>
In-Reply-To: <20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1031; i=david@ixit.cz;
 h=from:subject:message-id; bh=SnKFfm4qN/M+jaL16XHBrfpNpLQrOoZvc5aNlTISLv4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzYKuEAyDlig9CdL1SulbmT00rBOvPNJfXjnDC
 zWbK6I9BBOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2CrgAKCRBgAj/E00kg
 copkD/wJhhvuabsJfXdKoj3O6zIl1YjXzTSDBw7vD555UuKZGPywTtwAzDdMCcePydVx0CqHADA
 14V0hOecEACczuy395lLpZKImzRF5NkatglxISf2ylA2h1QfaL5e10gbLRnbYo6xV3h6gtqRrnu
 LSx+rwmQHjt/bWLTU7+W79kj/Vu7L04Di8M3SiOsoGHZ1lR+eOQGQfuzz1IQNagRn4tFZYYRR5w
 O7NQ6lubsH5sgqHES+2fbxZR0zod8ckRnllcTbYeXf9acgQ12PiqM/8IjfyllKSf3iKp46njLUv
 VwDjhoSjL0LpHotVqMMN4kLh5BUhOf/Pr5y8n/UY7peD9yZsSNvTXLxVHyood/pNx3556/ohb0b
 Yn1ims7HoW0BEOS0VefKFvgc3QWMP7LvQqZGtlI1LKBICjXAsrMJEfzE1fSX+CQj67VjzZnzJHC
 spVf3nDkF8fi4S8NcKPElPkg0xLElXuc+K2RI4guiNbOpAYGMAgUM4kI1aVFEKSed7zvIrX11gp
 d4YFmXuKgBEvfe4JX4jUFI9SYPXufTTDkj4CygexXLOBg5orOq/MgnzqLQzF1xIdOX+W+Te+XsA
 3LEYVyTk8dqc6qJ7Lkh0OV4oHpYuedbxJpBfWMv9rr82S7td8fgg5HUWnMNt1VT2OdRZTsjKoao
 iCIFBRZFdym47GA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Add framebuffer for early console and u-boot support.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi    | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 1298485c42142..a6ee3dd171def 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -39,6 +39,22 @@ aliases {
 		serial1 = &uart6;
 	};
 
+	chosen {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		framebuffer {
+			compatible = "simple-framebuffer";
+			memory-region = <&cont_splash_mem>;
+
+			format = "a8r8g8b8";
+			stride = <(1080 * 4)>;
+			height = <2246>;
+			width = <1080>;
+		};
+	};
+
 	gpio-keys {
 		compatible = "gpio-keys";
 		autorepeat;

-- 
2.53.0

