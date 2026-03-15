From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 19:52:43 +0100
Subject: [PATCH WIP v2 07/11] dt-bindings: input: touchscreen: st,stmfts:
 Introduce reset GPIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-stmfts5-v2-7-70bc83ee9591@ixit.cz>
References: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
In-Reply-To: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptv/5Hr4nIhYBYqKW3kJsb59+rMkofVULsqvjf
 LU/5n/61pOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+QAKCRBgAj/E00kg
 ckS4EAC+Ji6pS/DWWfmBRQx00NgDnq8aSy4O9EO1aNKr9j6j4LGWZz0EV/y28xtEpYkh+19vigC
 gUa4/Uj8aTUL2sgZkqFdCxIh1Pb7UWz2W8p7Mwth1uya/z4Fv/yXmqYHNSyA9NHatV/+v7g8KdP
 6Kuftrph9RlYEDvTlzsKFIzWgnC2liyuTfgWXh6tVg3wOdw+XC9HfS3WZGknm3b6BeMd1D1Vee+
 tLToc3RcDqXjtWlEwOOHhy5N77rYg+eKp18TTQY+VqMYcBiIn4rjP3VsZvs+UHZkQ/k6yHKmiP8
 t/DR2EsM63FRh43Di+0d1zbIRt0MlVAp1o2JvaOwz0P7QV7n6zROLNXsHlV9pXUuNvw+1wSgXwG
 AEKYch9OrIUUFENKkugiH2xTcwIZ/ZIQDqrEeUL9MtUylwxHYKspRJUY8v6bfroQaH2SdxziB8n
 RP/Q4UK/EV4QyNZj1txoivWzdOleXtnz8X0TyfI9qZs0io12ske1tpKfbX5sUvpZi/0XX3JKdwr
 WsWn/qg1ksn7VVblBD4Z1uGbGZaHcdSvDhALmX8m/Y1JDtE+6wmki5owqzgzptKAyMFIS3fvVxJ
 Dw0b5X4lPkHJvvqNYXqaZCKUdRGAgv7k7BONEVfdrg7m+B0+k2+M7FFAozQfuxo4Yd9UlzYUI9c
 Ubbo/vB94zUL08A==
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

