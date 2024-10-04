From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 04 Oct 2024 15:46:51 +0200
Subject: [PATCH v2 2/3] Input: adp5588-keys: error out if no IRQ is given
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241004-fix-adp5588-read-refactor-v2-2-275a093758ae@analog.com>
References: <20241004-fix-adp5588-read-refactor-v2-0-275a093758ae@analog.com>
In-Reply-To: <20241004-fix-adp5588-read-refactor-v2-0-275a093758ae@analog.com>
To: Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728049615; l=956;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Oyv6w1vVB0WsBBnLrEoR1/r+BQ9oW4zFkMd7v+3aoJg=;
 b=Fs81b3fJ5aOuuyMiSMYuhAbB6WFlTgIXVDF9IqQ/Hmv4MmfUO35qAse6aO2Xx0mjI01B3yVTb
 JSF+J+yuNOUA6O2PenI8BS4wpmYpwEylfSdLu1A6/o9mhFQtwyyTngE
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the keypad is configured, it also depends on the presence of an
interrupt. With
commit dc748812fca0 ("Input: adp5588-keys - add support for pure gpio"),
having an interrupt is no longer mandatory so better check for it when
it is indeed mandatory.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index 11a70ee18482..0152e4fa088c 100644
--- a/drivers/input/keyboard/adp5588-keys.c
+++ b/drivers/input/keyboard/adp5588-keys.c
@@ -680,6 +680,11 @@ static int adp5588_fw_parse(struct adp5588_kpad *kpad)
 		return 0;
 	}
 
+	if (!client->irq) {
+		dev_err(&client->dev, "Keypad configured but no IRQ present\n");
+		return -EINVAL;
+	}
+
 	ret = matrix_keypad_parse_properties(&client->dev, &kpad->rows,
 					     &kpad->cols);
 	if (ret)

-- 
2.46.1

