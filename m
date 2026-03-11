From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 10 Mar 2026 23:43:04 -0500
Subject: [PATCH 1/2] ASoC: dt-bindings: Document firmware-name for
 awinic,aw88166
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-aw88166-fw-v1-1-2777563bb673@gmail.com>
References: <20260310-aw88166-fw-v1-0-2777563bb673@gmail.com>
In-Reply-To: <20260310-aw88166-fw-v1-0-2777563bb673@gmail.com>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773204187; l=931;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=5MENRQH/Gn9FHW4tDRmUH1zYG53L9x/XxcifmwYU0Pw=;
 b=s3LgnJhJbb3oEy7LhdVGErl79GN/ajbCEOc6yqX52Lzy4pOGM9j7/dyeNFgbBt75fXJNKvlB0
 0xhxbxGy9mZCc/2e4ET/ocD67saePKBP6s4Ond/6mKxN0gmDnZLdHXH
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver currently loads a hardcoded firmware. Allow devices to
provide specifically tuned firmware, so the driver can use that instead.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/sound/awinic,aw88395.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml b/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml
index 994d68c074a9f221576a5bfef6ba125e3e30bfea..e12d030475e24dd11afaa3c9af4b53703f25f981 100644
--- a/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml
+++ b/Documentation/devicetree/bindings/sound/awinic,aw88395.yaml
@@ -48,6 +48,9 @@ properties:
       Flag bit used to keep the phase synchronized in the case of multiple PA
     $ref: /schemas/types.yaml#/definitions/flag
 
+  firmware-name:
+    maxItems: 1
+
 required:
   - compatible
   - reg

-- 
2.53.0

