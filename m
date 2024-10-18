From: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
Subject: [PATCH v2 0/2] common: buffer access out-of-bounds
Date: Fri, 18 Oct 2024 14:45:54 +0300
Message-Id: <20241018-errors_fixes-v2-0-7f49d5a0087b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHJKEmcC/3WMQQrCMBBFr1JmbaQTUhtceQ8pEpOxHbBNmUhQS
 u5u7N7l+5/3NkgkTAnOzQZCmRPHpYI+NOAnt4ykOFQG3WqDLfaKRKKk24PflJRFbWzfdXd7MlC
 VVWg/qnEdKk+cXlE+ez3jb/0TyqhQGW8COu1rNFzG2fHz6OMMQynlC4ho4F6oAAAA
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729251992; l=527;
 i=abdelrahmanyossef12@gmail.com; s=20241017; h=from:subject:message-id;
 bh=DwB4qhKEGaH5UaxcTDX1tQ/vNnewSgLF/1z4q0oLQpU=;
 b=YBYhsUqIJ7FENNqcmhBIy9c5AG47+ACGE1VVpmGymH+Ps8Kim459vabIjvMbjDJhhpqajWTW/
 t/j1OaRXQw3CFHsHX0BuOnGfbb8UZV9QtVptEnKu7mbicwHsMewyqTX
X-Developer-Key: i=abdelrahmanyossef12@gmail.com; a=ed25519;
 pk=ayjFVDSRo1qKm+PGih8rsNvcMQvJ4ROQWuZWrYU8ujc=
X-Endpoint-Received: by B4 Relay for abdelrahmanyossef12@gmail.com/20241017 with auth_id=251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
---
Abdelrahman Youssef (2):
      include: Include <linux/math.h> to resolve implicit declaration of do_div()
      common: buffer access out-of-bounds

 common/filetype.c     | 8 ++++----
 include/linux/ktime.h | 1 +
 2 files changed, 5 insertions(+), 4 deletions(-)
---
base-commit: 9d47ff66c3892c5a6ddd4704993365a797fbeb68
change-id: 20241017-errors_fixes-81248755b864

Best regards,
-- 
Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>

