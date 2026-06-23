From: David Heidelberg <david@ixit.cz>
Date: Tue, 23 Jun 2026 20:41:34 +0200
Subject: [PATCH] dt-bindings: arm: qcom,ids: Add SoC ID for Snapdragon SDA
 850
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-sda850-v1-1-ddd8e62c85d8@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAF3TOmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyNj3eKURAtTA12zJNNkw1QTEzMzo2QloOKCotS0zAqwQdGxtbUA8jg
 +/FgAAAA=
X-Change-ID: 20260623-sda850-6b5c1e44662c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1138; i=david@ixit.cz;
 h=from:subject:message-id; bh=sCETGokdPT28+RQWD1iS9ITAy/9lm/wifsqVmn6O6ss=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqOtNglR5svPqZW4gfuHTY4j+yRZLGfkXuivIcY
 OqMuZIlul2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCajrTYAAKCRBgAj/E00kg
 coo8D/9jwAGMPLcn+7aSyldg+mJnNs57yqMWFs2brYkeTdYstripNqfJcObbclsHI6nD5TJKGBt
 fil0rSsw4pvSYpj3g/9PEGLgdrNvPNgNrfYxrlRPI4J08K6UIrEGMGHun2XBfbEPK1ngINW2EpR
 x+evjW3OAZIWhKzIhNFWANbhgZnl6u2dYzNGCmC2JAb+q4VsB99e0fbwCyy5PcI7i1Pr4HWZVd+
 e9BD3dZSIsVKf5cWd5O0xGXs8FY3V1evXsc8Zdb+Lss7IR0W4gJhUYwTs5pfRnGTVjyZrJVAopC
 upzDwLEGcmh7F4DcLL/P7inVEH3sO4gMSyeJnRE/QcwOzwLNqeNBJ4bo+FOt+aaMt+6W14Z96E+
 8bjdz8VunG4ToBuQ1yzEkFjujoCG7BBo5R3SMr4PM1LQ4wvkIE+mUbNWbCa/dCzC3nvwlOCTuyo
 mD/a7tbL2mOTUxXm+jQuntzmmf0u2+9xISiAC9CkHvoW7V2nB6qD89yj8FX+deKu87jOmmT9f1f
 q/ydYUbwB5CgJHx1fhWRd5hEN4+PviZsokq7KXNi9BkRWUScr0YrzRi1B7UgVIm0rfQVqL2HOQQ
 kmldGrT199P1havmNfwvweaTgxeXew33n1UIMKDKjSpCFplJxnDwaW77DCYctQ4Vu7Ai4H6lTxT
 4KPsPtUWbCUKaIw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SoC ID for Qualcomm Snapdragon SDA850.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Will be used by Comma three.
---
 include/dt-bindings/arm/qcom,ids.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/dt-bindings/arm/qcom,ids.h b/include/dt-bindings/arm/qcom,ids.h
index 1af73c0ad41cd..4b3062f57eecd 100644
--- a/include/dt-bindings/arm/qcom,ids.h
+++ b/include/dt-bindings/arm/qcom,ids.h
@@ -179,16 +179,17 @@
 #define QCOM_ID_SDM450			338
 #define QCOM_ID_SM8150			339
 #define QCOM_ID_SDA845			341
 #define QCOM_ID_IPQ8072			342
 #define QCOM_ID_IPQ8076			343
 #define QCOM_ID_IPQ8078			344
 #define QCOM_ID_SDM636			345
 #define QCOM_ID_SDA636			346
+#define QCOM_ID_SDA850			348
 #define QCOM_ID_SDM632			349
 #define QCOM_ID_SDA632			350
 #define QCOM_ID_SDA450			351
 #define QCOM_ID_SDM439			353
 #define QCOM_ID_SDM429			354
 #define QCOM_ID_SM8250			356
 #define QCOM_ID_SA8155			362
 #define QCOM_ID_SDA439			363

---
base-commit: 948efecf22e49aa4bf55bb73ec79a0ddcfd38571
change-id: 20260623-sda850-6b5c1e44662c

Best regards,
-- 
David Heidelberg <david@ixit.cz>

