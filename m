From: Ivan Verbovoy <ivanverbovoy@gmail.com>
Date: Mon, 09 Nov 2026 19:15:55 +0200
Subject: [PATCH] Input: da7280 - do not advertise FF_GAIN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-da7280-fixes-v1-1-09cc3650261c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWWvSS1LiVcSil8FYIB1EIt5ds
 fxy8p8LGBMhQ1NckPAgpmXOUGUBYXTzgIJiNmiprVLSiOgqXUvR04ksfDDW6uhqYyLkZE34Dbl
 ou9+8+wnD9n7AfT83JOVbcAAAAA==
X-Change-ID: 20261103-da7280-fixes-bc3662da833d
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Support Opensource <support.opensource@diasemi.com>
Cc: Roy Im <roy.im.opensource@diasemi.com>, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Ivan Verbovoy <ivanverbovoy@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794244554; l=1634;
 i=ivanverbovoy@gmail.com; s=20261103; h=from:subject:message-id;
 bh=+tqVB3FFlOvTrxuwLoZlTGemlkZKQe11KqmDZ4ghgME=;
 b=XqGYSR/7q15sJpPAK7Uho+UjtaZTkO0DnDGaX9Y1u0dwatFlIUeVHZZF6L8dDnxHfuHcLi1Zz
 EZfHPuL7AU0CCx/a9jd3bIpfc4EydqRug4g2IvZ36+ADClp9OMQ+H2J
X-Developer-Key: i=ivanverbovoy@gmail.com; a=ed25519;
 pk=0AchqTH1hJFToIUeFfQRlVzzuaWQDs4e75SxT2y3s8c=
X-Endpoint-Received: by B4 Relay for ivanverbovoy@gmail.com/20261103 with auth_id=1396
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver sets FF_GAIN in the device's force feedback capabilities but
provides no set_gain() callback. input_ff_event() checks the capability
bit, not the callback, before calling ff->set_gain(), so an EV_FF/FF_GAIN
event written to the event node by any process with write access to it
calls through a NULL pointer.

The driver has no global gain to set: a constant effect carries its own
level, and a periodic effect plays a pattern from the device's waveform
memory. Drop FF_GAIN from the capabilities, so that input_ff_event()
ignores such an event.

Fixes: cd3f609823a5 ("Input: new da7280 haptic driver")
Cc: stable@vger.kernel.org
Signed-off-by: Ivan Verbovoy <ivanverbovoy@gmail.com>
---
A NULL set_gain() call on an FF_GAIN write, seen on a Surface Duo
(sm8150).
---
 drivers/input/misc/da7280.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/input/misc/da7280.c b/drivers/input/misc/da7280.c
index 995d3f7af41a..4c60fd4fb932 100644
--- a/drivers/input/misc/da7280.c
+++ b/drivers/input/misc/da7280.c
@@ -1226,7 +1226,6 @@ static int da7280_probe(struct i2c_client *client)
 	input_set_capability(haptics->input_dev, EV_FF, FF_PERIODIC);
 	input_set_capability(haptics->input_dev, EV_FF, FF_CUSTOM);
 	input_set_capability(haptics->input_dev, EV_FF, FF_CONSTANT);
-	input_set_capability(haptics->input_dev, EV_FF, FF_GAIN);
 
 	error = input_ff_create(haptics->input_dev,
 				DA7280_FF_EFFECT_COUNT_MAX);

---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261103-da7280-fixes-bc3662da833d

Best regards,
--  
Ivan Verbovoy <ivanverbovoy@gmail.com>

