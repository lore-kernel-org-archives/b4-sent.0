From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/3] iio: adc: mt6359-auxadc: various fixes
Date: Tue, 03 Nov 2026 18:32:06 +0200
Message-Id: <20261103-6768-6358-fixes-v1-0-2a868a33152b@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNjXTNzMwtdM2NTC920zIrUYt205JRkc8vEtMRUQ0MloK6ColSwBFB
 TdCyEX1yalJWaXAIyRqm2FgDBa7lWcwAAAA==
X-Change-ID: 20261103-6768-6358-fixes-fcdc79afae11
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 =?utf-8?q?N=C3=ADcolas_F=2E_R=2E_A=2E_Prado?= <nfraprado@collabora.com>
Cc: Chen-Yu Tsai <wenst@chromium.org>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793723743; l=950;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=doV4JykRzr4qLWTGO3/PJI6VtFZkP4IiQqJpVVNcdxM=;
 b=i2ltcp1uL6i2XvvgCUd1gj6cSYYIA2wrRRRsy5ngfrRObEo6GyY66rDAMj/UvULuGnKd2ynJt
 k+j7WbSQMzCCtusU1GCX49q9HS+//kVCDde493ZyOXlNeUh1BetuHwo
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series fixes various bugs in the mt6359 auxadc driver. For
some reason, the driver had channel types for temperature or resistance,
while the ADC can report only voltage. There were also issues with
battery channel ready bit masking and scale calculation.

Changes were verified on the mt6358 (mt6768 platform). Compile-tested
only for others.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Roman Vivchar (3):
      iio: adc: mt6359-auxadc: correct channel types to IIO_VOLTAGE
      iio: adc: mt6359-auxadc: mask conversion ready bit in mt6358_read_imp
      iio: adc: mt6359-auxadc: fix scale calculation

 drivers/iio/adc/mt6359-auxadc.c | 88 ++++++++++++++++++++---------------------
 1 file changed, 42 insertions(+), 46 deletions(-)
---
base-commit: 7649ba73f9e7e1e04d0b46213e39c79ae09dd55c
change-id: 20261103-6768-6358-fixes-fcdc79afae11

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

