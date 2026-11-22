From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:51 +0000
Subject: [PATCH 2/3] Input: synaptics-rmi4 - keep an I2C device that may
 wake the system powered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-rmi4-wakeup-v1-2-1b662be4a9d6@enser.io>
References: <20261122-b4-rmi4-wakeup-v1-0-1b662be4a9d6@enser.io>
In-Reply-To: <20261122-b4-rmi4-wakeup-v1-0-1b662be4a9d6@enser.io>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Abel Vesa <abelvesa@kernel.org>, Casey Connolly <casey.connolly@linaro.org>, 
 linux-input@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324430; l=2971;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=fDiPq/3r00nNm505fcLFxoFfTTgnQj9aL2qnPW//aiY=;
 b=WMSeGpwj6CI4Ce+yTljfHteDbAQCrDI7K/Sw6bk1eLeytA/E5e1Og22BqTMx09kKkI4lREWko
 YX2rRQNMYXCDdQb8qMeHZhLnhpOp9H/HpHsgeY3PjZKkg2VR0LeTzGX
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rmi_i2c_suspend() arms the attention interrupt for wakeup through
rmi_driver_suspend(..., true) and then disables the vdd and vio supplies.
Unpowered, the controller cannot report a touch, so the wakeup it has just
armed can never come from the user. Where the attention line is pulled up
from the switched I/O supply, cutting that supply also pulls the line
low, and that falling edge ends the suspend by itself.

On a OnePlus 6T (S3706B, attention on a falling-edge GPIO, vio from a
GPIO-controlled fixed regulator) with the touchscreen marked as a wakeup
source, every s2idle ended within 3 to 4 seconds with nobody touching the
phone, with one attention interrupt per suspend.

Keep the supplies on in system suspend when the device may wake the
system, as edt-ft5x06 does, and skip the matching re-enable and startup
delay on resume. A device that may not wake is powered down as before.

Tested on a OnePlus 6T on v7.4-rc3 with 'wakeup-source' on the
touchscreen node. With wakeup enabled and nothing touching the phone,
"rtcwake -m freeze -s 30" slept the full 30 seconds with no attention
interrupt (2 of 2), and a double-tap woke it (2 of 2, 120 second RTC
fallback). With wakeup disabled the supplies are cut as before and it
slept until the RTC (2 of 2).

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/input/rmi4/rmi_i2c.c | 22 +++++++++++++++-------
 1 file changed, 15 insertions(+), 7 deletions(-)

diff --git a/drivers/input/rmi4/rmi_i2c.c b/drivers/input/rmi4/rmi_i2c.c
index b0b36ddb27..315d203056 100644
--- a/drivers/input/rmi4/rmi_i2c.c
+++ b/drivers/input/rmi4/rmi_i2c.c
@@ -296,8 +296,14 @@ static int rmi_i2c_suspend(struct device *dev)
 	if (ret)
 		dev_warn(dev, "Failed to resume device: %d\n", ret);
 
-	regulator_bulk_disable(ARRAY_SIZE(rmi_i2c->supplies),
-			       rmi_i2c->supplies);
+	/*
+	 * A device that may wake the system has to stay powered: cutting its
+	 * supplies drops the attention line, which is a wake event of its own,
+	 * and leaves the controller unable to report a touch.
+	 */
+	if (!device_may_wakeup(dev))
+		regulator_bulk_disable(ARRAY_SIZE(rmi_i2c->supplies),
+				       rmi_i2c->supplies);
 
 	return ret;
 }
@@ -308,12 +314,14 @@ static int rmi_i2c_resume(struct device *dev)
 	struct rmi_i2c_xport *rmi_i2c = i2c_get_clientdata(client);
 	int ret;
 
-	ret = regulator_bulk_enable(ARRAY_SIZE(rmi_i2c->supplies),
-				    rmi_i2c->supplies);
-	if (ret)
-		return ret;
+	if (!device_may_wakeup(dev)) {
+		ret = regulator_bulk_enable(ARRAY_SIZE(rmi_i2c->supplies),
+					    rmi_i2c->supplies);
+		if (ret)
+			return ret;
 
-	msleep(rmi_i2c->startup_delay);
+		msleep(rmi_i2c->startup_delay);
+	}
 
 	ret = rmi_driver_resume(rmi_i2c->xport.rmi_dev, true);
 	if (ret)

-- 
2.47.3

