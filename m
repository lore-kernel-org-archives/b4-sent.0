From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v7 0/7] New features for the AD5686 IIO driver
Date: Fri, 10 Jul 2026 12:20:44 +0100
Message-Id: <20260710-ad5686-new-features-v7-0-1bcc8c280e4d@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIzVUGoC/33OzU7DMAzA8VeZciYocRs74cR7oB3y4WyRoJ3a0
 YGmvjvpLhS14vi35J99FyMPhUfxcriLgacylr6rQU8HEc++O7EsqbYABahQgfTJoEXZ8U1m9tf
 PgUfJWmNUbUgpOFE3LwPn8vVQ3461z2W89sP348ikl+n/3qSlkug0K21tk4Befeff+9Nz7D/EA
 k6wRtw+AhUhFVposomEaYM0K0TjPtJUJFtwORA7QNgg7QqBZh9pKwLWIXhDKai8QcwasfuIqYg
 hit6nkCmqDYK/CCmzj+DyCTrj2kjes/mDzPP8A2dvYa0QAgAA
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>, sashiko-bot@kernel.org, 
 Maxwell Doose <m32285159@gmail.com>, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783682457; l=3180;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=MQaVxbt5MgT9+pSNhtkCULBHkc7gzrmBDoIfbSTlv4A=;
 b=M7wQwbX8ZcTM5YvpHr44Jl9gLZIaQ2JyRbVNVZRlEvbaiEUYHZFaFHGaBkbTjlq4RcYx7GXdZ
 coZYgf3XtRyBLU9EjUY8SabNID6pGe84//boIFmQCsReHyeDPAyCQQ7
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
Changes in v7:
- Fix return value check of i2c_transfer().
- Amend refactoring of command/data macros.
- Link to v6: https://lore.kernel.org/r/20260705-ad5686-new-features-v6-0-269594c7aae5@analog.com

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
Rodrigo Alencar (7):
      iio: dac: ad5696: properly check i2c_transfer() return value
      iio: dac: ad5686: refactor command/data macros
      iio: dac: ad5686: introduce sync operation
      iio: dac: ad5686: implement new sync() op for the spi bus
      iio: dac: ad5686: read_raw/write_raw: use guard(mutex)()
      iio: dac: ad5686: add triggered buffer support
      iio: dac: ad5686: add gain control support

 drivers/iio/dac/Kconfig      |   2 +
 drivers/iio/dac/ad5686-spi.c | 136 ++++++++++++++++++++-------
 drivers/iio/dac/ad5686.c     | 215 +++++++++++++++++++++++++++++++++++++++----
 drivers/iio/dac/ad5686.h     |  52 ++++++++---
 drivers/iio/dac/ad5696-i2c.c |  17 ++--
 5 files changed, 345 insertions(+), 77 deletions(-)
---
base-commit: 4c0ecdbdc0d87570f74e656e21d56bae1ab6a8f1
change-id: 20260602-ad5686-new-features-e116c04bddb9

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

