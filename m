From: David Heidelberg <david@ixit.cz>
Date: Thu, 30 Oct 2025 08:24:29 +0100
Subject: [PATCH v2 1/2] Documentation: dt-bindings: arm: qcom: Add Pixel 3
 and 3 XL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-pixel-3-v2-1-8caddbe072c9@ixit.cz>
References: <20251030-pixel-3-v2-0-8caddbe072c9@ixit.cz>
In-Reply-To: <20251030-pixel-3-v2-0-8caddbe072c9@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=716; i=david@ixit.cz;
 h=from:subject:message-id; bh=DlXm2VUp7Ijt8uTzaBaBxliSbXJ4DoxMqfa5a4LztB0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpAxKxVrFT1VwZwJfehm2IryQgQOjZpqH+tViW1
 WYBJWhGs2KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQMSsQAKCRBgAj/E00kg
 cs4YD/9qzawViIzkeuR6ctXUpYb+EpmYU5qpFlWeAUVuEnPSB7NgEML7I6C2/ZbSqteCao63Uf9
 KzddLsDWszBcyO7Yz6FxU21ZsDGEmGa8WQChHUGx2mexka5q+yYkK4m89T28PRKafIy2BGTD64N
 B8anhGaNFhItMQNfKGdrkHQ1oZ7MDK6u2Z5N3FRSMDaNGDTxhvdIJaCNw86jfdb5GlNwmTkISh7
 YZyA7KKePdnWkhrPJd6K8LMGEKsvxHbCoPCVndKnzmNqR9f11OxlYRVL5uM6HssybKy2u/XzQvK
 6iwLUeeU3irxdLJsXOME8cbTOsAmyhT3SX9oh5sGidkN88oQsAYKGPjqRbWICnqopKyYCpH1WMt
 zEB6TlYjEVi/hZPTmf0zTMI7hbLpSx0+xFO6hUcPYx7EqChU/TVmyTvSAZtznW40ugDMoZd7xuX
 UkIiTG0dd5EzA5VaExF+jKx6Y93N4jNzfHPCcb8x8bEZc0PFeYC+bh7fhx/nMccjMZ9ZI5PInPM
 65+0Lc+kzKK+gQsg0bOrZTtm43EKdT/3a6cW1LShmAoMSQ7GvAOTKUPCCMZLTU1BZdOnNzV3FQl
 e3Lvtre7KF6Awzd07ZhF4QeB7037yT6AvMQPwX7EnMIqEXL43nhBGcfa35QxDQZrvhaNpjNhtQW
 xTAGnjPYz02nFcA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the bindings for the Pixel 3 and 3 XL.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d84bd3bca2010..760b6633b7a55 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -900,6 +900,8 @@ properties:
 
       - items:
           - enum:
+              - google,blueline
+              - google,crosshatch
               - huawei,planck
               - lenovo,yoga-c630
               - lg,judyln

-- 
2.51.0

