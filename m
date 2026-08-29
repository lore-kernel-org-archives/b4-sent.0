From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 29 Aug 2026 14:35:32 -0500
Subject: [PATCH v3 2/4] dt-bindings: arm: qcom: Add Retroid Pocket QCS8550
 Devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-rp-qcs8550-v3-2-198d5b2fc475@gmail.com>
References: <20260829-rp-qcs8550-v3-0-198d5b2fc475@gmail.com>
In-Reply-To: <20260829-rp-qcs8550-v3-0-198d5b2fc475@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788032141; l=736;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=WxDgKnm+oG3VxyfqzoJMACArjvmJTRv82JY4e2Z0FgY=;
 b=uoSqbYV11lBtoFNaWI/Aar9LwUrUDPPZj5GqJi8lRh/sfvAAhcKt2Uf4IzJ+GDFG/GpzsIABL
 7e3DwUVkGvGBvJ4EJ7b/GNrHl8Th+1c7fIHhCWb41OHUUFoP6cBfz2w
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Namely:
* Nova
* RP6

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 954be28203017..25d24c36c5e00 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1158,6 +1158,8 @@ properties:
               - ayntec,odin2mini
               - ayntec,odin2portal
               - ayntec,thor
+              - retroidpocket,nova
+              - retroidpocket,rp6
           - const: qcom,qcs8550
           - const: qcom,sm8550
 

-- 
2.54.0

