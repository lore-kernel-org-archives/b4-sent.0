From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 17:13:41 +0100
Subject: [PATCH] Input: stmfts - restore touch after system resume with the
 device open
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-stmfts-suspend-v1-1-4b2276879e8d@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw7CIBRG4a00dyyJ4APSrRgHFn70mpQ2XGqaN
 OxdrMNvcM5GgswQ6ruNMj4sPKUGfejIvx7pCcWhmczRXLU2JyVljEWULDIjBWWddcEBF2/P1KI
 5I/K6D2/3v2UZ3vDld6FavwM1Ec9yAAAA
X-Change-ID: 20261123-stmfts-suspend-7878d8ee5c74
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Andi Shyti <andi@etezian.org>, 
 Javier Martinez Canillas <javier@osg.samsung.com>, 
 Rob Herring <robh@kernel.org>
Cc: linux-input@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4220; i=david@ixit.cz;
 h=from:subject:message-id; bh=KNVO9ZDo1+Slo3mWxKh9KjmPpUcwFZVYrPbAM4cSGMI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBGY6XvwXyLW5+kIbRTHAKomf2ED2Khb36UPFU
 nIUpt+8IgKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawRmOgAKCRBgAj/E00kg
 cqHcD/0YaboxDDIX4IJX0IJS7HjXYCpeKTG9ImVlZVgPd7KYZOSA+1O+I5R2IKme1wW99/g494r
 6yCnDHs3fbeKvCqm4+/c+Uf+M5neRHnNma/sGyhCCv92vs+YNm5Qll5VUX/+YpVZGFZ25vUuGMo
 SKpQme4EzmKEZ00d5X0Q9sFiYUOkY+urm2ES5nH4WZtFxWUOrhtjnhwOrvxhvy9p8yJP+D+wtTB
 5J1dyQUR6fLH3iU1SyQfFwYApf/LrgVBxcVTpdZSP7ooKwW8dHEK8JyV+PCcf7WfpvbahaJZpvr
 uuTH1AZE9agPQozA/DnOXIXn2aBkWsQXQANZXyid6kNnZr5czLQ6CumszDUMUKnOWFAB66cLVwh
 HPjxLj+DlI/RSRTicY9G5CdcbihJbCIm8JmwEaARXu4sCg4ihSMP9JgKlzLYRJvjZJc/GXLWO4O
 AP/JMG4PagRurlktcGf38Jyh9Uka+awCwLSZ/RJlzGZuhTMPjeud4pKqipGawbLlL3AATFL9NMz
 GcQSucx6Su8cx6wjzenfD6O/lRztccN85aFpTadwa/bFPioulXZni9op1MrEWnsOBh2AVZ5IOEH
 LaMOsJKUYEd11kGQv6SiOaZRcNnhxkd7CIG0oiSh7IZF1SUpzA+JzicY5VJnIQdsRjI8iyDxJvB
 hlrPWMmv5Yu3ZhQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

stmfts_resume() only calls stmfts_power_on(), which re-initialises the
controller and deliberately leaves it in SLEEP_IN, assuming nobody uses
the touchscreen yet. That assumption does not hold for a system resume:
userspace keeps the evdev node open, runtime PM still considers the
device active and stmfts_input_open() never runs again, so the
controller stays asleep with scanning off. On FTS5 the controller
interrupt enable command is part of the runtime resume sequence, so the
result is a completely dead touchscreen until the input device is
reopened.

Factor the scan enable part of stmfts_input_open() into
stmfts_start_scan() and, when the input device is open, replay the
runtime resume sequence and re-enable scanning from stmfts_resume().

Fixes: 78bcac7b2ae1 ("Input: add support for the STMicroelectronics FingerTip touchscreen")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 53 +++++++++++++++++++++++++++++++-------
 1 file changed, 43 insertions(+), 10 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 36beea6e6eb28..2054c2254947b 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -563,30 +563,23 @@ static int stmfts5_set_scan(struct stmfts_data *sdata, bool enable)
 	err = i2c_master_send(sdata->client, scan_mode_cmd,
 			      sizeof(scan_mode_cmd));
 	if (err != sizeof(scan_mode_cmd))
 		return err < 0 ? err : -EIO;
 
 	return 0;
 }
 
-static int stmfts_input_open(struct input_dev *dev)
+static int stmfts_start_scan(struct stmfts_data *sdata)
 {
-	struct stmfts_data *sdata = input_get_drvdata(dev);
 	int err;
 
-	err = pm_runtime_resume_and_get(&sdata->client->dev);
-	if (err)
-		return err;
-
 	err = sdata->ops->set_scan(sdata, true);
-	if (err) {
-		pm_runtime_put_sync(&sdata->client->dev);
+	if (err)
 		return err;
-	}
 
 	scoped_guard(mutex, &sdata->mutex) {
 		sdata->running = true;
 
 		if (sdata->hover_enabled && sdata->ops->set_hover) {
 			err = sdata->ops->set_hover(sdata, true);
 			if (err)
 				dev_warn(&sdata->client->dev,
@@ -601,16 +594,32 @@ static int stmfts_input_open(struct input_dev *dev)
 			/* I can still use only the touch screen */
 			dev_warn(&sdata->client->dev,
 				 "failed to enable touchkey\n");
 	}
 
 	return 0;
 }
 
+static int stmfts_input_open(struct input_dev *dev)
+{
+	struct stmfts_data *sdata = input_get_drvdata(dev);
+	int err;
+
+	err = pm_runtime_resume_and_get(&sdata->client->dev);
+	if (err)
+		return err;
+
+	err = stmfts_start_scan(sdata);
+	if (err)
+		pm_runtime_put_sync(&sdata->client->dev);
+
+	return err;
+}
+
 static void stmfts_input_close(struct input_dev *dev)
 {
 	struct stmfts_data *sdata = input_get_drvdata(dev);
 	int err;
 
 	err = sdata->ops->set_scan(sdata, false);
 	if (err)
 		dev_warn(&sdata->client->dev,
@@ -1163,18 +1172,42 @@ static int stmfts_suspend(struct device *dev)
 	stmfts_power_off(sdata);
 
 	return 0;
 }
 
 static int stmfts_resume(struct device *dev)
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
+	int err;
+
+	err = stmfts_power_on(sdata);
+	if (err)
+		return err;
+
+	/*
+	 * stmfts_power_on() leaves the controller in sleep mode. If the
+	 * input device is open, runtime PM still considers the device
+	 * active and will not wake it up again, so redo the runtime
+	 * resume sequence and re-enable scanning here.
+	 */
+	guard(mutex)(&sdata->input->mutex);
+
+	if (!input_device_enabled(sdata->input))
+		return 0;
+
+	err = stmfts_runtime_resume(dev);
+	if (err)
+		return err;
 
-	return stmfts_power_on(sdata);
+	err = stmfts_start_scan(sdata);
+	if (err)
+		return err;
+
+	return 0;
 }
 
 static const struct dev_pm_ops stmfts_pm_ops = {
 	SYSTEM_SLEEP_PM_OPS(stmfts_suspend, stmfts_resume)
 	RUNTIME_PM_OPS(stmfts_runtime_suspend, stmfts_runtime_resume, NULL)
 };
 
 static const struct stmfts_chip_ops stmfts4_ops = {

---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261123-stmfts-suspend-7878d8ee5c74

Best regards,
--  
David Heidelberg <david@ixit.cz>

