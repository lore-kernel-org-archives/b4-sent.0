From: Xilin Wu <wuxilin123@gmail.com>
Date: Fri, 28 Jun 2024 19:30:12 +0800
Subject: [PATCH 1/2] dt-bindings: arm: qcom: Add ASUS Vivobook S 15
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240628-asus-vivobook-s15-v1-1-2a1e4571b8ab@gmail.com>
References: <20240628-asus-vivobook-s15-v1-0-2a1e4571b8ab@gmail.com>
In-Reply-To: <20240628-asus-vivobook-s15-v1-0-2a1e4571b8ab@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abel Vesa <abel.vesa@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719574221; l=679;
 i=wuxilin123@gmail.com; s=20240424; h=from:subject:message-id;
 bh=RGZfgpJlhdnNIXBEd0+u/3mv88NUycmZX6UUfdhL1s8=;
 b=B/encHNUfXVXiq2KLVK0ZyEvVjzQyuEZo1dssfZJrE/tNNBJZOCo/aa7fqf+Ge2odBkSHsTlu
 bvcShr+A8sQDt5vNzdzZmB1zRYv3LqDYe7Xqa9tvsq9fUf9A10A0tlV
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=vPnxeJnlD/PfEbyQPZzaay5ezxI/lMrke7qXy31lSM8=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20240424 with auth_id=157
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible for this device.

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ec1c10a12470..8342e3f2523f 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1036,6 +1036,7 @@ properties:
 
       - items:
           - enum:
+              - asus,vivobook-s15
               - qcom,x1e80100-crd
               - qcom,x1e80100-qcp
           - const: qcom,x1e80100

-- 
2.45.2

