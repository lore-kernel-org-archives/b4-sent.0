From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 22:26:47 +0200
Subject: [PATCH v2] Input: s6sy761 - fix resume ordering and restore
 sensing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-s6sy761-suspend-v2-1-8f00a96ee6e8@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0JmbU1bsRVX3sOwoGUq4wJIpxCQc
 HcB1y5f8v77CzBGQoZ7tkDEkZi6dgN9ysA3VftCQfXGoKU2stAXwYZna5TggXtsa6FzY3Mnb1f
 rKthWfcRA01F8lj/mwb3Rpz2zGw1x6uJ8XI5q9/7XRyWUMCGEwqBV3skHTZTO/gPluq5fbIySR
 74AAAA=
X-Change-ID: 20260923-s6sy761-suspend-24674b0857ba
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Andi Shyti <andi@etezian.org>, Rob Herring <robh@kernel.org>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, stable@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2550; i=david@ixit.cz;
 h=from:subject:message-id; bh=zam6eeZKJN3iy7FLZYqEzX+RoG2h8gfBIV6S+jPTMYo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBquCqItB6OXXeLTO07zF/aNObgie6pXfvp/zXcC
 zuQCrStHxWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCargqiAAKCRBgAj/E00kg
 cqI3D/wKUm1IG782wR+Rk+uc2OaP3CIfhd1+ZBDvW0FB5RqTvXHF+TquSmHjSF57RxvHre05s73
 +gRed7O8MXuFKQ8mHiBghTNJQTlxgha2mPm65bIpVERb05naperVRvgdXszbkei0AAZPdWyb8x7
 WfFaXEt7vDoK0TdpYmoPADBk029kj5sIwSoIf2C9dywTp2127bAjgDG/rBBiL6ayAY5SKTBHsS8
 Vo2giTI2IMUmb8QkCvy5yy2ALez1TmCVwngHWKlnRtRR4k8zPGmckUtqR4aC23iJ/jKJ6eIuH2G
 eTc4ZKAJDgI+KuufStFcNtfPueBsjXxzngZj6Zj6VEN4nFu/WGBjo1AWbdxdPNMmXsMl8L5VsTS
 Ys1A6FmRkUDBH4mFbpiHBE1wTBiS4m48xhyfYPy7Bbl1BGK1RrZV/Yo1yAZ1Kcu5tkt0qqFZb/P
 NZMk5GL7c+y6A0ztmVoHIEBdIz1hZ9SW1aKQZxHnmfOjgfzOCgXui1kK9fYGLjzdrCQVlc18Y/8
 KvwzxPpnKfuC9OL4leGUQS+pH0mrK+FOldq1v5SSJdopODAY2obzKk+HckeKhPwFY/xyaeyvfPx
 nlD6AS8pPHw+EB1U4mMPIWFFAzBlwi509DheTMtkmqgX3cXudm6B1Jf2g25164nnZVHEeP9xZQ3
 gfnKKYF9czjMEfA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

System suspend powers the controller off and resume powers it back on,
but the resume path enables the interrupt before s6sy761_power_on()
checks the boot. The firmware raises its boot-complete event on the
interrupt line, the threaded handler consumes it, s6sy761_power_on()
then reads an empty event and resume fails with -ENODEV, skipping the
touch function setup:

s6sy761 2-0048: PM: dpm_run_callback(): s6sy761_resume [s6sy761] returns -19

Power the chip on first and only then unmask the interrupt. Once resume
completes the boot handshake the chip comes back with sensing off, as
at probe where input_open() turns it on, so the touchscreen stays dead
after resume. Send SENSE_ON again when the input device is open.

Tested on a Pixel 3 XL over several s2idle cycles: resume succeeds and
the touch function and sense status match the pre-suspend state.

Assisted-by: LLM
Cc: stable@vger.kernel.org
Fixes: 0145a7141e59 ("Input: add support for the Samsung S6SY761 touchscreen")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Explicit return err in _resume. (Dmitry)
- Do not enable interrupt when power on fails. (Dmitry)
- Link to v1: https://patch.msgid.link/20260923-s6sy761-suspend-v1-1-6fff96e71cb0@ixit.cz
---
 drivers/input/touchscreen/s6sy761.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/s6sy761.c b/drivers/input/touchscreen/s6sy761.c
index 0f24a9b730635..899c179fb2d31 100644
--- a/drivers/input/touchscreen/s6sy761.c
+++ b/drivers/input/touchscreen/s6sy761.c
@@ -495,20 +495,32 @@ static int s6sy761_suspend(struct device *dev)
 	s6sy761_power_off(sdata);
 
 	return 0;
 }
 
 static int s6sy761_resume(struct device *dev)
 {
 	struct s6sy761_data *sdata = dev_get_drvdata(dev);
+	int err;
+
+	err = s6sy761_power_on(sdata);
+	if (err)
+		return err;
 
 	enable_irq(sdata->client->irq);
 
-	return s6sy761_power_on(sdata);
+	guard(mutex)(&sdata->input->mutex);
+
+	if (!input_device_enabled(sdata->input))
+		return 0;
+
+	err = i2c_smbus_write_byte(sdata->client, S6SY761_SENSE_ON);
+
+	return err;
 }
 
 static const struct dev_pm_ops s6sy761_pm_ops = {
 	SYSTEM_SLEEP_PM_OPS(s6sy761_suspend, s6sy761_resume)
 	RUNTIME_PM_OPS(s6sy761_runtime_suspend, s6sy761_runtime_resume, NULL)
 };
 
 #ifdef CONFIG_OF

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260923-s6sy761-suspend-24674b0857ba

Best regards,
--  
David Heidelberg <david@ixit.cz>

