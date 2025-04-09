From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v2 0/4] Add support for Loongson-1 AC97
Date: Wed, 09 Apr 2025 18:29:30 +0800
Message-Id: <20250409-loongson1-ac97-v2-0-65d5db96a046@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAApM9mcC/3XMQQ7CIBCF4as0sxYDVELrynuYLhCmdJIWDBiia
 bi72L3L/yXv2yFjIsxw7XZIWChTDC3kqQO7mOCRkWsNkkvFhVBsjTH4HINgxo6a9cPoDKJVCnt
 op2fCmd4HeJ9aL5RfMX0Ov4jf+pcqgnEm+aAf/OKs0/PNb4bWs40bTLXWL3nB5M6sAAAA
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-mips@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744194597; l=1358;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=wTO9XVahwzKLxaPS9+9HXlOMbiu+xAnQVIyTH2JqEdc=;
 b=DWbS+jO0h+JveVSR7kVCBar4uEFKji4nMkZQ8LrP60uOzZnWrsGlHTzVn9JbQJI7xcFuRHPnY
 LRoGsvkJKweBcUU5DwckahhyBroTWlBwmjn43xmY/zGtG/cpDa7YP9l
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the driver and dt-binding document for Loongson-1 AC97.
Add the dt-binding document for Realtek ALC203 Codec.
Add DT support for the AC97 generic codec driver.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Changes in v2:
- Added a reference to dai-common.yaml in realtek,alc203.yaml.
- Return -EINVAL when 'audio-tx' or 'audio-rx' is absent from reg-names.
- Link to v1: https://lore.kernel.org/r/20250115-loongson1-ac97-v1-0-2087b04dcd7f@gmail.com

---
Keguang Zhang (4):
      ASoC: dt-bindings: Add Loongson-1 AC97 Controller
      ASoC: dt-bindings: Add Realtek ALC203 Codec
      ASoC: loongson: Add Loongson-1 AC97 Driver
      ASoC: ac97: Add DT support

 .../bindings/sound/loongson,ls1b-ac97.yaml         |  68 ++++
 .../devicetree/bindings/sound/realtek,alc203.yaml  |  36 ++
 MAINTAINERS                                        |   1 +
 sound/soc/codecs/ac97.c                            |  10 +
 sound/soc/loongson/Kconfig                         |  10 +
 sound/soc/loongson/Makefile                        |   2 +
 sound/soc/loongson/loongson1_ac97.c                | 398 +++++++++++++++++++++
 7 files changed, 525 insertions(+)
---
base-commit: 46086739de22d72319e37c37a134d32db52e1c5c
change-id: 20250115-loongson1-ac97-389daeec55e3

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

