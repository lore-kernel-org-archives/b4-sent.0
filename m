From: Esteban Urrutia <esteuwu@proton.me>
Date: Wed, 29 Jul 2026 15:31:54 -0400
Subject: [PATCH 1/2] ASoC: dt-bindings: qcom,sm8250: Add compatible string
 for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-sm8475-asoc-v1-1-3edad8aa7628@proton.me>
References: <20260729-sm8475-asoc-v1-0-3edad8aa7628@proton.me>
In-Reply-To: <20260729-sm8475-asoc-v1-0-3edad8aa7628@proton.me>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785353516; l=837;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=9EIfnewBFvPepUyMsmU4lM3BbcorxKblP5HJ2b6wAfs=;
 b=i2Crzn9HnZ7Bg6O1T+D0aJcZzOafCjVocxob+FSMQs7j7b4X9IuyP/EighMhKC2F1ZBP+JQfU
 gDw9t7AmrQ8BqUlEFUx+vgq0Sz2amcho64BbpKOidBQboi2UHDZwU9E
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string for the sound card found in the SM8475 SoC.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 Documentation/devicetree/bindings/sound/qcom,sm8250.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml b/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
index bd5f5a6268a3..d12ac528c33f 100644
--- a/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
@@ -26,6 +26,7 @@ properties:
               - qcom,eliza-sndcard
               - qcom,hawi-sndcard
               - qcom,kaanapali-sndcard
+              - qcom,sm8475-sndcard
               - qcom,sm8550-sndcard
               - qcom,sm8650-sndcard
               - qcom,sm8750-sndcard

-- 
2.55.0

