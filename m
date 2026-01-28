From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Wed, 28 Jan 2026 23:21:49 +0530
Subject: [PATCH v8 2/6] iio: proximity: rfd77402: Align polling timeout
 with datasheet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260128-b4-rfd77402_v5-v8-2-36388fe7b95e@gmail.com>
References: <20260128-b4-rfd77402_v5-v8-0-36388fe7b95e@gmail.com>
In-Reply-To: <20260128-b4-rfd77402_v5-v8-0-36388fe7b95e@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769622737; l=817;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=EszL1g394dGoeHz3qJUHUL8JHDZu8HglWxCDO1QGkP4=;
 b=23HwLZpgAD8vtUAJKSQUEmxbI658qK90g0buVS+GDtugSwX4KRnUAj5g4iipyedgY0wORgj82
 IVIg6bnkjdQBSzZiC6jApSKfVewm3iEKWkBD2DSt7Abu2vgmr5D3s1/
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the polling delay to use a 100 ms timeout, as specified
in the RFD77402 datasheet.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index 69cc1505b964..8f7debf0e61f 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -132,7 +132,11 @@ static int rfd77402_measure(struct i2c_client *client)
 			goto err;
 		if (ret & RFD77402_ICSR_RESULT)
 			break;
-		msleep(20);
+		/*
+		 * As per RFD77402 datasheet section '3.1.1 Single Measure',
+		 * the suggested timeout value for single measure is 100ms.
+		 */
+		msleep(10);
 	}
 
 	if (tries < 0) {

-- 
2.43.0

