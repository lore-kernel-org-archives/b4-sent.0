From: =?utf-8?q?F=C3=A9lix_Pi=C3=A9dallu?= <felix.piedallu@non.se.com>
Subject: [PATCH 0/2] SPI: omap2-mcspi: Fix SPI CS behaviour around
 cs_change in SPI transfers
Date: Fri, 06 Jun 2025 15:37:23 +0200
Message-Id: <20250606-cs_change_fix-v1-0-27191a98a2e5@non.se.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABPvQmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDMwMz3eTieIhEfFpmhW5SkqlhYrJBmlFScpISUE9BUSpQGGxedGxtLQA
 Snt9UXwAAAA==
To: Mark Brown <broonie@kernel.org>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?F=C3=A9lix_Pi=C3=A9dallu?= <felix.piedallu@non.se.com>, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749217048; l=1712;
 i=felix.piedallu@non.se.com; s=20250606; h=from:subject:message-id;
 bh=X7XpGECVvpMPfrkP+mW0VHeflAdnttqoI0luHFxrs/0=;
 b=9Gw88HDO4sOl5Z78eu6YPKIanAs+oYZtHOlWMd9EmPytklBEmMBgCvnt1fSFcAa6kJI1g5fCD
 Zdpio3XEFzRCInG9+sOcIfofNgoy2S5aZKyyLSLqJOf8U/dgj36Hsvv
X-Developer-Key: i=felix.piedallu@non.se.com; a=ed25519;
 pk=Xe1dw6DIV7hmFbzuJfvaioG+S30kGix0QpIi5qPg99w=
X-Endpoint-Received: by B4 Relay for felix.piedallu@non.se.com/20250606 with auth_id=427
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches fix the behaviour of the SPI Chip Select of the OMAP2 MCSPI
driver used on TI SoCs.

The omap2-mcspi driver supports the use of multi mode (multichannel in TI
documentation). In this mode, the CS is asserted and deasserted by the
hardware.

The multi mode is disabled for messages when cs_change=0 for all transfers
(e.g when CS is kept asserted between transfers of a same message).

The multi mode also needs to be disabled for messages when cs_change=1 on the
last transfer (e.g when CS is kept asserted after the WHOLE message), and the
message right after.

Currently, that is not the case and it CS is deasserted by hardware when it
shouldn't.
This breaks peripheral drivers that send multiple messages with the CS asserted
in between.

Patch 1 ensures that multi mode is disabled when cs_change=1 on the last
transfer of the message.

Patch 2 ensures that multi mode is disable on a message following one with
cs_change=1 on the last transfer.

This is the case for the TPM TIS SPI driver that uses this logic for flow
control purposes.

Tested on an AM6442 platform with a TPM ST33HTPH2X32AHE4.

Signed-off-by: Félix Piédallu <felix.piedallu@non.se.com>
---
Félix Piédallu (2):
      spi: omap2-mcspi: Disable multi mode when CS should be kept asserted after message
      spi: omap2-mcspi: Disable multi-mode when the previous message kept CS asserted

 drivers/spi/spi-omap2-mcspi.c | 30 ++++++++++++++++++------------
 1 file changed, 18 insertions(+), 12 deletions(-)
---
base-commit: c46b66be7eb595e66e93eda13149e0d4f90924ea
change-id: 20250606-cs_change_fix-bb51ac0f2bcb

Best regards,
-- 
Félix Piédallu <felix.piedallu@non.se.com>

