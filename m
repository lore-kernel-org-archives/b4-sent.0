From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:28 +0530
Subject: [PATCH 1/2] ASoC: dt-bindings: qcom,sm8250: Add Motorola Signature
 sound card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vantage-sndcard-v1-1-df69a8759833@yahoo.com>
References: <20261116-vantage-sndcard-v1-0-df69a8759833@yahoo.com>
In-Reply-To: <20261116-vantage-sndcard-v1-0-df69a8759833@yahoo.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774027; l=954;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=nX9qTnZEW1eY4ue+aHl0y+aU2y03Je7/bL6nIWQuIPg=;
 b=krJygh5DLJPWif5c4HWThx0qoWh3j05sndx4UrP985vfoE3qbBsy6BWta2MAtuJgpERLrjTJJ
 oSUITQ3rwU1CO59kTw7NP+J9q7JFDFCsRYSxB6TYLKlTwS3frPSLzKF
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the sound card of the Motorola Signature (vantage) phone,
which has its speaker and earpiece amplifiers on an MI2S interface.

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 Documentation/devicetree/bindings/sound/qcom,sm8250.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml b/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
index e2e3fc99e6d9..7adf0f5ce2f7 100644
--- a/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
@@ -37,6 +37,7 @@ properties:
           - fairphone,fp4-sndcard
           - fairphone,fp5-sndcard
           - motorola,dubai-sndcard
+          - motorola,vantage-sndcard
           - qcom,apq8096-sndcard
           - qcom,glymur-sndcard
           - qcom,nord-sndcard

-- 
2.56.0

