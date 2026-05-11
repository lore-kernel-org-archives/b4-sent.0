From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 12:04:10 +0200
Subject: [PATCH 5/7] iio: light: opt3001: localize for loop iterator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-opt3001-cleanup-v1-5-f7879dc3455c@gmail.com>
References: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
In-Reply-To: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=965;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=u/HUKTzIcOfpvygcTLqBLKYbkfqnk+THD3TcTD43zww=;
 b=V7B5NHXs7MXVYQtshZ/EhhLkFp17pi8ropfMt6deX/iiH4b0+lfgOE2fYaPw5+ae7vzoouYJG
 cPbn7gWmtnyBMVWAXKQr2lX6hrT8R7q5KRpOVvg44Z0S2qo9pX0fcpJ
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Localize loop iterator to tighten scope and fix checkpatch.pl error.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index bdff785bcfa9744cd25d32c5d00d62a11dd9d866..3719757f6ed7784cbf2e4aa659e5c69a39b0cce2 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -228,8 +228,7 @@ static const struct opt3001_scale opt3002_scales[] = {
 static int opt3001_find_scale(const struct opt3001 *opt, int val,
 		int val2, u8 *exponent)
 {
-	int i;
-	for (i = 0; i < ARRAY_SIZE(*opt->chip_info->scales); i++) {
+	for (int i = 0; i < ARRAY_SIZE(*opt->chip_info->scales); i++) {
 		const struct opt3001_scale *scale = &(*opt->chip_info->scales)[i];
 		/*
 		 * Compare the integer and micro parts to determine value scale.

-- 
2.47.3

