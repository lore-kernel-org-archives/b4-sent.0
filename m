From: Dave Airlie <airlied@redhat.com>
Date: Tue, 24 Nov 2026 15:50:02 +1000
Subject: [PATCH v3 1/2] drm/nouveau: add option to leave GSP-capable GPUs
 to other drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-nova-nouveau-gsp-v3-1-e1440479ded6@redhat.com>
References: <20261124-nova-nouveau-gsp-v3-0-e1440479ded6@redhat.com>
In-Reply-To: <20261124-nova-nouveau-gsp-v3-0-e1440479ded6@redhat.com>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=9632; i=airlied@redhat.com;
 h=from:subject:message-id; bh=0MtPXBWLiOMLBzUoc9IAaznSPBKyhIWsf41ES/eP2j4=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBrBSWSdvR+rZuOx71GAfHJqvBB6SFXDKm1Jh7+D
 rkq7aMZY4mJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCawUlkgAKCRAMdPNZecSG
 vpn5EACBGYhJE9OsM7Si25pdcQ2V8umg4TrzI/zvEGICtgjZzgkdvaCt3GgRT0eLssSwWyDuogr
 daCrIiWirWBGGX59bYMLnQsgm1mdqpsHVstgST624xbu2Vmv7d+YGq6JKcba/AtXQl5qnh58XJV
 ICe0dV2ufnGZq6k8D2TskaSDSxYqOqT7g875YfDnVXcXC/bcDqJ+GrqMBh+DD2RxfwpNWXHP9dF
 GHW/mLVJ8yuUX+a2vHhpxGL9eZsuFXsEk8S0BBTTI7UUR8MbUd/go3UIAiHfugRF67XNKjtcZK2
 kDbk9KVh0cj3xtyZ9LvlYEN+S+LAsGHqn1jzbQ3dJcY9Q6TcRxFTyIkXUqALDvobNLEtHW8gvnc
 GxMAoNfbeJ66DEi1UB+iADtJgOImhbYO9dcI6YHbWCAWlLxrmVQzz3UAGfubfnvEv4OucCaYncp
 E4F+ujLrYmnJC8csf5BkaGOBQjvWtKSAzYB47OVgI2zMvbJqLErMN6qZ6+1wMq+YO6tjjgQLuLa
 YM7dTe6cJCEAdsXBwIRGTuQKIkZ6q2DeVw5Fh6VmkoIJ5ZpAM0qY6jrKwVUbZcfEX6YVuJiYCRS
 ASQCxLfx2OAgnFyCQzllA/1+EB3SEhd+KjzzGAID2tegxFzcAEjPC5DPOqpD/YUFnbGIcnDYD2r
 0i3TkS/qLeskTSg==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nouveau currently binds to every NVIDIA GPU it encounters. The
nova-core driver is being written for GSP-capable (Turing and later)
GPUs, so the two drivers compete for the same devices, with whichever
registers first winning.

Add the DRM_NOUVEAU_BIND_GSP Kconfig option (default y) and a bind_gsp
module parameter, defaulting to the Kconfig value and able to override
it in both directions, controlling whether nouveau claims GSP-capable
GPUs.

This fixes a bunch some bugs in the ctor failure paths to ensure
clean teardown if the device isn't bound.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/nouveau/Kconfig                   | 17 ++++++
 drivers/gpu/drm/nouveau/include/nvkm/core/pci.h   |  6 +-
 drivers/gpu/drm/nouveau/nouveau_drm.c             |  9 ++-
 drivers/gpu/drm/nouveau/nvkm/engine/device/base.c | 67 ++++++++++++++++++-----
 drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c  | 11 +++-
 5 files changed, 91 insertions(+), 19 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/Kconfig b/drivers/gpu/drm/nouveau/Kconfig
index 3b5757aed9c8..45e217cc8ec3 100644
--- a/drivers/gpu/drm/nouveau/Kconfig
+++ b/drivers/gpu/drm/nouveau/Kconfig
@@ -120,3 +120,20 @@ config DRM_NOUVEAU_SIL164
 	help
 	  Support for sil164 and similar single-link (or dual-link
 	  when used in pairs) TMDS transmitters.
+
+config DRM_NOUVEAU_BIND_GSP
+	bool "Make nouveau the default driver for GSP-capable GPUs"
+	depends on DRM_NOUVEAU
+	default y
+	help
+	  Make nouveau bind to all NVIDIA GPUs by default, as it always
+	  has.
+
+	  If another NVIDIA driver, such as nova-core, should claim the
+	  GSP-capable (Turing and later) GPUs instead, say N here; nouveau
+	  then leaves those GPUs alone and continues to bind to pre-Turing
+	  GPUs itself. nouveau can also be prevented from binding to
+	  GSP-capable GPUs at boot with nouveau.bind_gsp=0 on the kernel
+	  command line.
+
+	  If unsure, say Y.
diff --git a/drivers/gpu/drm/nouveau/include/nvkm/core/pci.h b/drivers/gpu/drm/nouveau/include/nvkm/core/pci.h
index 7444c4d59e09..4ba9313a736b 100644
--- a/drivers/gpu/drm/nouveau/include/nvkm/core/pci.h
+++ b/drivers/gpu/drm/nouveau/include/nvkm/core/pci.h
@@ -7,8 +7,12 @@ struct nvkm_device_pci {
 	struct nvkm_device device;
 	struct pci_dev *pdev;
 	bool suspend;
+	/* GSP-capable (Turing and later) GPUs may be bound; mirrors the
+	 * bind_gsp module parameter.
+	 */
+	bool bind_gsp;
 };
 
 int nvkm_device_pci_new(struct pci_dev *, const char *cfg, const char *dbg,
-			struct nvkm_device **);
+			bool bind_gsp, struct nvkm_device **);
 #endif
diff --git a/drivers/gpu/drm/nouveau/nouveau_drm.c b/drivers/gpu/drm/nouveau/nouveau_drm.c
index 5e1336615cf6..582eb0c91b10 100644
--- a/drivers/gpu/drm/nouveau/nouveau_drm.c
+++ b/drivers/gpu/drm/nouveau/nouveau_drm.c
@@ -112,6 +112,11 @@ MODULE_PARM_DESC(runpm, "disable (0), force enable (1), optimus only default (-1
 static int nouveau_runtime_pm = -1;
 module_param_named(runpm, nouveau_runtime_pm, int, 0400);
 
+MODULE_PARM_DESC(bind_gsp, "bind to GSP-capable (Turing and later) GPUs "
+		 "(0 = leave them to other drivers, e.g. nova)");
+static bool nouveau_bind_gsp = IS_ENABLED(CONFIG_DRM_NOUVEAU_BIND_GSP);
+module_param_named(bind_gsp, nouveau_bind_gsp, bool, 0400);
+
 static const struct drm_driver driver_legacy_kms;
 static const struct drm_driver driver_atomic_kms;
 
@@ -881,7 +886,8 @@ static int nouveau_drm_probe(struct pci_dev *pdev,
 	/* We need to check that the chipset is supported before booting
 	 * fbdev off the hardware, as there's no way to put it back.
 	 */
-	ret = nvkm_device_pci_new(pdev, nouveau_config, nouveau_debug, &device);
+	ret = nvkm_device_pci_new(pdev, nouveau_config, nouveau_debug,
+				  nouveau_bind_gsp, &device);
 	if (ret)
 		return ret;
 
@@ -1460,6 +1466,7 @@ static void nouveau_display_options(void)
 	DRM_DEBUG_DRIVER("... runpm        : %d\n", nouveau_runtime_pm);
 	DRM_DEBUG_DRIVER("... vram_pushbuf : %d\n", nouveau_vram_pushbuf);
 	DRM_DEBUG_DRIVER("... hdmimhz      : %d\n", nouveau_hdmimhz);
+	DRM_DEBUG_DRIVER("... bind_gsp      : %d\n", nouveau_bind_gsp);
 }
 
 static const struct dev_pm_ops nouveau_pm_ops = {
diff --git a/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c b/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c
index a2ed8c4fe52a..9d8e82781a25 100644
--- a/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c
+++ b/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c
@@ -25,6 +25,7 @@
 #include "acpi.h"
 
 #include <core/option.h>
+#include <core/pci.h>
 
 #include <subdev/bios.h>
 #include <subdev/therm.h>
@@ -3081,22 +3082,37 @@ nvkm_device_init(struct nvkm_device *device)
 	return ret;
 }
 
+/* Release the state constructed by nvkm_device_ctor(), apart from the
+ * resources owned by the caller (bus-specific state and the container
+ * allocation).
+ *
+ * Must be called with nv_devices_mutex held.
+ */
+static void
+nvkm_device_dtor(struct nvkm_device *device)
+{
+	struct nvkm_subdev *subdev, *tmp;
+
+	nvkm_intr_dtor(device);
+
+	list_for_each_entry_safe_reverse(subdev, tmp, &device->subdev, head)
+		nvkm_subdev_del(&subdev);
+
+	if (device->pri)
+		iounmap(device->pri);
+
+	list_del(&device->head);
+}
+
 void
 nvkm_device_del(struct nvkm_device **pdevice)
 {
 	struct nvkm_device *device = *pdevice;
-	struct nvkm_subdev *subdev, *subtmp;
+
 	if (device) {
 		mutex_lock(&nv_devices_mutex);
 
-		nvkm_intr_dtor(device);
-
-		list_for_each_entry_safe_reverse(subdev, subtmp, &device->subdev, head)
-			nvkm_subdev_del(&subdev);
-
-		if (device->pri)
-			iounmap(device->pri);
-		list_del(&device->head);
+		nvkm_device_dtor(device);
 
 		if (device->func->dtor)
 			*pdevice = device->func->dtor(device);
@@ -3152,6 +3168,14 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 	unsigned chipset;
 
 	mutex_lock(&nv_devices_mutex);
+
+	/* Initialize the state that the failure unwinding at done: relies
+	 * on, so that it is safe to run on every error path.
+	 */
+	INIT_LIST_HEAD(&device->head);
+	INIT_LIST_HEAD(&device->subdev);
+	nvkm_intr_ctor(device);
+
 	if (nvkm_device_find_locked(handle))
 		goto done;
 
@@ -3165,7 +3189,6 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 	device->name = name;
 	list_add_tail(&device->head, &nv_devices);
 	device->debug = nvkm_dbgopt(device->dbgopt, "device");
-	INIT_LIST_HEAD(&device->subdev);
 
 	mmio_base = device->func->resource_addr(device, NVKM_BAR0_PRI);
 	mmio_size = device->func->resource_size(device, NVKM_BAR0_PRI);
@@ -3381,6 +3404,21 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 		goto done;
 	}
 
+	/* Unless nouveau is the default NVIDIA driver, leave GSP-capable
+	 * (Turing and later) PCI GPUs to other drivers, such as nova-core.
+	 * Older GPUs are always bound.
+	 *
+	 * Reject before subdevs are constructed, as that would already load
+	 * GSP firmware for GPUs that are not going to be used.
+	 */
+	if (device->func->pci && device->card_type >= TU100 &&
+	    !device->func->pci(device)->bind_gsp) {
+		nvdev_info(device, "leaving GSP-capable GPU to other drivers "
+			   "(bind_gsp=0)\n");
+		ret = -ENODEV;
+		goto done;
+	}
+
 	/* read strapping information */
 	strap = nvkm_rd32(device, 0x101000);
 
@@ -3402,7 +3440,6 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 		device->name = device->chip->name;
 
 	mutex_init(&device->mutex);
-	nvkm_intr_ctor(device);
 
 #define NVKM_LAYOUT_ONCE(type,data,ptr)                                                      \
 	if (device->chip->ptr.inst) {                                                        \
@@ -3446,9 +3483,11 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 
 	ret = nvkm_intr_install(device);
 done:
-	if (ret && device->pri) {
-		iounmap(device->pri);
-		device->pri = NULL;
+	if (ret) {
+		/* Unwind the partially constructed device, so that the caller
+		 * only has to release the resources it allocated itself.
+		 */
+		nvkm_device_dtor(device);
 	}
 	mutex_unlock(&nv_devices_mutex);
 	return ret;
diff --git a/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c b/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c
index 248623b91e29..7e0127ff415f 100644
--- a/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c
+++ b/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c
@@ -1650,7 +1650,7 @@ nvkm_device_pci_func = {
 
 int
 nvkm_device_pci_new(struct pci_dev *pci_dev, const char *cfg, const char *dbg,
-		    struct nvkm_device **pdevice)
+		    bool bind_gsp, struct nvkm_device **pdevice)
 {
 	const struct nvkm_device_quirk *quirk = NULL;
 	const struct nvkm_device_pci_device *pcid;
@@ -1692,8 +1692,8 @@ nvkm_device_pci_new(struct pci_dev *pci_dev, const char *cfg, const char *dbg,
 		pci_disable_device(pci_dev);
 		return -ENOMEM;
 	}
-	*pdevice = &pdev->device;
 	pdev->pdev = pci_dev;
+	pdev->bind_gsp = bind_gsp;
 
 	ret = nvkm_device_ctor(&nvkm_device_pci_func, quirk, &pci_dev->dev,
 			       pci_is_pcie(pci_dev) ? NVKM_DEVICE_PCIE :
@@ -1705,8 +1705,13 @@ nvkm_device_pci_new(struct pci_dev *pci_dev, const char *cfg, const char *dbg,
 				    PCI_FUNC(pci_dev->devfn), name,
 			       cfg, dbg, &pdev->device);
 
-	if (ret)
+	if (ret) {
+		pci_disable_device(pci_dev);
+		kfree(pdev);
 		return ret;
+	}
+
+	*pdevice = &pdev->device;
 
 	/* Set DMA mask based on capabilities reported by the MMU subdev. */
 	if (pdev->device.mmu && !pdev->device.pci->agp.bridge)

-- 
2.56.1

