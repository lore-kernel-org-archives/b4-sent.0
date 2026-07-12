From: Younes Akhouayri <git@younes.io>
Date: Sun, 12 Jul 2026 15:39:46 +0200
Subject: [PATCH] rust: drm: Fix typo in FEAT_RENDER documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-docs-drm-feat-render-rustdoc-typo-v1-1-c9df1cbbce4b@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWN2wrCMBBEf6XsswttqQb8FfEhl6mNYFp2U6mU/
 ruJPi1nZji7k0IilK7NToJ31DinAt2pIT/Z9ADHUJj6tr+0pus5zF45yItH2MyCFCAsq+ZScP4
 sM8OYwdnhPJZLxbMIxrj9ftzuf9bVPeFzFdeFswp2YpOfalRtnLBlOo4vWD1XTaEAAAA=
X-Change-ID: 20260712-docs-drm-feat-render-rustdoc-typo-e774ba45f774
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783863604; l=1163;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=nFTIjsRD4bAT2kAKAWEo3ns3uC/V61sCbGPMbgYLnGE=;
 b=mJDT9j37Cs4ako4ZtN9x7e2ECNdlWeueLgwKLlhevca2zuiuJ861CYUDa37FTGv3U8yA3AtLM
 +tGJLO4D6O/AQOqrADyKe9FAKoYweLjol7FDYAkRMMUR1nfF0iAS3vy
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct the spelling of "privilege" in the DRIVER_RENDER Rustdoc.

Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/drm/driver.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/drm/driver.rs b/rust/kernel/drm/driver.rs
index 25f7e233884d..1dff81442b61 100644
--- a/rust/kernel/drm/driver.rs
+++ b/rust/kernel/drm/driver.rs
@@ -125,7 +125,7 @@ pub trait Driver {
     /// Sets the `DRIVER_RENDER` feature for this driver.
     ///
     /// When enabled, the driver exposes `/dev/dri/renderDXX` render nodes to
-    /// userspace. The render node is an alternate low-priviledge way to access
+    /// userspace. The render node is an alternate low-privilege way to access
     /// the driver, which is enforced on a per-ioctl level. Userspace processes
     /// that open the render node can only invoke ioctls explicitly listed as
     /// usable from the render node (i.e. marked DRM_RENDER_ALLOW), whereas

---
base-commit: 8cdeaa50eae8dad34885515f62559ee83e7e8dda
change-id: 20260712-docs-drm-feat-render-rustdoc-typo-e774ba45f774

Best regards,
--  
Younes Akhouayri <git@younes.io>

