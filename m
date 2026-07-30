From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 31 Jul 2026 01:05:45 +0800
Subject: [PATCH v2 7/9] rust: drm: gpuvm: add dump_gpuva_info to
 UniqueRefGpuVm
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-tyr-debugfs-v2-v2-7-aea19eccb996@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=1085;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=NX/9FQXMAwjzHsZtdfgcGo+thvCbDsU1kpIsxoHDurk=;
 b=cD39ySEYIbIAhUOKIQFpOc4MgiEtfltDPaMc4WolTSVbYVrpErF1ujIo9f14HN16T+q5MJyJz
 EnwgmZQwiviBPwAqNYogW//0Hpe0VYPTPP8y9CXV0uDkuY/IRUuM3yO
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add method wrapping drm_debugfs_gpuva_info to dump GPU VA space
mappings into a seq_file. Needed by the Tyr gpuvas debugfs file.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/drm/gpuvm/mod.rs | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/rust/kernel/drm/gpuvm/mod.rs b/rust/kernel/drm/gpuvm/mod.rs
index 20a08b3defeb8..9da88501a4206 100644
--- a/rust/kernel/drm/gpuvm/mod.rs
+++ b/rust/kernel/drm/gpuvm/mod.rs
@@ -312,6 +312,14 @@ pub fn data_ref(&self) -> &T {
         unsafe { &*self.0.data.get() }
     }
 
+    /// Dumps GPU VA space info into a seq_file.
+    ///
+    /// Wraps the C `drm_debugfs_gpuva_info` function.
+    pub fn dump_gpuva_info(&self, m: &crate::seq_file::SeqFile) -> Result {
+        // SAFETY: `m.as_raw()` and `self.as_raw()` are valid by the type invariants.
+        to_result(unsafe { bindings::drm_debugfs_gpuva_info(m.as_raw(), self.as_raw()) })
+    }
+
     /// Access the data owned by this `UniqueRefGpuVm` mutably.
     #[inline]
     pub fn data(&mut self) -> &mut T {

-- 
2.43.0

