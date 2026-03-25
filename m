From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Mar 2026 18:57:15 +0100
Subject: [PATCH v4 1/3] dt-bindings: wireless: ath10k: Add quirk to skip
 host cap QMI requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-skip-host-cam-qmi-req-v4-1-bc08538487aa@ixit.cz>
References: <20260325-skip-host-cam-qmi-req-v4-0-bc08538487aa@ixit.cz>
In-Reply-To: <20260325-skip-host-cam-qmi-req-v4-0-bc08538487aa@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1221; i=david@ixit.cz;
 h=from:subject:message-id; bh=/8qUsNDjZq5nMAWqSvN26r6+nO/+y9uNfhTrBdSgls4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxCH7tYvhKdRWxn37UiaCzxwuvwqrhsSG9sPeT
 +oOYgR7E4eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacQh+wAKCRBgAj/E00kg
 clTkD/48f15KKMy94GM3zg0pd84HcSO316PCHR8euVg4gAPZk054dbEOMbqZUENK/r+w3QQfzpw
 UE/5YYuWDHOmKGRzT301wJROqaHJE5iGlyvSNug/gAxIZwFzQjvtjtExvAnLe4bJoDqNxhctSD0
 ZhP3P0pQruy89bVhnkeXsSua8rzcdMSJfe/XKvWnFN60hXPhNVGV+blfMjWzxhfj2gHl6SCk1yt
 BBarcaVJzWOMeRPf9Bw8Ou6f8EHTZhowwLS5Mj0E5ExVyPsB+m9/WuOnrT5LEo0n6HTdgyd5h8e
 clddgb8GG7qVOqzFX4gJQ49Lyv1kLp7PZTre03ahAycNa7HeVfeB/SE1fNcj44MGXVWEAj9sXlW
 8ZKcbtib3lrK6dklP4zDEOyRaZ72imPMUryvsIvFG3jgps+EssvFIHKllLtliGwxh/IBgt9i3re
 GySSyAFpr/Y8hGpJPl3LdboTLuT7ltA/pLjtoT7gTJEE38QWN7LnFj8GCneZk7QRiz5Je9tsJ2K
 8gK8mf76hf22wnYZduMQvd+bzUghBlhveJHt7dFVizuowDz1tTOtyHMOAKBFNUfo/XLmsB6IdUe
 hF7RgnlzodNclnWz7vUKfxcqPngwmYaSbveSNKoYV/Vgr/++LDcM24UuxVA3JUqSBUBJqy+7bMu
 PUey1Vy5r/dvpkw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

Some firmware versions do not support the host-capability QMI request.
Since this request occurs before firmware and board files are loaded,
the quirk cannot be expressed in the firmware itself and must be described
in the device tree.

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

