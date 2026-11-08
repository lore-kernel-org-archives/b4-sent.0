From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sun, 08 Nov 2026 09:33:54 +0100
Subject: [PATCH 2/5] Input: s6sy761 - check the multitouch axis ranges
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-s6sy761-fts1ba90a-v1-2-999b3cfaf82d@dxdmail.cc>
References: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
In-Reply-To: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794126835; l=1089;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=a/pLroNBJtz3o9lo3KhseD8iBVAsH+uHttUxd7UDP/Y=;
 b=HDWPyass2lu1SrTdwK3bIsGL+a9szaSH9KZOW10verBpSAF0TUy8ldGdqh3EZOQbTQ7buF9Y3
 yNjZ9fmjPdRDH4ahPgNth/xO+BvbDIoFNbMjpetwRcXhx8sOQhMHtmy
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The axis check runs before input_mt_init_slots() copies the multitouch
ranges to ABS_X and ABS_Y, so it warns on every probe. Check
ABS_MT_POSITION_X and ABS_MT_POSITION_Y instead.

Fixes: 0145a7141e59 ("Input: add support for the Samsung S6SY761 touchscreen")
Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 drivers/input/touchscreen/s6sy761.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/input/touchscreen/s6sy761.c b/drivers/input/touchscreen/s6sy761.c
index 967fd222f0d6..59166865d397 100644
--- a/drivers/input/touchscreen/s6sy761.c
+++ b/drivers/input/touchscreen/s6sy761.c
@@ -449,8 +449,8 @@ static int s6sy761_probe(struct i2c_client *client)
 
 	touchscreen_parse_properties(sdata->input, true, &sdata->prop);
 
-	if (!input_abs_get_max(sdata->input, ABS_X) ||
-	    !input_abs_get_max(sdata->input, ABS_Y)) {
+	if (!input_abs_get_max(sdata->input, ABS_MT_POSITION_X) ||
+	    !input_abs_get_max(sdata->input, ABS_MT_POSITION_Y)) {
 		dev_warn(&client->dev, "the axis have not been set\n");
 	}
 

-- 
2.56.0

