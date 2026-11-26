From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 06:18:44 +0000
Subject: [PATCH 6.12.y v2 4/4] virtio_balloon: quiesce balloon work before
 device shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-virtio-final-v2-4-4cfd5590e924@certik.com>
References: <20261126-virtio-final-v2-0-4cfd5590e924@certik.com>
In-Reply-To: <20261126-virtio-final-v2-0-4cfd5590e924@certik.com>
To: stable@vger.kernel.org
Cc: "Michael S. Tsirkin" <mst@redhat.com>, 
 "Denis V. Lunev" <den@openvz.org>, David Hildenbrand <david@kernel.org>, 
 Eric Auger <eric.auger@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 virtualization@lists.linux.dev
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795673921; l=3090;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=YxT0JEcZt8be1Aod6X8plRSlx7+82SPoYFncZ9ti8IE=;
 b=UgO1apl0z0LJE8kVRiZ9zir503rVvLFWs8V6CuuHmaeib+SvAPyv1AFZA3rdymu7RxtiqSiJP
 xs6LPUIMkX8Au/Y6X6+61gROyuFmnawCJvKoLCtaPjsnOkTdwaQZdUe
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Denis V. Lunev" <den@openvz.org>

commit 7e17eef04600c399c7e0f5ce765da5cf9d40d8e1 upstream.

Commit 8bd2fa086a04 ("virtio: break and reset virtio devices on
device_shutdown()") added a generic virtio bus .shutdown handler that
breaks and resets every virtio device during device_shutdown(), i.e. on
reboot and kexec.

virtio_balloon provides no .shutdown of its own, so that generic path
runs while the balloon's asynchronous work is still armed. Once the
device has been broken, virtqueue_add_inbuf() in
virtballoon_free_page_report() returns -EIO and trips its
WARN_ON_ONCE(). On a kernel booted with panic_on_warn that turns an
ordinary reboot, for example a kexec based upgrade, into a fatal panic
in the middle of device_shutdown(), so the machine never reaches the
new kernel.

Relaxing that single WARN_ON_ONCE() would only hide the symptom: the
inflate/deflate and OOM paths do not warn, they call
wait_event(vb->acked, ...) and would instead block forever on a broken
queue that can no longer complete. The device has to be quiesced, not
just kept quiet.

Add a .shutdown handler that quiesces the balloon via the shared
virtballoon_quiesce() helper while the device is still alive, and only
then breaks and resets it via virtio_device_shutdown(). Unlike
virtballoon_remove() the balloon workqueue is not destroyed, as shutdown
does not free the device and cancel_work_sync() together with stop_update
already prevent any further work from being queued.

Fixes: 8bd2fa086a04 ("virtio: break and reset virtio devices on device_shutdown()")
Signed-off-by: Denis V. Lunev <den@openvz.org>
Reviewed-by: David Hildenbrand (Arm) <david@kernel.org>
Signed-off-by: Michael S. Tsirkin <mst@redhat.com>
Message-ID: <20260624140846.2616797-4-den@openvz.org>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 drivers/virtio/virtio_balloon.c |    7 +++++++
 1 file changed, 7 insertions(+)

Changes in v2
v2: resent through a whitespace-safe path; v1 <CAFaZ9epp-Y8efod8a7CQuQqYEjk5L_ruwP+c1SoBRPjdu9uGyQ@mail.gmail.com> was damaged by my mail client and does not apply.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

diff --git a/drivers/virtio/virtio_balloon.c b/drivers/virtio/virtio_balloon.c
index 726aef5be178..efa77daa93b8 100644
--- a/drivers/virtio/virtio_balloon.c
+++ b/drivers/virtio/virtio_balloon.c
@@ -1159,6 +1159,12 @@ static void virtballoon_remove(struct virtio_device *vdev)
 	kfree(vb);
 }
 
+static void virtballoon_shutdown(struct virtio_device *vdev)
+{
+	virtballoon_quiesce(vdev->priv);
+	virtio_device_shutdown(vdev);
+}
+
 #ifdef CONFIG_PM_SLEEP
 static int virtballoon_freeze(struct virtio_device *vdev)
 {
@@ -1229,6 +1235,7 @@ static struct virtio_driver virtio_balloon_driver = {
 	.validate =	virtballoon_validate,
 	.probe =	virtballoon_probe,
 	.remove =	virtballoon_remove,
+	.shutdown =	virtballoon_shutdown,
 	.config_changed = virtballoon_changed,
 #ifdef CONFIG_PM_SLEEP
 	.freeze	=	virtballoon_freeze,

