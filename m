From: Caspar Adriani <caspar.adriani@proton.me>
Date: Wed, 28 Oct 2026 15:05:41 +0100
Subject: [PATCH] media: amd: isp4: fix self-deadlock in
 isp4sd_start_stream() error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-isp4-start-stream-deadlock-v1-1-babd80273148@proton.me>
X-B4-Tracking: v=1; b=H4sIADQB4moC/yXMTQ6CQAxA4auQrm0CMwbEqxgWdaZq/QHSDsSEc
 HcH3Lzk27wFjFXY4FwsoDyLydBnVIcCwoP6O6PEbHClq6vSnVBsPKIl0pSrTB+MTPE9hBfWwXt
 qm+hd20AejMo3+e7zS/e3Tdcnh7QdYV1/FCsNcX4AAAA=
X-Change-ID: 20261028-isp4-start-stream-deadlock-6c33a97d3297
To: Bin Du <bin.du@amd.com>, Nirujogi Pratap <pratap.nirujogi@amd.com>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Benjamin Chan <Benjamin.Chan@amd.com>, King Li <King.Li@amd.com>, 
 Sultan Alsawaf <sultan@kerneltoast.com>, 
 Svetoslav Stoilov <Svetoslav.Stoilov@amd.com>, 
 Yifei Gao <gyf161023@gmail.com>, 
 Seifelden Abdelmonem <saif.elden.hatim@gmail.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Caspar Adriani <caspar.adriani@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793196385; l=4193;
 i=caspar.adriani@proton.me; s=20261028; h=from:subject:message-id;
 bh=Wpb8Myl41MGt4qqba1ihIdNcWGW2EqaKevO8Ep7ksRM=;
 b=bqMhtGPN1DmAUCg+oEEF0sAc5Qdp3/5Vtsb+TW6TWfV0LK1NrFyYsGEam0v0Jbb+UtCnbQCRu
 2KQX3yfy2+FCZ4kjFQmfv1nJz3/4VAfGwvXGZ/DZw/WIc7AOT89ldJA
X-Developer-Key: i=caspar.adriani@proton.me; a=ed25519;
 pk=cTxx5jb7r3X/atKU2VZ3+evuxnjAt/muekxKfcMI4Hc=
X-Endpoint-Received: by B4 Relay for caspar.adriani@proton.me/20261028 with auth_id=1344
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

isp4sd_start_stream() takes ops_mutex with guard() and, when
isp4sd_init_stream() or isp4sd_setup_output() fails, jumps to
err_stop_stream and calls isp4sd_stop_stream(). That function takes
ops_mutex again, so the task blocks on a mutex it already holds. Every
later open, close or ioctl on the device then blocks behind it, and
only a reboot recovers:

  INFO: task .v4l2-ctl-wrapp:38440 blocked for more than 122 seconds.
   isp4sd_stop_stream.isra.0+0x43/0x1d0 [amd_isp4_capture]
   isp4sd_enable_streams.cold+0x8b/0x26c [amd_isp4_capture]
   v4l2_subdev_enable_streams+0x1ff/0x360 [videodev]
   isp4vid_qops_start_streaming+0xf2/0x160 [amd_isp4_capture]
  INFO: task .v4l2-ctl-wrapp:38440 is blocked on a mutex likely owned
  by task .v4l2-ctl-wrapp:38440.

One way to reach the error path: start and stop a stream, then start
it again without setting the format. isp4sd_uninit_stream() clears the
subdev pad format on stop, so isp4sd_get_str_out_prop() fails on the
second start with "fail to get out prop" and "fail to setup output".

Move the body of isp4sd_stop_stream() into __isp4sd_stop_stream(),
which expects ops_mutex to be held, and call it from the error path.

Fixes: 4e5e7a7ddb4a ("media: platform: amd: isp4 subdev and firmware loading handling added")
Cc: stable@vger.kernel.org
Signed-off-by: Caspar Adriani <caspar.adriani@proton.me>
---
Tested on an ASUS ROG Flow Z13 (GZ302EA) on v7.3, with a local,
not-for-upstream change that adds its OMNI13B1 sensor to the ISP4 ACPI
tables so the capture device is created. The stock firmware does not
support that sensor, so no frames arrive, but the start and stop paths
run. Sequence: v4l2-ctl --set-fmt-video=1920x1080 NV12 --stream-mmap,
stopped after 10 s; the same without --set-fmt-video; then the first
command again.

Without this patch (v7.2.8, same setup) this failure hung the task as
shown above. With it, VIDIOC_STREAMON returns -EINVAL after "fail to
get out prop" / "fail to setup output", v4l2-ctl exits, no task is left
blocked, and the third run starts and stops the stream normally.
Not run: lockdep (CONFIG_PROVE_LOCKING is off in this kernel).
---
 drivers/media/platform/amd/isp4/isp4_subdev.c | 15 +++++++++++----
 1 file changed, 11 insertions(+), 4 deletions(-)

diff --git a/drivers/media/platform/amd/isp4/isp4_subdev.c b/drivers/media/platform/amd/isp4/isp4_subdev.c
index a108d90ace..08512f060a 100644
--- a/drivers/media/platform/amd/isp4/isp4_subdev.c
+++ b/drivers/media/platform/amd/isp4/isp4_subdev.c
@@ -745,15 +745,15 @@ int isp4sd_pwron_and_init(struct v4l2_subdev *sd)
 	return -EINVAL;
 }
 
-static int isp4sd_stop_stream(struct isp4_subdev *isp_subdev,
-			      struct v4l2_subdev_state *state, u32 pad)
+static void __isp4sd_stop_stream(struct isp4_subdev *isp_subdev,
+				 struct v4l2_subdev_state *state, u32 pad)
 {
 	struct isp4sd_sensor_info *sensor_info = &isp_subdev->sensor_info;
 	struct isp4sd_output_info *output_info = &sensor_info->output_info;
 	struct isp4_interface *ispif = &isp_subdev->ispif;
 	struct device *dev = isp_subdev->dev;
 
-	guard(mutex)(&isp_subdev->ops_mutex);
+	lockdep_assert_held(&isp_subdev->ops_mutex);
 	dev_dbg(dev, "status %i\n", output_info->start_status);
 
 	if (output_info->start_status == ISP4SD_START_STATUS_STARTED) {
@@ -786,6 +786,13 @@ static int isp4sd_stop_stream(struct isp4_subdev *isp_subdev,
 	}
 
 	isp4sd_uninit_stream(isp_subdev, state, pad);
+}
+
+static int isp4sd_stop_stream(struct isp4_subdev *isp_subdev,
+			      struct v4l2_subdev_state *state, u32 pad)
+{
+	guard(mutex)(&isp_subdev->ops_mutex);
+	__isp4sd_stop_stream(isp_subdev, state, pad);
 
 	/*
 	 * Return success to ensure the stop process proceeds,
@@ -836,7 +843,7 @@ static int isp4sd_start_stream(struct isp4_subdev *isp_subdev,
 	return 0;
 
 err_stop_stream:
-	isp4sd_stop_stream(isp_subdev, state, pad);
+	__isp4sd_stop_stream(isp_subdev, state, pad);
 	return ret;
 }
 

---
base-commit: 65ba8f34ec886ec72b2c07ddc8cf3d815c32869d
change-id: 20261028-isp4-start-stream-deadlock-6c33a97d3297

Best regards,
--  
Caspar Adriani <caspar.adriani@proton.me>

