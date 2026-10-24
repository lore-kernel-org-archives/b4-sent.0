From: Ishu Brar <patches@brar.si>
Date: Sat, 24 Oct 2026 09:24:27 +0530
Subject: [PATCH v2] dt-bindings: remoteproc: qcom,sm6350-pas: Document
 SM7250 ADSP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-adsp-sm7250-v2-1-ef278af8da5d@brar.si>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNQQ6CMBBFr0JmbU1boQgr72FYlHaQMRFIBxsN6
 d0FjAuXL3n//QUYAyFDnS0QMBLTOKygDxm43g43FORXBi21UVIVwnqeBD9KXUjhbXH2rcK8tAb
 WxRSwo9deuzZf5md7Rzdvic3oiecxvPe7qDbvVzZ/5aiEFLo7VdapTuaVubTBhiMTNCmlD5D63
 pq2AAAA
X-Change-ID: 20261015-adsp-sm7250-da58db1e47a6
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792814067; l=2822;
 i=patches@brar.si; h=from:subject:message-id;
 bh=GuEwrEMO43vHoIW4u6rPZvhBWRNxjETv3/Mw/VJkhR0=;
 b=J7g9bjVXCQ3xsqu578Sr23l8hEGB4wJwwCBDJA67wIAE2OmsJXWkrHEUPDJI+Zw12rKF2fiSw
 mxueE191jyrBjetKy9Gw9nQ/1xDd6DxU6GNOstir7OGw8EsICRdVC6b
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the ADSP Peripheral Authentication Service on the Qualcomm
SM7250 SoC. It has the same interrupts and LCX/LMX power domains as the
SM6350 ADSP, so use the SM6350 compatible as a fallback.

Signed-off-by: Ishu Brar <patches@brar.si>
---
Document the ADSP remoteproc of the Qualcomm SM7250 SoC (Snapdragon
765/765G/768G) in the SM6350 PAS binding, with qcom,sm6350-adsp-pas as
fallback. The SM7250 ADSP behaves like the SM6350 one: same PAS ID, same
interrupts, same LCX/LMX power domains, same SMEM crash reason item. So the
driver needs no change.

I am bringing up mainline on a OnePlus Nord (SM7250, "avicii"). With
this binding the ADSP boots on that phone and I can play audio through it
and read the sensors from it.

The SoC devicetree is not part of this series; it is being sent
separately.
---
Changes in v2:
- Use qcom,sm6350-adsp-pas as fallback compatible and drop the driver patch
  (Krzysztof)
- Match the fallback with contains in the allOf conditions
- Drop Reviewed-by from the binding patch, since the binding changed
- Link to v1: https://patch.msgid.link/20261016-adsp-sm7250-v1-0-2f39ac1f0496@brar.si
---
 .../bindings/remoteproc/qcom,sm6350-pas.yaml       | 23 +++++++++++++---------
 1 file changed, 14 insertions(+), 9 deletions(-)

diff --git a/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml b/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml
index 42e02c643..8387471d6 100644
--- a/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml
+++ b/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml
@@ -15,10 +15,14 @@ description:
 
 properties:
   compatible:
-    enum:
-      - qcom,sm6350-adsp-pas
-      - qcom,sm6350-cdsp-pas
-      - qcom,sm6350-mpss-pas
+    oneOf:
+      - enum:
+          - qcom,sm6350-adsp-pas
+          - qcom,sm6350-cdsp-pas
+          - qcom,sm6350-mpss-pas
+      - items:
+          - const: qcom,sm7250-adsp-pas
+          - const: qcom,sm6350-adsp-pas
 
   reg:
     maxItems: 1
@@ -83,9 +87,10 @@ allOf:
   - if:
       properties:
         compatible:
-          enum:
-            - qcom,sm6350-adsp-pas
-            - qcom,sm6350-cdsp-pas
+          contains:
+            enum:
+              - qcom,sm6350-adsp-pas
+              - qcom,sm6350-cdsp-pas
     then:
       properties:
         interrupts:
@@ -102,8 +107,8 @@ allOf:
   - if:
       properties:
         compatible:
-          enum:
-            - qcom,sm6350-adsp-pas
+          contains:
+            const: qcom,sm6350-adsp-pas
     then:
       properties:
         power-domains:

---
base-commit: 23d0516587f896f5f16a47c97ddb41d28e6289ff
change-id: 20261015-adsp-sm7250-da58db1e47a6

Best regards,
--  
Ishu Brar <patches@brar.si>

