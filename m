From: Junrui Luo <moonafterrain@outlook.com>
Date: Sat, 15 Aug 2026 14:37:08 +0800
Subject: [PATCH] drm: check for NULL master in drm_getunique() and
 drm_getmagic()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-drm-accel-null-master-v1-1-93bdd3ba52f1@outlook.com>
X-B4-Tracking: v=1; b=H4sIABMJgGoC/x3MQQqAIBBA0avErBtQqYiuEi1Mpxowi7EiiO6et
 HyL/x9IJEwJuuIBoYsTbzFDlwW4xcaZkH02GGUa1eoavaxonaOA8QwBV5sOElTe1NRoUyk7Qm5
 3oYnv/9sP7/sBoCUOC2cAAAA=
X-Change-ID: 20260815-drm-accel-null-master-0d25e61240ab
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>, Melissa Wen <mwen@igalia.com>, 
 Dave Airlie <airlied@redhat.com>, 
 Jacek Lawrynowicz <jacek.lawrynowicz@linux.intel.com>, 
 Oded Gabbay <ogabbay@kernel.org>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2581;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=14Xmewi+giltRJel9Gjr6ymfbKDBgR2rRdumGxnoDdQ=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrAZOqUOeDpPN7Pz9l2+SO3q5OeDTruefTzwPf/LY6
 ZuA7fLQ6uMdpSwMYlwMsmKKLMcLLn2z8N2iu8VnSzLMHFYmkCEMXJwCMBFfJkaGl3PW9f0Pn6O1
 4cQG7wWnzQ3eMz3nmLtm7rXIl/ptsn/L7BgZri59ujdx2WNLpQdRbSulfvv77rly723cwdN7N87
 Njw//xAAAUWlPag==
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drm_getunique() and drm_getmagic() dereference file_priv->master without
checking it, and both ioctls are registered with flags of 0.
drm_open_helper() only calls drm_master_open() for primary clients, so a
drm_file opened on a non-primary minor keeps master == NULL. Render
clients are already rejected by the DRM_RENDER_ALLOW test in
drm_ioctl_permit(), so before commit 2c204f3d5321 ("accel: add dedicated
minor for accelerator devices") every drm_file reaching these ioctls had
a master.

DRM_MINOR_ACCEL is neither primary nor render: it gets no master in
drm_open_helper() and is not covered by drm_is_render_client(). Issuing
DRM_IOCTL_GET_UNIQUE or DRM_IOCTL_GET_MAGIC on /dev/accel/accel* leads
to a NULL pointer dereference, in drm_getunique() with dev->master_mutex
held. The compat entry point reaches drm_getunique() through
drm_ioctl_kernel() with flags of 0 as well.

Return -EINVAL when master is NULL, matching drm_setmaster_ioctl().

Fixes: 2c204f3d5321 ("accel: add dedicated minor for accelerator devices")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/drm_auth.c  | 3 +++
 drivers/gpu/drm/drm_ioctl.c | 5 +++++
 2 files changed, 8 insertions(+)

diff --git a/drivers/gpu/drm/drm_auth.c b/drivers/gpu/drm/drm_auth.c
index e5013b870ba0..cb9e02c486f0 100644
--- a/drivers/gpu/drm/drm_auth.c
+++ b/drivers/gpu/drm/drm_auth.c
@@ -97,6 +97,9 @@ int drm_getmagic(struct drm_device *dev, void *data, struct drm_file *file_priv)
 	int ret = 0;
 
 	guard(mutex)(&dev->master_mutex);
+	if (!file_priv->master)
+		return -EINVAL;
+
 	if (!file_priv->magic) {
 		ret = idr_alloc(&file_priv->master->magic_map, file_priv,
 				1, 0, GFP_KERNEL);
diff --git a/drivers/gpu/drm/drm_ioctl.c b/drivers/gpu/drm/drm_ioctl.c
index 9039a39c4324..083722d8dd44 100644
--- a/drivers/gpu/drm/drm_ioctl.c
+++ b/drivers/gpu/drm/drm_ioctl.c
@@ -120,6 +120,11 @@ int drm_getunique(struct drm_device *dev, void *data,
 
 	mutex_lock(&dev->master_mutex);
 	master = file_priv->master;
+	if (!master) {
+		mutex_unlock(&dev->master_mutex);
+		return -EINVAL;
+	}
+
 	if (u->unique_len >= master->unique_len) {
 		if (copy_to_user(u->unique, master->unique, master->unique_len)) {
 			mutex_unlock(&dev->master_mutex);

---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260815-drm-accel-null-master-0d25e61240ab

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

