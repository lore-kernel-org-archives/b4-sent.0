From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH v2 0/2] gpio: i.MX: make _get_value() able to read output
 pin state
Date: Sat, 18 Oct 2025 11:59:46 +0200
Message-Id: <20251018-imx_gpio-v2-0-22e4fc090de6@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABJl82gC/23M0QqDIBTG8VeJcz2Hulm0q95jxNA65oGVoSGN8
 N3nut7l/+Pjd0DEQBjhUR0QMFEkv5SQlwoGp5cJGY2lQXKpBBeK0by/ppU8u9doUWCjzXiDcl8
 DWtpP6tmXdhQ3Hz6nnMRv/YMkwThD1bRS2ZbXxnTOb7Om93XwM/Q55y+Qo8PNogAAAA==
X-Change-ID: 20251015-imx_gpio-46efe1e7abd3
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>, 
 Ahmad Fatoum <a.fatoum@pengutronix.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760781589; l=1076;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=AjuJYAqdvRGQNNKhF1dbI2ZCG5noLDXzzqMsfPFTL88=;
 b=wXhUi6cv8AVZwBg4QPO79V798U4hLAxwyxz89U7R1wlalVw6hp4zQZl+IDqvq7y8HIEI1jbau
 dp/hxdLd+QFBZDpxKlGoynuZ0rDxKhpvNUXjpAceWieemYYywho8sfq
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make _get_value() read back the dr register instead of the psr register
when the direction is set to output. Now _get_value() can actually read
the state of an output gpio instead of being always low.

Also add a note in the migration guide file.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Changes in v2:
- Move the extra commit comment into the commit [1/2]
- Actually add a note to the migration file [2/2]
- Link to v1: https://lore.kernel.org/r/20251015-imx_gpio-v1-0-e57925f906bb@hotmail.com

---
Maud Spierings (2):
      gpio: i.MX: make _get_value() able to read output pin state
      Documentation: migration-2025.11.0: add note about new gpio behaviour

 .../migration-guides/migration-2025.11.0.rst          |  7 +++++++
 drivers/gpio/gpio-imx.c                               | 19 +++++++++++--------
 2 files changed, 18 insertions(+), 8 deletions(-)
---
base-commit: 8defba1d0ab1aef9dd5d57710e18d0d02e2c48e2
change-id: 20251015-imx_gpio-46efe1e7abd3

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

