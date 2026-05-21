From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 21 May 2026 11:55:44 +0200
Subject: [PATCH v3 7/7] iio: light: opt3001: add comment to mutex
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-opt3001-cleanup-v3-7-820169dec8c3@gmail.com>
References: <20260521-opt3001-cleanup-v3-0-820169dec8c3@gmail.com>
In-Reply-To: <20260521-opt3001-cleanup-v3-0-820169dec8c3@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Maxwell Doose <m32285159@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779357341; l=747;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=nPTHkMaVXMtfkGG3J9CutOPKt6djL0Q5K/PInamunpM=;
 b=tfZGJJQKv3e9OGXO8HACxP4MwXKSKOIZBIbPGD6yW/Wm2XKsmfVdV6Yy1sW/OvStrWEkhWzA8
 MzBFt738c76DYYrIpEVgNQTtKBsw6k21iOAPQ0iyk5EJIzVhj9eeUAS
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add comment to mutex per checkpatch.pl report.

No functional change.

Reviewed-by: Maxwell Doose <m32285159@gmail.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index ac1c7ba5679867f6b814894680e317615f2e373b..9d24d7a23ef00d160fdae737b6ea1943576a3fcf 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -103,6 +103,7 @@ struct opt3001_chip_info {
 struct opt3001 {
 	struct i2c_client	*client;
 
+	/* Mutex for ensuring one executed command at a time */
 	struct mutex		lock;
 	bool			ok_to_ignore_lock;
 	bool			result_ready;

-- 
2.47.3

