From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH 0/4] Add support for Loongson-1 AC97
Date: Wed, 15 Jan 2025 19:03:06 +0800
Message-Id: <20250115-loongson1-ac97-v1-0-2087b04dcd7f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOqVh2cC/x3MTQqAIBBA4avIrBP8QcquEi1EJxsIDYUIxLsnL
 b/Few0qFsIKK2tQ8KFKOQ3IiYE/XYrIKQyDEsoIKQ2/ck6x5iS583bmerHBIXpjUMOI7oIHvf9
 w23v/AOFwKkJgAAAA
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-mips@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736938989; l=1104;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=TgflvuICDFK30ml2cKH2ZgYrUsJrKdWN1Z5vaApfIV0=;
 b=RZzN0p9wcJQWMe0rv9jn9Qwuk75gGeQtNyKTe5foyOakzYVylCb9ycE4PdnoPNYaY90YfzF8l
 k3KR20EVLrKBYHH6ukvdDdfIH6d9UutWHAhGvCu7PQYv2bdX3y5uMet
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the driver and dt-binding document for Loongson-1 AC97.
Add the dt-binding document for Realtek ALC203 Codec.
Add DT support for the AC97 generic codec driver.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Keguang Zhang (4):
      ASoC: dt-bindings: Add Loongson-1 AC97 Controller
      ASoC: dt-bindings: Add Realtek ALC203 Codec
      ASoC: loongson: Add Loongson-1 AC97 Driver
      ASoC: ac97: Add DT support

 .../bindings/sound/loongson,ls1b-ac97.yaml         |  68 ++++
 .../devicetree/bindings/sound/realtek,alc203.yaml  |  33 ++
 MAINTAINERS                                        |   1 +
 sound/soc/codecs/ac97.c                            |  10 +
 sound/soc/loongson/Kconfig                         |  10 +
 sound/soc/loongson/Makefile                        |   2 +
 sound/soc/loongson/loongson1_ac97.c                | 394 +++++++++++++++++++++
 7 files changed, 518 insertions(+)
---
base-commit: e7bb221a638962d487231ac45a6699fb9bb8f9fa
change-id: 20250115-loongson1-ac97-389daeec55e3

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

