From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 31 Jul 2026 01:05:42 +0800
Subject: [PATCH v2 4/9] drm: move debugfs_init after dev->registered is set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-tyr-debugfs-v2-v2-4-aea19eccb996@linux.dev>
References: <20260731-tyr-debugfs-v2-v2-0-aea19eccb996@linux.dev>
In-Reply-To: <20260731-tyr-debugfs-v2-v2-0-aea19eccb996@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Matthew Brost <matthew.brost@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 =?utf-8?q?Ma=C3=ADra_Canal?= <mcanal@igalia.com>, 
 Melissa Wen <mwen@igalia.com>, Wambui Karuga <wambui.karugax@gmail.com>, 
 Eric Anholt <eric@anholt.net>, Ben Gamari <bgamari@gmail.com>, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=1502;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=WZR8Y42ND9E/OAlX111HbpPcKsxTChsq0oOfQ3+9UZM=;
 b=Nu6+7BcxiJjyRPpf2u+1b0iaiSQBOJe051oW2rzfFeF1mot84+/iQEuu/d+7bnherhoaUo22G
 PErAWGVIR6SCpdLLCp+QzHtk1b2X3Lol0rBTsYH8E7OtNJA4IEi52sW
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The debugfs_init callback was invoked by drm_debugfs_register before
dev->registered is set to true. Moving it to drm_dev_register after
dev->registered = true fixes the Ioctl type invariant violation.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/drm_debugfs.c | 3 ---
 drivers/gpu/drm/drm_drv.c     | 5 +++++
 2 files changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/drm_debugfs.c b/drivers/gpu/drm/drm_debugfs.c
index ae1c6126c2c59..38cf6ce387cc8 100644
--- a/drivers/gpu/drm/drm_debugfs.c
+++ b/drivers/gpu/drm/drm_debugfs.c
@@ -442,9 +442,6 @@ int drm_debugfs_register(struct drm_minor *minor, int minor_id)
 	/* TODO: Only for compatibility with drivers */
 	minor->debugfs_root = dev->debugfs_root;
 
-	if (dev->driver->debugfs_init && dev->render != minor)
-		dev->driver->debugfs_init(minor);
-
 	return 0;
 }
 
diff --git a/drivers/gpu/drm/drm_drv.c b/drivers/gpu/drm/drm_drv.c
index e890052061f30..15669764fe625 100644
--- a/drivers/gpu/drm/drm_drv.c
+++ b/drivers/gpu/drm/drm_drv.c
@@ -1101,6 +1101,11 @@ int drm_dev_register(struct drm_device *dev, unsigned long flags)
 	dev->registered = true;
 	dev->unplugged = false;
 
+	/* Call debugfs_init after the device is fully registered. */
+	if (dev->driver->debugfs_init && dev->primary &&
+	    dev->render != dev->primary)
+		dev->driver->debugfs_init(dev->primary);
+
 	if (driver->load) {
 		ret = driver->load(dev, flags);
 		if (ret)

-- 
2.43.0

