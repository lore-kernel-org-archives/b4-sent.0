From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Fri, 10 Mar 2023 11:28:42 +0100
Subject: [PATCH RESEND] bluetooth: btbcm: Fix logic error in forming the
 board name.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230224-btbcm-wtf-v1-1-98b56133a5b7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFkGC2QC/x2NsQ7CMAxEf6XyTKSQsMBMVwYYUYckdYiHpsiOo
 FXVfydhfO/udBsIMqHApduA8UNCc65wPHQQkssvVDRWBqON1caclC8+TOpboorRmoijxbPVUPv
 eCSrPLofUFpOTgtyCN2Ok5X/yhHv/6G9XGKpPJGXmtelh3383ljhSiwAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678444123; l=1051;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=+hMNA2WpUNZu2o8n2bsPzKVxjKjxWwSwKggqeF2dZBY=;
 b=mnQHxqtnBZuBU3DFpb7akNdZHagVnnVmY8+FCTDQjEVM1DQ4fsHWry00l2w0Im+Fgy5WF0vLl
 75//dVWW7IFBLEApayjftPEIfRMwpLeYHsC8x9DmKeliO8NQJN6XsnD
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch fixes an incorrect loop exit condition in code that replaces
'/' symbols in the board name. There might also be a memory corruption
issue here, but it is unlikely to be a real problem.

Cc: <stable@vger.kernel.org>
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
base-commit: fe15c26ee26efa11741a7b632e9f23b01aca4cc6
change-id: 20230224-btbcm-wtf-ff32fed3e930

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

