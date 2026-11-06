From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Fri, 06 Nov 2026 12:04:56 +0300
Subject: [PATCH] media: verisilicon: suspend the device before
 unregistering it on remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-hantro-remove-v1-1-d0a4678886d7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7TlAPgn0lOqittYc01ohA/HvSc
 QZmGlRkwgqzaMD4UKWSB+hJQDx83lHSNhiMMlZrZeWQNxfJeJYHpfMpRBes0snBaC7GRO//W9b
 eP1YuNu9fAAAA
X-Change-ID: 20261106-hantro-remove-9afbc9b601f9
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Frank Li <Frank.Li@nxp.com>, Tharit Tangkijwanichakul <tharitt97@gmail.com>, 
 linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793955898; l=3507;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=xS7oIoyimsaMRzqUpXTDBfcEIedzp94Ticoi5FpW/N4=;
 b=UveIQ1ueDQ9B30eFN2EHpuRf6itGbRtnVmhgM4utBXIjk1hHI0f0mylWYoYHySNVftCf9fxIi
 JL/Cv/6DmByCniakqQ9eDo0+UfNchjMmlWUmP1CQB8cNP+9XSUhhTR4
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clocks are enabled and disabled by the runtime PM callbacks.
hantro_remove() calls v4l2_device_unregister() and clk_bulk_unprepare()
first and only then pm_runtime_dont_use_autosuspend(), which suspends
an active device right away. By then v4l2_device_unregister() has
cleared the driver data (it points to the v4l2_device, the first member
of struct hantro_dev), so hantro_runtime_suspend() dereferences NULL.

The device is always active at that point: the driver core resumes it
before calling remove(), and its put only starts the 100 ms autosuspend
timer. So every unbind and every module unload, with or without a
decode before it, gives an "Unpreparing enabled" warning for each clock
and then that oops.

Stop runtime PM before the unregister and the unprepare. If runtime PM
is forbidden through sysfs (power/control set to "on"), the device is
still active after that, so disable its clocks and mark it suspended by
hand.

The probe error path unwinds in the same order. It can only hit this if
a job runs between the encoder node registration and a later probe
failure, so it is left for a follow-up.

Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board (G1, ID 0x6731); the assistant also drafted this
change. Tested on that board. Without this change, unloading the idle
module (runtime status "suspended") gives the warnings and the oops.
With it, the idle module unloads with no warning or oops, and so it does
right after an H.264 or VP8 decode with the autosuspend delay raised to
10 s through sysfs; the clock enable and prepare counts are back to
their values before the load. The same holds with power/control set to
"on", over three load, decode and unload cycles on one boot. kmemleak
reports nothing after five load, decode and unload cycles. Built with
W=1 with and without CONFIG_PM. Not tested on other SoCs or with a
power domain.

Fixes: 556ab0b2741d ("media: hantro: release runtime resources when device_run fails")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..8af47375d471 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -1286,10 +1286,16 @@ static void hantro_remove(struct platform_device *pdev)
 	hantro_remove_enc_func(vpu);
 	media_device_cleanup(&vpu->mdev);
 	v4l2_m2m_put(vpu->m2m_dev);
-	v4l2_device_unregister(&vpu->v4l2_dev);
-	clk_bulk_unprepare(vpu->variant->num_clocks, vpu->clocks);
+	/* Suspend first: v4l2_device_unregister() clears the driver data. */
 	pm_runtime_dont_use_autosuspend(vpu->dev);
 	pm_runtime_disable(vpu->dev);
+	/* Runtime PM forbidden through sysfs: the device is still active. */
+	if (IS_ENABLED(CONFIG_PM) && !pm_runtime_status_suspended(vpu->dev)) {
+		clk_bulk_disable(vpu->variant->num_clocks, vpu->clocks);
+		pm_runtime_set_suspended(vpu->dev);
+	}
+	v4l2_device_unregister(&vpu->v4l2_dev);
+	clk_bulk_unprepare(vpu->variant->num_clocks, vpu->clocks);
 	reset_control_assert(vpu->resets);
 }
 

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261106-hantro-remove-9afbc9b601f9

Best regards,
-- 
Sergei Khomenkov <shomenkow@gmail.com>

