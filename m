From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 18:51:20 +0100
Subject: [PATCH 06/10] dt-bindings: input: touchscreen: st,stmfts:
 Introduce reset GPIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-stmfts5-v1-6-22c458b9ac68@ixit.cz>
References: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
In-Reply-To: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=779; i=david@ixit.cz;
 h=from:subject:message-id; bh=uZFVfrrOjw9/Zf+PjQe4vJuLBGGgUOJaBtRtnZBDj/E=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppHyVjFgb3i+M6jMlXlM5TIrAbsCQX8E1F3tW4
 LGiF70vpT+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaR8lQAKCRBgAj/E00kg
 cgHiD/0X/wHMPyxoaYtkjW4WcPvXUC08KdGlHTZKNyGoRqvDGSy8aiu2vev+LCPIk+LHsTW/Nri
 OO3T8Az2mcmKmZxF9MoBaLKMOU90J8WpI5zSt8tcb7x2BfoIhHD3ovLKWuXU5KDoTFwujc04tHs
 z7ky5WmzaSZVaBvZ5JyGtD1qqYkVeL8QrnlgeY96B98DsymS5UBCPyql8vYlfI1hndGzI+83wwP
 VTbJaqb5gNbkvdieepGW8ic3cBCrjjaBj8MzX0MwtyAX79Oq2ZwjQ/0OPZ0zSzO6eRktELfF7ay
 7AbX+lXzJ5cBsoGO6laAuOJVP5tz2vC0FyRC3vw69byINXZ8sMQ7FFhRGYefrYxoJOh1PDd6+KA
 Q+ijRhnrlg1G6BVpDPxthLSlQ1nzIyy6U4EzAODMMPZq77zeF5Zb2faqB/3wVilA1nQf0NdyGhn
 fpsx3Hftb9aHn+E4HCj4W1G9oVdAf/1tkHKF6DOvy6CXtfhiBGBFbbV5BFyNEy1mbsiElGuRf1d
 Q/WRSlwQ3rk97JWFdR+Nd4GgRhouRMzK+zCtFBdQ5HuX9sQGUVY7R9NM9XrdBR3ktQrddgLFM6O
 CNZUSAvtZAXsKPugwymImVkyTTQZdjW/d6ck7x+j6KP/E3EqNWT1tQiD+3HKkDqsYXm+TwkHSco
 uhZ4cQlRs8Ssvkg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FTS may have associated reset GPIO, document it.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
index 12256ae7df90d..64c4f24ea3dd0 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
@@ -40,6 +40,10 @@ properties:
   vdd-supply:
     description: Power supply
 
+  reset-gpios:
+    description: Reset GPIO (active-low)
+    maxItems: 1
+
 required:
   - compatible
   - reg

-- 
2.51.0

