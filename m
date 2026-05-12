From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 12 May 2026 12:57:30 +0200
Subject: [PATCH v2 10/10] iio: light: opt3001: add comment to mutex
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-opt3001-cleanup-v2-10-8018cf3a8a0a@gmail.com>
References: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
In-Reply-To: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778583471; l=692;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=9LCbzPQ+voynoNiKus4VNoaaKdzkjvLt3vAM6THTWlQ=;
 b=C7b7QpXCOmCiaZBpNtXGQLqJYiad35EF6gLzN59OCN+4R+cAJn0jx9wPt4oIGoqeXSi5FRx7U
 Fl2SHx38W0qAnvYCWY5WxMLAOGWGCSMFOvODqtHYuRh0ggI8QvK8daU
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add comment to mutex per checkpatch.pl report.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 1319e5941b66bd82e4dc2badf5ea27cacbcfd54a..81afee6993d08b1126f07b1c63c3d3496d8b380c 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -104,6 +104,7 @@ struct opt3001 {
 	struct i2c_client	*client;
 	struct device		*dev;
 
+	/* Mutex for ensuring one executed command at a time */
 	struct mutex		lock;
 	bool			ok_to_ignore_lock;
 	bool			result_ready;

-- 
2.47.3

