From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 25 May 2026 10:20:22 +0200
Subject: [PATCH v4 8/8] iio: light: opt3001: add comment to mutex
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260525-opt3001-cleanup-v4-8-65b36a174f78@gmail.com>
References: <20260525-opt3001-cleanup-v4-0-65b36a174f78@gmail.com>
In-Reply-To: <20260525-opt3001-cleanup-v4-0-65b36a174f78@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779697227; l=901;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=e0FEzpVldsPt7x0C57i9zGOxx0GFmKdZq9MhceXE7aU=;
 b=natZBCGqCGJr+RedNb8eCq03yq6sNn2h1dH7JA5kC/CwhsVslf7ed3xZWASskUTnrGfzNAApw
 Uxj186nVxVPBmc/zXLykJz5+hDOovWSqVxP/FE7vCHTxBf6z/fxbp1l
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add comment to mutex per checkpatch.pl report. While we're at it, add
a comment to bool ok_to_ignore_lock.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index e35b5cf665e2651e8b6a576aa34fed5082f4ed19..8d89d539b19b862ad7a33cfabd922ddf8b826b2c 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -103,7 +103,13 @@ struct opt3001_chip_info {
 struct opt3001 {
 	struct i2c_client	*client;
 
+	/*
+	 * Ensure data capture and read-modify-write sequences are
+	 * not interrupted.
+	 */
 	struct mutex		lock;
+
+	/* Allows for IRQs to bypass locking mechanism */
 	bool			ok_to_ignore_lock;
 	bool			result_ready;
 	wait_queue_head_t	result_ready_queue;

-- 
2.47.3

