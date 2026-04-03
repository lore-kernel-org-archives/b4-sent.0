From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:36 +0200
Subject: [PATCH WIP v3 07/11] dt-bindings: input: touchscreen: st,stmfts:
 Introduce reset GPIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-7-5da768cfd201@ixit.cz>
References: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
In-Reply-To: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QQMAdMMa8inZgJe5N3QgZUxLL3HOo56OBBV
 XKlIO3YWsiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0EAAKCRBgAj/E00kg
 cg7TEAC3dCICaldvFwpJ1VhQ2F9/wtFtgSr6tcnU9h5ePpTcqk3blelW2AxD5fL6BY0hcVpQEgn
 zq3/mw0I3NfpVAcW2vXZ+x6Qxx0HtKM4ELLb6UPsUcXjw78ldYN9k/0kpljwWv2VYIEzBBtlcn9
 l1iYGkQp0CtnjfbvvBHrzaxvmDoC1cplh3FSzRVVujsHuF8ORmmedS58dQWI+ExwxsGwlYGSOCh
 UvruzaqrNWzvB/ap5xEQu75gTaQIYZTDa1bOJqXF0ff+ThmY9rLX7gT6R8dbbTACweYig+pxaD4
 wUTMvI0ZcJSNLq9/oi8WZLUZQf+5OoJN/+Ja8sYAWdEsxzENW/H/UbxAtqPv6Zz3fpu7BF8hAle
 sT18KpLuSlHJeQhY1HfDX16SAF/mz4qWqJ5F5Ek/bynAIIumhsztLdBbtgO7BbHmM6pZgAKPw+b
 jTDDG4E2UyXR/uOxRzMOcOr36/tFR/fEjRPkTgGG4WWq/8YmzvvLfKO7jMyoSiYZRS2VLAC9Jyt
 fUIyWmyDNXtV6qrkqtBfy77RubF+suBnVzxKzL4u3wrc9A4QWZkU7c6jaroY+dWE7mIkGpMPDUW
 +TyIggaw8QNegCIaKgyswUoTP//mwWMxNii9dqcAMhIamKx+pjghlnWQLh0pHCy8io+jiJ44KCW
 AY8mUjTNBEZLkbg==
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

