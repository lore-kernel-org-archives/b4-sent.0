From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH 0/2] gpio: i.MX: make _get_value() able to read output pin
 state
Date: Wed, 15 Oct 2025 20:03:27 +0200
Message-Id: <20251015-imx_gpio-v1-0-e57925f906bb@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO/h72gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDA0NT3czcivj0gsx8XROz1LRUw1TzxKQUYyWg8oKi1LTMCrBR0bG1tQC
 IoRihWgAAAA==
X-Change-ID: 20251015-imx_gpio-46efe1e7abd3
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760551410; l=833;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=fUinb2GjLx6gLrcWShw0RkZz2MWyw79BFrjlkNZPwMQ=;
 b=mGIYu2VABkMCmEl1mOcsB7hQ730IERmxY6FooLlW/gGWSx9nzfz+k3giEw9O8MUxhBQafLucs
 9TuMok9JUdZBiIBH09LAj0/y5gSqRUawO0h0Ozy2D6KxVqJLTNWmLg9
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make _get_value() read back the dr register instead of the psr register
when the direction is set to output. Now _get_value() can actually read
the state of an output gpio instead of being always low.

Also add a new empty migration guide file.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Maud Spierings (2):
      gpio: i.MX: make _get_value() able to read output pin state
      Documentation: migration-2025.11.0: add new empty file

 .../migration-guides/migration-2025.11.0.rst          |  0
 drivers/gpio/gpio-imx.c                               | 19 +++++++++++--------
 2 files changed, 11 insertions(+), 8 deletions(-)
---
base-commit: 8defba1d0ab1aef9dd5d57710e18d0d02e2c48e2
change-id: 20251015-imx_gpio-46efe1e7abd3

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

