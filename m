From: Peder Bergan <peder.bergan@gmail.com>
Date: Wed, 18 Nov 2026 11:39:59 +0100
Subject: [PATCH] rust: xarray: capture the iterator lifetime explicitly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-cleanup-xarray-precise-capture-v1-1-43e148eadea4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAH6A/WoC/yWN2wrCMAyGX2Xk2uA6sIivIl6kMXMVrSVpZTL27
 nZ6+f3HBUw0isGpW0DlHS2+UgO364AnSjfBeG0MQz9459wR+SGUasaZVOmDWYWjCTLlUlXQhbH
 3zh/Y8whtpPljnH8H58ufrYa7cNlWt0SgVg9KiadNqtmKCj33Wq1gkrnAun4BvZgxN6cAAAA=
X-Change-ID: 20261118-cleanup-xarray-precise-capture-1bf06165c6cf
To: Tamir Duberstein <tamird@kernel.org>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Miguel Ojeda <ojeda@kernel.org>
Cc: Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794998398; l=1477;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=BUiadxipdagmI2NAgF2mTTigbq84tSd2XDg8WwXyp/8=;
 b=orptA4Jd5c4u5bYxSkoiI+Ni+VLEozHmOlAP+QBxekc76Uf+67HjjjghbjfRMaHV1zgXptIK0
 c4MJTSOl8SXBbtBlSaYMX66UsQHdJNIofQx2uGTKBYEQ7gfdIVgQ3br
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

XArray::iter uses an outlives bound to capture the lifetime of the
borrow of self in the returned iterator. Its caller consumes the
iterator during pinned drop and does not need an outlives guarantee.

Use a precise capturing bound to name the borrowed lifetime. Also
include T, since the bound must list all in-scope type parameters.

Suggested-by: Jesung Yang <y.j3ms.n@gmail.com>
Link: https://github.com/Rust-for-Linux/linux/issues/1175
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
The XArray KUnit doctest passed on x86-64 QEMU. The Rust kernel
crate built with CLIPPY=1.

OpenAI Codex assisted with the signature changes, testing and
drafting this commit message.
---
 rust/kernel/xarray.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/xarray.rs b/rust/kernel/xarray.rs
index 987c9c0c2198..4a67e7f24335 100644
--- a/rust/kernel/xarray.rs
+++ b/rust/kernel/xarray.rs
@@ -108,7 +108,7 @@ pub fn new(kind: AllocKind) -> impl PinInit<Self> {
         })
     }
 
-    fn iter(&self) -> impl Iterator<Item = NonNull<c_void>> + '_ {
+    fn iter(&self) -> impl Iterator<Item = NonNull<c_void>> + use<'_, T> {
         let mut index = 0;
 
         // SAFETY: `self.xa` is always valid by the type invariant.

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261118-cleanup-xarray-precise-capture-1bf06165c6cf

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

