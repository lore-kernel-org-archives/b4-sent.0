From: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
Date: Wed, 15 Oct 2025 13:27:18 +0530
Subject: [PATCH v3 4/5] dt-bindings: soundwire: qcom: Add SoundWire v2.2.0
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251015-knp-audio-v2-v3-4-e0e3e4167d87@oss.qualcomm.com>
References: <20251015-knp-audio-v2-v3-0-e0e3e4167d87@oss.qualcomm.com>
In-Reply-To: <20251015-knp-audio-v2-v3-0-e0e3e4167d87@oss.qualcomm.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rao Mandadapu <quic_srivasam@quicinc.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Jingyi Wang <jingyi.wang@oss.qualcomm.com>, 
 Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760515036; l=969;
 i=prasad.kumpatla@oss.qualcomm.com; s=20251014; h=from:subject:message-id;
 bh=egvs9Cb3aIkw8DtcZE34LZxwWmk9TpONHHIdUNRu10k=;
 b=ZFOm64BEIzqrw8kfN+ozmCkogJq+U/wGtKWimJnh1kIoRsByVYRX3zaCXBlb22ZDaKIcFKNcg
 ImM07Xd1VFZAT6yfnu7oEXKq0yll/KscGJ7dWMgftSYTQufWiTkGxbV
X-Developer-Key: i=prasad.kumpatla@oss.qualcomm.com; a=ed25519;
 pk=I3mn8JNlYnnm7frqMGXms1Rm2H+0gpAfknMlnBYqCzw=
X-Endpoint-Received: by B4 Relay for prasad.kumpatla@oss.qualcomm.com/20251014 with auth_id=541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add qcom,soundwire-v2.2.0 to the list of supported Qualcomm
SoundWire controller versions. This version falls back to
qcom,soundwire-v2.0.0 if not explicitly handled by the driver.

Signed-off-by: Jingyi Wang <jingyi.wang@oss.qualcomm.com>
Signed-off-by: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/soundwire/qcom,soundwire.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/soundwire/qcom,soundwire.yaml b/Documentation/devicetree/bindings/soundwire/qcom,soundwire.yaml
index 95d947fda6a7..1c4b0bdbb044 100644
--- a/Documentation/devicetree/bindings/soundwire/qcom,soundwire.yaml
+++ b/Documentation/devicetree/bindings/soundwire/qcom,soundwire.yaml
@@ -26,6 +26,7 @@ properties:
       - items:
           - enum:
               - qcom,soundwire-v2.1.0
+              - qcom,soundwire-v2.2.0
           - const: qcom,soundwire-v2.0.0
 
   reg:

-- 
2.34.1

