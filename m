From: Dave Airlie <airlied@redhat.com>
Date: Tue, 03 Nov 2026 10:33:38 +1000
Subject: [PATCH v3 1/2] rust: time: expose as_nanos for clock sources.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nova-timer-v3-1-0cf9bbae8fd9@redhat.com>
References: <20261103-nova-timer-v3-0-0cf9bbae8fd9@redhat.com>
In-Reply-To: <20261103-nova-timer-v3-0-0cf9bbae8fd9@redhat.com>
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=792; i=airlied@redhat.com;
 h=from:subject:message-id; bh=pY3ItZTyRBqrXe1s0swCsV4mLrXTPTHBAc2wQUfEkfs=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq6SvvuMdC0YZcKfwwRh5+Chrb8yGgeHkwOrhnn
 qssdm91hpWJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCaukr7wAKCRAMdPNZecSG
 vniPD/9aSMYxOBOjmA7A223lAdd7J2iJcfUjUEoueoZHWD9q6o+1eROV5AcWcnwbGU372ou77j9
 Q6Pyh2mUB8wzJpqZMSHKCbwp8u5oXcdNGHCRb3LwpDmm3NOU9D9rQ66d8sNlLwdw6fiEaS7rTao
 h8NR2MU4/l6m57od5jN7+eJeKT4QhpiiHxDOyu9n3NZTVNTrHx0nowBcLGjeIc03EaTS2bcg5MV
 N+PiMoEFxCZ4zEc+Sky/xoqiFne8YUPVeWvSVxOoNjs2YWaoQaunnFFqbgoktm/+kqV95tufY+D
 3+iwPVDSH7vzuyeN5V15mMcjk0lWUFFk4FYVu4WOBsPvHzBIAwFm2e/NvmEKqYHDIuQ9RcZkiu+
 O3OLFXPH6AEVxR881tR4pTQiUkl5eQBZS3QWrK8i6TpAroQpALKkx1H8luSa096zYmr1WDNFCfp
 5ema1ki0ky5o0eIriRQYeZV+2Wp0F8T/DOSsutHuHUh5HsCb+OKnWbEKd3eLFsUKJW/HAkit7zX
 k21+uPPOq0NF7mQb2c5G+gXB/bv2IO9UAXyNyDISNQgZwpjyHuU0KZwQ1KwWiKBErBYVdiI7b2X
 3H3nxd8/3QoPtq77CbS/QvfVoiUfTpt4x93+L8f0hyZiBrSXgU+ipb8NEl/YnnjHqGPIDy0kJvR
 WqNwrvbBcn8sLqQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nouveau C driver does ktime_to_ns(ktime_get()) to program
the cpu ns into some hw/fw, so allow this method for rust drivers.

Reviewed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 rust/kernel/time.rs | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/time.rs b/rust/kernel/time.rs
index 6c0a5e8090d0..a91ddf04785b 100644
--- a/rust/kernel/time.rs
+++ b/rust/kernel/time.rs
@@ -211,8 +211,9 @@ pub fn elapsed(&self) -> Delta {
         Self::now() - *self
     }
 
+    /// Return the raw nanoseconds values since the epoch of clock `C`.
     #[inline]
-    pub(crate) fn as_nanos(&self) -> i64 {
+    pub fn as_nanos(&self) -> i64 {
         self.inner
     }
 

-- 
2.56.0

