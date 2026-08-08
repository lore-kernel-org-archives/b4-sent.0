From: Junrui Luo <moonafterrain@outlook.com>
Date: Sat, 08 Aug 2026 19:14:17 +0800
Subject: [PATCH 1/2] drm/nouveau: bound sync and op counts in EXEC and
 VM_BIND
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-nouveau-fixes-v1-1-c3ebdc17a89c@outlook.com>
References: <20260808-nouveau-fixes-v1-0-c3ebdc17a89c@outlook.com>
In-Reply-To: <20260808-nouveau-fixes-v1-0-c3ebdc17a89c@outlook.com>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4929;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=/J/SpTfGUfN//kW/CFeXf5X2Ys5xRXob1tq0NKDsF84=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrHIBiw3LsjR1vkVcLPZoXmJtyjGd2XudWuW5jar6T
 wO8/uypfddRysIgxsUgK6bIcrzg0jcL3y26W3y2JMPMYWUCGcLAxSkAEzmtxPA/dDM3m+YUxQyJ
 ax9iw2Vjxe6xhC9hktj2yTY/7i7/k5tHGRmuSfh8Cd+9J8OqrSQiNeQGh6LOYsFjZ1e76ik4BSW
 6rWIHACkZRQU=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nouveau_exec_ucopy() and nouveau_uvmm_vm_bind_ucopy() pass user-supplied
u32 counts to u_memcpya(). DRM_IOCTL_NOUVEAU_EXEC bounds only
req->push_count against push_max, leaving req->wait_count and
req->sig_count unchecked; DRM_IOCTL_NOUVEAU_VM_BIND bounds none of
op_count, wait_count or sig_count. u_memcpya() itself only rejects
multiplication overflow, which on 64-bit never triggers for a u32 count
times a small element size.

A wait_count of 0xffffffff therefore becomes a 64 GB vmemdup_user()
request. Since vmemdup_user() allocates with GFP_USER and hence without
__GFP_NOWARN, a size above INT_MAX trips the WARN_ON_ONCE() in
__kvmalloc_node_noprof(); below that the kernel attempts an up to 2 GB
vmalloc that GFP_USER also leaves uncharged to the caller's memcg. Both
ioctls are DRM_RENDER_ALLOW, so any client holding a render node can
issue this.

Reject the oversized counts at the ioctl entry points, the way
nouveau_gem_ioctl_pushbuf() and the existing push_count check already
do, so that the client is told which limit it exceeded. Sync objects get
NOUVEAU_MAX_SYNCS, matching both NOUVEAU_GEM_MAX_BUFFERS and the value
xe settled on for the same field in DRM_XE_MAX_SYNCS. VM_BIND operations
have no comparable semantic limit, so NOUVEAU_VM_BIND_MAX_OPS is set
well above any batch size a client is expected to submit; it exists only
to keep the copy-in allocation finite.

Fixes: b88baab82871 ("drm/nouveau: implement new VM_BIND uAPI")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/nouveau/nouveau_exec.c | 12 ++++++++++++
 drivers/gpu/drm/nouveau/nouveau_uvmm.c | 18 ++++++++++++++++++
 include/uapi/drm/nouveau_drm.h         | 18 ++++++++++++++++++
 3 files changed, 48 insertions(+)

diff --git a/drivers/gpu/drm/nouveau/nouveau_exec.c b/drivers/gpu/drm/nouveau/nouveau_exec.c
index a08ab1cfea9b..7bdccbae53b1 100644
--- a/drivers/gpu/drm/nouveau/nouveau_exec.c
+++ b/drivers/gpu/drm/nouveau/nouveau_exec.c
@@ -389,6 +389,18 @@ nouveau_exec_ioctl_exec(struct drm_device *dev,
 		return nouveau_abi16_put(abi16, -EINVAL);
 	}
 
+	if (unlikely(req->wait_count > NOUVEAU_MAX_SYNCS)) {
+		NV_PRINTK(err, cli, "exec wait count exceeds limit: %d max %d\n",
+			  req->wait_count, NOUVEAU_MAX_SYNCS);
+		return nouveau_abi16_put(abi16, -EINVAL);
+	}
+
+	if (unlikely(req->sig_count > NOUVEAU_MAX_SYNCS)) {
+		NV_PRINTK(err, cli, "exec sig count exceeds limit: %d max %d\n",
+			  req->sig_count, NOUVEAU_MAX_SYNCS);
+		return nouveau_abi16_put(abi16, -EINVAL);
+	}
+
 	ret = nouveau_exec_ucopy(&args, req);
 	if (ret)
 		goto out;
diff --git a/drivers/gpu/drm/nouveau/nouveau_uvmm.c b/drivers/gpu/drm/nouveau/nouveau_uvmm.c
index f5e4756b4de4..bced1481674e 100644
--- a/drivers/gpu/drm/nouveau/nouveau_uvmm.c
+++ b/drivers/gpu/drm/nouveau/nouveau_uvmm.c
@@ -1807,6 +1807,24 @@ nouveau_uvmm_ioctl_vm_bind(struct drm_device *dev,
 	if (unlikely(!nouveau_cli_uvmm_locked(cli)))
 		return -ENOSYS;
 
+	if (unlikely(req->op_count > NOUVEAU_VM_BIND_MAX_OPS)) {
+		NV_PRINTK(err, cli, "vm_bind op count exceeds limit: %d max %d\n",
+			  req->op_count, NOUVEAU_VM_BIND_MAX_OPS);
+		return -EINVAL;
+	}
+
+	if (unlikely(req->wait_count > NOUVEAU_MAX_SYNCS)) {
+		NV_PRINTK(err, cli, "vm_bind wait count exceeds limit: %d max %d\n",
+			  req->wait_count, NOUVEAU_MAX_SYNCS);
+		return -EINVAL;
+	}
+
+	if (unlikely(req->sig_count > NOUVEAU_MAX_SYNCS)) {
+		NV_PRINTK(err, cli, "vm_bind sig count exceeds limit: %d max %d\n",
+			  req->sig_count, NOUVEAU_MAX_SYNCS);
+		return -EINVAL;
+	}
+
 	ret = nouveau_uvmm_vm_bind_ucopy(&args, req);
 	if (ret)
 		return ret;
diff --git a/include/uapi/drm/nouveau_drm.h b/include/uapi/drm/nouveau_drm.h
index 1fa82fa6af38..35ddf97ca873 100644
--- a/include/uapi/drm/nouveau_drm.h
+++ b/include/uapi/drm/nouveau_drm.h
@@ -220,6 +220,14 @@ struct drm_nouveau_gem_cpu_fini {
 	__u32 handle;
 };
 
+/*
+ * NOUVEAU_MAX_SYNCS - maximum number of sync objects per ioctl
+ *
+ * The maximum value EXEC and VM_BIND accept in their wait_count and
+ * sig_count fields.
+ */
+#define NOUVEAU_MAX_SYNCS 1024
+
 /**
  * struct drm_nouveau_sync - sync object
  *
@@ -332,6 +340,16 @@ struct drm_nouveau_vm_bind_op {
 	__u64 range;
 };
 
+/*
+ * NOUVEAU_VM_BIND_MAX_OPS - maximum number of &drm_nouveau_vm_bind_ops
+ *
+ * The maximum value VM_BIND accepts in its op_count field. There is no
+ * semantic limit on the number of operations a bind may carry; this bound
+ * exists only to keep the copy-in allocation finite and is far above any
+ * batch size a client is expected to submit.
+ */
+#define NOUVEAU_VM_BIND_MAX_OPS 65536
+
 /**
  * struct drm_nouveau_vm_bind - structure for DRM_IOCTL_NOUVEAU_VM_BIND
  */

-- 
2.51.2

