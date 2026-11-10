From: Jiebing Chen <jiebing.chen@amlogic.com>
Date: Tue, 10 Nov 2026 10:28:25 +0800
Subject: [PATCH v8 2/5] dt-bindings: Asoc: axg-audio: Add S4 audio tocodec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-audio_drvier-v8-2-1489241e4c83@amlogic.com>
References: <20261110-audio_drvier-v8-0-1489241e4c83@amlogic.com>
In-Reply-To: <20261110-audio_drvier-v8-0-1489241e4c83@amlogic.com>
To: Jerome Brunet <jbrunet@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 jian.xu@amlogic.com, shuai.li@amlogic.com, zhe.wang@amlogic.com, 
 jiebing chen <jiebing.chen@amlogic.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794277720; l=851;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=DMgqU4dy+C9otoBnz7xzg+U2RUB122T3zVnjUiL76gQ=;
 b=6BQpXVkZnsnNKIesQNk5sWSYdBPvE4chX1wqGNXC/6aZi1VS4vlh+/fkXxe8bpTFUBhCNLdjo
 GWyvxOJOZxrBIdhDKK21mqV4ENPhzDR8XlYZzv81+/Mz7VQ8r6x9o7m
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add S4 SoC tocodec compatibility support.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Jiebing Chen <jiebing.chen@amlogic.com>
---
 Documentation/devicetree/bindings/sound/amlogic,g12a-toacodec.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/sound/amlogic,g12a-toacodec.yaml b/Documentation/devicetree/bindings/sound/amlogic,g12a-toacodec.yaml
index 23f82bb89750..7e053aaa0f59 100644
--- a/Documentation/devicetree/bindings/sound/amlogic,g12a-toacodec.yaml
+++ b/Documentation/devicetree/bindings/sound/amlogic,g12a-toacodec.yaml
@@ -25,6 +25,7 @@ properties:
           - const: amlogic,g12a-toacodec
       - items:
           - enum:
+              - amlogic,s4-toacodec
               - amlogic,sm1-toacodec
           - const: amlogic,g12a-toacodec
 

-- 
2.52.0

