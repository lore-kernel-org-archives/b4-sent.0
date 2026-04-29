From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Wed, 29 Apr 2026 17:04:55 +0200
Subject: [PATCH v3 7/8] iio: light: si1133: reset counter to prevent race
 condition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-si1133-checkup-v3-7-469f21d960eb@gmail.com>
References: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
In-Reply-To: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777475147; l=1283;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=w5+8yh3xuGpn+X2XqfBM/QUEQDOv+CuyHlSCRq32RGk=;
 b=N+thik5dCDitv8Y5v6yQadfTjYzWgatWrVGaWSgs2/ysj5GlhS4q7jKx+4dTZnTnDWjM4sZMJ
 S2W/3fMGeNfBJMBqmLPcdlfUE8yno3ogfTBbX1yg4mYkWqr7M+tc8oK
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sashiko reported a potential race condition happening when the driver
returns an errno after a timeout in the si1133_command() function. The
premature exit causes the hardware and software counters to become out
of sync by not updating data->rsp_seq, therefore the internal hardware
counter keeps incrementing.

Fix this by adding a call to si1133_cmd_reset_counter() before returing
from timeout.

Closes: https://sashiko.dev/#/message/20260428-si1133-checkup-v2-5-70ad14bfefe2%40gmail.com
Assisted-by: gemini:gemini-3.1-pro-preview
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index 471692057b0f16c82946507bf7d23a0004f80bf0..842a59bc68c20b3206e0c826f86c913f6c66bd7c 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -430,6 +430,12 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 			dev_warn(dev,
 				 "Failed to read command 0x%02x, ret=%d\n",
 				 cmd, err);
+			/*
+			 * reset counter on err to prevent sofware and hardware
+			 * counters being out of sync
+			 */
+			si1133_cmd_reset_counter(data);
+
 			return err;
 		}
 	}

-- 
2.47.3

