From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:50 +0200
Subject: [PATCH v4 07/11] dt-bindings: input: touchscreen: st,stmfts:
 Introduce reset GPIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-7-64fe62027db5@ixit.cz>
References: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
In-Reply-To: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=774; i=david@ixit.cz;
 h=from:subject:message-id; bh=B9kCQKy2FHl0reom6sgNtirncPHLOm+2NoyBOxtDRYc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tOSJUHdlj3O0LPhM1jaiJv/ALPX+SD6InEhO
 o/IffCvj2GJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkgAKCRBgAj/E00kg
 csyXD/9/mTo3zD8m6fYZQtO0bvVO2xJ+E9/paboBT2bTq30RkJAtPxJMH+l5LwJAAMOz+RlfBDs
 a9GEsQj0fEeU33q4F7tDgH2l1jX7wvOzes41WGBRRTThMvbrpq5/UfNcqGtoHrLG5pQQ85keYID
 YtbgeV1EyDkV6h6oGWHNduo2e7IOsX8PMjXcgkWGniJTjeuMM/t1VlBsb02WDj5vCnnBnzLJzWk
 Q2YO4Jr024nHqEQ8OeRXu4RZrrbGLyzHvMK+6Zaz06VndUFlKelFCb0H2nxBJr38simrrDsn+AZ
 TduQwSLEtpXvnGmLr35o112ZfG45NyHteCGGvmrVnEfWdOJZk+3J8DTnJaaYMWhAiU37NfflkhR
 Bdbwxt2jwx0twBZ15uVW9C8tDJM39mDXiEEWjXOB+31qJ5LJ9bRSI5dEaPalnfk+qJvAiojLPQa
 rQJkoysMbAyJqiYgJaOkFoHG6K3eFSkla9+K1DC+JQSkQnqGl20Xc9CgPFJbioU8lNfm2nFsmYO
 RTLoXFzxS9S83/AYR22zQI1GjnTsqslGGVzzSv0Ybe4MMOFIKkqZMcR6HpkFQv4TuGbE8jAt01/
 HKdGaSAZrw8vEyoMRqcSW2wQyt9k2Lnyn+F+fvFGV6Rn+cHhfGmng6sbgVbXrUsyG7/oAOYLOd2
 AatmeUfB27sCQyg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FTS has associated reset GPIO, document it.

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
2.53.0

