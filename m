From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Tue, 19 May 2026 11:46:04 +0530
Subject: [PATCH 14/15] accel/qda: Add remote memory mapping to DSP address
 space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-qda-series-v1-14-b2d984c297f8@oss.qualcomm.com>
References: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
In-Reply-To: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
To: Oded Gabbay <ogabbay@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>
Cc: Bharath Kumar <quic_bkumar@quicinc.com>, 
 Chenna Kesava Raju <quic_chennak@quicinc.com>, srini@kernel.org, 
 dmitry.baryshkov@oss.qualcomm.com, andersson@kernel.org, 
 konradybcio@kernel.org, robin.clark@oss.qualcomm.com, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 iommu@lists.linux.dev, linux-media@vger.kernel.org, 
 linaro-mm-sig@lists.linaro.org, 
 Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779171352; l=18523;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=1y6l12E4bwnORXFC5MmjscV6xqZVUgmj4pKaSEicZPg=;
 b=9/kHibFv1JNbTshjef82dSbo/rtXtd+Ta/NHtTIJEGSn3rw6jZWbxYphIE4MGgSMBDgWfHtbr
 yCpz5WnrtWuBjlkO1kSo+QhyIT4AerbkY3UNHc7Ic0wCZ4hSqhwAYbX
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement DRM_IOCTL_QDA_REMOTE_MAP, which maps a DMA buffer into the
DSP's virtual address space and returns the DSP virtual address to
user-space. Two mapping modes are supported:

QDA_MAP_REQUEST_LEGACY (FASTRPC_RMID_INIT_MMAP)
  Legacy three-argument mapping: sends a fastrpc_map_req_msg to the
  DSP containing the session ID, mapping flags, and virtual address
  hint, together with the physical page descriptor resolved from the
  DMA-BUF fd. The DSP returns the assigned virtual address in
  fastrpc_map_rsp_msg.vaddrout.

QDA_MAP_REQUEST_ATTR (FASTRPC_RMID_INIT_MEM_MAP)
  Attribute-based four-argument mapping: sends a
  fastrpc_mem_map_req_msg which additionally carries the DMA-BUF fd,
  byte offset, and SMMU attribute flags. The DSP uses these to apply
  custom cache and permission attributes to the mapping.

In both cases qda_fastrpc_return_result() writes the DSP virtual
address back into the drm_qda_mem_map.vaddrout field so the DRM
framework copies it to user-space on IOCTL return.

The DMA-BUF fd is resolved to a fastrpc_phy_page descriptor via
setup_mmap_pages(), which imports the fd as a GEM object to obtain
the IOMMU-mapped dma_addr and then releases the extra reference.

Assisted-by: Claude:claude-4-6-sonnet
Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 drivers/accel/qda/qda_drv.c     |   1 +
 drivers/accel/qda/qda_fastrpc.c | 237 ++++++++++++++++++++++++++++++++++++++++
 drivers/accel/qda/qda_fastrpc.h |  56 ++++++++++
 drivers/accel/qda/qda_ioctl.c   |  36 ++++++
 drivers/accel/qda/qda_ioctl.h   |   1 +
 include/uapi/drm/qda_accel.h    |  45 +++++++-
 6 files changed, 375 insertions(+), 1 deletion(-)

diff --git a/drivers/accel/qda/qda_drv.c b/drivers/accel/qda/qda_drv.c
index 4eaba9b050c0..3640e4a41605 100644
--- a/drivers/accel/qda/qda_drv.c
+++ b/drivers/accel/qda/qda_drv.c
@@ -67,6 +67,7 @@ static const struct drm_ioctl_desc qda_ioctls[] = {
 	DRM_IOCTL_DEF_DRV(QDA_GEM_CREATE, qda_ioctl_gem_create, 0),
 	DRM_IOCTL_DEF_DRV(QDA_GEM_MMAP_OFFSET, qda_ioctl_gem_mmap_offset, 0),
 	DRM_IOCTL_DEF_DRV(QDA_REMOTE_SESSION_CREATE, qda_ioctl_init_create, 0),
+	DRM_IOCTL_DEF_DRV(QDA_REMOTE_MAP, qda_ioctl_mmap, 0),
 	DRM_IOCTL_DEF_DRV(QDA_REMOTE_INVOKE, qda_ioctl_invoke, 0),
 };
 
diff --git a/drivers/accel/qda/qda_fastrpc.c b/drivers/accel/qda/qda_fastrpc.c
index 305915022b91..cab3a560ceb5 100644
--- a/drivers/accel/qda/qda_fastrpc.c
+++ b/drivers/accel/qda/qda_fastrpc.c
@@ -524,6 +524,44 @@ int qda_fastrpc_invoke_unpack(struct fastrpc_invoke_context *ctx,
 	return err;
 }
 
+static int fastrpc_return_result_mem_map(struct fastrpc_invoke_context *ctx, char __user *argp)
+{
+	struct drm_qda_mem_map margs;
+	struct fastrpc_map_rsp_msg *rsp_msg;
+
+	rsp_msg = ctx->rsp;
+
+	memcpy(&margs, argp, sizeof(margs));
+
+	margs.vaddrout = rsp_msg->vaddrout;
+
+	memcpy(argp, &margs, sizeof(margs));
+	return 0;
+}
+
+/**
+ * qda_fastrpc_return_result() - Return invocation result to user-space
+ * @ctx: FastRPC invocation context
+ * @argp: User-space pointer to write result into
+ *
+ * Return: 0 on success, negative error code on failure
+ */
+int qda_fastrpc_return_result(struct fastrpc_invoke_context *ctx, char __user *argp)
+{
+	int err = 0;
+
+	switch (ctx->type) {
+	case FASTRPC_RMID_INIT_MMAP:
+	case FASTRPC_RMID_INIT_MEM_MAP:
+		err = fastrpc_return_result_mem_map(ctx, argp);
+		break;
+	default:
+		break;
+	}
+
+	return err;
+}
+
 static void setup_create_process_args(struct drm_qda_fastrpc_invoke_args *args,
 				      struct fastrpc_create_process_inbuf *inbuf,
 				      struct drm_qda_init_create *init,
@@ -561,6 +599,37 @@ static void setup_single_arg(struct drm_qda_fastrpc_invoke_args *args, const voi
 	args[0].fd = -1;
 }
 
+/*
+ * setup_mmap_pages() - Resolve a DMA-BUF fd to a physical page descriptor
+ *
+ * Imports the DMA-BUF fd as a GEM object to obtain the IOMMU-mapped
+ * dma_addr, fills in the fastrpc_phy_page entry, then releases the extra
+ * GEM object reference.  The handle table keeps the object alive.
+ */
+static int setup_mmap_pages(struct fastrpc_invoke_context *ctx, int dmabuf_fd,
+			    struct fastrpc_phy_page *pages)
+{
+	struct drm_gem_object *gem_obj;
+	struct qda_gem_obj *qda_gem_obj;
+	int err;
+
+	if (dmabuf_fd <= 0) {
+		pages->addr = 0;
+		pages->size = 0;
+		return 0;
+	}
+
+	err = get_gem_obj_from_dmabuf_fd(ctx, dmabuf_fd, &gem_obj);
+	if (err)
+		return err;
+
+	qda_gem_obj = to_qda_gem_obj(gem_obj);
+	setup_pages_from_gem_obj(qda_gem_obj, pages);
+
+	drm_gem_object_put(gem_obj);
+	return 0;
+}
+
 static int fastrpc_prepare_args_release_process(struct fastrpc_invoke_context *ctx)
 {
 	struct drm_qda_fastrpc_invoke_args *args;
@@ -656,6 +725,168 @@ static int fastrpc_prepare_args_init_create(struct fastrpc_invoke_context *ctx,
 	return err;
 }
 
+static int fastrpc_prepare_args_map(struct fastrpc_invoke_context *ctx, char __user *argp)
+{
+	struct drm_qda_mem_map margs;
+	struct drm_qda_fastrpc_invoke_args *args;
+	void *req, *rsp;
+	struct fastrpc_map_req_msg *req_msg;
+	struct fastrpc_map_rsp_msg *rsp_msg;
+	int err;
+
+	memcpy(&margs, argp, sizeof(margs));
+
+	args = kzalloc_objs(*args, 3);
+	if (!args)
+		return -ENOMEM;
+
+	req = kzalloc_obj(*req_msg);
+	if (!req) {
+		err = -ENOMEM;
+		goto err_free_args;
+	}
+	req_msg = (struct fastrpc_map_req_msg *)req;
+
+	rsp = kzalloc_obj(*rsp_msg);
+	if (!rsp) {
+		err = -ENOMEM;
+		goto err_free_req;
+	}
+	rsp_msg = (struct fastrpc_map_rsp_msg *)rsp;
+
+	ctx->input_pages = kzalloc_objs(*ctx->input_pages, 1);
+	if (!ctx->input_pages) {
+		err = -ENOMEM;
+		goto err_free_rsp;
+	}
+
+	req_msg->remote_session_id = ctx->remote_session_id;
+	req_msg->flags = margs.flags;
+	req_msg->vaddr = margs.vaddrin;
+	req_msg->num = sizeof(*ctx->input_pages);
+
+	args[0].ptr = (u64)(uintptr_t)req;
+	args[0].length = sizeof(*req_msg);
+	args[0].fd = -1;
+
+	/* Resolve DMA-BUF fd to physical page descriptor */
+	err = setup_mmap_pages(ctx, margs.fd, ctx->input_pages);
+	if (err)
+		goto err_free_input_pages;
+
+	args[1].ptr = (u64)(uintptr_t)ctx->input_pages;
+	args[1].length = sizeof(*ctx->input_pages);
+	args[1].fd = -1;
+
+	args[2].ptr = (u64)(uintptr_t)rsp;
+	args[2].length = sizeof(*rsp_msg);
+	args[2].fd = -1;
+
+	ctx->sc = FASTRPC_SCALARS(FASTRPC_RMID_INIT_MMAP, 2, 1);
+	ctx->args = args;
+	ctx->req = req;
+	ctx->rsp = rsp;
+	ctx->handle = FASTRPC_INIT_HANDLE;
+
+	return 0;
+
+err_free_input_pages:
+	kfree(ctx->input_pages);
+	ctx->input_pages = NULL;
+err_free_rsp:
+	kfree(rsp);
+err_free_req:
+	kfree(req);
+err_free_args:
+	kfree(args);
+	return err;
+}
+
+static int fastrpc_prepare_args_mem_map_attr(struct fastrpc_invoke_context *ctx, char __user *argp)
+{
+	struct drm_qda_mem_map margs;
+	struct drm_qda_fastrpc_invoke_args *args;
+	void *req, *rsp;
+	struct fastrpc_mem_map_req_msg *req_msg;
+	struct fastrpc_map_rsp_msg *rsp_msg;
+	int err;
+
+	memcpy(&margs, argp, sizeof(margs));
+
+	args = kzalloc_objs(*args, 4);
+	if (!args)
+		return -ENOMEM;
+
+	req = kzalloc_obj(*req_msg);
+	if (!req) {
+		err = -ENOMEM;
+		goto err_free_args;
+	}
+	req_msg = (struct fastrpc_mem_map_req_msg *)req;
+
+	rsp = kzalloc_obj(*rsp_msg);
+	if (!rsp) {
+		err = -ENOMEM;
+		goto err_free_req;
+	}
+	rsp_msg = (struct fastrpc_map_rsp_msg *)rsp;
+
+	ctx->input_pages = kzalloc_objs(*ctx->input_pages, 1);
+	if (!ctx->input_pages) {
+		err = -ENOMEM;
+		goto err_free_rsp;
+	}
+
+	req_msg->remote_session_id = ctx->remote_session_id;
+	req_msg->fd       = margs.fd;		/* DMA-BUF fd forwarded to DSP */
+	req_msg->offset   = margs.offset;
+	req_msg->flags    = margs.flags;
+	req_msg->vaddrin  = margs.vaddrin;
+	req_msg->num      = sizeof(*ctx->input_pages);
+	req_msg->data_len = 0;
+
+	args[0].ptr = (u64)(uintptr_t)req;
+	args[0].length = sizeof(*req_msg);
+	args[0].fd = -1;
+
+	/* Resolve DMA-BUF fd to physical page descriptor */
+	err = setup_mmap_pages(ctx, margs.fd, ctx->input_pages);
+	if (err)
+		goto err_free_input_pages;
+
+	args[1].ptr = (u64)(uintptr_t)ctx->input_pages;
+	args[1].length = sizeof(*ctx->input_pages);
+	args[1].fd = -1;
+
+	/* args[2] is a zero-length handle-only entry required by the DSP protocol */
+	args[2].ptr = (u64)(uintptr_t)ctx->input_pages;
+	args[2].length = 0;
+	args[2].fd = -1;
+
+	args[3].ptr = (u64)(uintptr_t)rsp;
+	args[3].length = sizeof(*rsp_msg);
+	args[3].fd = -1;
+
+	ctx->sc = FASTRPC_SCALARS(FASTRPC_RMID_INIT_MEM_MAP, 3, 1);
+	ctx->args = args;
+	ctx->req = req;
+	ctx->rsp = rsp;
+	ctx->handle = FASTRPC_INIT_HANDLE;
+
+	return 0;
+
+err_free_input_pages:
+	kfree(ctx->input_pages);
+	ctx->input_pages = NULL;
+err_free_rsp:
+	kfree(rsp);
+err_free_req:
+	kfree(req);
+err_free_args:
+	kfree(args);
+	return err;
+}
+
 static int fastrpc_prepare_args_invoke(struct fastrpc_invoke_context *ctx, char __user *argp)
 {
 	struct drm_qda_invoke_args invoke_args;
@@ -708,6 +939,12 @@ int qda_fastrpc_prepare_args(struct fastrpc_invoke_context *ctx, char __user *ar
 		ctx->pd = QDA_USER_PD;
 		err = fastrpc_prepare_args_init_create(ctx, argp);
 		break;
+	case FASTRPC_RMID_INIT_MMAP:
+		err = fastrpc_prepare_args_map(ctx, argp);
+		break;
+	case FASTRPC_RMID_INIT_MEM_MAP:
+		err = fastrpc_prepare_args_mem_map_attr(ctx, argp);
+		break;
 	case FASTRPC_RMID_INVOKE_DYNAMIC:
 		err = fastrpc_prepare_args_invoke(ctx, argp);
 		break;
diff --git a/drivers/accel/qda/qda_fastrpc.h b/drivers/accel/qda/qda_fastrpc.h
index 1c1236f9525e..71812eaf9a54 100644
--- a/drivers/accel/qda/qda_fastrpc.h
+++ b/drivers/accel/qda/qda_fastrpc.h
@@ -274,8 +274,10 @@ struct fastrpc_invoke_context {
 
 /* Remote Method ID table - identifies initialization and control operations */
 #define FASTRPC_RMID_INIT_RELEASE	1	/* Release DSP process */
+#define FASTRPC_RMID_INIT_MMAP		4	/* Map memory region to DSP */
 #define FASTRPC_RMID_INIT_CREATE	6	/* Create DSP process */
 #define FASTRPC_RMID_INIT_CREATE_ATTR	7	/* Create DSP process with attributes */
+#define FASTRPC_RMID_INIT_MEM_MAP	10	/* Map DMA buffer with attributes to DSP */
 #define FASTRPC_RMID_INVOKE_DYNAMIC	0xFFFFFFFF	/* Dynamic method invocation */
 
 /* Common handle for initialization operations */
@@ -290,11 +292,65 @@ struct fastrpc_invoke_context {
 /* Maximum initialization file size (4 MB) */
 #define FASTRPC_INIT_FILELEN_MAX	(4 * 1024 * 1024)
 
+/* Message structures for internal FastRPC calls */
+
+/**
+ * struct fastrpc_mem_map_req_msg - Memory map request message with attributes
+ *
+ * This message structure is sent to the DSP to request mapping
+ * of a DMA buffer with custom attributes (ATTR request).
+ */
+struct fastrpc_mem_map_req_msg {
+	/** @remote_session_id: Client identifier for the session */
+	s32 remote_session_id;
+	/** @fd: DMA-BUF file descriptor of the buffer to map */
+	s32 fd;
+	/** @offset: Byte offset within the buffer */
+	s32 offset;
+	/** @flags: Mapping flags (cache attributes, permissions) */
+	u32 flags;
+	/** @vaddrin: Virtual address hint for the DSP mapping */
+	u64 vaddrin;
+	/** @num: Size of the physical page descriptor array in bytes */
+	s32 num;
+	/** @data_len: Length of additional inline data */
+	s32 data_len;
+};
+
+/**
+ * struct fastrpc_map_req_msg - Legacy memory map request message
+ *
+ * This message structure is sent to the DSP to request mapping
+ * of a DMA buffer into the DSP's virtual address space.
+ */
+struct fastrpc_map_req_msg {
+	/** @remote_session_id: Client identifier for the session */
+	s32 remote_session_id;
+	/** @flags: Mapping flags (cache attributes, permissions) */
+	u32 flags;
+	/** @vaddr: Virtual address hint for the DSP mapping */
+	u64 vaddr;
+	/** @num: Size of the physical page descriptor array in bytes */
+	s32 num;
+};
+
+/**
+ * struct fastrpc_map_rsp_msg - Memory map response message
+ *
+ * This message structure is returned by the DSP after successfully
+ * mapping a buffer, providing the virtual address for future access.
+ */
+struct fastrpc_map_rsp_msg {
+	/** @vaddrout: DSP virtual address assigned to the mapped buffer */
+	u64 vaddrout;
+};
+
 void qda_fastrpc_context_free(struct kref *ref);
 struct fastrpc_invoke_context *qda_fastrpc_context_alloc(void);
 int qda_fastrpc_prepare_args(struct fastrpc_invoke_context *ctx, char __user *argp);
 int qda_fastrpc_get_header_size(struct fastrpc_invoke_context *ctx, size_t *out_size);
 int qda_fastrpc_invoke_pack(struct fastrpc_invoke_context *ctx, struct qda_msg *msg);
 int qda_fastrpc_invoke_unpack(struct fastrpc_invoke_context *ctx, struct qda_msg *msg);
+int qda_fastrpc_return_result(struct fastrpc_invoke_context *ctx, char __user *argp);
 
 #endif /* __QDA_FASTRPC_H__ */
diff --git a/drivers/accel/qda/qda_ioctl.c b/drivers/accel/qda/qda_ioctl.c
index 33f0a798ad13..283eb7535c45 100644
--- a/drivers/accel/qda/qda_ioctl.c
+++ b/drivers/accel/qda/qda_ioctl.c
@@ -1,6 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0-only
 // Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
 #include <drm/drm_ioctl.h>
+#include <drm/drm_print.h>
 #include <drm/qda_accel.h>
 #include "qda_drv.h"
 #include "qda_fastrpc.h"
@@ -178,6 +179,10 @@ static int fastrpc_invoke(int type, struct drm_device *dev, void *data,
 	if (err)
 		goto err_context_free;
 
+	err = qda_fastrpc_return_result(ctx, (char __user *)data);
+	if (err)
+		goto err_context_free;
+
 	fastrpc_context_put_id(ctx, qdev);
 	kref_put(&ctx->refcount, qda_fastrpc_context_free);
 	return 0;
@@ -218,6 +223,37 @@ int qda_release_dsp_process(struct qda_dev *qdev, struct drm_file *file_priv)
 	return fastrpc_invoke(FASTRPC_RMID_INIT_RELEASE, &qdev->drm_dev, NULL, file_priv);
 }
 
+/**
+ * qda_ioctl_mmap() - Map memory to DSP address space
+ * @dev: DRM device structure
+ * @data: User-space data (struct drm_qda_mem_map)
+ * @file_priv: DRM file private data
+ *
+ * Return: 0 on success, negative error code on failure
+ */
+int qda_ioctl_mmap(struct drm_device *dev, void *data, struct drm_file *file_priv)
+{
+	struct drm_qda_mem_map *map_req;
+
+	if (!data)
+		return -EINVAL;
+
+	map_req = (struct drm_qda_mem_map *)data;
+
+	if (map_req->pad)
+		return -EINVAL;
+
+	switch (map_req->request) {
+	case QDA_MAP_REQUEST_LEGACY:
+		return fastrpc_invoke(FASTRPC_RMID_INIT_MMAP, dev, data, file_priv);
+	case QDA_MAP_REQUEST_ATTR:
+		return fastrpc_invoke(FASTRPC_RMID_INIT_MEM_MAP, dev, data, file_priv);
+	default:
+		drm_err(dev, "Invalid map request type: %u\n", map_req->request);
+		return -EINVAL;
+	}
+}
+
 /**
  * qda_ioctl_invoke() - Perform a dynamic FastRPC method invocation
  * @dev: DRM device structure
diff --git a/drivers/accel/qda/qda_ioctl.h b/drivers/accel/qda/qda_ioctl.h
index 192565434363..457ceccede08 100644
--- a/drivers/accel/qda/qda_ioctl.h
+++ b/drivers/accel/qda/qda_ioctl.h
@@ -13,5 +13,6 @@ int qda_ioctl_init_create(struct drm_device *dev, void *data, struct drm_file *f
 int qda_ioctl_gem_create(struct drm_device *dev, void *data, struct drm_file *file_priv);
 int qda_ioctl_gem_mmap_offset(struct drm_device *dev, void *data, struct drm_file *file_priv);
 int qda_ioctl_invoke(struct drm_device *dev, void *data, struct drm_file *file_priv);
+int qda_ioctl_mmap(struct drm_device *dev, void *data, struct drm_file *file_priv);
 
 #endif /* __QDA_IOCTL_H__ */
diff --git a/include/uapi/drm/qda_accel.h b/include/uapi/drm/qda_accel.h
index 711e2523a570..173f59abd361 100644
--- a/include/uapi/drm/qda_accel.h
+++ b/include/uapi/drm/qda_accel.h
@@ -21,8 +21,9 @@ extern "C" {
 #define DRM_QDA_QUERY		0x00
 #define DRM_QDA_GEM_CREATE		0x01
 #define DRM_QDA_GEM_MMAP_OFFSET	0x02
-/* Command number 0x03 reserved for INIT_ATTACH; 0x05-0x06 reserved for MAP, MUNMAP */
+/* Command number 0x03 reserved for INIT_ATTACH; 0x06 reserved for MUNMAP */
 #define DRM_QDA_REMOTE_SESSION_CREATE		0x04
+#define DRM_QDA_REMOTE_MAP			0x05
 #define DRM_QDA_REMOTE_INVOKE			0x07
 
 /*
@@ -41,9 +42,15 @@ extern "C" {
 #define DRM_IOCTL_QDA_REMOTE_SESSION_CREATE					\
 	DRM_IOWR(DRM_COMMAND_BASE + DRM_QDA_REMOTE_SESSION_CREATE,		\
 		 struct drm_qda_init_create)
+#define DRM_IOCTL_QDA_REMOTE_MAP	DRM_IOWR(DRM_COMMAND_BASE + DRM_QDA_REMOTE_MAP, \
+					  struct drm_qda_mem_map)
 #define DRM_IOCTL_QDA_REMOTE_INVOKE	DRM_IOWR(DRM_COMMAND_BASE + DRM_QDA_REMOTE_INVOKE, \
 					  struct drm_qda_invoke_args)
 
+/* Request type definitions for qda_mem_map */
+#define QDA_MAP_REQUEST_LEGACY    1  /* Legacy MMAP operation */
+#define QDA_MAP_REQUEST_ATTR      2  /* Handle-based MEM_MAP operation with attributes */
+
 /**
  * struct drm_qda_query - Device information query structure
  * @dsp_name: Name of DSP (e.g., "adsp", "cdsp", "cdsp1", "gdsp0", "gdsp1")
@@ -145,6 +152,42 @@ struct drm_qda_invoke_args {
 	__u64 args;
 };
 
+/**
+ * struct drm_qda_mem_map - Memory mapping request structure
+ * @request: Request type (QDA_MAP_REQUEST_LEGACY or QDA_MAP_REQUEST_ATTR)
+ * @flags: Mapping flags for DSP (cache attributes, permissions)
+ * @fd: DMA-BUF file descriptor of the buffer to map
+ * @attrs: Mapping attributes (used for ATTR request)
+ * @offset: Offset within buffer (used for ATTR request)
+ * @pad: Padding for 64-bit alignment (must be zero)
+ * @vaddrin: Optional virtual address hint for mapping
+ * @size: Size of the memory region to map in bytes
+ * @vaddrout: Output DSP virtual address after successful mapping
+ *
+ * This structure is used to request mapping of a DMA buffer into the
+ * DSP's virtual address space. The DSP will map the buffer according
+ * to the specified flags and return the virtual address in vaddrout.
+ *
+ * For QDA_MAP_REQUEST_LEGACY (value 1):
+ *   - Uses fields: fd, flags, vaddrin, size, vaddrout
+ *   - Legacy MMAP operation for backward compatibility
+ *
+ * For QDA_MAP_REQUEST_ATTR (value 2):
+ *   - Uses all fields including attrs and offset
+ *   - FD-based MEM_MAP operation with custom SMMU attributes
+ */
+struct drm_qda_mem_map {
+	__u32 request;
+	__u32 flags;
+	__s32 fd;
+	__u32 attrs;
+	__u32 offset;
+	__u32 pad;
+	__u64 vaddrin;
+	__u64 size;
+	__u64 vaddrout;
+};
+
 #if defined(__cplusplus)
 }
 #endif

-- 
2.34.1

