From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 06:18:42 +0000
Subject: [PATCH 6.12.y v2 2/4] virtio: add virtio_device_shutdown() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-virtio-final-v2-2-4cfd5590e924@certik.com>
References: <20261126-virtio-final-v2-0-4cfd5590e924@certik.com>
In-Reply-To: <20261126-virtio-final-v2-0-4cfd5590e924@certik.com>
To: stable@vger.kernel.org
Cc: "Michael S. Tsirkin" <mst@redhat.com>, 
 "Denis V. Lunev" <den@openvz.org>, David Hildenbrand <david@kernel.org>, 
 Eric Auger <eric.auger@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 virtualization@lists.linux.dev
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795673921; l=3867;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=IcRCbKCQ8/HNKH9FULxInqnnyB/eMIUHgoJ8eusL0Kw=;
 b=rC4KBoBX5N4hV6jb97hQRvcrTjezt/PyFAPDtSODnOGqv9FIRQiL0SD9YvMyJMo96S/9bIy8C
 BwLoujBMBLNCRIHaEa6khzswu6ngAVE3A9X/DDbaWL2A/LHfjRR6RS0
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Denis V. Lunev" <den@openvz.org>

commit 0d8aebe089b4ba887e792884cf041ce9f1040ff4 upstream.

The generic virtio bus .shutdown handler, virtio_dev_shutdown(), breaks
and resets a device once it has established that the driver has no
.shutdown of its own. A driver that does implement .shutdown, to quiesce
its own activity first, still needs the same break and reset afterwards
and would otherwise have to open code it.

Factor the break + synchronize_cbs + reset sequence out of
virtio_dev_shutdown() into an exported virtio_device_shutdown() helper so
such drivers can reuse it instead of duplicating the core logic.

No functional change.

Signed-off-by: Denis V. Lunev <den@openvz.org>
Reviewed-by: David Hildenbrand (Arm) <david@kernel.org>
Signed-off-by: Michael S. Tsirkin <mst@redhat.com>
Message-ID: <20260624140846.2616797-2-den@openvz.org>
[ adapted to 6.12: no virtio_irq_get_affinity(), put the helper above virtio_dev_shutdown() ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 drivers/virtio/virtio.c |   41 +++++++++++++++++++++++++++--------------
 include/linux/virtio.h  |    1 +
 2 files changed, 28 insertions(+), 14 deletions(-)

Changes in v2
v2: resent through a whitespace-safe path; v1 <CAFaZ9eovUow4CR0U-iaUtFHbvf2Dk97Vs6hz6hZWh747R6Xr-Q@mail.gmail.com> was damaged by my mail client and does not apply.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

diff --git a/drivers/virtio/virtio.c b/drivers/virtio/virtio.c
index 8241024f0890..f70ae3a672f7 100644
--- a/drivers/virtio/virtio.c
+++ b/drivers/virtio/virtio.c
@@ -379,6 +379,32 @@ static void virtio_dev_remove(struct device *_d)
 	of_node_put(dev->dev.of_node);
 }
 
+/**
+ * virtio_device_shutdown - break and reset a device on shutdown
+ * @dev: the device
+ *
+ * Drivers with their own .shutdown method should quiesce their activity and
+ * then call this to stop the device the way the generic shutdown path does.
+ */
+void virtio_device_shutdown(struct virtio_device *dev)
+{
+	/*
+	 * Some devices get wedged if you kick them after they are
+	 * reset. Mark all vqs as broken to make sure we don't.
+	 */
+	virtio_break_device(dev);
+	/*
+	 * Guarantee that any callback will see vq->broken as true.
+	 */
+	virtio_synchronize_cbs(dev);
+	/*
+	 * As IOMMUs are reset on shutdown, this will block device access to memory.
+	 * Some devices get wedged if this happens, so reset to make sure it does not.
+	 */
+	dev->config->reset(dev);
+}
+EXPORT_SYMBOL_GPL(virtio_device_shutdown);
+
 static void virtio_dev_shutdown(struct device *_d)
 {
 	struct virtio_device *dev = dev_to_virtio(_d);
@@ -397,20 +423,7 @@ static void virtio_dev_shutdown(struct device *_d)
 		return;
 	}
 
-	/*
-	 * Some devices get wedged if you kick them after they are
-	 * reset. Mark all vqs as broken to make sure we don't.
-	 */
-	virtio_break_device(dev);
-	/*
-	 * Guarantee that any callback will see vq->broken as true.
-	 */
-	virtio_synchronize_cbs(dev);
-	/*
-	 * As IOMMUs are reset on shutdown, this will block device access to memory.
-	 * Some devices get wedged if this happens, so reset to make sure it does not.
-	 */
-	dev->config->reset(dev);
+	virtio_device_shutdown(dev);
 }
 
 static const struct bus_type virtio_bus = {
diff --git a/include/linux/virtio.h b/include/linux/virtio.h
index 2759e2c24d6e..2d8820c0832a 100644
--- a/include/linux/virtio.h
+++ b/include/linux/virtio.h
@@ -180,6 +180,7 @@ int virtio_device_freeze(struct virtio_device *dev);
 int virtio_device_restore(struct virtio_device *dev);
 #endif
 void virtio_reset_device(struct virtio_device *dev);
+void virtio_device_shutdown(struct virtio_device *dev);
 
 size_t virtio_max_dma_size(const struct virtio_device *vdev);
 

