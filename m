From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Tue, 27 Jan 2026 01:02:16 +0530
Subject: [PATCH v7 2/6] iio: proximity: rfd77402: Align polling timeout
 with datasheet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260127-b4-rfd77402_v5-v7-2-3e7f2d452da2@gmail.com>
References: <20260127-b4-rfd77402_v5-v7-0-3e7f2d452da2@gmail.com>
In-Reply-To: <20260127-b4-rfd77402_v5-v7-0-3e7f2d452da2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769455974; l=667;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=TaE9gAMSfYWdrqq17KNOJs0YkY1PEqKmG/gPTNBcwIU=;
 b=CWkUr6w16yGAeDFoPX3hanjbzQ3l9UN8Ao5BJmpx82u+yiJWbcTKshE34IQGcdpwPGlqQ4jyW
 TUN5z49hnVUC5YtZmGMXe5oB/krpUig4e++bTS8DXSo4aHamujqoshZ
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the polling delay to use a 100 ms timeout, as specified
in the RFD77402 datasheet.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index 69cc1505b964..3e14660a4bb1 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -132,7 +132,7 @@ static int rfd77402_measure(struct i2c_client *client)
 			goto err;
 		if (ret & RFD77402_ICSR_RESULT)
 			break;
-		msleep(20);
+		msleep(10);
 	}
 
 	if (tries < 0) {

-- 
2.43.0

