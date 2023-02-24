From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Fri, 24 Feb 2023 12:59:31 +0100
Subject: [PATCH] bluetooth: btbcm: Fix logic error in forming the board
 name.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230224-btbcm-wtf-v1-1-be717d728e56@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKKm+GMC/x2NQQ7CMAwEv1L5jKXg9AJfQRyS1G59aEB2BJWq/
 p2U42hnNTs4m7LDfdjB+KOur9rhehmgLKnOjDp1BgoUA9GIueWy4rcJikQSniLfYoDu5+SM2VI
 ty/lYkze2c3gbi27/yON5HD9e6z/4dAAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, stable@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677239981; l=1021;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=liXj6eso7YibAPpq3C6GEb2euORWvG95T35Md9MPiuM=;
 b=Fk8BUaDW2JcDWQIOtNnG7UY8stvFMte2f8CocTlQj9cWdcvSB9Q9Rq5Ltk3Y+zJDD4RD4ZG8d
 ZoqwvFk4SQCDcUwZhfNQp87ASdy5EqrY3VRFNyE2mtnVRXwFN7LgshB
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch fixes an incorrect loop exit condition in code that replaces
'/' symbols in the board name. There might also be a memory corruption
issue here, but it is unlikely to be a real problem.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/bluetooth/btbcm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/bluetooth/btbcm.c b/drivers/bluetooth/btbcm.c
index 3006e2a0f37e..43e98a598bd9 100644
--- a/drivers/bluetooth/btbcm.c
+++ b/drivers/bluetooth/btbcm.c
@@ -511,7 +511,7 @@ static const char *btbcm_get_board_name(struct device *dev)
 	len = strlen(tmp) + 1;
 	board_type = devm_kzalloc(dev, len, GFP_KERNEL);
 	strscpy(board_type, tmp, len);
-	for (i = 0; i < board_type[i]; i++) {
+	for (i = 0; i < len; i++) {
 		if (board_type[i] == '/')
 			board_type[i] = '-';
 	}

---
base-commit: c9c3395d5e3dcc6daee66c6908354d47bf98cb0c
change-id: 20230224-btbcm-wtf-ff32fed3e930

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

