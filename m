From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Apr 2026 12:54:55 +0200
Subject: [PATCH v2 1/2] dt-bindings: arm: qcom: Document Xiaomi Poco F1
 Tianma variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260405-beryllium-compat-string-v2-1-91149be07835@ixit.cz>
References: <20260405-beryllium-compat-string-v2-0-91149be07835@ixit.cz>
In-Reply-To: <20260405-beryllium-compat-string-v2-0-91149be07835@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, 
 Jens Reidel <adrian@travitia.xyz>, Arnaud Ferraris <aferraris@debian.org>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Petr Hodina <petr.hodina@protonmail.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1912; i=david@ixit.cz;
 h=from:subject:message-id; bh=3okoeHHsLKYkc9npC24SfpxwXKr1llfhyo8vc91adjk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp0j9/J+BdQUFAeWoPoVuMTDi5PhyzqApcMWxdd
 PtYGm792pKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadI/fwAKCRBgAj/E00kg
 chgRD/9Wv8KpzXdWLygz7fFRVQKLarIowcySGNeUuzMgHB9qZnaJY+3gs5qZ9HzuUbGa0Ex3GK6
 sadTr0xdWzeqsdTtRHA1jQHBB7VNjrV0ubZoprphQ4uANE07R/fPSQzW3+HOng8bhlKtJIsTVpA
 EBi+HAqICw5d96W806Kb1bhRq2dFcV/8pQJLsRPU7NLuupbH0V5Qg4BJB3G0vVSHk0wuIOG/ZYg
 xvrS3m4KaFe1iMVI77taMa+BewNriqAsoppZFmGcT3fOcmRfIGyMswz1COho1DB18sIZH7pXWQR
 OCrdnr2QJLv0S9Ck4DkikkKAJb5229ITH4LaOoIZPRZiIc6ebTsgLGqkLbP4rrmbW/pgrtYJvWx
 ofBcBvJNntREklIufXCcSB8Uf0YB0j25+4dXM+U6uy3huXBkQZi1KfbKtxZkay6+slNwf2l/oWd
 8dxt1w3xQgOUMqFbTCzoCDnQRKzCp3IdgHylV1CwiPYqp9vaXvfOv41K0/w9exdRIdji7eMliMx
 7NgYt3gk6xMF8rb3LfKm3nK9MnR7HiFrkRJ3IvztGvQVOmi4wCE5Mhc569AEqfrdhOScPgF2sdz
 vfnXQxhvf7kOAh4NzBpgD5UBMSWPjjbRq1viTWAtdtA43OuwAcZ5yOI6k4V93QiaHqgJDj/ms9D
 EFF72lg9RTcZkpw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the panel-specific compatible string for the Tianma variant
of the Xiaomi Poco F1:

  - "xiaomi,beryllium-tianma"

and require the generic fallback compatible:

  - "xiaomi,beryllium"

Update the binding to clarify that all panel variants must list the
variant-specific compatible first, followed by the generic device
compatible, in accordance with DT matching rules.

The previous binding documentation did not describe the Tianma variant
and did not clearly specify the required fallback compatible, which
resulted in inconsistent DTS implementations.

No functional differences are currently exposed between Tianma and EBBG
variants at the binding level; both rely on the same generic device
compatibility for software support.

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

