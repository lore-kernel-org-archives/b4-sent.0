From: David Heidelberg <david@ixit.cz>
Date: Sun, 09 Aug 2026 18:48:54 +0200
Subject: [PATCH 1/2] dt-bindings: arm: qcom: Add Xiaomi Mi 8 family
 compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260809-dipper-v1-1-eb4d501e85df@ixit.cz>
References: <20260809-dipper-v1-0-eb4d501e85df@ixit.cz>
In-Reply-To: <20260809-dipper-v1-0-eb4d501e85df@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1821; i=david@ixit.cz;
 h=from:subject:message-id; bh=/Ll77Db7EYel11IohG9BeTICteMQOe9RQFJs36K0wIc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqeK95dVXr0NeM4PpqgrRa1D0bkG3N3FuxCP1Qj
 rq43LOwXKGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaniveQAKCRBgAj/E00kg
 ctXKD/wKNo+UCUc1oocYQcm1iyAy8EPbWC1bzIcUlTXXm30JJawwiyUFimqvZzSZtOthmnTdShj
 909X9AFwvRAhzmsJDj8UaG2A6ZIO6Ti223jt49DKPdmBo9yP9jNApYDiomJ+kxMOzsmqFI77R8d
 MnftaSk+9Y8wuj8X288zf2nxPMnI9M8RR7Bo/FV+08bYe8d4g36EC8LiNYy+sASr4Cgqtth4Mzi
 xxtAy+fD/aJEibQyMMlt3zzVfM1vKWmDovPubBpxcJvOPzZlbEkSl6+7RCkv2tvMAWLqA+cCrKK
 jGrc2nCdqsLIphRaCdzFgbmUCiO+K0MufP4+45ESC/f0mXOiTr8RgZu6MdWaxqYt0o9odaDQud+
 V7J2iwltYhLA2aThAF7hkdFqO9JTmW10xVpNfWRdmfJwVpkv7aJd7H+sQl7E3frxSBWfZunxKbE
 sBRHrXBdMgKvlqMva1PzkvFySkIXw9vK5ucHwF8KYBm0HMEPXqa52XSvzu0YB4NmKA0Nospt8rI
 iYmGonGJcIKu6R/yUVB3UMZ+aDfxyYXEZA27dIMLLlI/FYyZ+Wx58YZHU0reRdyl1BGzjzTPZw0
 lkKENcI7JouLcYhOXGYeyG5abfA9g8Cs9UbBv+4qqtn/C4Vy9EB/wmR9YsAiXzSt14l1pL+f6x4
 VkebCEm1DBxz4YQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This smartphone codenamed dipper is now supported by this series,
variants such as ursa and equuleus just documented.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index c7c9a92796846..5a43d480fd999 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -944,16 +944,25 @@ properties:
           - const: qcom,sdm670
 
       - items:
           - enum:
               - google,bonito-tianma
           - const: google,bonito
           - const: qcom,sdm670
 
+      - description: Xiaomi Mi 8 family
+        items:
+          - enum:
+              - xiaomi,dipper
+              - xiaomi,equuleus
+              - xiaomi,ursa
+          - const: xiaomi,dipper-common
+          - const: qcom,sdm845
+
       - description: Xiaomi Poco F1
         items:
           - enum:
               - xiaomi,beryllium-ebbg
               - xiaomi,beryllium-tianma
           - const: xiaomi,beryllium
           - const: qcom,sdm845
 
@@ -970,16 +979,17 @@ properties:
               - qcom,sdm845-mtp
               - shift,axolotl
               - samsung,starqltechn
               - samsung,w737
               - sony,akari-row
               - sony,akatsuki-row
               - sony,apollo-row
               - thundercomm,db845c
+              - xiaomi,dipper
               - xiaomi,polaris
           - const: qcom,sdm845
 
       - items:
           - enum:
               - qcom,shikra-cqm-evk
           - const: qcom,shikra-cqm-som
           - const: qcom,shikra

-- 
2.55.0

