From: Dave Airlie <airlied@redhat.com>
Date: Mon, 23 Nov 2026 12:50:27 +1000
Subject: [PATCH v2 1/3] drm/nouveau/nvkm: fix device leak on ctor failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-nova-nouveau-gsp-v2-1-5e8c27aa8555@redhat.com>
References: <20261123-nova-nouveau-gsp-v2-0-5e8c27aa8555@redhat.com>
In-Reply-To: <20261123-nova-nouveau-gsp-v2-0-5e8c27aa8555@redhat.com>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3909; i=airlied@redhat.com;
 h=from:subject:message-id; bh=FxQfPnbiZkoWyGg4qBk10lfI9Hri+d/S962EuPutKEU=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBrA6n6anMYHK63Q0J31oUW/5PpHvs2g5RpShL2F
 L6Iu0Iq4nKJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCawOp+gAKCRAMdPNZecSG
 vvgvEACMoLrNbIEJ7IHYcOOhmSDlOr3dWKhKT5XQgLcWTBeQAKCu4EttfNbOYKMHH23Wq+oTWcp
 6+h+ckVmVkfrgI4B5SHp6ebSSexhM2VvIlRct091miELwNw4pVwWscNVr1qGTm3kcg8eeOA/0+g
 6uiZMW/KahcxS1BXtNz/oNz2vzuXhVJtwRlfANsICN1+e6RjO7IDQLcTdSh6lRNkO5qstgVVCHB
 tccWaFNo7V1LSHiHjKmnZFL+xXLRmTPFZdCzEjOE+SKZFMYvcDBn2fmzbzETbOliwUtgk9Avqhx
 6c7f50m8m2KWe9DfqnuT57LSbMKb8Fape5k+ebLrSA98cCfWdMNduXhgIS/VEpppfGpGUQoxLa4
 YC/RsTL7vC5oMG8zi3QzkKOBly/Uqx29cFvC0z3Uvik5VK85KXeQRhFXsInkcoB1KvQPci/PrwI
 VD2r+WXUpwTA1U+sN/7m72vWr/llIbsO7RcMd6eNts6tX6i6vJhw/HvNTo0hXjQA48xnU6HPGvS
 q0wc9RspgPccUSXXNPhCX8os1yheRbLnoUJHbwC5LMo4s7m0aj8VnzjffJoG+X70hRIbyYhbUuG
 RTgaEr2Aaaa4yN4eiEhy1tW/VoQE7GzjfR/K8d/EEBnmzls97CNo6h+FusgdHh9iHqMqb0uBC94
 yRefElBdy2DzMwg==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When adding a new failure path from device_ctor, the missing
clean up paths in the current code were uncovered.

The device_del path doesn't work because it relies on initialisation
that hadn't been done yet.

This patch cleans up the failure paths and initialises the
things needed for the nvkm_device_del path to work.

Fixes: 0d5dd3f301bb ("drm/nouveau/lib: various tweaks")
---
 drivers/gpu/drm/nouveau/nvkm/engine/device/base.c  | 13 ++++++++++---
 drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c   |  4 +++-
 drivers/gpu/drm/nouveau/nvkm/engine/device/tegra.c | 13 +++++++++----
 3 files changed, 22 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c b/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c
index a2ed8c4fe52a..625bb019736a 100644
--- a/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c
+++ b/drivers/gpu/drm/nouveau/nvkm/engine/device/base.c
@@ -3152,10 +3152,19 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 	unsigned chipset;
 
 	mutex_lock(&nv_devices_mutex);
+
+	/* Set up the state that nvkm_device_del() relies on before anything
+	 * that can fail, so that a device whose construction failed can be
+	 * cleaned up by the caller with nvkm_device_del().
+	 */
+	device->func = func;
+	INIT_LIST_HEAD(&device->head);
+	INIT_LIST_HEAD(&device->subdev);
+	nvkm_intr_ctor(device);
+
 	if (nvkm_device_find_locked(handle))
 		goto done;
 
-	device->func = func;
 	device->quirk = quirk;
 	device->dev = dev;
 	device->type = type;
@@ -3165,7 +3174,6 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 	device->name = name;
 	list_add_tail(&device->head, &nv_devices);
 	device->debug = nvkm_dbgopt(device->dbgopt, "device");
-	INIT_LIST_HEAD(&device->subdev);
 
 	mmio_base = device->func->resource_addr(device, NVKM_BAR0_PRI);
 	mmio_size = device->func->resource_size(device, NVKM_BAR0_PRI);
@@ -3402,7 +3410,6 @@ nvkm_device_ctor(const struct nvkm_device_func *func,
 		device->name = device->chip->name;
 
 	mutex_init(&device->mutex);
-	nvkm_intr_ctor(device);
 
 #define NVKM_LAYOUT_ONCE(type,data,ptr)                                                      \
 	if (device->chip->ptr.inst) {                                                        \
diff --git a/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c b/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c
index 248623b91e29..269ccd4b482e 100644
--- a/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c
+++ b/drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c
@@ -1705,8 +1705,10 @@ nvkm_device_pci_new(struct pci_dev *pci_dev, const char *cfg, const char *dbg,
 				    PCI_FUNC(pci_dev->devfn), name,
 			       cfg, dbg, &pdev->device);
 
-	if (ret)
+	if (ret) {
+		nvkm_device_del(pdevice);
 		return ret;
+	}
 
 	/* Set DMA mask based on capabilities reported by the MMU subdev. */
 	if (pdev->device.mmu && !pdev->device.pci->agp.bridge)
diff --git a/drivers/gpu/drm/nouveau/nvkm/engine/device/tegra.c b/drivers/gpu/drm/nouveau/nvkm/engine/device/tegra.c
index 3c8d0878891a..eb4f43287796 100644
--- a/drivers/gpu/drm/nouveau/nvkm/engine/device/tegra.c
+++ b/drivers/gpu/drm/nouveau/nvkm/engine/device/tegra.c
@@ -332,15 +332,20 @@ nvkm_device_tegra_new(const struct nvkm_device_tegra_func *func,
 	ret = nvkm_device_ctor(&nvkm_device_tegra_func, NULL, &pdev->dev,
 			       NVKM_DEVICE_TEGRA, pdev->id, NULL,
 			       cfg, dbg, &tdev->device);
-	if (ret)
-		goto powerdown;
+	if (ret) {
+		struct nvkm_device *device = &tdev->device;
+
+		/* Cleans up the partially constructed device, including
+		 * powering it down and freeing tdev.
+		 */
+		nvkm_device_del(&device);
+		return ret;
+	}
 
 	*pdevice = &tdev->device;
 
 	return 0;
 
-powerdown:
-	nvkm_device_tegra_power_down(tdev);
 remove:
 	nvkm_device_tegra_remove_iommu(tdev);
 free:

-- 
2.56.1

