From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 18:55:33 +0200
Subject: [PATCH 1/2] dt-bindings: arm: qcom: Add Xiaomi Poco F1 Tianma
 variant bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-beryllium-compat-string-v1-1-0a6b9cb55a20@ixit.cz>
References: <20260403-beryllium-compat-string-v1-0-0a6b9cb55a20@ixit.cz>
In-Reply-To: <20260403-beryllium-compat-string-v1-0-0a6b9cb55a20@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, 
 Jens Reidel <adrian@travitia.xyz>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1363; i=david@ixit.cz;
 h=from:subject:message-id; bh=AtgDPB6o9zOT8gmNuMq9hNsNDcrlPLcnjmej/ulGt/g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/EF/XHbZnknU2q9GYZE1b1+B+HQBIPS+BMAu
 FLyyc4yKkGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/xBQAKCRBgAj/E00kg
 cpeXD/9qfPaIKGyIFatNhQlvAxgq67x4QBtje0FIAW5zaF01DPyD5SluUuqyWDU5Qspv8UHOo16
 PmY/sqzltuBcMOQaLjkEKVjk9LfNWX28m2iovXJ9VSI8hL51qd3Ev7560Fu3SsvzTuVvcA2AQoG
 Cy+CKynm1+DvV83vCH98hz+OdiunZSkWbGpwO4BlHiHcJ6UDrHSX6ta8xRk5gBUNoteEloyIQxY
 P7A1Q87DrddWwey8vAwhYRV6tsuUEndBP39PPWf8PpdgCeknsnsKgzCeVfDcaLuD329IxdlYH6P
 WvFZTb7PMYToorhgO3nFLyAMMpGJ8JixLvUjUu6neK1BMQ/aPVm20ilIz0jrLNRsWTY9opqgRGG
 iXFruwNk1CnPSgP2HVX0ELW4Bd76yPZM6vyavs2RA5H8eVIKZiqcuSR7z730/9onybBcHn4C6qJ
 U6djopaSjBDLfr4xCRVMWwlIN4JKNigdMRDQRWFSit/wTyShu0hiKxsq+h0y4kyYiNDqILi/SeG
 kliRhWNYYoKG/anJTTujHZYZqVHjKQ8dnHb4flSUWFnnHI9jTrpDE1LfivszT5URklTJ7RpEHEE
 cN5F42Pe1H5psJB+IHJeXOx6lvRdTpxIteGxSzGqJWZgJqbQf31+A5fN00W3Lj/rDiW5fglUnbb
 ymvjge6fXsnNbHw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for Tianma display and touchscreen variant.

While at it, correct binding documentation expectation.

Fixes: 341fdef8ea49 ("dt-bindings: arm: qcom: Add Xiaomi Poco F1 EBBG variant bindings")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 8c5fdd320cfcf..b412543f0afb8 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -822,6 +822,14 @@ properties:
           - const: google,zombie-sku514
           - const: qcom,sc7280
 
+      - description: Xiaomi Poco F1
+        items:
+          - enum:
+              - xiaomi,beryllium-ebbg
+              - xiaomi,beryllium-tianma
+          - const: xiaomi,beryllium
+          - const: qcom,sdm845
+
       - items:
           - enum:
               - lenovo,flex-5g
@@ -971,8 +979,6 @@ properties:
               - sony,akatsuki-row
               - sony,apollo-row
               - thundercomm,db845c
-              - xiaomi,beryllium
-              - xiaomi,beryllium-ebbg
               - xiaomi,polaris
           - const: qcom,sdm845
 

-- 
2.53.0

