From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/4] ASoC: codecs: adau1373: drop platform data
Date: Mon, 28 Oct 2024 16:43:37 +0100
Message-Id: <20241028-adau1373-shutdown-v2-0-647f56bbd182@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACmxH2cC/x2MuwqAMAwAf0UyWzCpUPRXxKHa1Gap0voC8d8tD
 jfccPdA5iScoa8eSHxKljUWobqCOdi4sBJXHKihFgvKOnugNlrlcOxuvaLqkNiT1zihgdJtib3
 c/3MY3/cDn9cZ2GMAAAA=
To: linux-sound@vger.kernel.org, devicetree@vger.kernel.org
Cc: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730130219; l=1126;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=hG904Ejk14QzUK5GUCqREAtgpqylEPSsrKPmrN/RinA=;
 b=Mioo4Du/EgbgNIZY5irudzwOi/1vAN5HzRIrCZc6P+J950jCVzehd6biTY+6nGthqQnSl4z+I
 CtWSydD+XJvDVzKfPFLTsxnnYz1vUAbGTmN8epWRqDX12JFuTZXv06w
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Mark,

Here it goes v2...

v1:
 * https://lore.kernel.org/all/20241021-adau1373-shutdown-v1-0-bec4ff9dfa16@analog.com/ 

v2:
 - Patch 2 (Bindings):
   * Removed extra blank line;
   * Fixed example messed indentation;
   * Added more properties to the example;
   * Add maxItems.
 - Patch 4 (Powerdown gpio):
   * Powerdown the chip when unbound.

---
Nuno Sa (4):
      ASoC: codecs: adau1373: add some kconfig text
      ASoC: dt-bindings: document the adau1373 Codec
      ASoC: codecs: adau1373: drop patform_data
      ASoC: codecs: adau1373: add powerdown gpio

 .../devicetree/bindings/sound/adi,adau1373.yaml    | 111 +++++++++++
 MAINTAINERS                                        |   1 +
 include/sound/adau1373.h                           |  33 ----
 sound/soc/codecs/Kconfig                           |   2 +-
 sound/soc/codecs/adau1373.c                        | 208 ++++++++++++++++-----
 5 files changed, 272 insertions(+), 83 deletions(-)
---
base-commit: e25169fb5a8c37e8f7d1da3d1427dee938f15f07
change-id: 20241024-adau1373-shutdown-912ef2f31b17
--

Thanks!
- Nuno Sá

