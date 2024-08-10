From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH kmod 0/2] Couple of SPDX fixes
Date: Sat, 10 Aug 2024 13:25:14 +0100
Message-Id: <20240810-b4-spdx-fixup-v1-0-b9c84d637fb3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACpct2YC/x2MQQqAIBAAvyJ7bkFDSvpKdNDcai8mSiGIf086D
 sNMhUyJKcMiKiR6OfMdOqhBwH7ZcBKy7wyjHLU0SqLTmKMveHB5IrrZeUvGTdJb6E1M1MX/W7f
 WPvV0rBNfAAAA
To: linux-modules@vger.kernel.org
Cc: Lucas De Marchi <lucas.de.marchi@gmail.com>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723292726; l=857;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=wOHVJ5H+ilz1a1R5578g5XOMZxAQTNQ4cTfxrsDR+Ic=;
 b=UGtH1lYs4R6M5KdqytjVGwm6VB4lOy81mD+sjgSwsOMlGj8AvulAkNfDrYS3mfYOq0oI9RECD
 0qsCLC2PrrYB6zyxRDWbmnxw/38iR7OjO8xx1dOIG9Z9OinVZhqNva+
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

Seems like the revision of the SPDX license identifiers, that landed in
master, dropped the wrong hunk/paragraph.

Namely: a function description/summary was removed in one m4 file, while
the license exception in the second m4 file was intended.

I've left the two changes as separate patches, since I'm not 100% sure
if dropping the former wasn't semi-intentional.

Feel free to pick whichever patch makes sense o/

---
Emil Velikov (2):
      m4: reinstate CC_CHECK_FLAG_APPEND summary
      m4: remove verbose license exception clause

 m4/attributes.m4 |  5 +++++
 m4/features.m4   | 13 -------------
 2 files changed, 5 insertions(+), 13 deletions(-)
---
base-commit: af21689dd0f1ef6f40d6ecc323885026a07486f9
change-id: 20240810-b4-spdx-fixup-b7bdae8b60da

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

