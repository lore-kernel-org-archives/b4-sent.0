From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v6 0/6] New features for the AD5686 IIO driver
Date: Sun, 05 Jul 2026 12:38:55 +0100
Message-Id: <20260705-ad5686-new-features-v6-0-269594c7aae5@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE9CSmoC/33NTW7DIBCG4atErEsFgxmgq94j6oKfIUFq7QpSp
 1Xku5dk5cpWl+8nzTM31qgWauzlcGOV5tLKNPbApwOLZz+eiJfUm4EAFCiA+6TRIh/pyjP5y1e
 lxklKjGIIKQXH+uVnpVy+H+rxrfe5tMtUfx5PZnlf//dmyQVHJ0lIa1UC8+pH/z6dnuP0we7gD
 GvE7SPQESPCACrraDBtELVCJO4jqiPZgsvBkAOEDTKsEFD7yNARsA7Ba5OCyBtErxG7j+iOaGO
 i9ylkE8UfZFmWX75rPbfLAQAA
X-Change-ID: 20260602-ad5686-new-features-e116c04bddb9
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Maxwell Doose <m32285159@gmail.com>, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783251560; l=2903;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=cRmTCTA5csWbCv0b+iGmBX/uosZKYsS/BSqEGF8I34o=;
 b=/p0HUcH8oDFF/pcQkr+mAD3c6F6UBjyPOFH5O3ZVQv188MZnhA0JlQhi3E/hI6sMt16IbjJ1O
 oE7ewGn8EBADeIt3iVPS21bcdkCaMEb5WOB65bIsp81+fanfShjH5EJ
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the second series of three on updating the AD5686 driver.

Initially, a big patch series was sent:
https://lore.kernel.org/r/20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com

Then, the first patch series added fixes and cleanups:
https://lore.kernel.org/linux-iio/20260524-ad5686-fixes-v7-0-b6bf395d08bd@analog.com/

This one is introducing new features:
- Consume optional reset and correct power supplies;
- LDAC GPIO handling (active-low, held low when unused);
- SPI bus sync() implementation for batching multiple transfers;
- Triggered buffer support, leveraging LDAC and sync() to flush
  all channel writes atomically;
- Gain control support through the scale property.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v6:
- Refactor command/data macros in favor of FIELD_PREP()
- Link to v5: https://lore.kernel.org/r/20260628-ad5686-new-features-v5-0-577caadbf7c0@analog.com

Changes in v5:
- Create auxiliary handler for the triggered buffer.
- Do not allow modification of double_scale in case gain_gpio is not set.
- Link to v4: https://lore.kernel.org/r/20260623-ad5686-new-features-v4-0-28962a57db0f@analog.com

Changes in v4:
- Replace anyof+const for enum in dt-bindings. 
- Address some sashiko's comments.
- Use guard(mutex)() in trigger handler and other misc changes.
- Link to v3: https://lore.kernel.org/r/20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com

Changes in v3:
- Add range-double property.
- Acquire reset control after power-up delay.
- Include cleanup.h and use guard(mutex)() in read_raw().
- Link to v2: https://lore.kernel.org/r/20260609-ad5686-new-features-v2-0-70b423f5c76d@analog.com

Changes in v2:
- Get reset control deasserted.
- Update entire spi_transfer struct rather than individual fields.
- Replace udelay() for fsleep() in probe().
- Minor changes addressing further feedback.
- Link to v1: https://lore.kernel.org/r/20260602-ad5686-new-features-v1-0-691e01883d27@analog.com

---
Rodrigo Alencar (6):
      iio: dac: ad5686: refactor command/data macros
      iio: dac: ad5686: introduce sync operation
      iio: dac: ad5686: implement new sync() op for the spi bus
      iio: dac: ad5686: read_raw/write_raw: use guard(mutex)()
      iio: dac: ad5686: add triggered buffer support
      iio: dac: ad5686: add gain control support

 drivers/iio/dac/Kconfig      |   2 +
 drivers/iio/dac/ad5686-spi.c | 136 +++++++++++++++++++++-------
 drivers/iio/dac/ad5686.c     | 209 +++++++++++++++++++++++++++++++++++++++----
 drivers/iio/dac/ad5686.h     |  43 ++++++---
 drivers/iio/dac/ad5696-i2c.c |  13 +--
 5 files changed, 334 insertions(+), 69 deletions(-)
---
base-commit: 4c0ecdbdc0d87570f74e656e21d56bae1ab6a8f1
change-id: 20260602-ad5686-new-features-e116c04bddb9

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

