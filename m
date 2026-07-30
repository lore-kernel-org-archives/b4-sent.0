From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 31 Jul 2026 01:05:47 +0800
Subject: [PATCH v2 9/9] drm/debugfs: hold device reference for the lifetime
 of open files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-tyr-debugfs-v2-v2-9-aea19eccb996@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=3132;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=skA4KVHM8LMz73TA56MQb3n/Ixh2G2cs8JHXFUZaNIU=;
 b=byirK3xd7xbmRD0KNzAAenKpeldvUER6QjL52yREv13nnnfpFq5CGiZ65r+lwQ7WTBzZbuVjH
 2PRTkN6XUtDB1MhPnoqzBmw/q8DJSTtfx8+g8cJQ91uO8Obgrcp4MCI
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hold a device reference (via drm_dev_get/put) across the lifetime of open
debugfs files. Prevents use-after-free when a device is unregistered while
a debugfs file remains open. Both drm_debugfs_open (legacy info_list)
and drm_debugfs_entry_open (drm_debugfs_add_file) paths are covered.

Fixes: 1c9cacbea8805 ("drm/debugfs: create device-centered debugfs functions")
Fixes: 28a62277e06f9 ("drm: Convert proc files to seq_file and introduce debugfs")

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/drm_debugfs.c | 42 ++++++++++++++++++++++++++++++++++++++----
 1 file changed, 38 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/drm_debugfs.c b/drivers/gpu/drm/drm_debugfs.c
index 38cf6ce387cc8..5262a708f1602 100644
--- a/drivers/gpu/drm/drm_debugfs.c
+++ b/drivers/gpu/drm/drm_debugfs.c
@@ -159,11 +159,28 @@ static const struct drm_debugfs_info drm_debugfs_list[] = {
 static int drm_debugfs_open(struct inode *inode, struct file *file)
 {
 	struct drm_info_node *node = inode->i_private;
+	struct drm_device *dev = node->minor->dev;
+	int ret;
 
 	if (!device_is_registered(node->minor->kdev))
 		return -ENODEV;
 
-	return single_open(file, node->info_ent->show, node);
+	drm_dev_get(dev);
+
+	ret = single_open(file, node->info_ent->show, node);
+	if (ret)
+		drm_dev_put(dev);
+
+	return ret;
+}
+
+static int drm_debugfs_release(struct inode *inode, struct file *file)
+{
+	struct drm_info_node *node =
+		((struct seq_file *)file->private_data)->private;
+
+	drm_dev_put(node->minor->dev);
+	return single_release(inode, file);
 }
 
 static int drm_debugfs_entry_open(struct inode *inode, struct file *file)
@@ -171,11 +188,28 @@ static int drm_debugfs_entry_open(struct inode *inode, struct file *file)
 	struct drm_debugfs_entry *entry = inode->i_private;
 	struct drm_debugfs_info *node = &entry->file;
 	struct drm_minor *minor = entry->dev->primary ?: entry->dev->accel;
+	struct drm_device *dev = entry->dev;
+	int ret;
 
 	if (!device_is_registered(minor->kdev))
 		return -ENODEV;
 
-	return single_open(file, node->show, entry);
+	drm_dev_get(dev);
+
+	ret = single_open(file, node->show, entry);
+	if (ret)
+		drm_dev_put(dev);
+
+	return ret;
+}
+
+static int drm_debugfs_entry_release(struct inode *inode, struct file *file)
+{
+	struct drm_debugfs_entry *entry =
+		((struct seq_file *)file->private_data)->private;
+
+	drm_dev_put(entry->dev);
+	return single_release(inode, file);
 }
 
 static const struct file_operations drm_debugfs_entry_fops = {
@@ -183,7 +217,7 @@ static const struct file_operations drm_debugfs_entry_fops = {
 	.open = drm_debugfs_entry_open,
 	.read = seq_read,
 	.llseek = seq_lseek,
-	.release = single_release,
+	.release = drm_debugfs_entry_release,
 };
 
 static const struct file_operations drm_debugfs_fops = {
@@ -191,7 +225,7 @@ static const struct file_operations drm_debugfs_fops = {
 	.open = drm_debugfs_open,
 	.read = seq_read,
 	.llseek = seq_lseek,
-	.release = single_release,
+	.release = drm_debugfs_release,
 };
 
 /**

-- 
2.43.0

