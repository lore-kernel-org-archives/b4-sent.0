From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 31 Jul 2026 01:05:39 +0800
Subject: [PATCH v2 1/9] rust: seq_file: add as_raw() method
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-tyr-debugfs-v2-v2-1-aea19eccb996@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=882;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=s/xpgHrjMnr3Dw/gDnMO8NhtKWrQpFIoMn7udGnLIvs=;
 b=RllQx43KbHuxgGco1sV76In+WKsRfcxUAilY4N3HdnKKwnLHutWJYha4dKAQ3SU4ikxcNuoVI
 X7YXbjya30dAzwLGJRoE2TzSdEk4DTVXOA7frGQiq4WSXNZaWgkas6X
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a method to obtain a raw pointer to the underlying struct
seq_file, needed for FFI calls into C (e.g. drm_debugfs_gpuva_info).

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/seq_file.rs | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/rust/kernel/seq_file.rs b/rust/kernel/seq_file.rs
index 518265558d66f..fbc75e0e77634 100644
--- a/rust/kernel/seq_file.rs
+++ b/rust/kernel/seq_file.rs
@@ -29,6 +29,12 @@ pub unsafe fn from_raw<'a>(ptr: *mut bindings::seq_file) -> &'a SeqFile {
         unsafe { &*ptr.cast() }
     }
 
+    /// Returns a raw pointer to the underlying `struct seq_file`.
+    #[inline]
+    pub fn as_raw(&self) -> *mut bindings::seq_file {
+        self.inner.get()
+    }
+
     /// Used by the [`seq_print`] macro.
     #[inline]
     pub fn call_printf(&self, args: fmt::Arguments<'_>) {

-- 
2.43.0

