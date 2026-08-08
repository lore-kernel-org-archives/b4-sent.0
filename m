From: Junrui Luo <moonafterrain@outlook.com>
Date: Sat, 08 Aug 2026 19:14:18 +0800
Subject: [PATCH 2/2] drm/nouveau/uvmm: reject a second VM_INIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-nouveau-fixes-v1-2-c3ebdc17a89c@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1979;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=kir+5s3fujjv8rmqeaXun1k1yrvbyiCBLh8cPyNLZQ8=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrHIBi6WxtVx5p//fuOjpXSW9d1dYj9jfeyFGP+1fF
 za9v/MmxaejlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJjJvOyPDI4PGSzyi0SHz
 JSX9i6Xecy3hY9pmn3p22apLf5x7G9RuMjLsrWCZf+hniKnml7y4aLWggInflvz8tULjb3kLn2t
 RgxIDAK7KSdM=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nouveau_uvmm_ioctl_vm_init() sets up the GPU VA space for a drm_file and
is reachable from an unprivileged render node client (DRM_RENDER_ALLOW).
After the cli->uvmm.disabled check it unconditionally allocates a
nouveau_uvmm, initialises its drm_gpuvm and region maple tree, creates
the backing nvif vmm and overwrites cli->uvmm.ptr, without testing
whether one already exists.

Calling DRM_IOCTL_NOUVEAU_VM_INIT twice therefore drops the previous
nouveau_uvmm with no remaining reference to it: drm_gpuvm_put() is
reached only from nouveau_uvmm_fini(), which nouveau_cli_fini() calls
once on whatever cli->uvmm.ptr holds at close time. The orphaned
nouveau_uvmm, its drm_gpuvm, that gpuvm's reservation GEM object and its
region maple tree are never freed, buffer objects mapped in it stay
pinned by the orphaned uvmas, and its nvif vmm keeps the GPU page
directories allocated until the file is closed, so repeating the ioctl
leaks kernel memory without bound.

Test cli->uvmm.ptr under cli->mutex before anything is allocated and
return -EBUSY, mirroring nouveau_svmm_init().

Fixes: b88baab82871 ("drm/nouveau: implement new VM_BIND uAPI")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/nouveau/nouveau_uvmm.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/gpu/drm/nouveau/nouveau_uvmm.c b/drivers/gpu/drm/nouveau/nouveau_uvmm.c
index bced1481674e..26d2a57b5aac 100644
--- a/drivers/gpu/drm/nouveau/nouveau_uvmm.c
+++ b/drivers/gpu/drm/nouveau/nouveau_uvmm.c
@@ -1929,6 +1929,12 @@ nouveau_uvmm_ioctl_vm_init(struct drm_device *dev,
 		goto out_unlock;
 	}
 
+	/* Check that a GPU VA space isn't already set up for the client. */
+	if (cli->uvmm.ptr) {
+		ret = -EBUSY;
+		goto out_unlock;
+	}
+
 	uvmm = kzalloc_obj(*uvmm);
 	if (!uvmm) {
 		ret = -ENOMEM;

-- 
2.51.2

