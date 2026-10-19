From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Tue, 20 Oct 2026 00:42:09 +0200
Subject: [PATCH v3 1/2] dt-bindings: arm: qcom: Add Samsung Galaxy Tab S9
 Wi-Fi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-gts9wifi-dts-v3-1-afd06fb2d9f9@dxdmail.cc>
References: <20261020-gts9wifi-dts-v3-0-afd06fb2d9f9@dxdmail.cc>
In-Reply-To: <20261020-gts9wifi-dts-v3-0-afd06fb2d9f9@dxdmail.cc>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792449747; l=868;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=sR0cnCpdpiTlMKTOwU1tkGMcO6qB707MJF9oZ3BW5c0=;
 b=ipjhObC3/ajONJXHIUQWos0btqPdA9Sa/3KwuzgZyp9CAbMZ0/a3euAs4NfEFulO5MGav2zOx
 XDJ71oqwV6HCISDKtq1RTziwfgeObvNLFzVeMQmCUgpnq9SwVZbqBPM
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Samsung Galaxy Tab S9 Wi-Fi (SM-X710), a tablet based on
the SM8550 SoC.

Assisted-by: LLM
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 121ca557ce1e..5e560f523d32 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1173,6 +1173,7 @@ properties:
               - qcom,sm8550-hdk
               - qcom,sm8550-mtp
               - qcom,sm8550-qrd
+              - samsung,gts9wifi
               - samsung,q5q
               - sony,pdx234
           - const: qcom,sm8550

-- 
2.56.0

