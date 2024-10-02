From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 02 Oct 2024 12:51:52 +0200
Subject: [PATCH 3/4] Input: adp5588-keys: error out if no IRQ is given
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241002-fix-adp5588-read-refactor-v1-3-28800f1b9773@analog.com>
References: <20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com>
In-Reply-To: <20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com>
To: Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727866310; l=956;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Oyv6w1vVB0WsBBnLrEoR1/r+BQ9oW4zFkMd7v+3aoJg=;
 b=R4ykC6WUXoS2Pr1ZkyEWK/TbVMKvSNrHRAKHmo6YaN1hMhyoNEoNlqWfi02Wig7gGRn5aHsLp
 4fVvMG63iAUAEkHh7R5D2XuyGfokQEw9OBzpMzyrusmHnM9cQoVjipk
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

