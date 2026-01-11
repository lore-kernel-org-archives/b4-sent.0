From: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
Subject: [PATCH 0/2] ASoC: codecs: aw88261: add dvdd-supply property
Date: Sun, 11 Jan 2026 15:40:29 +0530
Message-Id: <20260111-aw88261-dvdd-v1-0-83fa0850d561@machinesoul.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABZ3Y2kC/x3MQQqAIBBA0avIrBMcSZGuEi1Mp5qNhYIF0t2Tl
 m/xf4NCmanAJBpkqlz4TB04CAiHTztJjt2glbYKEaW/ndMWZawxSqPCiAENrl5BT65MGz//bl7
 e9wOaJ6zHXgAAAA==
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>
Cc: Bhushan Shah <bhushan.shah@machinesoul.in>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768126255; l=732;
 i=bharadwaj.raju@machinesoul.in; s=20260111; h=from:subject:message-id;
 bh=zV/ctewfiPYQ3WgFlicNsePqY0KYzA9iBBwBOFgllA0=;
 b=BlsJq7CwBNYETg1lA3PeqFyXeE9jGEu7zr0hww5nZDeDOXZQhXjwfXR3UaJ8wLUbnbouHWxgB
 HkhYLeKb8M7BoiBRmwiL5iITfLACHtVCtWtG1B2qnRY1q9ozCiJ2bXp
X-Developer-Key: i=bharadwaj.raju@machinesoul.in; a=ed25519;
 pk=0M1a+iMXDqasbx7bQL71NdtuutFXu+lVxsiSnEiyAIg=
X-Endpoint-Received: by B4 Relay for bharadwaj.raju@machinesoul.in/20260111 with auth_id=598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make the aw88261 driver depend on and enable the dvdd-supply regulator,
so that the correct regulator can be specified in the device tree.

Signed-off-by: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
---
Bharadwaj Raju (2):
      ASoC: codecs: aw88261: use dvdd-supply regulator
      ASoC: dt-bindings: document dvdd-supply property for awinic,aw88261

 Documentation/devicetree/bindings/sound/awinic,aw88395.yaml | 13 +++++++++++++
 sound/soc/codecs/aw88261.c                                  |  5 +++++
 2 files changed, 18 insertions(+)
---
base-commit: db1c30e19243982e34f027a2e564c93e94f42cb2
change-id: 20260111-aw88261-dvdd-50c41c151ba0

Best regards,
-- 
Bharadwaj Raju <bharadwaj.raju@machinesoul.in>

