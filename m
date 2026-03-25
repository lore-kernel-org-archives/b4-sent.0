From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Mar 2026 17:41:12 +0100
Subject: [PATCH v3 1/3] dt-bindings: wireless: ath10k: Introduce quirk to
 skip host cap QMI requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-skip-host-cam-qmi-req-v3-1-b163cf7b3c81@ixit.cz>
References: <20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz>
In-Reply-To: <20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1103; i=david@ixit.cz;
 h=from:subject:message-id; bh=MEOt3SMdJE/GBpWMQAq3qov+9BM1LX4l8sFyx0gK28g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxBAs06VVgNasyU9OMzOcVIK8wXTqTwoy05ExR
 Gxby/HcVj6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacQQLAAKCRBgAj/E00kg
 ckctEADPstXjr6+tPWWuzprLUqZj21UqGEPg57hKPIIiXgIkmkBvohi73ttOJrZwJHx8SsrQvx7
 yS35aDxoS7m5tllrMzJDes06wKJeB0oXUEp3KjcPEj+mGsUz5eSHKaz2sSKe3u90lv3hhMXFZCz
 NS1lez41OuhhNaXF6zxumA0gD4NBXkpChoSTdrjgcP3qcAcP0BGPhZ+d1yRJReT7Ji9+iTOI/X4
 BIQrdHeyjPAohizWMt9Xvhz5FM715UJttf4iE0mnnzF49c6RlVfSb1s+fBocsZ3kMoJtdkHbJS0
 OhX+94KINFkstZtkeSf9Wb+kleF9WmTRJOltvPkAIWjud3IvADff46T23ic+oTFgdbHCLfld3tr
 iVUNq2TQit5eBoTulrxrX8xHPJV+y4/BbW7tfvqy25sKvPejhSWU8n6jQpZp+/dk7un87RDOoPJ
 564yVBNl9Rl9kUOAJZvxkK09h8qgEyzssyyTBq2K2TKWzh6QVbvrrFnTURt6/jS5MZEjV0h00Zo
 53myBSjacOHAoZZ4l3yyueTYgFBJxqeHJQWc4+0PubmpnpWWJoJCV3tIgegXRWGeMd2HIwc2ROp
 vtHGred+Lc+cggPZZ1mvljb2nsAkEdobLrXx18FdusFi7djz4rq6RCTLXjT1zlyovTc75cbhpZx
 wZbOErO56Q9FKiQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

Introducing this quirk to skip host capability QMI request for the firmware
versions which do not support this feature.

Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml b/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml
index f2440d39b7ebc..5120b3589ab57 100644
--- a/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml
@@ -171,6 +171,12 @@ properties:
       Quirk specifying that the firmware expects the 8bit version
       of the host capability QMI request
 
+  qcom,snoc-host-cap-skip-quirk:
+    type: boolean
+    description:
+      Quirk specifying that the firmware wants to skip the host
+      capability QMI request
+
   qcom,xo-cal-data:
     $ref: /schemas/types.yaml#/definitions/uint32
     description:

-- 
2.53.0

