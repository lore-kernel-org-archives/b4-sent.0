From: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
Subject: [PATCH v2 0/2] ASoC: codecs: aw88261: add dvdd-supply property
Date: Wed, 14 Jan 2026 16:03:23 +0530
Message-Id: <20260114-aw88261-dvdd-v2-0-ef485b82a7a7@machinesoul.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMQQ7CIBCF4as0sxYzg0KIK+9hukCgMolSA4qah
 ruL3bv8X/K+BUrIHAochgVyqFx4Tj3kZgAXbboEwb43SJQaiUjYlzFSk/DVe6HQ7cmRorNF6Jd
 7DhO/V+409o5cHnP+rHql3/oHqiRQmN1k0Sj0StPxZl3kFMr8vG45wdha+wJAH0KgrQAAAA==
X-Change-ID: 20260111-aw88261-dvdd-50c41c151ba0
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>
Cc: Bhushan Shah <bhushan.shah@machinesoul.in>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768386804; l=1091;
 i=bharadwaj.raju@machinesoul.in; s=20260111; h=from:subject:message-id;
 bh=EZvwB5xw50grkJYmYSe3ftlsXRapgsRBC0XIhXklg7s=;
 b=dctiuFwMwQeOuQtE+M4tVuEm8ZhDLG09fILkQ25KfKPtApWh78uS5cujBhwx+MZPCYE1LH/Fh
 Uu/V3Qm+9Q4DQeKeRQzzHD5Yu5djgvrF0PZRj3465embPdYDbKhJ87E
X-Developer-Key: i=bharadwaj.raju@machinesoul.in; a=ed25519;
 pk=0M1a+iMXDqasbx7bQL71NdtuutFXu+lVxsiSnEiyAIg=
X-Endpoint-Received: by B4 Relay for bharadwaj.raju@machinesoul.in/20260111 with auth_id=598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AW88261 has a DVDD chip which needs to be powered on for it to 
function correctly. The property for this was missing, so this patchset 
adds the dvdd-supply property which enables a regulator to be bound 
to it in a device tree.

Signed-off-by: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
---
Changes in v2:
- reorder so that the dt-bindings change is before the implementation
- describe the reasons for the new required property in the commit msg
- Link to v1: https://lore.kernel.org/r/20260111-aw88261-dvdd-v1-0-83fa0850d561@machinesoul.in

---
Bharadwaj Raju (2):
      ASoC: dt-bindings: document dvdd-supply property for awinic,aw88261
      ASoC: codecs: aw88261: use dvdd-supply regulator

 Documentation/devicetree/bindings/sound/awinic,aw88395.yaml | 13 +++++++++++++
 sound/soc/codecs/aw88261.c                                  |  5 +++++
 2 files changed, 18 insertions(+)
---
base-commit: db1c30e19243982e34f027a2e564c93e94f42cb2
change-id: 20260111-aw88261-dvdd-50c41c151ba0

Best regards,
-- 
Bharadwaj Raju <bharadwaj.raju@machinesoul.in>

