From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH 0/7] media: i2c: dw9719: add DT compatible and DW9718S
 support
Date: Sun, 17 Aug 2025 19:09:19 +0200
Message-Id: <20250817-dw9719-v1-0-426f46c69a5a@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL8MomgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwNL3ZRyS3NDS12LRAsLI6PUtGTDJEMloOKCotS0zAqwQdGxtbUA3gN
 6gFgAAAA=
X-Change-ID: 20250709-dw9719-8a8822efc1b1
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Val Packett <val@packett.cool>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755450582; l=1698;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=swz7EduqrJXYn4m0DTsTWGz7NiPMJvLP6reejfaggDA=;
 b=Ju0qSZUBUEP3Chv/ygqg2puoFe5Q9Mu7/kvpDtNbyaoSpR+dMnKWyz4hMeUna57Fe2rhS4TwG
 cn01ixbWCCiAGToq1qSUbhczDpEinCYkrhfvRz1YNeRI/tMy71VU5ZO
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DW9718S voice coil motor is found on various smartphones like
motorola-nora that are currently being worked on in the postmarketOS
community. Since the way it operates is very similar to DW9719, this
patch series adds support for it to the existing dw9719 driver. Because
that driver did not yet support DT, we also add DT bindings and the
dongwoon,dw9719 ofw compatible. With DW9718S, the driver was
tested fully, including runtime PM.

This is a follow-up of [1] and [2].

Changes compared to previous submission:
* Deprecate dongwoon,vcm-freq in favor of dongwoon,vcm-prescale
* Instead of per-device config struct use model ID to handle cases

[1] https://lore.kernel.org/linux-media/20250210082035.8670-1-val@packett.cool/
[2] https://lore.kernel.org/linux-media/20250209-dw9761dts-v3-0-14d3f00f0585@apitzsch.eu/

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
André Apitzsch (2):
      dt-bindings: media: i2c: Add DW9718S, DW9719 and DW9761 VCM
      media: i2c: dw9719: Deprecate dongwoon,vcm-freq

Val Packett (5):
      media: i2c: dw9719: Add driver_data matching
      media: i2c: dw9719: Add DW9718S support
      media: i2c: dw9719: Update PM last busy time upon close
      media: i2c: dw9719: Add an of_match_table
      media: i2c: dw9719: Fix power on/off sequence

 .../bindings/media/i2c/dongwoon,dw9719.yaml        | 115 +++++++++++++++++++++
 drivers/media/i2c/dw9719.c                         | 111 +++++++++++++++++---
 2 files changed, 209 insertions(+), 17 deletions(-)
---
base-commit: 1357b2649c026b51353c84ddd32bc963e8999603
change-id: 20250709-dw9719-8a8822efc1b1

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

