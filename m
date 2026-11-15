From: yzddMr6 <yzddmr6@gmail.com>
Date: Sun, 15 Nov 2026 21:12:57 +0800
Subject: [PATCH] ASoC: qcom: q6dsp-lpass-clocks: Set driver data before
 registering clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-upstream-q6dsp-clk-drvdata-v1-1-4d7dbea52e52@gmail.com>
X-B4-Tracking: v=1; b=H4sIANiv+WoC/zXMyw6CMBCF4Vchs3aUVgLiqxgXvQxSL4Az0JgQ3
 t2CcfmfnHwzCHEggXM2A1MMEvouhdpl4FrT3QiDTw0616VSqsBpkJHJvPBdehnQPR/oOXozGqS
 89rpq9Km2R0jAwNSEz4Zfrr+Wyd7Jjau4PqwRQsumc+06/e3DtsdqXyA7DcvyBbn5X9OnAAAA
X-Change-ID: 20261114-upstream-q6dsp-clk-drvdata-e09d27f289b3
To: Srinivas Kandagatla <srini@kernel.org>, Mark Brown <broonie@kernel.org>
Cc: Liam Girdwood <lgirdwood@gmail.com>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, linux-sound@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, yzddMr6 <yzddmr6@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794748380; l=4515;
 i=yzddmr6@gmail.com; s=20261028; h=from:subject:message-id;
 bh=IhpdDzjG8SfUTWw69Q02/8xD6GDVJahHeSuoz5N6di4=;
 b=1VjHJ+3hckZdc0O+FuL60XGYogx0ZxwJhD+VOXHMKTe3EPdoyEnpqTWiIqO8cOPhscKIRQjan
 UBcaxw7PFcQAtzV+3B+D6bnxJHIYHcKVusuuFUHGEN5vOJxUKkfxkEN
X-Developer-Key: i=yzddmr6@gmail.com; a=ed25519;
 pk=QLT2mwairk4R38oU379hkHynqjoLrlqd0Cl1ERUqIqY=
X-Endpoint-Received: by B4 Relay for yzddmr6@gmail.com/20261028 with auth_id=1489
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clk ops of the q6dsp clock controller look up struct q6dsp_cc with
dev_get_drvdata(), but q6dsp_clock_dev_probe() sets the driver data only
after it has registered the clocks and added the OF clock provider. A
consumer that gets and prepares one of the clocks in between
dereferences a NULL pointer.

fw_devlink does not keep consumers out of that window. The q6prm and
q6afe clock controllers are described below the ADSP remoteproc node,
and their devices are only created once the ADSP has booted and its
GPR/APR services have come up, long after the remoteproc device has
bound. fw_devlink therefore makes the remoteproc device the supplier of
their consumers. A consumer such as the LPASS LPI pinctrl then just
defers until of_clk_get() succeeds, and its retry from the deferred
probe worker can run while the clock controller is still in its probe.

That happened once on a Xiaomi Pad 8 Pro (SM8750). While the LPI pinctrl
probe registered its GPIO chip, gpiolib read a GPIO direction, which
runtime resumed the device and prepared its q6prm vote clocks through
pm_clk. The prepare op then faulted with a NULL pointer dereference at
virtual address 0x350 (trimmed):

  pc : clk_vote_q6dsp_block+0x24/0x58 [snd_q6dsp_common]
  lr : clk_core_prepare+0x7c/0x298
  Call trace:
   clk_vote_q6dsp_block+0x24/0x58 [snd_q6dsp_common] (P)
   clk_core_prepare+0x7c/0x298
   clk_prepare+0x28/0x44
   pm_clk_resume+0x10c/0x188
   pm_generic_runtime_resume+0x2c/0x44
   ...
   __pm_runtime_resume+0x50/0x94
   ...
   lpi_gpio_get_direction+0x4c/0x8c [pinctrl_lpass_lpi]
   gpiochip_add_data_with_key+0x7b0/0x10dc
   devm_gpiochip_add_data_with_key+0x38/0x8c
   lpi_pinctrl_probe+0x2b8/0x320 [pinctrl_lpass_lpi]
   ...
   deferred_probe_work_func+0x88/0xc0

0x350 is the offset of desc in struct q6dsp_cc; the driver data pointer
it was loaded from was NULL. The oops left the clk prepare_lock held,
which blocks every later clk_prepare(), and the system did not finish
booting.

On mainline the window is short, but it includes a wait for prepare_lock
in clk_core_reparent_orphans(), which of_clk_add_hw_provider() calls
right after listing the provider. The kernel that hit this had
out-of-tree changes to drivers/clk/clk.c that do more work at that
point, which makes the window wider.

Both q6afe-clocks and q6prm-clocks use q6dsp_clock_dev_probe(). Set the
driver data before the first clock is registered.

The oops was analysed and the fix written with the help of an AI coding
assistant.

Fixes: 9ab71ac37240 ("ASoC: qdsp6: q6afe-clocks: move audio-clocks to common file")
Cc: stable@vger.kernel.org
Signed-off-by: yzddMr6 <yzddmr6@gmail.com>
---
The kernel that hit this was v7.4-rc2 with out-of-tree board support and
other changes, including the clk.c changes mentioned above. The oops
showed up once in the 23 boots of that kernel I have logs for, and I
have not been able to reproduce it on demand. The patch is build-tested
(arm64 defconfig, W=1) on the base commit below.

I used an AI coding assistant for this work. It analysed the oops,
traced the probe ordering and drafted this patch and changelog. I have
reviewed the change.
---
 sound/soc/qcom/qdsp6/q6dsp-lpass-clocks.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/sound/soc/qcom/qdsp6/q6dsp-lpass-clocks.c b/sound/soc/qcom/qdsp6/q6dsp-lpass-clocks.c
index 94d96130245e..c3628f90fdb2 100644
--- a/sound/soc/qcom/qdsp6/q6dsp-lpass-clocks.c
+++ b/sound/soc/qcom/qdsp6/q6dsp-lpass-clocks.c
@@ -146,6 +146,12 @@ int q6dsp_clock_dev_probe(struct platform_device *pdev)
 	cc->dev = dev;
 	q6dsp_clks = desc->clks;
 
+	/*
+	 * The clk ops look up cc through the driver data, so set it before
+	 * any of the clocks can be prepared.
+	 */
+	dev_set_drvdata(dev, cc);
+
 	for (i = 0; i < desc->num_clks; i++) {
 		unsigned int id = q6dsp_clks[i].clk_id;
 		struct clk_init_data init = {
@@ -174,12 +180,6 @@ int q6dsp_clock_dev_probe(struct platform_device *pdev)
 			return ret;
 	}
 
-	ret = devm_of_clk_add_hw_provider(dev, q6dsp_of_clk_hw_get, cc);
-	if (ret)
-		return ret;
-
-	dev_set_drvdata(dev, cc);
-
-	return 0;
+	return devm_of_clk_add_hw_provider(dev, q6dsp_of_clk_hw_get, cc);
 }
 EXPORT_SYMBOL_GPL(q6dsp_clock_dev_probe);

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261114-upstream-q6dsp-clk-drvdata-e09d27f289b3

Best regards,
--  
yzddMr6 <yzddmr6@gmail.com>

